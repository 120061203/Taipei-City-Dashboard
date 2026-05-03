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

CREATE TABLE IF NOT EXISTS vendor_enforcement_ntpc (
    id            SERIAL PRIMARY KEY,
    city          TEXT,
    source_file   TEXT,
    year          INTEGER,
    month         INTEGER,
    organ         TEXT,
    district      TEXT,
    kind          TEXT,
    number        INTEGER,
    num_of_people INTEGER
);
ALTER TABLE vendor_enforcement_ntpc ADD COLUMN IF NOT EXISTS source_file TEXT;
ALTER TABLE vendor_enforcement_ntpc ADD COLUMN IF NOT EXISTS month INTEGER;
ALTER TABLE vendor_enforcement_ntpc ADD COLUMN IF NOT EXISTS organ TEXT;
ALTER TABLE vendor_enforcement_ntpc ADD COLUMN IF NOT EXISTS kind TEXT;
ALTER TABLE vendor_enforcement_ntpc ADD COLUMN IF NOT EXISTS num_of_people INTEGER;
TRUNCATE TABLE vendor_enforcement_ntpc RESTART IDENTITY;

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
-- Static data not covered by ETL (ETL-provided Taipei rows are inserted by food_safety_etl.py)
-- ============================================================

-- food_hygiene_work: 新北市113年（2024）食品中毒人數（ETL 無新北來源，手動輸入）
INSERT INTO food_hygiene_work (city, year, food_poisoning_people) VALUES
('ntpc', 2024, 1288);

