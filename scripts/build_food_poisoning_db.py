#!/usr/bin/env python3
"""Build a local SQLite database from food poisoning annual PDFs."""

from __future__ import annotations

import argparse
import hashlib
import re
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import fitz


TABLE_TYPE_BY_NO = {
    "一": "monthly",
    "二": "pathogen",
    "三": "food_category",
    "四": "eating_place",
    "五": "contamination_place",
}

HEADER_LINES = {
    "月別",
    "件數",
    "案件數",
    "通報案件數",
    "患者數",
    "死亡數",
    "死者數",
    "病因物質",
    "原因食品",
    "攝食場所",
    "場所",
}


@dataclass(frozen=True)
class SourceFile:
    path: Path
    year: int
    is_canonical: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", default="食物中毒", help="Directory containing annual PDFs")
    parser.add_argument("--output", default="data/food_poisoning.sqlite", help="SQLite output path")
    return parser.parse_args()


def roc_year_from_name(path: Path) -> int:
    match = re.search(r"民國(\d+)年", path.name)
    if not match:
        raise ValueError(f"Cannot find ROC year in filename: {path}")
    return int(match.group(1))


def get_source_files(source_dir: Path) -> list[SourceFile]:
    pdfs = sorted(source_dir.glob("*.pdf"), key=lambda p: (roc_year_from_name(p), "(1)" in p.name, p.name))
    canonical_by_year: dict[int, Path] = {}
    for pdf in pdfs:
        year = roc_year_from_name(pdf)
        canonical_by_year.setdefault(year, pdf)
        if "(1)" not in pdf.name:
            canonical_by_year[year] = pdf
    return [
        SourceFile(path=pdf, year=roc_year_from_name(pdf), is_canonical=(canonical_by_year[roc_year_from_name(pdf)] == pdf))
        for pdf in pdfs
    ]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_pdf_text(path: Path) -> tuple[str, int]:
    with fitz.open(path) as doc:
        text = "\n".join(page.get_text() for page in doc)
        return text, len(doc)


def clean_line(line: str) -> str:
    return re.sub(r"\s+", " ", line.strip())


def is_number(line: str) -> bool:
    return bool(re.fullmatch(r"\d[\d,]*", line))


def to_int(line: str) -> int:
    return int(line.replace(",", ""))


def table_blocks(text: str) -> list[tuple[str, str, str]]:
    pattern = re.compile(r"(表([一二三四五六七八九十]+)[：:][^\n]*)")
    matches = list(pattern.finditer(text))
    blocks = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        table_no = match.group(2)
        title = clean_line(match.group(1))
        blocks.append((table_no, title, text[match.end() : end]))
    return blocks


def normalize_item(raw_item: str) -> str:
    item = raw_item.replace("＊", "").replace("*", "")
    item = re.sub(r"\s+", " ", item).strip()
    month = re.search(r"(\d{1,2})\s*月", item)
    if month:
        return f"{int(month.group(1))} 月"
    compact = re.sub(r"\s+", "", item)
    if re.search(r"總+計+", compact):
        return "總計"
    if re.search(r"合+計+", compact):
        return "合計"
    item = re.sub(r"(?<=[\u4e00-\u9fff）)])\d+$", "", item)
    return item.strip()


def table_rows(block: str) -> list[tuple[str, str, int, int, int, int]]:
    lines = [clean_line(line) for line in block.splitlines()]
    lines = [line for line in lines if line]
    rows: list[tuple[str, str, int, int, int, int]] = []
    label_parts: list[str] = []
    row_order = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if (
            line in HEADER_LINES
            or "單位" in line
            or "食品中毒案件" in line
            or line in {"案", "人", "：", "，", "（", "）", "年"}
        ):
            i += 1
            continue
        if re.fullmatch(r"\d+", line) and not label_parts:
            i += 1
            continue
        if is_number(line) and i + 2 < len(lines) and is_number(lines[i + 1]) and is_number(lines[i + 2]) and label_parts:
            raw_item = " ".join(label_parts).strip()
            item = normalize_item(raw_item)
            rows.append((raw_item, item, to_int(line), to_int(lines[i + 1]), to_int(lines[i + 2]), row_order))
            row_order += 1
            label_parts = []
            i += 3
            continue
        if not is_number(line):
            label_parts.append(line)
        i += 1
    return rows


