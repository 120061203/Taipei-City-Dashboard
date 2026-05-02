#!/usr/bin/env python3
"""
Seed script for food_hygiene_management_work table.

直接從主計處下載 CSV 並寫入 postgres-data，不依賴 Airflow。
用法：
    python3 seed_data.py
環境變數（選填，預設值如下）：
    DB_HOST      postgres-data 的 host（預設 localhost）
    DB_PORT      預設 5432
    DB_USER      預設 postgres
    DB_PASSWORD  預設空字串
    DB_NAME      預設 dashboard
"""

import os
import ssl
import urllib.request
from datetime import datetime, timezone
from io import StringIO

import pandas as pd
from sqlalchemy import create_engine, text

# ── DB 連線設定 ──────────────────────────────────────────────
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "dashboard")

URL = (
    "https://tsis.dbas.gov.taipei/statis/webMain.aspx"
    "?sys=220&ymf=5900&kind=21&type=0&funid=a05031801"
    "&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1"
)

TABLE = "food_hygiene_management_work"


def fetch_csv() -> pd.DataFrame:
    print(f"下載資料：{URL}")
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(URL, context=ctx) as resp:
        return pd.read_csv(StringIO(resp.read().decode("utf-8-sig")))


def transform(raw: pd.DataFrame) -> pd.DataFrame:
    data = raw.copy()
    column_mapping = {}
    for col in data.columns:
        if "統計期" in col:
            column_mapping[col] = "year"
        elif "不合格飭令改善家次" in col and col.count("/") == 1:
            column_mapping[col] = "non_compliant_visits"
        elif "稽查家次" in col and col.count("/") == 1:
            column_mapping[col] = "inspection_visits"
        elif "食品中毒人數" in col:
            column_mapping[col] = "food_poisoning_cases"
    data = data.rename(columns=column_mapping)
    data = data[["year", "inspection_visits", "non_compliant_visits", "food_poisoning_cases"]].copy()
    data["year"] = data["year"].astype(str).str.replace(r"[^\d]", "", regex=True).astype(int) + 1911
    data = data.dropna()
    for col in ["inspection_visits", "non_compliant_visits", "food_poisoning_cases"]:
        data[col] = pd.to_numeric(data[col], errors="coerce").fillna(0).astype(int)
    data["data_time"] = datetime.now(timezone.utc)
    return data


def load(data: pd.DataFrame, engine) -> None:
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {TABLE}"))
    data.to_sql(TABLE, engine, if_exists="append", index=False)
    print(f"寫入 {len(data)} 筆資料到 {TABLE}")


def main():
    db_url = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    engine = create_engine(db_url)

    raw = fetch_csv()
    print(f"下載完成，共 {len(raw)} 筆原始資料")

    data = transform(raw)
    print(f"轉換完成，年份範圍：{data['year'].min()} ~ {data['year'].max()}")

    load(data, engine)
    print("完成！")


if __name__ == "__main__":
    main()
