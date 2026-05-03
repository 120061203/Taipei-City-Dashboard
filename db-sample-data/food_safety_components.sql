-- 食安守護 dashboard component registration for postgres-manager (dashboardmanager DB)
-- Run by food_safety_etl.py after creating tables in postgres-data.

-- Clean up old dashboard/group assignments from earlier ETL versions.
DELETE FROM dashboard_groups WHERE dashboard_id IN (
    SELECT id FROM dashboards WHERE index IN ('food_safety_taipei', 'food_safety_metrotpe')
);
DELETE FROM dashboards WHERE index IN ('food_safety_taipei', 'food_safety_metrotpe');
DELETE FROM query_charts WHERE index = 'food_inspection_category_risk';
DELETE FROM component_charts WHERE index = 'food_inspection_category_risk';
DELETE FROM components WHERE index = 'food_inspection_category_risk';

-- components
INSERT INTO components (index, name) VALUES ('food_inspection_failures', '食材風險提醒')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO components (index, name) VALUES ('food_grade_rank', '餐飲衛生優級店家數')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO components (index, name) VALUES ('district_food_risk', '行政區食安風險指數')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO components (index, name) VALUES ('foodborne_illness_trend', '食品中毒事件趨勢')
ON CONFLICT (index) DO UPDATE SET name = EXCLUDED.name;

-- component_charts
INSERT INTO component_charts (index, color, types, unit)
VALUES (
    'food_inspection_failures',
    ARRAY['#b91c1c','#c2410c','#dc2626','#ea580c','#f97316','#fb923c','#f59e0b','#fbbf24','#facc15','#fde68a'],
    ARRAY['FoodRiskDrilldownChart'],
    '件'
)
ON CONFLICT (index) DO UPDATE
    SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;