def is_total_item(item: str) -> bool:
    compact = re.sub(r"\s+", "", item)
    return compact.startswith(("總計", "合計")) or bool(re.search(r"總+計+|合+計+", compact))


def is_summary_item(item: str) -> bool:
    return "小計" in item or "合計" in item or is_total_item(item)


def month_from_item(item: str) -> int | None:
    match = re.search(r"(\d{1,2})\s*月", item)
    if not match:
        return None
    month = int(match.group(1))
    return month if 1 <= month <= 12 else None


def create_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        DROP TABLE IF EXISTS source_files;
        DROP TABLE IF EXISTS pdf_texts;
        DROP TABLE IF EXISTS table_rows;
        DROP TABLE IF EXISTS yearly_totals;
        DROP TABLE IF EXISTS monthly_stats;
        DROP TABLE IF EXISTS category_stats;

        CREATE TABLE source_files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            roc_year INTEGER NOT NULL,
            gregorian_year INTEGER NOT NULL,
            filename TEXT NOT NULL,
            relative_path TEXT NOT NULL,
            size_bytes INTEGER NOT NULL,
            sha256 TEXT NOT NULL,
            page_count INTEGER NOT NULL,
            is_canonical INTEGER NOT NULL
        );

        CREATE TABLE pdf_texts (
            source_file_id INTEGER PRIMARY KEY,
            raw_text TEXT NOT NULL,
            FOREIGN KEY (source_file_id) REFERENCES source_files(id)
        );

        CREATE TABLE table_rows (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_file_id INTEGER NOT NULL,
            roc_year INTEGER NOT NULL,
            table_no TEXT NOT NULL,
            table_type TEXT NOT NULL,
            table_title TEXT NOT NULL,
            row_order INTEGER NOT NULL,
            raw_item TEXT NOT NULL,
            item TEXT NOT NULL,
            cases INTEGER NOT NULL,
            patients INTEGER NOT NULL,
            deaths INTEGER NOT NULL,
            is_total INTEGER NOT NULL,
            is_summary INTEGER NOT NULL,
            FOREIGN KEY (source_file_id) REFERENCES source_files(id)
        );

        CREATE TABLE yearly_totals (
            roc_year INTEGER PRIMARY KEY,
            gregorian_year INTEGER NOT NULL,
            cases INTEGER NOT NULL,
            patients INTEGER NOT NULL,
            deaths INTEGER NOT NULL,
            source_file_id INTEGER NOT NULL,
            FOREIGN KEY (source_file_id) REFERENCES source_files(id)
        );

        CREATE TABLE monthly_stats (
            roc_year INTEGER NOT NULL,
            gregorian_year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            cases INTEGER NOT NULL,
            patients INTEGER NOT NULL,
            deaths INTEGER NOT NULL,
            source_file_id INTEGER NOT NULL,
            PRIMARY KEY (roc_year, month),
            FOREIGN KEY (source_file_id) REFERENCES source_files(id)
        );

        CREATE TABLE category_stats (
            roc_year INTEGER NOT NULL,
            gregorian_year INTEGER NOT NULL,
            category_type TEXT NOT NULL,
            item TEXT NOT NULL,
            raw_item TEXT NOT NULL,
            cases INTEGER NOT NULL,
            patients INTEGER NOT NULL,
            deaths INTEGER NOT NULL,
            is_total INTEGER NOT NULL,
            is_summary INTEGER NOT NULL,
            source_file_id INTEGER NOT NULL,
            FOREIGN KEY (source_file_id) REFERENCES source_files(id)
        );

        CREATE INDEX idx_table_rows_year_type ON table_rows (roc_year, table_type);
        CREATE INDEX idx_category_stats_type_item ON category_stats (category_type, item);
        CREATE INDEX idx_monthly_stats_month ON monthly_stats (month);
        """
    )


def insert_source(conn: sqlite3.Connection, source: SourceFile, text: str, page_count: int) -> int:
    stat = source.path.stat()
    cur = conn.execute(
        """
        INSERT INTO source_files (
            roc_year, gregorian_year, filename, relative_path, size_bytes, sha256, page_count, is_canonical
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            source.year,
            source.year + 1911,
            source.path.name,
            source.path.as_posix(),
            stat.st_size,
            sha256_file(source.path),
            page_count,
            int(source.is_canonical),
        ),
    )
    source_file_id = int(cur.lastrowid)
    conn.execute("INSERT INTO pdf_texts (source_file_id, raw_text) VALUES (?, ?)", (source_file_id, text))
    return source_file_id


