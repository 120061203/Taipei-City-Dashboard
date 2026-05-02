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
