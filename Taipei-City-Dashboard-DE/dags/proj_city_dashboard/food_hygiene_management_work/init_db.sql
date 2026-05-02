-- ============================================================
-- 1. postgres-data: 建立資料表
-- ============================================================
CREATE TABLE IF NOT EXISTS food_hygiene_management_work (
    year                  INT PRIMARY KEY,
    inspection_visits     INT,
    non_compliant_visits  INT,
    food_poisoning_cases  INT,
    data_time             TIMESTAMPTZ
);


-- ============================================================
-- 2. postgres-manager: 新增組件
-- ============================================================
INSERT INTO components (index, name)
VALUES ('foodborne_illness_trend', '食品中毒事件趨勢')
ON CONFLICT (index) DO NOTHING;


-- ============================================================
-- 3. postgres-manager: 新增圖表查詢設定
--    資料來源為臺北市主計處，兩個 city 共用同一份資料
-- ============================================================
INSERT INTO query_charts (
    index,
    city,
    query_type,
    query_chart,
    time_from,
    time_to,
    update_freq,
    update_freq_unit,
    source,
    short_desc,
    long_desc,
    use_case,
    links,
    contributors,
    created_at,
    updated_at
)
VALUES (
    'foodborne_illness_trend',
    'metrotaipei',
    'time',
    'SELECT
    make_timestamptz(year, 7, 1, 0, 0, 0, ''UTC'') AS x_axis,
    ''食品中毒人數'' AS y_axis,
    food_poisoning_cases::float AS data
FROM (
    SELECT year, food_poisoning_cases
    FROM food_hygiene_management_work
    WHERE food_poisoning_cases > 0
    ORDER BY year DESC
    LIMIT 12
) sub
ORDER BY year',
    'static',
    'static',
    1,
    'year',
    '臺北市主計處－食品衛生管理工作統計',
    '臺北市歷年食品中毒人數趨勢，資料來源為主計處年度統計。',
    '本組件呈現臺北市民國59年至今每年食品中毒人數，可觀察長期趨勢與異常年份。',
    '衛生局與市府可用年度趨勢判斷食安政策成效，評估特定年份食品中毒爆增的原因。',
    ARRAY['https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=5900&kind=21&type=0&funid=a05031801&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1'],
    ARRAY['doit'],
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;

INSERT INTO query_charts (
    index,
    city,
    query_type,
    query_chart,
    time_from,
    time_to,
    update_freq,
    update_freq_unit,
    source,
    short_desc,
    long_desc,
    use_case,
    links,
    contributors,
    created_at,
    updated_at
)
VALUES (
    'foodborne_illness_trend',
    'taipei',
    'time',
    'SELECT
    make_timestamptz(year, 7, 1, 0, 0, 0, ''UTC'') AS x_axis,
    ''食品中毒人數'' AS y_axis,
    food_poisoning_cases::float AS data
FROM (
    SELECT year, food_poisoning_cases
    FROM food_hygiene_management_work
    WHERE food_poisoning_cases > 0
    ORDER BY year DESC
    LIMIT 12
) sub
ORDER BY year',
    'static',
    'static',
    1,
    'year',
    '臺北市主計處－食品衛生管理工作統計',
    '臺北市歷年食品中毒人數趨勢，資料來源為主計處年度統計。',
    '本組件呈現臺北市民國59年至今每年食品中毒人數，可觀察長期趨勢與異常年份。',
    '衛生局與市府可用年度趨勢判斷食安政策成效，評估特定年份食品中毒爆增的原因。',
    ARRAY['https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=5900&kind=21&type=0&funid=a05031801&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1'],
    ARRAY['doit'],
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;


-- ============================================================
-- 4. postgres-manager: 將組件加入食安儀表板
--    （若 food_safety_metrotpe 儀表板已存在）
-- ============================================================
UPDATE dashboards
SET
    components = array_append(
        components,
        (SELECT id FROM components WHERE index = 'foodborne_illness_trend')
    ),
    updated_at = NOW()
WHERE index = 'food_safety_metrotpe'
  AND NOT (
      (SELECT id FROM components WHERE index = 'foodborne_illness_trend')
      = ANY(components)
  );
