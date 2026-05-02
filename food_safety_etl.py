#!/usr/bin/env python3
"""
Food-safety ETL for Taipei-City-Dashboard.

Downloads Taipei food-safety raw resources, cleans them, writes JSON outputs,
and optionally loads the results into the Dashboard PostgreSQL databases.

Outputs:
- public/foodSafety/raw/*: downloaded source files
- public/foodSafety/normalized/*.json: cleaned records by dataset
- public/foodSafety/dashboard/*.json: chart-ready aggregates
- public/foodSafety/catalog_inventory.json: dataset availability inventory

DB load (default on, skip with --skip-db):
- postgres-data: creates/replaces 5 chart data tables
- postgres-manager: registers 5 components + '食品安全' dashboard
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# ── DB settings ──────────────────────────────────────────────────────────────
_POSTGRES_DATA_CONTAINER = "postgres-data"
_POSTGRES_MANAGER_CONTAINER = "postgres-manager"
_PG_USER = "postgres"
_DATA_DB = "dashboard"
_MANAGER_DB = "dashboardmanager"
_DASHBOARD_INDEX = "food_safety_taipei"
_DASHBOARD_NAME = "食品安全"
_DASHBOARD_ICON = "verified"


REPO_ROOT = Path(__file__).resolve().parent
DEFAULT_FOOD_SAFETY_DIR = REPO_ROOT / "Taipei-City-Dashboard-FE" / "public" / "foodSafety"
DEFAULT_RAW_DIR = DEFAULT_FOOD_SAFETY_DIR / "raw"

TAIPEI_OPEN_DATA_BASE_URL = "https://data.taipei"

TAIPEI_DISTRICTS = {
    "100": "中正區",
    "103": "大同區",
    "104": "中山區",
    "105": "松山區",
    "106": "大安區",
    "108": "萬華區",
    "110": "信義區",
    "111": "士林區",
    "112": "北投區",
    "114": "內湖區",
    "115": "南港區",
    "116": "文山區",
}

TAIPEI_DISTRICT_CODE_SUFFIX = {
    "0010": "松山區",
    "0020": "信義區",
    "0030": "大安區",
    "0040": "中山區",
    "0050": "中正區",
    "0060": "大同區",
    "0070": "萬華區",
    "0080": "文山區",
    "0090": "南港區",
    "0100": "內湖區",
    "0110": "士林區",
    "0120": "北投區",
}

FOOD_SAFETY_TARGETS = [
    {
        "key": "taipei_inspection_failures",
        "city": "taipei",
        "dataset_id": "09a917a0-0fb5-47e1-957c-5f1268fba517",
        "name": "臺北市衛生局食品抽驗不合格清冊",
        "agency": "衛生局",
        "update_frequency": "每1年",
        "role": "食品抽驗不合格紀錄",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=09a917a0-0fb5-47e1-957c-5f1268fba517",
        "access_urls": [
            "https://data.taipei/api/dataset/09a917a0-0fb5-47e1-957c-5f1268fba517/resource/bb347e3d-626a-46e5-bb96-9061e8d08c26/download",
            "https://data.taipei/api/dataset/09a917a0-0fb5-47e1-957c-5f1268fba517/resource/bc24a40f-5687-4338-8f9a-449de248ab93/download",
            "https://data.taipei/api/dataset/09a917a0-0fb5-47e1-957c-5f1268fba517/resource/3fc106cb-c8aa-4f74-8dbc-3272c7ffcae0/download",
        ],
        "raw_glob": "taipei_inspection_failures-*.csv",
        "raw_files": [
            "taipei_inspection_failures-1.csv",
            "taipei_inspection_failures-2.csv",
            "taipei_inspection_failures-3.csv",
        ],
    },
    {
        "key": "taipei_hygiene_grade",
        "city": "taipei",
        "dataset_id": "59579c19-a561-4564-8c0f-545bfb32c0f6",
        "name": "臺北市通過餐飲衛生管理分級評核業者",
        "agency": "衛生局",
        "update_frequency": "每1年",
        "role": "餐飲衛生分級評核業者",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=59579c19-a561-4564-8c0f-545bfb32c0f6",
        "access_urls": [
            "https://data.taipei/api/dataset/59579c19-a561-4564-8c0f-545bfb32c0f6/resource/c5646d80-9118-4439-b924-075f96371d75/download",
        ],
        "raw_glob": "taipei_hygiene_grade.csv",
        "raw_files": ["taipei_hygiene_grade.csv"],
    },
    {
        "key": "taipei_haccp_inspection",
        "city": "taipei",
        "dataset_id": "bb665f7f-085c-40f9-9b9a-844e46da9c65",
        "name": "臺北市HACCP稽查",
        "agency": "衛生局",
        "update_frequency": "不定期更新",
        "role": "HACCP 稽查業者",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=bb665f7f-085c-40f9-9b9a-844e46da9c65",
        "access_urls": [
            "https://data.taipei/api/dataset/bb665f7f-085c-40f9-9b9a-844e46da9c65/resource/43839156-d54e-48e5-a957-ada2f228f655/download",
        ],
        "raw_glob": "taipei_haccp_inspection.csv",
        "raw_files": ["taipei_haccp_inspection.csv"],
    },
    {
        "key": "taipei_market_mass_spec_failures",
        "city": "taipei",
        "dataset_id": "ad63197e-217c-472b-a63f-94b0d29d0e7a",
        "name": "臺北市批發市場質譜化學快檢不合格統計資料",
        "agency": "產業局市場處",
        "update_frequency": "每1月",
        "role": "批發市場質譜化學快檢不合格統計",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=ad63197e-217c-472b-a63f-94b0d29d0e7a",
        "access_urls": [
            "https://data.taipei/api/dataset/ad63197e-217c-472b-a63f-94b0d29d0e7a/resource/617777b1-5082-4efb-b372-1a57951bd6aa/download",
        ],
        "raw_glob": "taipei_market_mass_spec_failures.csv",
        "raw_files": ["taipei_market_mass_spec_failures.csv"],
    },
    {
        "key": "taipei_agri_label_sampling",
        "city": "taipei",
        "dataset_id": "8ab917b0-1029-4003-b776-f169b4e561f1",
        "name": "臺北市政府標章農產品抽檢清冊",
        "agency": "產業局",
        "update_frequency": "不定期更新",
        "role": "標章農產品抽檢合格率",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=8ab917b0-1029-4003-b776-f169b4e561f1",
        "access_urls": [
            "https://data.taipei/api/dataset/8ab917b0-1029-4003-b776-f169b4e561f1/resource/b93ade0e-8492-4f82-97f3-e30fdd13cd9f/download",
        ],
        "raw_glob": "taipei_agri_label_sampling.csv",
        "raw_files": ["taipei_agri_label_sampling.csv"],
    },
    {
        "key": "taipei_food_hygiene_work",
        "city": "taipei",
        "dataset_id": "7d50657f-b35b-496e-b83f-5713893b9a9e",
        "name": "臺北市食品衛生管理工作",
        "agency": "主計處",
        "update_frequency": "每1年",
        "role": "食品衛生稽查與不合格改善",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=7d50657f-b35b-496e-b83f-5713893b9a9e",
        "access_urls": [
            "https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=5900&kind=21&type=0&funid=a05031801&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1",
        ],
        "raw_glob": "taipei_food_hygiene_work.aspx",
        "raw_files": ["taipei_food_hygiene_work.aspx"],
    },
    {
        "key": "taipei_food_business_count",
        "city": "taipei",
        "dataset_id": "9431f450-57d6-4c23-aca6-0ff50de49f0d",
        "name": "臺北市食品業者登錄數",
        "agency": "衛生局",
        "update_frequency": "不定期更新",
        "role": "食品業者登錄數",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=9431f450-57d6-4c23-aca6-0ff50de49f0d",
        "access_urls": [
            "https://data.taipei/api/dataset/9431f450-57d6-4c23-aca6-0ff50de49f0d/resource/2227c204-5f9f-4b20-8c6d-c6048eab6475/download",
        ],
        "raw_glob": "taipei_food_business_count.csv",
        "raw_files": ["taipei_food_business_count.csv"],
    },
    {
        "key": "taipei_food_check_work",
        "city": "taipei",
        "dataset_id": "c3ae074c-f65f-4f69-bf65-2c00a674e870",
        "name": "臺北市食品衛生管理查驗工作",
        "agency": "主計處",
        "update_frequency": "每1年",
        "role": "食品衛生查驗不符比率",
        "dataset_page_url": f"{TAIPEI_OPEN_DATA_BASE_URL}/dataset/detail?id=c3ae074c-f65f-4f69-bf65-2c00a674e870",
        "access_urls": [
            "https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=8100&ymt=9400&kind=21&type=0&funid=a05032001&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1",
            "https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=9500&kind=21&type=0&funid=a05032002&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1",
        ],
        "raw_glob": "taipei_food_check_work-*.aspx",
        "raw_files": [
            "taipei_food_check_work-1.aspx",
            "taipei_food_check_work-2.aspx",
        ],
    },
]


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def decode_text(path: Path) -> tuple[str, str]:
    data = path.read_bytes()
    for encoding in ("utf-8-sig", "utf-8", "big5", "cp950"):
        try:
            return data.decode(encoding), encoding
        except UnicodeDecodeError:
            continue
    return data.decode("utf-8", errors="replace"), "utf-8-replace"


def read_csv_rows(path: Path) -> tuple[list[dict[str, str]], str]:
    text, encoding = decode_text(path)
    reader = csv.DictReader(text.splitlines())
    rows = []
    for row in reader:
        cleaned = {(key or "").strip(): (value or "").strip() for key, value in row.items()}
        rows.append(cleaned)
    return rows, encoding


def raw_file_names(target: dict[str, Any], access_url_count: int) -> list[str]:
    configured = target.get("raw_files") or []
    if len(configured) >= access_url_count:
        return configured[:access_url_count]

    suffix = ".csv"
    if str(target.get("raw_glob", "")).endswith(".aspx"):
        suffix = ".aspx"

    return [f"{target['key']}-{index + 1}{suffix}" for index in range(access_url_count)]


def download_url(url: str, path: Path) -> None:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Taipei-City-Dashboard food safety ETL/1.0",
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        path.write_bytes(response.read())


def download_raw_files(
    raw_dir: Path,
    refresh: bool,
) -> list[dict[str, Any]]:
    raw_dir.mkdir(parents=True, exist_ok=True)
    results = []

    for target in FOOD_SAFETY_TARGETS:
        access_urls = target.get("access_urls", [])
        filenames = raw_file_names(target, len(access_urls))
        target_results = []

        for url, filename in zip(access_urls, filenames):
            output_path = raw_dir / filename
            if output_path.exists() and not refresh:
                target_results.append(
                    {
                        "file": filename,
                        "url": url,
                        "status": "skipped_existing",
                        "bytes": output_path.stat().st_size,
                    }
                )
                continue

            try:
                download_url(url, output_path)
                target_results.append(
                    {
                        "file": filename,
                        "url": url,
                        "status": "downloaded",
                        "bytes": output_path.stat().st_size,
                    }
                )
            except (OSError, urllib.error.URLError, urllib.error.HTTPError) as error:
                target_results.append(
                    {
                        "file": filename,
                        "url": url,
                        "status": "error",
                        "error": str(error),
                    }
                )

        if not access_urls:
            target_results.append(
                {
                    "status": "no_access_url",
                    "error": "Catalog item has no downloadable resource URL.",
                }
            )

        results.append({"key": target["key"], "resources": target_results})

    return results


def to_int(value: Any) -> int | None:
    if value is None:
        return None
    cleaned = str(value).replace(",", "").strip()
    if cleaned in ("", "-", "--"):
        return None
    match = re.search(r"-?\d+", cleaned)
    return int(match.group(0)) if match else None


def to_float(value: Any) -> float | None:
    if value is None:
        return None
    cleaned = str(value).replace(",", "").replace("%", "").strip()
    if cleaned in ("", "-", "--"):
        return None
    try:
        return float(cleaned)
    except ValueError:
        return None


def parse_year(value: Any) -> int | None:
    if value is None:
        return None
    match = re.search(r"\d{2,4}", str(value))
    if not match:
        return None
    year = int(match.group(0))
    if year < 1911:
        year += 1911
    return year


def parse_date(value: Any) -> str | None:
    raw = re.sub(r"\D", "", str(value or ""))
    if len(raw) == 8 and raw.startswith("20"):
        year, month, day = int(raw[:4]), int(raw[4:6]), int(raw[6:8])
    elif len(raw) == 7:
        year, month, day = int(raw[:3]) + 1911, int(raw[3:5]), int(raw[5:7])
    elif len(raw) == 6:
        year, month, day = int(raw[:2]) + 1911, int(raw[2:4]), int(raw[4:6])
    else:
        return None
    try:
        return datetime(year, month, day).date().isoformat()
    except ValueError:
        return None


def district_from_code(code: Any) -> str | None:
    text = str(code or "").strip()
    if text in TAIPEI_DISTRICTS:
        return TAIPEI_DISTRICTS[text]
    suffix = text[-4:]
    return TAIPEI_DISTRICT_CODE_SUFFIX.get(suffix)


def district_from_text(value: Any) -> str | None:
    text = str(value or "")
    for district in TAIPEI_DISTRICTS.values():
        if district in text:
            return district
    return None


def split_place(value: str) -> tuple[str | None, str | None]:
    text = (value or "").strip()
    city_match = re.search(r"[臺台]北市", text)
    if city_match:
        name = text[: city_match.start()].rstrip(" /")
        address = text[city_match.start() :]
        return name or None, address or None
    if "/" not in text:
        return text or None, None
    name, address = text.rsplit("/", 1)
    return name.strip() or None, address.strip() or None


def count_by(rows: list[dict[str, Any]], field: str) -> list[dict[str, Any]]:
    counter = Counter(row.get(field) or "未分類" for row in rows)
    return [{"name": key, "count": value} for key, value in counter.most_common()]


def rows_from_files(raw_dir: Path, pattern: str) -> tuple[list[dict[str, str]], list[dict[str, Any]]]:
    rows: list[dict[str, str]] = []
    sources = []
    for path in sorted(raw_dir.glob(pattern)):
        file_rows, encoding = read_csv_rows(path)
        sources.append({"file": path.name, "encoding": encoding, "rows": len(file_rows)})
        for row in file_rows:
            row["_source_file"] = path.name
            rows.append(row)
    return rows, sources


def normalize_inspection_failures(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        business_name, address = split_place(row.get("抽驗地點", ""))
        date = parse_date(row.get("抽驗日期"))
        postal_code = row.get("抽驗行政郵遞區號") or None
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "project": row.get("專案名稱") or None,
                "sample_date": date,
                "year": int(date[:4]) if date else None,
                "category": row.get("分類") or None,
                "sample_name": row.get("檢體名稱") or None,
                "postal_code": postal_code,
                "district": district_from_code(postal_code) or district_from_text(address),
                "business_name": business_name,
                "address": address,
                "result": row.get("檢驗結果") or None,
                "reason": row.get("不符合規定原因") or None,
            }
        )
    return output


def normalize_hygiene_grade(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        address = row.get("地址") or None
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "district_code": row.get("行政區域代碼") or None,
                "district": district_from_code(row.get("行政區域代碼")) or district_from_text(address),
                "business_name": row.get("業者名稱店名") or None,
                "registration_id": row.get("食品業者登錄字號") or None,
                "address": address,
                "grade": row.get("評核結果") or None,
            }
        )
    return output


def normalize_haccp(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        address = row.get("地址") or None
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "district_code": row.get("行政區域代碼") or None,
                "district": district_from_code(row.get("行政區域代碼")) or district_from_text(address),
                "business_name": row.get("業者名稱") or None,
                "address": address,
                "category": row.get("類別") or None,
            }
        )
    return output


def normalize_market_failures(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        date = parse_date(row.get("抽驗日期"))
        weight = to_float(row.get("總重量（公斤）") or row.get("總重量(公斤)"))
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "sample_date": date,
                "year": int(date[:4]) if date else None,
                "sample_name": row.get("檢體名稱") or None,
                "supplier_code": row.get("供應代號") or None,
                "supplier": row.get("來源廠商") or None,
                "case_count": to_int(row.get("件數")),
                "total_weight_kg": weight,
                "follow_up_date": parse_date(row.get("加強抽驗/到貨日期")),
                "follow_up_result": row.get("加強抽驗結果") or None,
                "note": row.get("備註") or None,
            }
        )
    return output


def normalize_agri_label_sampling(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        year = parse_year(row.get("年度"))
        total = to_int(row.get("抽驗件數/場"))
        passed = to_int(row.get("合格[件/場]"))
        failed = to_int(row.get("不合格[件/場]"))
        pass_rate = to_float(row.get("合格率"))
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "year": year,
                "check_type": row.get("類別") or None,
                "item": row.get("項目") or None,
                "sample_count": total,
                "passed_count": passed,
                "failed_count": failed,
                "pass_rate": pass_rate,
            }
        )
    return output


def normalize_food_business_count(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    return [
        {
            "city": row.get("行政區") or "臺北市",
            "source_file": row["_source_file"],
            "dataset_name": row.get("資料集名稱") or None,
            "business_count": to_int(row.get("食品業者登錄數")),
            "scope": row.get("內容") or None,
        }
        for row in raw_rows
    ]


def normalize_food_check_work(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        reason_counts = {}
        for key, value in row.items():
            clean_key = key.strip()
            if clean_key.startswith("與規定不符件數按原因別/"):
                reason = clean_key.split("/", 1)[1].replace("[件]", "")
                reason_counts[reason] = to_int(value) or 0
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "year": parse_year(row.get("統計期")),
                "checked_total": to_int(row.get("查驗件數/總計[件]")),
                "checked_inspection": to_int(row.get("查驗件數/檢查[件]") or row.get("查驗件數/查核[件]")),
                "checked_lab": to_int(row.get("查驗件數/檢驗[件]")),
                "failed_total": to_int(row.get("與規定不符件數/總計[件]")),
                "failed_inspection": to_int(row.get("與規定不符件數/檢查[件]") or row.get("與規定不符件數/查核[件]")),
                "failed_lab": to_int(row.get("與規定不符件數/檢驗[件]")),
                "failure_rate": to_float(row.get("不符規定比率[%]")),
                "reason_counts": reason_counts,
                "transferred_unclosed": to_int(row.get("移外縣市未結案[件]")),
            }
        )
    return output


def normalize_food_hygiene_work(raw_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    output = []
    for row in raw_rows:
        output.append(
            {
                "city": "臺北市",
                "source_file": row["_source_file"],
                "year": parse_year(row.get("統計期")),
                "inspection_visits": to_int(row.get("食品衛生管理稽查工作/稽查家次[家次]")),
                "failed_improvement_visits": to_int(row.get("食品衛生管理稽查工作/不合格飭令改善家次[家次]")),
                "food_poisoning_people": to_int(row.get("食品中毒人數[人]")),
                "restaurant_inspection_visits": to_int(row.get("食品衛生管理稽查工作/餐飲店/稽查家次[家次]")),
                "restaurant_failed_improvement_visits": to_int(row.get("食品衛生管理稽查工作/餐飲店/不合格飭令改善家次[家次]")),
                "market_inspection_visits": to_int(row.get("食品衛生管理稽查工作/傳統市場/稽查家次[家次]")),
                "market_failed_improvement_visits": to_int(row.get("食品衛生管理稽查工作/傳統市場/不合格飭令改善家次[家次]")),
            }
        )
    return output


NORMALIZERS = {
    "taipei_inspection_failures": normalize_inspection_failures,
    "taipei_hygiene_grade": normalize_hygiene_grade,
    "taipei_haccp_inspection": normalize_haccp,
    "taipei_market_mass_spec_failures": normalize_market_failures,
    "taipei_agri_label_sampling": normalize_agri_label_sampling,
    "taipei_food_hygiene_work": normalize_food_hygiene_work,
    "taipei_food_business_count": normalize_food_business_count,
    "taipei_food_check_work": normalize_food_check_work,
}


def build_inventory(raw_dir: Path) -> list[dict[str, Any]]:
    inventory = []
    for target in FOOD_SAFETY_TARGETS:
        raw_files = sorted(path.name for path in raw_dir.glob(target["raw_glob"]))
        status = "raw_available" if raw_files else "not_downloaded"
        item = {
            "key": target["key"],
            "city": target["city"],
            "dataset_id": target["dataset_id"],
            "name": target["name"],
            "agency": target["agency"],
            "update_frequency": target["update_frequency"],
            "role": target["role"],
            "dataset_page_url": target["dataset_page_url"],
            "access_urls": target["access_urls"],
            "raw_glob": target["raw_glob"],
            "expected_raw_files": target["raw_files"],
            "status": status,
            "raw_files": raw_files,
        }
        inventory.append(item)
    return inventory


def build_food_inspection_dashboard(rows: list[dict[str, Any]]) -> dict[str, Any]:
    sorted_rows = sorted(rows, key=lambda row: row.get("sample_date") or "", reverse=True)
    return {
        "summary": {
            "total_failures": len(rows),
            "latest_sample_date": sorted_rows[0].get("sample_date") if sorted_rows else None,
            "district_count": len({row.get("district") for row in rows if row.get("district")}),
        },
        "by_year": count_by(rows, "year"),
        "by_district": count_by(rows, "district"),
        "by_category": count_by(rows, "category"),
        "latest_records": sorted_rows[:500],
    }


def build_food_grade_dashboard(grades: list[dict[str, Any]], haccp: list[dict[str, Any]]) -> dict[str, Any]:
    by_district: dict[str, Counter[str]] = defaultdict(Counter)
    for row in grades:
        by_district[row.get("district") or "未分類"][row.get("grade") or "未分類"] += 1

    district_rows = []
    for district, counter in by_district.items():
        total = sum(counter.values())
        excellent = counter.get("優", 0)
        district_rows.append(
            {
                "district": district,
                "total": total,
                "excellent": excellent,
                "good": counter.get("良", 0),
                "excellent_rate": round(excellent / total * 100, 2) if total else None,
            }
        )

    district_rows.sort(key=lambda row: (row["excellent_rate"] or 0, row["total"]), reverse=True)
    return {
        "summary": {
            "graded_businesses": len(grades),
            "haccp_businesses": len(haccp),
        },
        "by_grade": count_by(grades, "grade"),
        "by_district": district_rows,
        "haccp_by_district": count_by(haccp, "district"),
        "records": grades,
    }


def build_market_dashboard(
    market_failures: list[dict[str, Any]],
    agri_sampling: list[dict[str, Any]],
) -> dict[str, Any]:
    agri_by_year: dict[int, dict[str, Any]] = {}
    for row in agri_sampling:
        year = row.get("year")
        if not year:
            continue
        bucket = agri_by_year.setdefault(year, {"year": year, "sample_count": 0, "passed_count": 0, "failed_count": 0})
        bucket["sample_count"] += row.get("sample_count") or 0
        bucket["passed_count"] += row.get("passed_count") or 0
        bucket["failed_count"] += row.get("failed_count") or 0

    for bucket in agri_by_year.values():
        total = bucket["sample_count"]
        bucket["pass_rate"] = round(bucket["passed_count"] / total * 100, 2) if total else None

    return {
        "summary": {
            "market_failure_records": len(market_failures),
            "agri_sampling_rows": len(agri_sampling),
        },
        "market_failures_by_year": count_by(market_failures, "year"),
        "market_failures_by_item": count_by(market_failures, "sample_name"),
        "agri_sampling_by_year": sorted(agri_by_year.values(), key=lambda row: row["year"]),
        "agri_sampling_rows": agri_sampling,
        "market_failure_records": market_failures,
    }


def build_district_risk_dashboard(
    failures: list[dict[str, Any]],
    grades: list[dict[str, Any]],
    haccp: list[dict[str, Any]],
    business_counts: list[dict[str, Any]],
    check_work: list[dict[str, Any]],
    hygiene_work: list[dict[str, Any]],
) -> dict[str, Any]:
    districts = sorted(set(TAIPEI_DISTRICTS.values()))
    failure_counter = Counter(row.get("district") for row in failures if row.get("district"))
    grade_counter = Counter(row.get("district") for row in grades if row.get("district"))
    excellent_counter = Counter(row.get("district") for row in grades if row.get("grade") == "優" and row.get("district"))
    haccp_counter = Counter(row.get("district") for row in haccp if row.get("district"))

    district_rows = []
    for district in districts:
        graded = grade_counter[district]
        excellent_rate = excellent_counter[district] / graded * 100 if graded else None
        risk_score = min(
            100,
            round(
                failure_counter[district] * 6
                + ((100 - excellent_rate) * 0.35 if excellent_rate is not None else 0),
                2,
            ),
        )
        district_rows.append(
            {
                "district": district,
                "inspection_failure_count": failure_counter[district],
                "graded_business_count": graded,
                "excellent_grade_count": excellent_counter[district],
                "excellent_grade_rate": round(excellent_rate, 2) if excellent_rate is not None else None,
                "haccp_business_count": haccp_counter[district],
                "risk_score": risk_score,
            }
        )

    district_rows.sort(key=lambda row: row["risk_score"], reverse=True)
    latest_check = max(check_work, key=lambda row: row.get("year") or 0, default=None)
    latest_hygiene = max(hygiene_work, key=lambda row: row.get("year") or 0, default=None)

    return {
        "summary": {
            "districts": len(district_rows),
            "city_business_count": business_counts[0].get("business_count") if business_counts else None,
            "latest_check_work": latest_check,
            "latest_hygiene_work": latest_hygiene,
        },
        "by_district": district_rows,
        "check_work_by_year": sorted(check_work, key=lambda row: row.get("year") or 0),
        "hygiene_work_by_year": sorted(hygiene_work, key=lambda row: row.get("year") or 0),
    }


# ── DB helpers ───────────────────────────────────────────────────────────────

def _s(value: str | None) -> str:
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def _pg_array(items: list[str]) -> str:
    return "ARRAY[" + ", ".join(_s(i) for i in items) + "]"


def _run_sql(container: str, db: str, sql: str) -> None:
    result = subprocess.run(
        ["docker", "exec", "-i", container, "psql", "-U", _PG_USER, "-d", db, "-v", "ON_ERROR_STOP=1"],
        input=sql.encode(),
        capture_output=True,
    )
    if result.returncode != 0:
        print(f"[ERROR] SQL failed on {container}/{db}:\n{result.stderr.decode()}", file=sys.stderr)
        sys.exit(1)


def _val(v: Any) -> str:
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, dict):
        return _s(json.dumps(v, ensure_ascii=False))
    return _s(str(v))


def _insert_rows(table: str, columns: list[str], rows: list[dict[str, Any]]) -> str:
    if not rows:
        return ""
    cols = ", ".join(columns)
    values = ",\n  ".join(
        "(" + ", ".join(_val(row.get(c)) for c in columns) + ")"
        for row in rows
    )
    return f"INSERT INTO {table} ({cols}) VALUES\n  {values};\n"


def _create_normalized_tables(normalized: dict[str, list[dict[str, Any]]], dashboards: dict[str, Any]) -> None:
    stmts: list[str] = []

    # ── 1. food_inspection_failures ──────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_inspection_failures;
CREATE TABLE food_inspection_failures (
    id            SERIAL PRIMARY KEY,
    city          TEXT,
    source_file   TEXT,
    project       TEXT,
    sample_date   DATE,
    year          INTEGER,
    category      TEXT,
    sample_name   TEXT,
    postal_code   TEXT,
    district      TEXT,
    business_name TEXT,
    address       TEXT,
    result        TEXT,
    reason        TEXT
);""")
    stmts.append(_insert_rows(
        "food_inspection_failures",
        ["city", "source_file", "project", "sample_date", "year", "category",
         "sample_name", "postal_code", "district", "business_name", "address", "result", "reason"],
        normalized.get("taipei_inspection_failures", []),
    ))

    # ── 2. food_hygiene_grade ─────────────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_hygiene_grade;
