import json
import csv

input_file = "Open Data.json"
output_file = "Open Data Summary.csv"

with open(input_file, encoding="utf-8") as f:
    data = json.load(f)

fields = ["資料集名稱", "主題分類", "資料集描述", "主要欄位說明"]

with open(output_file, "w", encoding="utf-8-sig", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
    writer.writeheader()
    writer.writerows(data)

print(f"完成，共匯出 {len(data)} 筆 → {output_file}")
