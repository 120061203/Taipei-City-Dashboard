-- Food safety tables for postgres-data (dashboard DB)
-- Run by food_safety_etl.py before inserting normalized data rows.
-- Uses CREATE TABLE IF NOT EXISTS + TRUNCATE to preserve schema on re-runs.

CREATE TABLE IF NOT EXISTS food_inspection_failures (
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
);
TRUNCATE TABLE food_inspection_failures RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_hygiene_grade (
    id              SERIAL PRIMARY KEY,
    city            TEXT,
    source_file     TEXT,
    district_code   TEXT,
    district        TEXT,
    business_name   TEXT,
    registration_id TEXT,
    address         TEXT,
    grade           TEXT
);
TRUNCATE TABLE food_hygiene_grade RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_haccp_inspection (
    id            SERIAL PRIMARY KEY,
    city          TEXT,
    source_file   TEXT,
    district_code TEXT,
    district      TEXT,
    business_name TEXT,
    address       TEXT,
    category      TEXT
);
TRUNCATE TABLE food_haccp_inspection RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_market_spec_failures (
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
);
TRUNCATE TABLE food_market_spec_failures RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_agri_label_sampling (
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
);
TRUNCATE TABLE food_agri_label_sampling RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_hygiene_work (
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
);
TRUNCATE TABLE food_hygiene_work RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_business_count (
    id             SERIAL PRIMARY KEY,
    city           TEXT,
    source_file    TEXT,
    dataset_name   TEXT,
    business_count INTEGER,
    scope          TEXT
);
TRUNCATE TABLE food_business_count RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS food_check_work (
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
);
TRUNCATE TABLE food_check_work RESTART IDENTITY;

CREATE TABLE IF NOT EXISTS district_food_risk (
    x_axis TEXT PRIMARY KEY,
    data NUMERIC(6,2)
);
ALTER TABLE district_food_risk ADD COLUMN IF NOT EXISTS inspection_failure_count INTEGER;
ALTER TABLE district_food_risk ADD COLUMN IF NOT EXISTS graded_business_count INTEGER;
ALTER TABLE district_food_risk ADD COLUMN IF NOT EXISTS excellent_grade_count INTEGER;
ALTER TABLE district_food_risk ADD COLUMN IF NOT EXISTS excellent_grade_rate NUMERIC(6,2);
ALTER TABLE district_food_risk ADD COLUMN IF NOT EXISTS haccp_business_count INTEGER;
TRUNCATE TABLE district_food_risk;

-- Drop legacy tables from earlier ETL versions
DROP TABLE IF EXISTS food_inspection_trend;
DROP TABLE IF EXISTS food_inspection_by_district;
DROP TABLE IF EXISTS agri_sampling_pass_rate;

-- ============================================================
-- Sample data for dashboard demonstration
-- ============================================================

-- food_hygiene_work: 臺北市歷年食品中毒人數（用於 foodborne_illness_trend 折線圖）
INSERT INTO food_hygiene_work (city, year, inspection_visits, failed_improvement_visits, food_poisoning_people) VALUES
('taipei', 2014, 58432, 1203, 820),
('taipei', 2015, 61245, 1156, 763),
('taipei', 2016, 63180, 1289, 695),
('taipei', 2017, 65432, 1102, 612),
('taipei', 2018, 67890, 1345, 758),
('taipei', 2019, 69123, 1234, 834),
('taipei', 2020, 55678, 987,  543),
('taipei', 2021, 57234, 1023, 489),
('taipei', 2022, 62341, 1189, 671),
('taipei', 2023, 68902, 1312, 892),
('taipei', 2024, 71234, 1401, 945),
('taipei', 2025, 70821, 1367, 909),
-- 新北市113年（2024）食品中毒人數
('ntpc', 2024, NULL, NULL, 1288);

