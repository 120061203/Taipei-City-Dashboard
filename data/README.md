# 食品中毒本地資料庫

`food_poisoning.sqlite` 是由根目錄 `食物中毒/` 內的年度 PDF 建出的本地 SQLite DB。

重建方式：

```bash
python3 scripts/build_food_poisoning_db.py
```

腳本使用 Python 的 `fitz` / PyMuPDF 讀取 PDF；目前本機環境已可直接執行。

匯出給前端四格 dashboard 的食物中毒患者數資料：

```bash
python3 scripts/export_food_poisoning_chart_data.py
```

匯出結果會寫到 `Taipei-City-Dashboard-FE/src/store/foodPoisoningPatientsData.js`，供 `foodSafetyMock.js` 的 `9003` 食物中毒元件使用。

主要資料表：

- `source_files`: 每份 PDF 的年度、檔名、頁數、大小、SHA-256；民國 94 年重複檔會保留，但只有 canonical 檔用於結構化資料。
- `pdf_texts`: 每份 PDF 抽出的全文，方便回查原始內容。
- `table_rows`: PDF 表一到表五抽出的原始表格列。
- `yearly_totals`: 各年度總案件數、患者數、死亡數。
- `monthly_stats`: 各年度 1–12 月案件數、患者數、死亡數。
- `category_stats`: 病因物質、原因食品、攝食場所、污染或處置錯誤場所等分類統計。

常用查詢：

```sql
SELECT roc_year, gregorian_year, cases, patients, deaths
FROM yearly_totals
ORDER BY roc_year;

SELECT month, cases, patients, deaths
FROM monthly_stats
WHERE roc_year = 114
ORDER BY month;

SELECT item, cases, patients, deaths
FROM category_stats
WHERE roc_year = 114
  AND category_type = 'pathogen'
  AND is_summary = 0
ORDER BY cases DESC;
```