-- (food_hygiene_grade, food_inspection_failures, district_food_risk 由 food_safety_etl.py 從真實資料產生，不在此預填)


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
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士東市場' AND year = 2020;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '南門市場' AND year = 2020;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '寧夏夜市' AND year = 2020;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '大直市場' AND year = 2020;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '華山市場' AND year = 2020;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林市場' AND year = 2020;
UPDATE market_quality_awards SET district = '內湖區' WHERE city = 'taipei' AND market_name = '西湖市場' AND year = 2020;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '中崙市場' AND year = 2020;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂市場(3樓)' AND year = 2020;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '建國假日玉市(社團法人中華玉器藝術文化交流協會)' AND year = 2020;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '松江市場' AND year = 2020;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '長春市場' AND year = 2020;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '光華數位新天地' AND year = 2020;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '晴光攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '東三水街攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '南機場臨時攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '華西街攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '龍山商場(百貨部)' AND year = 2020;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '四平街臨時攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '水源市場' AND year = 2020;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '成功市場' AND year = 2020;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '公館夜市' AND year = 2020;
UPDATE market_quality_awards SET district = '信義區' WHERE city = 'taipei' AND market_name = '永春市場' AND year = 2020;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '光復市場' AND year = 2020;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西寧市場(B1)' AND year = 2020;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '廣州街攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '建國假日玉市(社團法人臺北市玉石文物協進會)' AND year = 2020;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '成德市場' AND year = 2020;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '悟州街攤販集中場' AND year = 2020;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '直興市場' AND year = 2020;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '安東市場' AND year = 2020;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '寧夏夜市' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士東市場' AND year = 2022;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '南門市場' AND year = 2022;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '大直公有零售市場' AND year = 2022;
UPDATE market_quality_awards SET district = '內湖區' WHERE city = 'taipei' AND market_name = '西湖公有零售市場' AND year = 2022;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '中崙公有零售市場' AND year = 2022;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '大龍市場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '華西街攤販集中場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西寧市場1樓' AND year = 2022;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '華山市場' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林夜市' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林市場' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林夜市商圈聯合會' AND year = 2022;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '四平街攤販集中場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '南機場攤販集中區' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '艋舺夜市' AND year = 2022;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '光華數位新天地' AND year = 2022;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '水源市場' AND year = 2022;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '長春市場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '龍山商場百貨部' AND year = 2022;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂市場3樓' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '晴光攤販集中區' AND year = 2022;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '安東市場' AND year = 2022;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '松江市場' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '雙城街攤販集中場' AND year = 2022;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '公館夜市' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '梧州街攤販集中場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '廣州街攤販集中場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西園路二段140巷攤販集中場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西門市場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西寧市場地下1樓' AND year = 2022;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '大稻埕慈聖宮美食街' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '新富市場' AND year = 2022;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '龍山商場飲食部' AND year = 2022;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '光復市場' AND year = 2022;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '建國市場' AND year = 2022;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '錦安市場' AND year = 2022;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '成德市場' AND year = 2022;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '直興市場' AND year = 2022;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士東市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '寧夏路臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '南門市場' AND year = 2023;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林夜市(社團法人台北市士林夜市商圈聯合會)' AND year = 2024;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林夜市(社團法人台北市士林夜市國際觀光發展協會)' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '寧夏夜市' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '華西街觀光夜市' AND year = 2024;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林夜市(臺北市士林夜市商圈聯合會)' AND year = 2023;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林夜市(臺北市士林夜市國際觀光發展協會)' AND year = 2023;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '士林市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '大龍市場' AND year = 2023;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '成功市場' AND year = 2023;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '大直市場' AND year = 2023;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '光華數位新天地' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '南機場臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '華山市場' AND year = 2023;
UPDATE market_quality_awards SET district = '內湖區' WHERE city = 'taipei' AND market_name = '西湖市場' AND year = 2023;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '中崙市場' AND year = 2023;
UPDATE market_quality_awards SET district = '信義區' WHERE city = 'taipei' AND market_name = '永春市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '東三水街攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西寧市場一樓' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂市場1樓' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂商場3樓' AND year = 2023;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '安東市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '錦安市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '臨江街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '四平街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '松江市場' AND year = 2023;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '晴光臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '遼寧街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '雙城街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '公館夜市' AND year = 2023;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '水源市場' AND year = 2023;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '東門市場' AND year = 2023;
UPDATE market_quality_awards SET district = '文山區' WHERE city = 'taipei' AND market_name = '木柵市場' AND year = 2023;
UPDATE market_quality_awards SET district = '文山區' WHERE city = 'taipei' AND market_name = '興隆市場' AND year = 2023;
UPDATE market_quality_awards SET district = '北投區' WHERE city = 'taipei' AND market_name = '北投中繼市場' AND year = 2023;
UPDATE market_quality_awards SET district = '內湖區' WHERE city = 'taipei' AND market_name = '龍城市場' AND year = 2023;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '光復市場' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西寧市場B1' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '梧州街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '華西街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '艋舺夜市' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '廣州街臨時攤販集中場' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '龍山商場百貨部' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '龍山商場飲食部' AND year = 2023;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '環南中繼市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂商場2樓' AND year = 2023;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '長春市場' AND year = 2023;
UPDATE market_quality_awards SET district = '文山區' WHERE city = 'taipei' AND market_name = '木新市場' AND year = 2023;
UPDATE market_quality_awards SET district = '南港區' WHERE city = 'taipei' AND market_name = '中研市場' AND year = 2023;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '直興市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '蘭州市場' AND year = 2023;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '建國市場' AND year = 2023;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '臺北市公有南門市場' AND year = 2024;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '臺北市公有士東市場' AND year = 2024;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '光華數位新天地' AND year = 2024;
UPDATE market_quality_awards SET district = '信義區' WHERE city = 'taipei' AND market_name = '臺北市永春公有市場' AND year = 2024;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '台北市公有成功市場' AND year = 2024;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '大直市場' AND year = 2024;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '臺北市公有士林市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '安東市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '台北市公有大龍市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '華山公有零售市場' AND year = 2024;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '臺北市公有水源市場' AND year = 2024;
UPDATE market_quality_awards SET district = '北投區' WHERE city = 'taipei' AND market_name = '北投中繼市場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '南機場臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '東三水街臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '臺北市公有中崙市場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '臺北市公有龍山商場飲食部' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '臺北市公有西寧市場一樓' AND year = 2024;
UPDATE market_quality_awards SET district = '內湖區' WHERE city = 'taipei' AND market_name = '西湖市場' AND year = 2024;
UPDATE market_quality_awards SET district = '文山區' WHERE city = 'taipei' AND market_name = '臺北市公有興隆市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '錦安市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂布業商場3樓' AND year = 2024;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '臺北市公有松江市場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '環南綜合市場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '臺北市公有龍山商場百貨部' AND year = 2024;
UPDATE market_quality_awards SET district = '內湖區' WHERE city = 'taipei' AND market_name = '龍城市場' AND year = 2024;
UPDATE market_quality_awards SET district = '文山區' WHERE city = 'taipei' AND market_name = '臺北市公有木新市場' AND year = 2024;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '光復市場' AND year = 2024;
UPDATE market_quality_awards SET district = '文山區' WHERE city = 'taipei' AND market_name = '臺北市公有木柵市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '永樂市場1樓' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '西寧市場B1' AND year = 2024;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '台北市公有東門市場' AND year = 2024;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '直興市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '臨江街觀光夜市' AND year = 2024;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '晴光臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '四平街臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '士林區' WHERE city = 'taipei' AND market_name = '雙城街臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '延平北路三段臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '艋舺夜市' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '廣州街臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '梧州街臨時攤販集中場' AND year = 2024;
UPDATE market_quality_awards SET district = '中正區' WHERE city = 'taipei' AND market_name = '公館觀光夜市' AND year = 2024;
UPDATE market_quality_awards SET district = '中山區' WHERE city = 'taipei' AND market_name = '行天宮命理街' AND year = 2024;
UPDATE market_quality_awards SET district = '大同區' WHERE city = 'taipei' AND market_name = '台北市公有雙連市場' AND year = 2024;
UPDATE market_quality_awards SET district = '大安區' WHERE city = 'taipei' AND market_name = '建國市場' AND year = 2024;
UPDATE market_quality_awards SET district = '南港區' WHERE city = 'taipei' AND market_name = '中研市場' AND year = 2024;
UPDATE market_quality_awards SET district = '松山區' WHERE city = 'taipei' AND market_name = '南松市場' AND year = 2024;
UPDATE market_quality_awards SET district = '信義區' WHERE city = 'taipei' AND market_name = '永吉市場' AND year = 2024;
UPDATE market_quality_awards SET district = '萬華區' WHERE city = 'taipei' AND market_name = '德昌街臨時攤販集中場' AND year = 2024;