-- food_hygiene_grade: 臺北市餐飲衛生優級店家（用於 food_grade_rank 柱狀圖）
INSERT INTO food_hygiene_grade (city, district, business_name, grade) VALUES
('taipei', '大安區', '某餐廳01', '優'), ('taipei', '大安區', '某餐廳02', '優'), ('taipei', '大安區', '某餐廳03', '優'), ('taipei', '大安區', '某餐廳04', '優'), ('taipei', '大安區', '某餐廳05', '優'),
('taipei', '大安區', '某餐廳06', '優'), ('taipei', '大安區', '某餐廳07', '優'), ('taipei', '大安區', '某餐廳08', '優'), ('taipei', '大安區', '某餐廳09', '優'), ('taipei', '大安區', '某餐廳10', '優'),
('taipei', '大安區', '某餐廳11', '優'), ('taipei', '大安區', '某餐廳12', '優'), ('taipei', '大安區', '某餐廳13', '優'), ('taipei', '大安區', '某餐廳14', '優'), ('taipei', '大安區', '某餐廳15', '優'),
('taipei', '大安區', '某餐廳16', '優'), ('taipei', '大安區', '某餐廳17', '優'), ('taipei', '大安區', '某餐廳18', '優'), ('taipei', '大安區', '某餐廳19', '優'), ('taipei', '大安區', '某餐廳20', '優'),
('taipei', '信義區', '某餐廳21', '優'), ('taipei', '信義區', '某餐廳22', '優'), ('taipei', '信義區', '某餐廳23', '優'), ('taipei', '信義區', '某餐廳24', '優'), ('taipei', '信義區', '某餐廳25', '優'),
('taipei', '信義區', '某餐廳26', '優'), ('taipei', '信義區', '某餐廳27', '優'), ('taipei', '信義區', '某餐廳28', '優'), ('taipei', '信義區', '某餐廳29', '優'), ('taipei', '信義區', '某餐廳30', '優'),
('taipei', '信義區', '某餐廳31', '優'), ('taipei', '信義區', '某餐廳32', '優'), ('taipei', '信義區', '某餐廳33', '優'), ('taipei', '信義區', '某餐廳34', '優'), ('taipei', '信義區', '某餐廳35', '優'),
('taipei', '信義區', '某餐廳36', '優'), ('taipei', '信義區', '某餐廳37', '優'), ('taipei', '信義區', '某餐廳38', '優'),
('taipei', '中山區', '某餐廳39', '優'), ('taipei', '中山區', '某餐廳40', '優'), ('taipei', '中山區', '某餐廳41', '優'), ('taipei', '中山區', '某餐廳42', '優'), ('taipei', '中山區', '某餐廳43', '優'),
('taipei', '中山區', '某餐廳44', '優'), ('taipei', '中山區', '某餐廳45', '優'), ('taipei', '中山區', '某餐廳46', '優'), ('taipei', '中山區', '某餐廳47', '優'), ('taipei', '中山區', '某餐廳48', '優'),
('taipei', '中山區', '某餐廳49', '優'), ('taipei', '中山區', '某餐廳50', '優'), ('taipei', '中山區', '某餐廳51', '優'), ('taipei', '中山區', '某餐廳52', '優'), ('taipei', '中山區', '某餐廳53', '優'),
('taipei', '中山區', '某餐廳54', '優'), ('taipei', '中山區', '某餐廳55', '優'),
('taipei', '內湖區', '某餐廳56', '優'), ('taipei', '內湖區', '某餐廳57', '優'), ('taipei', '內湖區', '某餐廳58', '優'), ('taipei', '內湖區', '某餐廳59', '優'), ('taipei', '內湖區', '某餐廳60', '優'),
('taipei', '內湖區', '某餐廳61', '優'), ('taipei', '內湖區', '某餐廳62', '優'), ('taipei', '內湖區', '某餐廳63', '優'), ('taipei', '內湖區', '某餐廳64', '優'), ('taipei', '內湖區', '某餐廳65', '優'),
('taipei', '內湖區', '某餐廳66', '優'), ('taipei', '內湖區', '某餐廳67', '優'), ('taipei', '內湖區', '某餐廳68', '優'), ('taipei', '內湖區', '某餐廳69', '優'), ('taipei', '內湖區', '某餐廳70', '優'),
('taipei', '士林區', '某餐廳71', '優'), ('taipei', '士林區', '某餐廳72', '優'), ('taipei', '士林區', '某餐廳73', '優'), ('taipei', '士林區', '某餐廳74', '優'), ('taipei', '士林區', '某餐廳75', '優'),
('taipei', '士林區', '某餐廳76', '優'), ('taipei', '士林區', '某餐廳77', '優'), ('taipei', '士林區', '某餐廳78', '優'), ('taipei', '士林區', '某餐廳79', '優'), ('taipei', '士林區', '某餐廳80', '優'),
('taipei', '士林區', '某餐廳81', '優'), ('taipei', '士林區', '某餐廳82', '優'), ('taipei', '士林區', '某餐廳83', '優'),
('taipei', '文山區', '某餐廳84', '優'), ('taipei', '文山區', '某餐廳85', '優'), ('taipei', '文山區', '某餐廳86', '優'), ('taipei', '文山區', '某餐廳87', '優'), ('taipei', '文山區', '某餐廳88', '優'),
('taipei', '文山區', '某餐廳89', '優'), ('taipei', '文山區', '某餐廳90', '優'), ('taipei', '文山區', '某餐廳91', '優'), ('taipei', '文山區', '某餐廳92', '優'), ('taipei', '文山區', '某餐廳93', '優'),
('taipei', '文山區', '某餐廳94', '優'), ('taipei', '文山區', '某餐廳95', '優'),
('taipei', '松山區', '某餐廳96', '優'), ('taipei', '松山區', '某餐廳97', '優'), ('taipei', '松山區', '某餐廳98', '優'), ('taipei', '松山區', '某餐廳99', '優'), ('taipei', '松山區', '某餐廳100', '優'),
('taipei', '松山區', '某餐廳101', '優'), ('taipei', '松山區', '某餐廳102', '優'), ('taipei', '松山區', '某餐廳103', '優'), ('taipei', '松山區', '某餐廳104', '優'), ('taipei', '松山區', '某餐廳105', '優'),
('taipei', '北投區', '某餐廳106', '優'), ('taipei', '北投區', '某餐廳107', '優'), ('taipei', '北投區', '某餐廳108', '優'), ('taipei', '北投區', '某餐廳109', '優'), ('taipei', '北投區', '某餐廳110', '優'),
('taipei', '北投區', '某餐廳111', '優'), ('taipei', '北投區', '某餐廳112', '優'), ('taipei', '北投區', '某餐廳113', '優'), ('taipei', '北投區', '某餐廳114', '優'),
('taipei', '中正區', '某餐廳115', '優'), ('taipei', '中正區', '某餐廳116', '優'), ('taipei', '中正區', '某餐廳117', '優'), ('taipei', '中正區', '某餐廳118', '優'), ('taipei', '中正區', '某餐廳119', '優'),
('taipei', '中正區', '某餐廳120', '優'), ('taipei', '中正區', '某餐廳121', '優'), ('taipei', '中正區', '某餐廳122', '優'),
('taipei', '南港區', '某餐廳123', '優'), ('taipei', '南港區', '某餐廳124', '優'), ('taipei', '南港區', '某餐廳125', '優'), ('taipei', '南港區', '某餐廳126', '優'), ('taipei', '南港區', '某餐廳127', '優'),
('taipei', '南港區', '某餐廳128', '優'), ('taipei', '南港區', '某餐廳129', '優'),
('taipei', '大同區', '某餐廳130', '優'), ('taipei', '大同區', '某餐廳131', '優'), ('taipei', '大同區', '某餐廳132', '優'), ('taipei', '大同區', '某餐廳133', '優'), ('taipei', '大同區', '某餐廳134', '優'),
('taipei', '大同區', '某餐廳135', '優'),
('taipei', '萬華區', '某餐廳136', '優'), ('taipei', '萬華區', '某餐廳137', '優'), ('taipei', '萬華區', '某餐廳138', '優'), ('taipei', '萬華區', '某餐廳139', '優'), ('taipei', '萬華區', '某餐廳140', '優');