CREATE TABLE food_hygiene_grade (
    id              SERIAL PRIMARY KEY,
    city            TEXT,
    source_file     TEXT,
    district_code   TEXT,
    district        TEXT,
    business_name   TEXT,
    registration_id TEXT,
    address         TEXT,
    grade           TEXT
);""")
    stmts.append(_insert_rows(
        "food_hygiene_grade",
        ["city", "source_file", "district_code", "district", "business_name", "registration_id", "address", "grade"],
        normalized.get("taipei_hygiene_grade", []),
    ))

    # ── 3. food_haccp_inspection ──────────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_haccp_inspection;
CREATE TABLE food_haccp_inspection (
    id            SERIAL PRIMARY KEY,
    city          TEXT,
    source_file   TEXT,
    district_code TEXT,
    district      TEXT,
    business_name TEXT,
    address       TEXT,
    category      TEXT
);""")
    stmts.append(_insert_rows(
        "food_haccp_inspection",
        ["city", "source_file", "district_code", "district", "business_name", "address", "category"],
        normalized.get("taipei_haccp_inspection", []),
    ))

    # ── 4. food_market_spec_failures ──────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_market_spec_failures;
CREATE TABLE food_market_spec_failures (
    id               SERIAL PRIMARY KEY,
    city             TEXT,
    source_file      TEXT,
    sample_date      DATE,
    year             INTEGER,
    sample_name      TEXT,
    supplier_code    TEXT,
    supplier         TEXT,
    case_count       INTEGER,
    total_weight_kg  NUMERIC,
    follow_up_date   DATE,
    follow_up_result TEXT,
    note             TEXT
);""")
    stmts.append(_insert_rows(
        "food_market_spec_failures",
        ["city", "source_file", "sample_date", "year", "sample_name", "supplier_code",
         "supplier", "case_count", "total_weight_kg", "follow_up_date", "follow_up_result", "note"],
        normalized.get("taipei_market_mass_spec_failures", []),
    ))

    # ── 5. food_agri_label_sampling ───────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_agri_label_sampling;
CREATE TABLE food_agri_label_sampling (
    id            SERIAL PRIMARY KEY,
    city          TEXT,
    source_file   TEXT,
    year          INTEGER,
    check_type    TEXT,
    item          TEXT,
    sample_count  INTEGER,
    passed_count  INTEGER,
    failed_count  INTEGER,
    pass_rate     NUMERIC
);""")
    stmts.append(_insert_rows(
        "food_agri_label_sampling",
        ["city", "source_file", "year", "check_type", "item",
         "sample_count", "passed_count", "failed_count", "pass_rate"],
        normalized.get("taipei_agri_label_sampling", []),
    ))

    # ── 6. food_hygiene_work ──────────────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_hygiene_work;