def build_database(source_dir: Path, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()

    conn = sqlite3.connect(output_path)
    try:
        create_schema(conn)
        conn.execute(
            "CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)"
        )
        conn.execute(
            "INSERT INTO metadata (key, value) VALUES (?, ?)",
            ("created_at", datetime.now(timezone.utc).isoformat()),
        )
        conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)", ("source_dir", source_dir.as_posix()))

        source_files = get_source_files(source_dir)
        for source in source_files:
            text, page_count = extract_pdf_text(source.path)
            source_file_id = insert_source(conn, source, text, page_count)
            if not source.is_canonical:
                continue

            for table_no, title, block in table_blocks(text):
                table_type = TABLE_TYPE_BY_NO.get(table_no, f"table_{table_no}")
                for raw_item, item, cases, patients, deaths, row_order in table_rows(block):
                    is_total = int(is_total_item(item))
                    is_summary = int(is_summary_item(item))
                    conn.execute(
                        """
                        INSERT INTO table_rows (
                            source_file_id, roc_year, table_no, table_type, table_title, row_order,
                            raw_item, item, cases, patients, deaths, is_total, is_summary
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            source_file_id,
                            source.year,
                            table_no,
                            table_type,
                            title,
                            row_order,
                            raw_item,
                            item,
                            cases,
                            patients,
                            deaths,
                            is_total,
                            is_summary,
                        ),
                    )

                    if table_type == "monthly":
                        month = month_from_item(item)
                        if month:
                            conn.execute(
                                """
                                INSERT INTO monthly_stats (
                                    roc_year, gregorian_year, month, cases, patients, deaths, source_file_id
                                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                                """,
                                (source.year, source.year + 1911, month, cases, patients, deaths, source_file_id),
                            )
                        elif is_total:
                            conn.execute(
                                """
                                INSERT OR REPLACE INTO yearly_totals (
                                    roc_year, gregorian_year, cases, patients, deaths, source_file_id
                                ) VALUES (?, ?, ?, ?, ?, ?)
                                """,
                                (source.year, source.year + 1911, cases, patients, deaths, source_file_id),
                            )
                    elif table_type in {"pathogen", "food_category", "eating_place", "contamination_place"}:
                        conn.execute(
                            """
                            INSERT INTO category_stats (
                                roc_year, gregorian_year, category_type, item, raw_item, cases, patients, deaths,
                                is_total, is_summary, source_file_id
                            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            """,
                            (
                                source.year,
                                source.year + 1911,
                                table_type,
                                item,
                                raw_item,
                                cases,
                                patients,
                                deaths,
                                is_total,
                                is_summary,
                                source_file_id,
                            ),
                        )

        conn.commit()
    finally:
        conn.close()


def main() -> None:
    args = parse_args()
    build_database(Path(args.source_dir), Path(args.output))


if __name__ == "__main__":
    main()
