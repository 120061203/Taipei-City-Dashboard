-- 食安守護 dashboard component registration for postgres-manager (dashboardmanager DB)
-- Run by food_safety_etl.py after creating tables in postgres-data.

-- Clean up old food_safety_taipei dashboard
DELETE FROM dashboard_groups WHERE dashboard_id IN (
    SELECT id FROM dashboards WHERE index = 'food_safety_taipei'
);
DELETE FROM dashboards WHERE index = 'food_safety_taipei';

-- components
INSERT INTO components (index, name) VALUES ('food_inspection_failures', '食品抽驗不合格地圖')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO components (index, name) VALUES ('food_grade_rank', '餐飲衛生分級榜')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO components (index, name) VALUES ('district_food_risk', '行政區食安風險指數')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

-- component_charts
INSERT INTO component_charts (index, color, types, unit)
VALUES (
    'food_inspection_failures',
    ARRAY['#ed5a5a','#f0883e','#eac54f','#5a9cf8','#7ee787','#d2a8ff'],
    ARRAY['BarChart','DonutChart'],
    '件'
)
ON CONFLICT (index) DO UPDATE
    SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;

INSERT INTO component_charts (index, color, types, unit)
VALUES (
    'food_grade_rank',
    ARRAY['#7ee787','#5a9cf8','#eac54f'],
    ARRAY['BarChart','ColumnChart'],
    '家'
)
ON CONFLICT (index) DO UPDATE
    SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;

INSERT INTO component_charts (index, color, types, unit)
VALUES (
    'district_food_risk',
    ARRAY['#ed5a5a'],
    ARRAY['DistrictChart','BarChart'],
    '指數'
)
ON CONFLICT (index) DO UPDATE
    SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;

-- query_charts
DELETE FROM query_charts WHERE index = 'food_inspection_failures';
INSERT INTO query_charts (
    index, city, query_type, query_chart,
    short_desc, long_desc, source,
    time_from, time_to, update_freq, update_freq_unit, created_at, updated_at
) VALUES (
    'food_inspection_failures', 'metrotaipei', 'two_d',
    'SELECT category AS x_axis, COUNT(*)::integer AS data FROM food_inspection_failures WHERE category IS NOT NULL GROUP BY category ORDER BY data DESC',
    '臺北市近期食品抽驗不合格件數，依業者類別統計前五名',
    '資料來源：臺北市衛生局食品抽驗不合格清冊',
    '臺北市衛生局',
    'static', 'static', 1, 'year', NOW(), NOW()
);

DELETE FROM query_charts WHERE index = 'food_grade_rank';
INSERT INTO query_charts (
    index, city, query_type, query_chart,
    short_desc, long_desc, source,
    time_from, time_to, update_freq, update_freq_unit, created_at, updated_at
) VALUES (
    'food_grade_rank', 'metrotaipei', 'two_d',
    'SELECT district AS x_axis, COUNT(*)::integer AS data FROM food_hygiene_grade WHERE district IS NOT NULL GROUP BY district ORDER BY data DESC LIMIT 5',
    '臺北市通過餐飲衛生管理分級評核業者，依行政區統計前五名',
    '資料來源：臺北市衛生局餐飲衛生管理分級評核與HACCP稽查',
    '臺北市衛生局',
    'static', 'static', 1, 'year', NOW(), NOW()
);

DELETE FROM query_charts WHERE index = 'district_food_risk';
INSERT INTO query_charts (
    index, city, query_type, query_chart,
    short_desc, long_desc, source,
    time_from, time_to, update_freq, update_freq_unit, created_at, updated_at
) VALUES (
    'district_food_risk', 'metrotaipei', 'two_d',
    'SELECT x_axis, data FROM district_food_risk ORDER BY data DESC',
    '依不合格件數與衛生分級計算各行政區風險指數（0–100）',
    '計算公式：不合格件數×6 + (100-優等率)×0.35，最高100分',
    '臺北市衛生局',
    'static', 'static', 1, 'year', NOW(), NOW()
);

-- dashboard & group assignment
DO $$
DECLARE comp_ids INTEGER[]; dash_id INTEGER;
BEGIN
    SELECT ARRAY_AGG(id ORDER BY id) INTO comp_ids
    FROM components WHERE index IN (
        'food_inspection_failures', 'food_grade_rank', 'district_food_risk'
    );
    INSERT INTO dashboards (index, name, components, icon, created_at, updated_at)
    VALUES ('food_safety_metrotpe', '食安守護', comp_ids, 'restaurant', NOW(), NOW())
    ON CONFLICT (index) DO UPDATE
        SET name      = EXCLUDED.name,
            components = EXCLUDED.components,
            icon      = EXCLUDED.icon,
            updated_at = NOW()
    RETURNING id INTO dash_id;
    INSERT INTO dashboard_groups (dashboard_id, group_id)
    SELECT dash_id, id FROM groups WHERE name = 'metrotaipei'
    ON CONFLICT DO NOTHING;
END$$;