CREATE TABLE food_hygiene_work (
    id                                    SERIAL PRIMARY KEY,
    city                                  TEXT,
    source_file                           TEXT,
    year                                  INTEGER,
    inspection_visits                     INTEGER,
    failed_improvement_visits             INTEGER,
    food_poisoning_people                 INTEGER,
    restaurant_inspection_visits          INTEGER,
    restaurant_failed_improvement_visits  INTEGER,
    market_inspection_visits              INTEGER,
    market_failed_improvement_visits      INTEGER
);""")
    stmts.append(_insert_rows(
        "food_hygiene_work",
        ["city", "source_file", "year", "inspection_visits", "failed_improvement_visits",
         "food_poisoning_people", "restaurant_inspection_visits", "restaurant_failed_improvement_visits",
         "market_inspection_visits", "market_failed_improvement_visits"],
        normalized.get("taipei_food_hygiene_work", []),
    ))

    # ── 7. food_business_count ────────────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_business_count;
CREATE TABLE food_business_count (
    id             SERIAL PRIMARY KEY,
    city           TEXT,
    source_file    TEXT,
    dataset_name   TEXT,
    business_count INTEGER,
    scope          TEXT
);""")
    stmts.append(_insert_rows(
        "food_business_count",
        ["city", "source_file", "dataset_name", "business_count", "scope"],
        normalized.get("taipei_food_business_count", []),
    ))

    # ── 8. food_check_work ────────────────────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS food_check_work;