INSERT INTO component_charts (index, color, types, unit)
VALUES (
    'food_grade_rank',
    ARRAY['#7ee787','#6fd17c','#5fbce8','#5a9cf8','#8ab4f8','#eac54f','#c6e48b','#9be9a8','#64d2ff','#a7f3d0'],
    ARRAY['ColumnChart'],
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

INSERT INTO component_charts (index, color, types, unit)
VALUES (
    'foodborne_illness_trend',
    ARRAY['#5a9cf8'],
    ARRAY['TimelineSeparateChart'],
    '人'
)
ON CONFLICT (index) DO UPDATE
    SET color = EXCLUDED.color, types = EXCLUDED.types, unit = EXCLUDED.unit;

-- query_charts
DELETE FROM query_charts WHERE index = 'food_inspection_failures';
INSERT INTO query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    short_desc, long_desc, source,
    use_case, links, contributors,
    created_at, updated_at, query_type, query_chart, query_history, city
) VALUES (
    'food_inspection_failures', NULL, NULL, NULL,
    'static', NULL, 1, 'year',
    '顯示臺北市食品抽驗不合格紀錄中，食材大類與具體品項的不合格件數。',
    '顯示臺北市食品抽驗不合格清冊中，依檢體名稱歸納出的食材大類與各大類下的具體品項。大類包含香辛植物、葉菜類、水果類、根莖類、豆製穀堅果類、瓜果豆菜類、菇蕈乾貨類、茶葉花草類、肉蛋水產類等；分類依檢體名稱文字規則產生，無法歸類的品項不列入圖表，數值為清冊中的不合格紀錄筆數。',
    '臺北市政府衛生局',
    '先比較食材大類在不合格紀錄中的件數，再切入該類別下的具體食材品項排行。',
    ARRAY['https://data.taipei/dataset/detail?id=09a917a0-0fb5-47e1-957c-5f1268fba517'],
    ARRAY['doit'],
    NOW(), NOW(), 'two_d',
    'WITH normalized AS (SELECT CASE WHEN sample_name ~ ''烘焙紙|料理紙|調理紙|美耐皿|水壺|矽膠|洗潔精|杯|餐具|容器|塑膠|紙杯|湯匙|盤|碗|抹布'' THEN ''餐具包材類'' WHEN sample_name ~ ''茶|菊花|蝶豆花|花草|迷迭香|咖哩葉|九里香|香草|番茶'' THEN ''茶葉花草類'' WHEN sample_name ~ ''含冰塊|冰|綠豆沙|飲料|咖啡|水晶|雪花冰|果汁|奶茶|紅茶|青茶'' THEN ''飲品冰品類'' WHEN sample_name ~ ''醬油|咖哩|奶油|鮮奶油|奶精|花生醬|調味|香料|花椒|辣椒粉|醬|乳瑪琳'' THEN ''調味醬料類'' WHEN sample_name ~ ''青江菜|小白菜|菠菜|茼蒿|油菜|白菜|芥菜|刈菜|萵苣|大陸妹|空心菜|地瓜葉|高麗菜|韭菜|韭黃|芥藍|芥蘭|莧菜|龍鬚菜|紅鳳菜|青花菜|花椰菜|葉菜'' THEN ''葉菜類'' WHEN sample_name ~ ''芫荽|香菜|青蔥|蔥|九層塔|羅勒|芹菜|辣椒|蒜|薑|香辛'' THEN ''香辛植物'' WHEN sample_name ~ ''蘿蔔|馬鈴薯|芋|地瓜|山藥|竹筍|洋蔥|蓮藕|百合|根莖'' THEN ''根莖類'' WHEN sample_name ~ ''草莓|莓|百香果|葡萄|芒果|柑|橘|蘋果|梨|李|桃|香蕉|荔枝|龍眼|木瓜|檸檬|波蘿蜜|玉荷包|橄欖|水果|八仙果'' THEN ''水果類'' WHEN sample_name ~ ''茄子|豌豆|敏豆|菜豆|四季豆|南瓜|苦瓜|絲瓜|胡瓜|瓜|豆苗'' THEN ''瓜果豆菜類'' WHEN sample_name ~ ''木耳|香菇|菇|竹笙|金針|筍干|乾貨|乾'' THEN ''菇蕈乾貨類'' WHEN sample_name ~ ''豆干|豆乾|干絲|豆腐|豆皮|豆製|綠豆|毛綠豆|花生|堅果|芝麻'' THEN ''豆製穀堅果類'' WHEN sample_name ~ ''魚|蝦|貝|蟹|海鮮|水產|豬|雞|牛|羊|肉|蛋|鵝'' THEN ''肉蛋水產類'' ELSE ''其他'' END AS food_group, CASE WHEN sample_name ~ ''蘿蔔'' THEN ''白蘿蔔'' WHEN sample_name ~ ''芫荽|香菜'' THEN ''香菜/芫荽'' WHEN sample_name ~ ''九層塔|羅勒'' THEN ''九層塔/羅勒'' WHEN sample_name ~ ''辣椒'' THEN ''辣椒'' WHEN sample_name ~ ''草莓|莓果'' THEN ''草莓/莓果'' WHEN sample_name ~ ''青蔥|^蔥$'' THEN ''青蔥'' WHEN sample_name ~ ''芹菜'' THEN ''芹菜'' ELSE btrim(regexp_replace(sample_name, ''[（(].*?[）)]'', '''', ''g'')) END AS food_item FROM food_inspection_failures WHERE sample_name IS NOT NULL AND btrim(sample_name) <> ''''), classified AS (SELECT food_group, food_item FROM normalized WHERE food_group NOT IN (''其他'', ''餐具包材類'') AND food_item IS NOT NULL AND btrim(food_item) <> ''''), category_totals AS (SELECT food_group || ''｜__total__'' AS x_axis, COUNT(*)::integer AS data, food_group, 0 AS sort_order, COUNT(*)::integer AS sort_count FROM classified GROUP BY food_group), item_counts AS (SELECT food_group, food_item, COUNT(*)::integer AS data FROM classified GROUP BY food_group, food_item) SELECT x_axis, data FROM (SELECT x_axis, data, food_group, sort_order, sort_count FROM category_totals UNION ALL SELECT food_group || ''｜'' || food_item AS x_axis, data, food_group, 1 AS sort_order, data AS sort_count FROM item_counts) output ORDER BY food_group, sort_order, sort_count DESC, x_axis',
    NULL,
    'taipei'
);

DELETE FROM query_charts WHERE index = 'food_grade_rank';
INSERT INTO query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    short_desc, long_desc, source,
    use_case, links, contributors,
    created_at, updated_at, query_type, query_chart, query_history, city
) VALUES (
    'food_grade_rank', NULL, NULL, NULL,
    'static', NULL, 1, 'year',
    '顯示臺北市餐飲衛生管理分級評核優級店家數，依行政區統計。',
    '顯示臺北市通過餐飲衛生管理分級評核且評核結果為優級的業者數，依行政區彙整。資料來源為臺北市政府衛生局公開名冊，反映各行政區已通過分級評核的餐飲店家分布。',
    '臺北市政府衛生局',
    '選擇外食區域時，可查看各行政區優級評核店家的分布情形，再搭配公開名冊查詢店名與地址。',
    ARRAY['https://data.taipei/dataset/detail?id=59579c19-a561-4564-8c0f-545bfb32c0f6','https://data.taipei/dataset/detail?id=bb665f7f-085c-40f9-9b9a-844e46da9c65'],
    ARRAY['doit'],
    NOW(), NOW(), 'two_d',
    'SELECT district AS x_axis, COUNT(*)::integer AS data FROM food_hygiene_grade WHERE district IS NOT NULL AND grade = ''優'' GROUP BY district ORDER BY data DESC, district LIMIT 10',
    NULL,
    'taipei'
);

DELETE FROM query_charts WHERE index = 'district_food_risk';
INSERT INTO query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    short_desc, long_desc, source,
    use_case, links, contributors,
    created_at, updated_at, query_type, query_chart, query_history, city
) VALUES (
    'district_food_risk', NULL, NULL, NULL,
    'static', NULL, 1, 'year',
    '顯示臺北市各行政區食品抽驗不合格與餐飲評核資料彙整後的食安風險指數。',
    '顯示臺北市各行政區食安風險指數。指數以食品抽驗不合格件數正規化計算，分數為0至100分，數值越高代表該行政區不合格紀錄相對較多。計算方式為「該區不合格件數 ÷ 各區最高不合格件數 × 100」，確保台北與雙北顯示時採用相同量尺。',
    '臺北市政府衛生局',
    '可用於比較行政區間的食品安全管理壓力，作為稽查資源配置、外食環境觀察或跨區比較的參考。',
    ARRAY['https://data.taipei/dataset/detail?id=09a917a0-0fb5-47e1-957c-5f1268fba517','https://data.taipei/dataset/detail?id=59579c19-a561-4564-8c0f-545bfb32c0f6','https://data.taipei/dataset/detail?id=bb665f7f-085c-40f9-9b9a-844e46da9c65','https://data.taipei/dataset/detail?id=9431f450-57d6-4c23-aca6-0ff50de49f0d','https://data.taipei/dataset/detail?id=c3ae074c-f65f-4f69-bf65-2c00a674e870','https://data.taipei/dataset/detail?id=7d50657f-b35b-496e-b83f-5713893b9a9e'],
    ARRAY['doit'],
    NOW(), NOW(), 'two_d',
    'SELECT x_axis, ROUND(data)::float AS data FROM district_food_risk ORDER BY data DESC',
    NULL,
    'taipei'
);

INSERT INTO query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    short_desc, long_desc, source,
    use_case, links, contributors,
    created_at, updated_at, query_type, query_chart, query_history, city
) VALUES (
    'district_food_risk', NULL, ARRAY[1], NULL,
    'static', NULL, 1, 'year',
    '顯示雙北各行政區食安風險指數，台北以抽驗不合格件數、新北以稽查取締件數正規化為0–100。',
    '顯示雙北各行政區食安風險指數。台北以食品抽驗不合格件數正規化（最高值=100），新北以稽查取締攤販件數正規化（最高值=100），兩城市均採0至100分量尺，數值越高代表相對食安壓力越大。',
    '臺北市政府衛生局、新北市政府警察局',
    '可用於比較雙北各行政區間的食品安全管理壓力。',
    ARRAY['https://data.taipei/dataset/detail?id=09a917a0-0fb5-47e1-957c-5f1268fba517','https://data.ntpc.gov.tw/datasets/c3ae074c-f65f-4f69-bf65-2c00a674e870'],
    ARRAY['doit'],
    NOW(), NOW(), 'two_d',
    'WITH ntpc_raw AS (
    SELECT district, SUM(number)::numeric AS total
    FROM vendor_enforcement_ntpc
    WHERE year = (SELECT MAX(year) FROM vendor_enforcement_ntpc)
      AND district NOT LIKE ''%總%''
    GROUP BY district
),
ntpc_max AS (SELECT MAX(total) AS m FROM ntpc_raw),
ntpc_normalized AS (
    SELECT district AS x_axis, ROUND(total / m * 100)::float AS data
    FROM ntpc_raw, ntpc_max
),
taipei AS (
    SELECT x_axis, data FROM district_food_risk
)
SELECT x_axis, data FROM ntpc_normalized
UNION ALL
SELECT x_axis, data FROM taipei
ORDER BY data DESC',
    NULL,
    'metrotaipei'
);

DELETE FROM query_charts WHERE index = 'foodborne_illness_trend';
INSERT INTO query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    short_desc, long_desc, source,
    use_case, links, contributors,
    created_at, updated_at, query_type, query_chart, query_history, city
) VALUES (
    'foodborne_illness_trend', NULL, NULL, NULL,
    'static', NULL, 1, 'year',
    '顯示臺北市歷年食品中毒人數趨勢，資料來源為年度食品衛生管理工作統計。',
    '顯示臺北市食品衛生管理工作統計中的年度食品中毒人數。折線圖以最近 12 筆有食品中毒人數的年份呈現，數值為該年度統計人數，可用於觀察長期變化與異常年度。',
    '臺北市政府主計處',
    '可用於觀察食品中毒人數年度變化，搭配稽查、不合格改善及其他食安組件判讀食安管理重點。',
    ARRAY['https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=5900&kind=21&type=0&funid=a05031801&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1'],
    ARRAY['doit'],
    NOW(), NOW(), 'time',
    'SELECT make_timestamptz(year, 7, 1, 0, 0, 0, ''UTC'') AS x_axis, ''食品中毒人數'' AS y_axis, food_poisoning_people::float AS data FROM (SELECT year, food_poisoning_people FROM food_hygiene_work WHERE city = ''taipei'' AND food_poisoning_people > 0 ORDER BY year DESC LIMIT 12) sub ORDER BY year',
    NULL,
    'taipei'
);

INSERT INTO query_charts (
    index, history_config, map_config_ids, map_filter,
    time_from, time_to, update_freq, update_freq_unit,
    short_desc, long_desc, source,
    use_case, links, contributors,
    created_at, updated_at, query_type, query_chart, query_history, city
) VALUES (
    'foodborne_illness_trend', NULL, NULL, NULL,
    'static', NULL, 1, 'year',
    '顯示臺北市歷年與新北市113年食品中毒人數，資料來源為年度食品衛生管理工作統計。',
    '顯示雙北食品中毒人數。臺北市呈現最近12筆年度趨勢，新北市目前僅有113年（2024）1288人資料，以單點呈現。',
    '臺北市政府主計處、新北市政府衛生局',
    '可用於觀察雙北食品中毒人數趨勢，搭配其他食安組件判讀管理重點。',
    ARRAY['https://tsis.dbas.gov.taipei/statis/webMain.aspx?sys=220&ymf=5900&kind=21&type=0&funid=a05031801&cycle=4&outmode=12&compmode=0&outkind=1&deflst=2&nzo=1'],
    ARRAY['doit'],
    NOW(), NOW(), 'time',
    'SELECT x_axis, y_axis, data FROM (
  SELECT make_timestamptz(year, 7, 1, 0, 0, 0, ''UTC'') AS x_axis,
         ''臺北市食品中毒人數'' AS y_axis,
         food_poisoning_people::float AS data,
         year
  FROM (SELECT year, food_poisoning_people FROM food_hygiene_work
        WHERE city = ''taipei'' AND food_poisoning_people > 0
        ORDER BY year DESC LIMIT 12) tp
  UNION ALL
  SELECT make_timestamptz(year, 7, 1, 0, 0, 0, ''UTC'') AS x_axis,
         ''新北市食品中毒人數'' AS y_axis,
         food_poisoning_people::float AS data,
         year
  FROM food_hygiene_work
  WHERE city = ''ntpc'' AND food_poisoning_people > 0
) combined ORDER BY x_axis',
    NULL,
    'metrotaipei'
);

-- dashboard & group assignment
DO $$
DECLARE comp_ids INTEGER[]; dash_id INTEGER;
BEGIN
    SELECT ARRAY_AGG(id ORDER BY CASE index
            WHEN 'food_inspection_failures' THEN 1
            WHEN 'food_grade_rank' THEN 2
            WHEN 'district_food_risk' THEN 3
            WHEN 'foodborne_illness_trend' THEN 4
            ELSE 99
        END) INTO comp_ids
    FROM components WHERE index IN (
        'food_inspection_failures',
        'food_grade_rank',
        'district_food_risk',
        'foodborne_illness_trend'
    );
    INSERT INTO dashboards (index, name, components, icon, created_at, updated_at)
    VALUES ('food_safety_taipei', '食安守護', comp_ids, 'restaurant', NOW(), NOW())
    ON CONFLICT (index) DO UPDATE
        SET name      = EXCLUDED.name,
            components = EXCLUDED.components,
            icon      = EXCLUDED.icon,
            updated_at = NOW()
    RETURNING id INTO dash_id;
    INSERT INTO dashboard_groups (dashboard_id, group_id)
    SELECT dash_id, id FROM groups WHERE name = 'taipei'
    ON CONFLICT DO NOTHING;
END$$;