-- food_inspection_failures: 臺北市食品抽驗不合格（用於 food_inspection_failures 鑽取圖）
INSERT INTO food_inspection_failures (city, sample_name, district, result) VALUES
('taipei', '芫荽', '大安區', '不合格'), ('taipei', '香菜', '信義區', '不合格'), ('taipei', '九層塔', '中山區', '不合格'), ('taipei', '九層塔', '士林區', '不合格'),
('taipei', '辣椒', '內湖區', '不合格'), ('taipei', '辣椒', '文山區', '不合格'), ('taipei', '辣椒', '大安區', '不合格'), ('taipei', '青蔥', '北投區', '不合格'),
('taipei', '青蔥', '中正區', '不合格'), ('taipei', '芹菜', '大安區', '不合格'), ('taipei', '芹菜', '信義區', '不合格'),
('taipei', '草莓', '大安區', '不合格'), ('taipei', '草莓', '信義區', '不合格'), ('taipei', '草莓', '中山區', '不合格'), ('taipei', '草莓', '士林區', '不合格'),
('taipei', '葡萄', '內湖區', '不合格'), ('taipei', '葡萄', '文山區', '不合格'), ('taipei', '芒果', '松山區', '不合格'),
('taipei', '青江菜', '大安區', '不合格'), ('taipei', '青江菜', '信義區', '不合格'), ('taipei', '菠菜', '中山區', '不合格'), ('taipei', '菠菜', '內湖區', '不合格'),
('taipei', '高麗菜', '士林區', '不合格'), ('taipei', '高麗菜', '文山區', '不合格'), ('taipei', '高麗菜', '北投區', '不合格'),
('taipei', '豆干', '大安區', '不合格'), ('taipei', '豆腐', '信義區', '不合格'), ('taipei', '豆腐', '中山區', '不合格'), ('taipei', '花生', '士林區', '不合格'),
('taipei', '馬鈴薯', '內湖區', '不合格'), ('taipei', '白蘿蔔', '文山區', '不合格'), ('taipei', '白蘿蔔', '松山區', '不合格'),
('taipei', '豬肉', '大安區', '不合格'), ('taipei', '雞肉', '信義區', '不合格'), ('taipei', '魚', '中山區', '不合格'), ('taipei', '蝦', '士林區', '不合格'),
('taipei', '豬肉', '內湖區', '不合格'), ('taipei', '雞蛋', '文山區', '不合格'), ('taipei', '雞蛋', '北投區', '不合格'), ('taipei', '魚', '松山區', '不合格'),
('taipei', '木耳', '大安區', '不合格'), ('taipei', '香菇', '信義區', '不合格'), ('taipei', '香菇', '中山區', '不合格'),
('taipei', '茶葉', '大安區', '不合格'), ('taipei', '菊花', '信義區', '不合格');

-- district_food_risk: 行政區食安風險指數（正規化 0-100，以各區抽驗不合格件數 / 最大值 * 100）
INSERT INTO district_food_risk (x_axis, data, inspection_failure_count, graded_business_count, excellent_grade_count, excellent_grade_rate) VALUES
('大安區', 100.0, 9, 1250, 20, 1.60),
('信義區',  88.9, 8, 980, 18, 1.84),
('中山區',  66.7, 6, 1100, 17, 1.55),
('文山區',  55.6, 5, 810, 12, 1.48),
('士林區',  55.6, 5, 870, 13, 1.49),
('內湖區',  55.6, 5, 920, 15, 1.63),
('北投區',  33.3, 3, 690, 9, 1.30),
('松山區',  33.3, 3, 760, 10, 1.32),
('中正區',  11.1, 1, 720, 8, 1.11),
('南港區',   0.0, 0, 580, 7, 1.21),
('大同區',   0.0, 0, 540, 6, 1.11),
('萬華區',   0.0, 0, 620, 5, 0.81);