CREATE TABLE food_check_work (
    id                   SERIAL PRIMARY KEY,
    city                 TEXT,
    source_file          TEXT,
    year                 INTEGER,
    checked_total        INTEGER,
    checked_inspection   INTEGER,
    checked_lab          INTEGER,
    failed_total         INTEGER,
    failed_inspection    INTEGER,
    failed_lab           INTEGER,
    failure_rate         NUMERIC,
    reason_counts        JSONB,
    transferred_unclosed INTEGER
);""")
    stmts.append(_insert_rows(
        "food_check_work",
        ["city", "source_file", "year", "checked_total", "checked_inspection", "checked_lab",
         "failed_total", "failed_inspection", "failed_lab", "failure_rate",
         "reason_counts", "transferred_unclosed"],
        normalized.get("taipei_food_check_work", []),
    ))

    # ── 9. district_food_risk (computed) ──────────────────────────────────────
    stmts.append("""
DROP TABLE IF EXISTS district_food_risk;
CREATE TABLE district_food_risk (x_axis TEXT, data NUMERIC(6,2));
""")
    for row in sorted(dashboards["district_food_risk"]["by_district"], key=lambda r: -r["risk_score"]):
        stmts.append(f"INSERT INTO district_food_risk VALUES ({_s(row['district'])}, {row['risk_score']});")

    # ── drop old aggregated tables if they exist ──────────────────────────────
    for old_table in ("food_inspection_trend", "food_inspection_by_district", "agri_sampling_pass_rate"):
        stmts.append(f"DROP TABLE IF EXISTS {old_table};")

    _run_sql(_POSTGRES_DATA_CONTAINER, _DATA_DB, "\n".join(stmts))


def _register_components() -> None:
    components = [
        {
            "index": "food_inspection_trend",
            "name": "食品抽驗不合格趨勢",
            "color": ["#E05C5C", "#F5A623"],
            "types": ["ColumnChart"],
            "unit": "件",
            "query_type": "two_d",
            "query_chart": "SELECT year::text AS x_axis, COUNT(*)::integer AS data FROM food_inspection_failures WHERE year IS NOT NULL GROUP BY year ORDER BY year",
            "short_desc": "臺北市食品抽驗不合格件數，依年度統計",
            "long_desc": "資料來源：臺北市衛生局食品抽驗不合格清冊",
            "source": "臺北市衛生局",
            "update_freq": 1,
            "update_freq_unit": "year",
        },
        {
            "index": "food_inspection_by_district",
            "name": "行政區食品抽驗不合格",
            "color": ["#E05C5C"],
            "types": ["BarChart"],
            "unit": "件",
            "query_type": "two_d",
            "query_chart": "SELECT district AS x_axis, COUNT(*)::integer AS data FROM food_inspection_failures WHERE district IS NOT NULL GROUP BY district ORDER BY data DESC",
            "short_desc": "臺北市各行政區食品抽驗不合格件數",
            "long_desc": "資料來源：臺北市衛生局食品抽驗不合格清冊",
            "source": "臺北市衛生局",
            "update_freq": 1,
            "update_freq_unit": "year",
        },
        {
            "index": "food_hygiene_grade",
            "name": "餐飲衛生分級評核",
            "color": ["#56B96D", "#F8CF58"],
            "types": ["BarPercentChart"],
            "unit": "家",
            "query_type": "three_d",
            "query_chart": "SELECT district AS x_axis, NULL::text AS icon, grade AS y_axis, COUNT(*)::integer AS data FROM food_hygiene_grade WHERE district IS NOT NULL AND grade IS NOT NULL GROUP BY district, grade ORDER BY district, grade DESC",
            "short_desc": "臺北市通過餐飲衛生管理分級評核業者，優/良分佈",
            "long_desc": "資料來源：臺北市衛生局餐飲衛生管理分級評核",
            "source": "臺北市衛生局",
            "update_freq": 1,
            "update_freq_unit": "year",
        },
        {
            "index": "district_food_risk",
            "name": "行政區食品安全風險指數",
            "color": ["#F05C5C", "#F5A623", "#56B96D"],
            "types": ["ColumnChart"],
            "unit": "分",
            "query_type": "two_d",
            "query_chart": "SELECT x_axis, data FROM district_food_risk ORDER BY data DESC",
            "short_desc": "依不合格件數與衛生分級計算各行政區風險指數（0–100）",
            "long_desc": "計算公式：不合格件數×6 + (100-優等率)×0.35，最高100分",
            "source": "臺北市衛生局",
            "update_freq": 1,
            "update_freq_unit": "year",
        },
        {
            "index": "agri_sampling_pass_rate",
            "name": "標章農產品抽檢合格率",
            "color": ["#56B96D"],
            "types": ["ColumnChart"],
            "unit": "%",
            "query_type": "two_d",
            "query_chart": "SELECT year::text AS x_axis, ROUND(AVG(pass_rate)::numeric, 2) AS data FROM food_agri_label_sampling WHERE year IS NOT NULL AND pass_rate IS NOT NULL GROUP BY year ORDER BY year",
            "short_desc": "臺北市標章農產品抽驗合格率，依年度統計",
            "long_desc": "資料來源：臺北市政府標章農產品抽檢清冊",
            "source": "臺北市產業局",
            "update_freq": 1,
            "update_freq_unit": "year",
        },
    ]

    stmts: list[str] = []
    for comp in components:
        idx = _s(comp["index"])
        stmts.append(f"""
