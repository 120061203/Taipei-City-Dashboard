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


-- market_quality_awards: 雙北優良市集獲獎名單
CREATE TABLE IF NOT EXISTS market_quality_awards (
    id       SERIAL PRIMARY KEY,
    city     TEXT,
    year     INTEGER,
    market_name TEXT,
    grade    INTEGER,
    district TEXT
);
TRUNCATE TABLE market_quality_awards RESTART IDENTITY;
INSERT INTO market_quality_awards (city, year, market_name, grade, district) VALUES
('taipei', 2020, '士東市場', 5, NULL),
('taipei', 2020, '南門市場', 5, NULL),
('taipei', 2020, '寧夏夜市', 5, NULL),
('taipei', 2020, '大直市場', 4, NULL),
('taipei', 2020, '華山市場', 4, NULL),
('taipei', 2020, '士林市場', 4, NULL),
('taipei', 2020, '西湖市場', 3, NULL),
('taipei', 2020, '中崙市場', 3, NULL),
('taipei', 2020, '永樂市場(3樓)', 3, NULL),
('taipei', 2020, '建國假日玉市(社團法人中華玉器藝術文化交流協會)', 3, NULL),
('taipei', 2020, '松江市場', 3, NULL),
('taipei', 2020, '長春市場', 3, NULL),
('taipei', 2020, '光華數位新天地', 3, NULL),
('taipei', 2020, '晴光攤販集中場', 3, NULL),
('taipei', 2020, '東三水街攤販集中場', 3, NULL),
('taipei', 2020, '南機場臨時攤販集中場', 3, NULL),
('taipei', 2020, '華西街攤販集中場', 3, NULL),
('taipei', 2020, '龍山商場(百貨部)', 3, NULL),
('taipei', 2020, '四平街臨時攤販集中場', 3, NULL),
('taipei', 2020, '水源市場', 3, NULL),
('taipei', 2020, '成功市場', 2, NULL),
('taipei', 2020, '公館夜市', 2, NULL),
('taipei', 2020, '永春市場', 2, NULL),
('taipei', 2020, '光復市場', 2, NULL),
('taipei', 2020, '西寧市場(B1)', 2, NULL),
('taipei', 2020, '廣州街攤販集中場', 2, NULL),
('taipei', 2020, '建國假日玉市(社團法人臺北市玉石文物協進會)', 2, NULL),
('taipei', 2020, '成德市場', 2, NULL),
('taipei', 2020, '悟州街攤販集中場', 1, NULL),
('taipei', 2020, '直興市場', 1, NULL),
('taipei', 2020, '安東市場', 1, NULL),
('taipei', 2022, '寧夏夜市', 5, NULL),
('taipei', 2022, '士東市場', 5, NULL),
('taipei', 2022, '南門市場', 5, NULL),
('taipei', 2022, '大直公有零售市場', 4, NULL),
('taipei', 2022, '西湖公有零售市場', 4, NULL),
('taipei', 2022, '中崙公有零售市場', 4, NULL),
('taipei', 2022, '大龍市場', 4, NULL),
('taipei', 2022, '華西街攤販集中場', 4, NULL),
('taipei', 2022, '西寧市場1樓', 4, NULL),
('taipei', 2022, '華山市場', 4, NULL),
('taipei', 2022, '士林夜市', 4, NULL),
('taipei', 2022, '士林市場', 4, NULL),
('taipei', 2022, '士林夜市商圈聯合會', 3, NULL),
('taipei', 2022, '四平街攤販集中場', 3, NULL),
('taipei', 2022, '南機場攤販集中區', 3, NULL),
('taipei', 2022, '艋舺夜市', 3, NULL),
('taipei', 2022, '光華數位新天地', 3, NULL),
('taipei', 2022, '水源市場', 3, NULL),
('taipei', 2022, '長春市場', 3, NULL),
('taipei', 2022, '龍山商場百貨部', 3, NULL),
('taipei', 2022, '永樂市場3樓', 3, NULL),
('taipei', 2022, '晴光攤販集中區', 3, NULL),
('taipei', 2022, '安東市場', 2, NULL),
('taipei', 2022, '松江市場', 2, NULL),
('taipei', 2022, '雙城街攤販集中場', 2, NULL),
('taipei', 2022, '公館夜市', 2, NULL),
('taipei', 2022, '梧州街攤販集中場', 2, NULL),
('taipei', 2022, '廣州街攤販集中場', 2, NULL),
('taipei', 2022, '西園路二段140巷攤販集中場', 2, NULL),
('taipei', 2022, '西門市場', 2, NULL),
('taipei', 2022, '西寧市場地下1樓', 2, NULL),
('taipei', 2022, '大稻埕慈聖宮美食街', 2, NULL),
('taipei', 2022, '新富市場', 2, NULL),
('taipei', 2022, '龍山商場飲食部', 2, NULL),
('taipei', 2022, '光復市場', 2, NULL),
('taipei', 2022, '建國市場', 1, NULL),
('taipei', 2022, '錦安市場', 1, NULL),
('taipei', 2022, '成德市場', 1, NULL),
('taipei', 2022, '直興市場', 1, NULL),
('taipei', 2023, '士東市場', 5, NULL),
('taipei', 2023, '寧夏路臨時攤販集中場', 5, NULL),
('taipei', 2023, '南門市場', 5, NULL),
('taipei', 2024, '士林夜市(社團法人台北市士林夜市商圈聯合會)', 5, NULL),
('taipei', 2024, '士林夜市(社團法人台北市士林夜市國際觀光發展協會)', 5, NULL),
('taipei', 2024, '寧夏夜市', 5, NULL),
('taipei', 2024, '華西街觀光夜市', 4, NULL),
('taipei', 2023, '士林夜市(臺北市士林夜市商圈聯合會)', 4, NULL),
('taipei', 2023, '士林夜市(臺北市士林夜市國際觀光發展協會)', 4, NULL),
('taipei', 2023, '士林市場', 4, NULL),
('taipei', 2023, '大龍市場', 4, NULL),
('taipei', 2023, '成功市場', 4, NULL),
('taipei', 2023, '大直市場', 4, NULL),
('taipei', 2023, '光華數位新天地', 4, NULL),
('taipei', 2023, '南機場臨時攤販集中場', 4, NULL),
('taipei', 2023, '華山市場', 4, NULL),
('taipei', 2023, '西湖市場', 4, NULL),
('taipei', 2023, '中崙市場', 4, NULL),
('taipei', 2023, '永春市場', 4, NULL),
('taipei', 2023, '東三水街攤販集中場', 4, NULL),
('taipei', 2023, '西寧市場一樓', 4, NULL),
('taipei', 2023, '永樂市場1樓', 3, NULL),
('taipei', 2023, '永樂商場3樓', 3, NULL),
('taipei', 2023, '安東市場', 3, NULL),
('taipei', 2023, '錦安市場', 3, NULL),
('taipei', 2023, '臨江街臨時攤販集中場', 3, NULL),
('taipei', 2023, '四平街臨時攤販集中場', 3, NULL),
('taipei', 2023, '松江市場', 3, NULL),
('taipei', 2023, '晴光臨時攤販集中場', 3, NULL),
('taipei', 2023, '遼寧街臨時攤販集中場', 3, NULL),
('taipei', 2023, '雙城街臨時攤販集中場', 3, NULL),
('taipei', 2023, '公館夜市', 3, NULL),
('taipei', 2023, '水源市場', 3, NULL),
('taipei', 2023, '東門市場', 3, NULL),
('taipei', 2023, '木柵市場', 3, NULL),
('taipei', 2023, '興隆市場', 3, NULL),
('taipei', 2023, '北投中繼市場', 3, NULL),
('taipei', 2023, '龍城市場', 3, NULL),
('taipei', 2023, '光復市場', 3, NULL),
('taipei', 2023, '西寧市場B1', 3, NULL),
('taipei', 2023, '梧州街臨時攤販集中場', 3, NULL),
('taipei', 2023, '華西街臨時攤販集中場', 3, NULL),
('taipei', 2023, '艋舺夜市', 3, NULL),
('taipei', 2023, '廣州街臨時攤販集中場', 3, NULL),
('taipei', 2023, '龍山商場百貨部', 3, NULL),
('taipei', 2023, '龍山商場飲食部', 3, NULL),
('taipei', 2023, '環南中繼市場', 3, NULL),
('taipei', 2023, '永樂商場2樓', 2, NULL),
('taipei', 2023, '長春市場', 2, NULL),
('taipei', 2023, '木新市場', 2, NULL),
('taipei', 2023, '中研市場', 2, NULL),
('taipei', 2023, '直興市場', 2, NULL),
('taipei', 2023, '蘭州市場', 1, NULL),
('taipei', 2023, '建國市場', 1, NULL),
('taipei', 2024, '臺北市公有南門市場', 5, NULL),
('taipei', 2024, '臺北市公有士東市場', 5, NULL),
('taipei', 2024, '光華數位新天地', 4, NULL),
('taipei', 2024, '臺北市永春公有市場', 4, NULL),
('taipei', 2024, '台北市公有成功市場', 4, NULL),
('taipei', 2024, '大直市場', 4, NULL),
('taipei', 2024, '臺北市公有士林市場', 4, NULL),
('taipei', 2024, '安東市場', 4, NULL),
('taipei', 2024, '台北市公有大龍市場', 4, NULL),
('taipei', 2024, '華山公有零售市場', 4, NULL),
('taipei', 2024, '臺北市公有水源市場', 4, NULL),
('taipei', 2024, '北投中繼市場', 4, NULL),
('taipei', 2024, '南機場臨時攤販集中場', 4, NULL),
('taipei', 2024, '東三水街臨時攤販集中場', 4, NULL),
('taipei', 2024, '臺北市公有中崙市場', 3, NULL),
('taipei', 2024, '臺北市公有龍山商場飲食部', 3, NULL),
('taipei', 2024, '臺北市公有西寧市場一樓', 3, NULL),
('taipei', 2024, '西湖市場', 3, NULL),
('taipei', 2024, '臺北市公有興隆市場', 3, NULL),
('taipei', 2024, '錦安市場', 3, NULL),
('taipei', 2024, '永樂布業商場3樓', 3, NULL),
('taipei', 2024, '臺北市公有松江市場', 3, NULL),
('taipei', 2024, '環南綜合市場', 3, NULL),
('taipei', 2024, '臺北市公有龍山商場百貨部', 3, NULL),
('taipei', 2024, '龍城市場', 3, NULL),
('taipei', 2024, '臺北市公有木新市場', 3, NULL),
('taipei', 2024, '光復市場', 3, NULL),
('taipei', 2024, '臺北市公有木柵市場', 3, NULL),
('taipei', 2024, '永樂市場1樓', 3, NULL),
('taipei', 2024, '西寧市場B1', 3, NULL),
('taipei', 2024, '台北市公有東門市場', 3, NULL),
('taipei', 2024, '直興市場', 3, NULL),
('taipei', 2024, '臨江街觀光夜市', 3, NULL),
('taipei', 2024, '晴光臨時攤販集中場', 3, NULL),
('taipei', 2024, '四平街臨時攤販集中場', 3, NULL),
('taipei', 2024, '雙城街臨時攤販集中場', 3, NULL),
('taipei', 2024, '延平北路三段臨時攤販集中場', 3, NULL),
('taipei', 2024, '艋舺夜市', 3, NULL),
('taipei', 2024, '廣州街臨時攤販集中場', 3, NULL),
('taipei', 2024, '梧州街臨時攤販集中場', 3, NULL),
('taipei', 2024, '公館觀光夜市', 3, NULL),
('taipei', 2024, '行天宮命理街', 2, NULL),
('taipei', 2024, '台北市公有雙連市場', 2, NULL),
('taipei', 2024, '建國市場', 2, NULL),
('taipei', 2024, '中研市場', 2, NULL),
('taipei', 2024, '南松市場', 1, NULL),
('taipei', 2024, '永吉市場', 1, NULL),
('taipei', 2024, '德昌街臨時攤販集中場', 1, NULL),
('ntpc', 2024, '汐止觀光夜市', 5, '汐止區'),
('ntpc', 2024, '瑞芳美食廣場', 5, '瑞芳區'),
('ntpc', 2024, '泰山公有零售市場', 5, '泰山區'),
('ntpc', 2024, '林口公有零售市場', 5, '林口區'),
('ntpc', 2024, '淡水中正美食廣場', 5, '淡水區'),
('ntpc', 2024, '五股公有零售市場', 4, '五股區'),
('ntpc', 2024, '永安公有零售市場', 4, '永和區'),
('ntpc', 2024, '三峽公有零售市場', 4, '三峽區'),
('ntpc', 2024, '林森公有攤販集中區', 4, '汐止區'),
('ntpc', 2024, '金龍公有零售市場', 4, '汐止區'),
('ntpc', 2024, '東勢公有零售市場', 4, '林口區'),
('ntpc', 2024, '中央公有零售市場', 4, '三重區'),
('ntpc', 2024, '鶯歌美食廣場', 4, '鶯歌區'),
('ntpc', 2024, '秀豐公有零售市場', 4, '汐止區'),
('ntpc', 2024, '和平街臨時攤販集中區', 4, '中和區'),
('ntpc', 2024, '樂華夜市', 4, '永和區'),
('ntpc', 2024, '民享公有零售市場', 3, '中和區'),
('ntpc', 2024, '萬里野柳臨時賣店區', 3, '萬里區'),
('ntpc', 2024, '保安攤販集中區', 3, '樹林區'),
('ntpc', 2024, '永平公有零售市場', 3, '蘆洲區'),
('ntpc', 2024, '湳雅夜市', 3, '板橋區'),
('ntpc', 2024, '忠厚公有零售市場', 3, '汐止區'),
('ntpc', 2024, '中央公有零售市場', 3, '新店區'),
('ntpc', 2024, '中山公有零售市場', 3, '淡水區'),
('ntpc', 2024, '下庄公有零售市場', 2, '八里區'),
('ntpc', 2024, '光明公有零售市場', 2, '三重區'),
('ntpc', 2024, '重新公有零售市場', 2, '三重區'),
('ntpc', 2024, '第一公有零售市場', 2, '金山區'),
('ntpc', 2024, '新莊第一公有零售市場', 2, '新莊區'),
('ntpc', 2024, '溪州公有零售市場', 2, '永和區'),
('ntpc', 2024, '後埔公有零售市場', 1, '板橋區'),
('ntpc', 2024, '湳興公有零售市場', 1, '板橋區'),
('ntpc', 2024, '土城公有零售市場', 1, '土城區');