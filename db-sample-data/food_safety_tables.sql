-- Food safety tables for postgres-data (dashboard DB)
-- Run by food_safety_etl.py before inserting normalized data rows.

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
);

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
);

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
);

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
);

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
);

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
);

DROP TABLE IF EXISTS food_business_count;
CREATE TABLE food_business_count (
    id             SERIAL PRIMARY KEY,
    city           TEXT,
    source_file    TEXT,
    dataset_name   TEXT,
    business_count INTEGER,
    scope          TEXT
);

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
);

DROP TABLE IF EXISTS district_food_risk;
CREATE TABLE district_food_risk (x_axis TEXT, data NUMERIC(6,2));

-- Drop legacy tables from earlier ETL versions
DROP TABLE IF EXISTS food_inspection_trend;
DROP TABLE IF EXISTS food_inspection_by_district;
DROP TABLE IF EXISTS agri_sampling_pass_rate;