INSERT INTO components (index, name) VALUES ({idx}, {_s(comp['name'])})
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;
""")
        stmts.append(f"""
INSERT INTO component_charts (index, color, types, unit)
VALUES ({idx}, {_pg_array(comp['color'])}, {_pg_array(comp['types'])}, {_s(comp['unit'])})
ON CONFLICT (index) DO UPDATE
    SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;
""")
        stmts.append(f"""
INSERT INTO query_charts (
    index, city, query_type, query_chart,
    short_desc, long_desc, source,
    update_freq, update_freq_unit, created_at, updated_at
) VALUES (
    {idx}, {_s('taipei')}, {_s(comp['query_type'])}, {_s(comp['query_chart'])},
    {_s(comp['short_desc'])}, {_s(comp['long_desc'])}, {_s(comp['source'])},
    {comp['update_freq']}, {_s(comp['update_freq_unit'])}, NOW(), NOW()
) ON CONFLICT DO NOTHING;
""")

    indices_list = ", ".join(_s(c["index"]) for c in components)
    stmts.append(f"""
DO $$
DECLARE comp_ids INTEGER[];
BEGIN
    SELECT ARRAY_AGG(id ORDER BY id) INTO comp_ids
    FROM components WHERE index IN ({indices_list});
    INSERT INTO dashboards (index, name, components, icon, created_at, updated_at)
    VALUES ({_s(_DASHBOARD_INDEX)}, {_s(_DASHBOARD_NAME)}, comp_ids, {_s(_DASHBOARD_ICON)}, NOW(), NOW())
    ON CONFLICT (index) DO UPDATE
        SET name = EXCLUDED.name, components = EXCLUDED.components,
            icon = EXCLUDED.icon, updated_at = NOW();
END$$;
""")

    _run_sql(_POSTGRES_MANAGER_CONTAINER, _MANAGER_DB, "\n".join(stmts))


def load_to_db(normalized: dict[str, list[dict[str, Any]]], dashboards: dict[str, Any]) -> None:
    print("[db] Creating normalized tables in postgres-data...")
    _create_normalized_tables(normalized, dashboards)
    print("[db] Registering components in postgres-manager...")
    _register_components()
    print(f"[db] Dashboard '{_DASHBOARD_NAME}' ready.")


# ── ETL ───────────────────────────────────────────────────────────────────────

def run_etl(
    raw_dir: Path,
    output_dir: Path,
    skip_download: bool,
    refresh_raw: bool,
    skip_db: bool = False,
) -> dict[str, Any]:
    normalized_dir = output_dir / "normalized"
    dashboard_dir = output_dir / "dashboard"

    download_results = []
    if not skip_download:
        download_results = download_raw_files(raw_dir, refresh_raw)

    inventory = build_inventory(raw_dir)
    normalized: dict[str, list[dict[str, Any]]] = {}
    raw_sources: dict[str, list[dict[str, Any]]] = {}

    for target in FOOD_SAFETY_TARGETS:
        normalizer = NORMALIZERS.get(target["key"])
        if not normalizer:
            continue
        raw_rows, sources = rows_from_files(raw_dir, target["raw_glob"])
        raw_sources[target["key"]] = sources
        rows = normalizer(raw_rows)
        normalized[target["key"]] = rows
        write_json(normalized_dir / f"{target['key']}.json", rows)

    write_json(output_dir / "catalog_inventory.json", inventory)

    dashboards = {
        "food_inspection_failures": build_food_inspection_dashboard(normalized.get("taipei_inspection_failures", [])),
        "food_grade_rank": build_food_grade_dashboard(
            normalized.get("taipei_hygiene_grade", []),
            normalized.get("taipei_haccp_inspection", []),
        ),
        "market_inspection_pass_rate": build_market_dashboard(
            normalized.get("taipei_market_mass_spec_failures", []),
            normalized.get("taipei_agri_label_sampling", []),
        ),
        "district_food_risk": build_district_risk_dashboard(
            normalized.get("taipei_inspection_failures", []),
            normalized.get("taipei_hygiene_grade", []),
            normalized.get("taipei_haccp_inspection", []),
            normalized.get("taipei_food_business_count", []),
            normalized.get("taipei_food_check_work", []),
            normalized.get("taipei_food_hygiene_work", []),
        ),
    }

    for name, data in dashboards.items():
        write_json(dashboard_dir / f"{name}.json", data)

    if not skip_db:
        load_to_db(normalized, dashboards)

    run_summary = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "raw_dir": str(raw_dir),
        "output_dir": str(output_dir),
        "download_mode": "skipped" if skip_download else ("refresh" if refresh_raw else "missing_only"),
        "downloads": download_results,
        "datasets": [
            {
                "key": target["key"],
                "status": next(item["status"] for item in inventory if item["key"] == target["key"]),
                "raw_sources": raw_sources.get(target["key"], []),
                "normalized_rows": len(normalized.get(target["key"], [])),
            }
            for target in FOOD_SAFETY_TARGETS
        ],
        "dashboard_files": [f"dashboard/{name}.json" for name in dashboards],
    }
    write_json(output_dir / "etl_summary.json", run_summary)
    return run_summary


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download and clean Taipei food-safety datasets, then load into Dashboard DBs."
    )
    parser.add_argument("--raw-dir", type=Path, default=DEFAULT_RAW_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_FOOD_SAFETY_DIR)
    parser.add_argument(
        "--skip-download",
        action="store_true",
        help="Only clean existing raw files; do not download missing raw resources.",
    )
    parser.add_argument(
        "--refresh-raw",
        action="store_true",
        help="Download raw resources again even when matching local raw files already exist.",
    )
    parser.add_argument(
        "--skip-db",
        action="store_true",
        help="Skip writing data to PostgreSQL (ETL + JSON output only).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    summary = run_etl(
        args.raw_dir,
        args.output_dir,
        args.skip_download,
        args.refresh_raw,
        args.skip_db,
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
