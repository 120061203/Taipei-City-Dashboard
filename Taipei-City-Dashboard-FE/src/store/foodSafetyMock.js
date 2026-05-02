import { foodPoisoningPatientSeries } from "./foodPoisoningPatientsData";

// =============================================================
// 食安守護 (Food Safety) Mock Dashboard - Team 20 Hackathon
// =============================================================
// 注入到 contentStore，避免依賴 BE 即可在前端 demo
//
// 元件與資料源（雙北對稱）：
//   ① 食品抽驗不合格地圖
//      - TP 09a917a0  衛生局食品抽驗不合格清冊       (每年)
//      - NTP 078CB722 食品抽驗資料                    (每月)
//      欄位: 抽驗日期、檢體、地點、不符原因
//   ② 餐飲衛生分級榜
//      - TP 59579c19  通過餐飲衛生分級評核業者       (每年)
//      - TP bb665f7f  HACCP 稽查                       (不定期)
//      - NTP 8E64B205 餐飲業者（含座標）              (每日)
//      欄位: 業者名稱、地址、評核結果（A/B/C 或 優/良/HACCP）
//   ③ 歷年食物中毒患者數
//      - 衛生福利部食品藥物管理署 食品中毒發生狀況 (每年)
//      欄位: 年度、患者數
//   ④ 主要病因物質分布
//      - 衛生福利部食品藥物管理署 食品中毒發生狀況 (每年)
//      欄位: 病原名稱、患者數
//   ⑤ 行政區食安風險指數
//      - TP 7d50657f  食品衛生管理工作               (每年)
//      - TP 9431f450  食品業者登錄數                 (不定期)
//      - TP c3ae074c  食品衛生管理查驗工作           (每年)
//      - NTP D67EC90F 食品業者登錄數                (每季)
//      欄位: 稽查家次、不符比率、業者密度
// =============================================================

export const FOOD_SAFETY_DASHBOARD_INDEX = "food_safety_metrotpe";
export const FOOD_SAFETY_CITY = "metrotaipei";

export const foodSafetyDashboard = {
	id: 9000,
	index: FOOD_SAFETY_DASHBOARD_INDEX,
	name: "食安守護",
	icon: "restaurant",
	components: [9001, 9002, 9003, 9004],
};

const baseFields = {
	query_data: "",
	time_from: "static",
	time_to: "static",
	city: FOOD_SAFETY_CITY,
};

const taipeiDatasetPage = (id) => `https://data.taipei/dataset/detail?id=${id}`;

const foodSafetyDataSources = {
	inspectionFailures: [
		{
			city: "臺北市",
			id: "09a917a0-0fb5-47e1-957c-5f1268fba517",
			name: "臺北市衛生局食品抽驗不合格清冊",
			agency: "衛生局",
			updateFrequency: "每1年",
			lastUpdated: "2025-12-16T10:22:37",
			url: taipeiDatasetPage("09a917a0-0fb5-47e1-957c-5f1268fba517"),
		},
		{
			city: "新北市",
			id: "078CB722-15AC-4E1E-B541-E75BFE0AA440",
			name: "新北市食品抽驗資料",
			agency: "新北市政府衛生局/食品藥物管理科/食品股",
			updateFrequency: "每月",
			url: "https://data.ntpc.gov.tw/datasets/078cb722-15ac-4e1e-b541-e75bfe0aa440",
		},
	],
	hygieneRanking: [
		{
			city: "臺北市",
			id: "59579c19-a561-4564-8c0f-545bfb32c0f6",
			name: "臺北市通過餐飲衛生管理分級評核業者",
			agency: "衛生局",
			updateFrequency: "每1年",
			lastUpdated: "2025-12-19T13:59:56",
			url: taipeiDatasetPage("59579c19-a561-4564-8c0f-545bfb32c0f6"),
		},
		{
			city: "臺北市",
			id: "bb665f7f-085c-40f9-9b9a-844e46da9c65",
			name: "臺北市HACCP稽查",
			agency: "衛生局",
			updateFrequency: "不定期更新",
			lastUpdated: "2025-12-19T14:00:19",
			url: taipeiDatasetPage("bb665f7f-085c-40f9-9b9a-844e46da9c65"),
		},
		{
			city: "新北市",
			id: "8E64B205-A100-4A9A-BD76-8E362761FD61",
			name: "新北市餐飲業者(中文-106年更新)",
			agency: "新北市政府觀光旅遊局/觀光企劃科",
			updateFrequency: "每日",
			url: "https://data.ntpc.gov.tw/datasets/8e64b205-a100-4a9a-bd76-8e362761fd61",
		},
	],
	marketPassRate: [
		{
			city: "臺北市",
			id: "ad63197e-217c-472b-a63f-94b0d29d0e7a",
			name: "臺北市批發市場質譜化學快檢不合格統計資料",
			agency: "產業局市場處",
			updateFrequency: "每1月",
			lastUpdated: "2026-04-24T10:32:18",
			url: taipeiDatasetPage("ad63197e-217c-472b-a63f-94b0d29d0e7a"),
		},
		{
			city: "臺北市",
			id: "8ab917b0-1029-4003-b776-f169b4e561f1",
			name: "臺北市政府標章農產品抽檢清冊",
			agency: "產業局",
			updateFrequency: "不定期更新",
			lastUpdated: "2026-01-09T15:03:28",
			url: taipeiDatasetPage("8ab917b0-1029-4003-b776-f169b4e561f1"),
		},
		{
			city: "新北市",
			id: "D2D69F7E-E283-406E-859B-E9E5DC98AC50",
			name: "市售食品抽驗合格率",
			agency: "新北市政府衛生局/食品藥物管理科/食品股",
			updateFrequency: "每季",
			url: "https://data.ntpc.gov.tw/datasets/d2d69f7e-e283-406e-859b-e9e5dc98ac50",
		},
		{
			city: "新北市",
			id: "B57C14E9-593C-4416-8EDD-D1AC8CDCEB48",
			name: "市售食品標示合格率",
			agency: "新北市政府衛生局/食品藥物管理科/食品股",
			updateFrequency: "每季",
			url: "https://data.ntpc.gov.tw/datasets/b57c14e9-593c-4416-8edd-d1ac8cdceb48",
		},
	],
	districtRisk: [
		{
			city: "臺北市",
			id: "7d50657f-b35b-496e-b83f-5713893b9a9e",
			name: "臺北市食品衛生管理工作",
			agency: "主計處",
			updateFrequency: "每1年",
			lastUpdated: "2026-03-15T20:21:00",
			url: taipeiDatasetPage("7d50657f-b35b-496e-b83f-5713893b9a9e"),
		},
		{
			city: "臺北市",
			id: "9431f450-57d6-4c23-aca6-0ff50de49f0d",
			name: "臺北市食品業者登錄數",
			agency: "衛生局",
			updateFrequency: "不定期更新",
			lastUpdated: "2025-12-19T09:15:46",
			url: taipeiDatasetPage("9431f450-57d6-4c23-aca6-0ff50de49f0d"),
		},
		{
			city: "臺北市",
			id: "c3ae074c-f65f-4f69-bf65-2c00a674e870",
			name: "臺北市食品衛生管理查驗工作",
			agency: "主計處",
			updateFrequency: "每1年",
			lastUpdated: "2026-03-15T20:20:59",
			url: taipeiDatasetPage("c3ae074c-f65f-4f69-bf65-2c00a674e870"),
		},
		{
			city: "新北市",
			id: "D67EC90F-2045-4FA1-A41E-1ABC6ABA62DD",
			name: "食品業者登錄數",
			agency: "新北市政府衛生局/食品藥物管理科/食品股",
			updateFrequency: "每季",
			url: "https://data.ntpc.gov.tw/datasets/d67ec90f-2045-4fa1-a41e-1abc6aba62dd",
		},
	],
};

const sourceText = (sources) =>
	sources
		.map((source) => `${source.city} ${source.name}（${source.updateFrequency}）`)
		.join(" / ");

const sourceLinks = (sources) => sources.map((source) => source.url);

// =============================================================
// ① 食品抽驗不合格地圖
//    TP 09a917a0 + NTP 078CB722
// =============================================================
const compMap = {
	...baseFields,
	id: 9001,
	index: "food_inspection_failures",
	name: "食品抽驗不合格地圖",
	chart_config: {
		color: ["#ed5a5a", "#f0883e", "#eac54f", "#5a9cf8", "#7ee787", "#d2a8ff"],
		types: ["DonutChart", "BarChart"],
		unit: "件",
		categories: null,
	},
	// 近 90 天各類別不合格件數
	chart_data: [
		{
			name: "近 90 天不合格件數",
			data: [
				{ x: "餐飲業", y: 14 },
				{ x: "攤販", y: 9 },
				{ x: "市場", y: 6 },
				{ x: "便當", y: 5 },
				{ x: "飲料", y: 3 },
				{ x: "工廠", y: 1 },
			],
		},
	],
	map_config: [
		{
			index: "food_failures_metrotaipei",
			title: "食品抽驗不合格點",
			type: "symbol",
			source: "geojson",
			size: null,
			icon: "recall",
			paint: {
				"icon-image": [
					"match",
					["get", "severity"],
					"major", "recall_red",
					"medium", "recall_orange",
					"recall_yellow",
				],
				"icon-size": 0.6,
			},
			property: [
				{ key: "name", name: "業者" },
				{ key: "cat", name: "類別" },
				{ key: "date", name: "抽驗日期" },
				{ key: "addr", name: "地址" },
				{ key: "sample", name: "檢體" },
				{ key: "reason", name: "違規原因" },
			],
		},
	],
	map_filter: null,
	history_config: null,
	source: sourceText(foodSafetyDataSources.inspectionFailures),
	links: sourceLinks(foodSafetyDataSources.inspectionFailures),
	contributors: ["doit", "ntpc"],
	update_freq: 1,
	update_freq_unit: "month",
	short_desc:
		"雙北近 90 天食品抽驗不合格紀錄地圖，以類別分布快速掌握高風險業者類型。資料目錄來源：Open Data.json、dataList.json。",
};

// =============================================================
// ② 餐飲衛生分級榜
//    TP 59579c19 + TP bb665f7f + NTP 8E64B205
// =============================================================
const compRank = {
	...baseFields,
	id: 9002,
	index: "food_grade_rank",
	name: "餐飲衛生分級榜",
	chart_config: {
		color: ["#7ee787", "#5a9cf8", "#eac54f"],
		types: ["BarChart", "ColumnChart"],
		unit: "家",
		categories: null,
	},
	// 各行政區通過評核（A/B/C 級 + HACCP）的餐飲業者家數
	chart_data: [
		{
			name: "通過分級評核業者數",
			data: [
				{ x: "信義區", y: 87 },
				{ x: "大安區", y: 72 },
				{ x: "中山區", y: 68 },
				{ x: "板橋區", y: 64 },
				{ x: "松山區", y: 51 },
				{ x: "永和區", y: 42 },
				{ x: "中正區", y: 39 },
				{ x: "新店區", y: 35 },
				{ x: "萬華區", y: 28 },
				{ x: "三重區", y: 26 },
			],
		},
	],
	map_config: null,
	map_filter: null,
	history_config: null,
	source: sourceText(foodSafetyDataSources.hygieneRanking),
	links: sourceLinks(foodSafetyDataSources.hygieneRanking),
	contributors: ["doit", "ntpc"],
	update_freq: 1,
	update_freq_unit: "year",
	short_desc:
		"雙北通過衛生分級評核業者分布（A/B/C 級 + HACCP 認證）。資料目錄來源：Open Data.json、dataList.json。",
};

// =============================================================
// ③ 食物中毒年月與病因分析
//    衛生福利部食品藥物管理署 食品中毒發生狀況 (民國90-114年)
//    自訂圖表：FoodPoisoningYearlyChart
//    series 格式: [{ name, patients, monthly: number[12], pathogens: {x,y}[] }]
//    - 數值皆為患者數，資料由 data/food_poisoning.sqlite 匯出
// =============================================================
const compPoisoningCases = {
	...baseFields,
	id: 9003,
	index: "food_poisoning_yearly",
	name: "食物中毒年月與病因分析",
	chart_config: {
		color: ["#ed5a5a", "#f0883e", "#eac54f", "#5a9cf8", "#7ee787", "#d2a8ff"],
		types: ["FoodPoisoningYearlyChart"],
		unit: "人",
		categories: null,
	},
	chart_data: foodPoisoningPatientSeries,
	map_config: null,
	map_filter: null,
	history_config: null,
	source: "衛生福利部食品藥物管理署 食品中毒發生狀況（每年）",
	links: ["https://www.fda.gov.tw/TC/site.aspx?sid=4"],
	contributors: ["mohw"],
	update_freq: 1,
	update_freq_unit: "year",
	short_desc:
		"月份模式：選年份查看當月患者數；年份模式：以5年為一區間瀏覽民國90-114年各病因患者數占年度患者數比例。",
};

// =============================================================
// ④ 行政區食安風險指數
//    TP 7d50657f + TP 9431f450 + TP c3ae074c + NTP D67EC90F
// =============================================================
const compRisk = {
	...baseFields,
	id: 9004,
	index: "district_food_risk",
	name: "行政區食安風險指數",
	chart_config: {
		color: ["#ed5a5a"],
		types: ["DistrictChart", "BarChart"],
		unit: "指數",
		categories: null,
	},
	// DistrictChart 期望 series[0].data = [{x: 行政區名, y: value}]
	// 風險指數 = (違規率 × 業者密度) × 1000，以 100 為上限歸一
	chart_data: [
		{
			name: "風險指數",
			data: [
				// Taipei 12 districts
				{ x: "中山區", y: 78 },
				{ x: "萬華區", y: 81 },
				{ x: "大安區", y: 62 },
				{ x: "信義區", y: 55 },
				{ x: "中正區", y: 68 },
				{ x: "士林區", y: 71 },
				{ x: "北投區", y: 48 },
				{ x: "內湖區", y: 52 },
				{ x: "南港區", y: 45 },
				{ x: "松山區", y: 64 },
				{ x: "大同區", y: 70 },
				{ x: "文山區", y: 50 },
				// New Taipei
				{ x: "板橋區", y: 88 },
				{ x: "三重區", y: 82 },
				{ x: "永和區", y: 75 },
				{ x: "中和區", y: 76 },
				{ x: "新店區", y: 58 },
				{ x: "土城區", y: 65 },
				{ x: "蘆洲區", y: 73 },
				{ x: "林口區", y: 42 },
				{ x: "淡水區", y: 47 },
				{ x: "汐止區", y: 60 },
				{ x: "新莊區", y: 84 },
				{ x: "樹林區", y: 56 },
			],
		},
	],
	map_config: null,
	map_filter: null,
	history_config: null,
	source: sourceText(foodSafetyDataSources.districtRisk),
	links: sourceLinks(foodSafetyDataSources.districtRisk),
	contributors: ["doit", "ntpc"],
	update_freq: 1,
	update_freq_unit: "year",
	short_desc:
		"雙北行政區食安風險指數 = (違規率 × 業者密度) × 1000。資料目錄來源：Open Data.json、dataList.json。",
};

export const foodSafetyComponents = [
	compMap,
	compRank,
	compPoisoningCases,
	compRisk,
];

// =============================================================
// 食品抽驗不合格 GeoJSON (給 Mapbox layer 用)
//   38 筆雙北近 90 天抽驗不合格紀錄
//   嚴重度: major / medium / minor
// =============================================================
const failureGeoJSONFeatures = [
	// 餐飲業
	{ name: "○○早餐店", cat: "餐飲", date: "2026-04-29", addr: "萬華區中華路二段 416 號", lat: 25.0298, lng: 121.5009, sample: "蛋餅皮", reason: "大腸桿菌群超標", severity: "major" },
	{ name: "○○食堂", cat: "餐飲", date: "2026-04-29", addr: "永和區永和路二段 57 號", lat: 25.0086, lng: 121.5174, sample: "滷雞腿", reason: "黃麴毒素超標", severity: "major" },
	{ name: "○○麵店", cat: "餐飲", date: "2026-04-08", addr: "中正區忠孝西路一段 50 號", lat: 25.0463, lng: 121.5166, sample: "滷肉", reason: "亞硝酸鹽超標", severity: "major" },
	{ name: "○○麵包", cat: "餐飲", date: "2026-04-05", addr: "信義區松壽路 11 號", lat: 25.0357, lng: 121.5681, sample: "麵包", reason: "己二烯酸超標", severity: "medium" },
	{ name: "○○早餐", cat: "餐飲", date: "2026-03-15", addr: "新店區中正路 100 號", lat: 25.0152, lng: 121.5419, sample: "蛋餅皮", reason: "大腸桿菌群超標", severity: "medium" },
	{ name: "○○早餐店", cat: "餐飲", date: "2026-02-25", addr: "大同區重慶北路三段 70 號", lat: 25.0686, lng: 121.5130, sample: "蛋餅皮", reason: "大腸桿菌群", severity: "medium" },
	{ name: "○○燒臘", cat: "餐飲", date: "2026-02-05", addr: "松山區八德路四段 100 號", lat: 25.0497, lng: 121.5746, sample: "叉燒", reason: "亞硝酸鹽超標", severity: "major" },
	{ name: "○○素食", cat: "餐飲", date: "2026-01-15", addr: "古亭區羅斯福路二段 20 號", lat: 25.0205, lng: 121.5290, sample: "豆製品", reason: "苯甲酸超標", severity: "minor" },
	{ name: "○○早餐", cat: "餐飲", date: "2026-03-08", addr: "土城區金城路二段 65 號", lat: 24.9728, lng: 121.4439, sample: "蘿蔔糕", reason: "己二烯酸超標", severity: "medium" },
	{ name: "○○麵店", cat: "餐飲", date: "2025-12-22", addr: "板橋區文化路二段 50 號", lat: 25.0150, lng: 121.4625, sample: "滷肉", reason: "亞硝酸鹽", severity: "medium" },
	{ name: "○○鍋貼", cat: "餐飲", date: "2026-04-20", addr: "大安區忠孝東路四段 100 號", lat: 25.0418, lng: 121.5510, sample: "內餡（豬肉）", reason: "抗生素檢出", severity: "medium" },
	{ name: "○○烘焙", cat: "餐飲", date: "2026-04-18", addr: "中山區南京東路三段 60 號", lat: 25.0521, lng: 121.5408, sample: "蛋糕", reason: "防腐劑超標", severity: "medium" },
	{ name: "○○素食", cat: "餐飲", date: "2026-05-01", addr: "中山區長安東路二段 178 號", lat: 25.0468, lng: 121.5338, sample: "素料", reason: "黃麴毒素超標", severity: "major" },
	{ name: "○○食堂", cat: "餐飲", date: "2026-05-02", addr: "蘆洲區中正路 52 號", lat: 25.0876, lng: 121.4690, sample: "湯品", reason: "大腸桿菌群超標", severity: "medium" },
	// 攤販
	{ name: "○○滷味", cat: "攤販", date: "2026-04-21", addr: "士林區大東路 35 號", lat: 25.0888, lng: 121.5253, sample: "滷豆乾", reason: "苯甲酸超標", severity: "major" },
	{ name: "○○鹹酥雞", cat: "攤販", date: "2026-04-15", addr: "萬華區廣州街 22 號", lat: 25.0356, lng: 121.5040, sample: "鹹酥雞", reason: "油脂酸價過高", severity: "medium" },
	{ name: "○○熟食", cat: "攤販", date: "2026-03-22", addr: "三重區重新路四段 120 號", lat: 25.0612, lng: 121.4884, sample: "滷蛋", reason: "生菌數超標", severity: "medium" },
	{ name: "○○雞排", cat: "攤販", date: "2026-02-10", addr: "文山區木柵路四段 56 號", lat: 24.9886, lng: 121.5708, sample: "雞排", reason: "油脂酸價過高", severity: "minor" },
	{ name: "○○滷味", cat: "攤販", date: "2026-01-05", addr: "淡水區中正路 100 號", lat: 25.1697, lng: 121.4406, sample: "滷豆腐", reason: "苯甲酸", severity: "minor" },
	{ name: "○○早餐車", cat: "攤販", date: "2025-12-28", addr: "新莊區中正路 250 號", lat: 25.0356, lng: 121.4501, sample: "蛋餅皮", reason: "大腸桿菌群", severity: "medium" },
	{ name: "○○炸物", cat: "攤販", date: "2026-04-12", addr: "板橋區南雅南路二段 31 號", lat: 25.0089, lng: 121.4582, sample: "薯條", reason: "油脂酸價超標", severity: "minor" },
	{ name: "○○烤肉", cat: "攤販", date: "2026-04-26", addr: "中山區南京東路二段 32 巷", lat: 25.0520, lng: 121.5343, sample: "雞肉串", reason: "亞硝酸鹽", severity: "medium" },
	{ name: "○○早餐車", cat: "攤販", date: "2026-05-01", addr: "永和區中山路一段 220 號", lat: 25.0102, lng: 121.5155, sample: "漢堡肉", reason: "大腸桿菌群超標", severity: "medium" },
	// 便當
	{ name: "○○便當", cat: "便當", date: "2026-04-08", addr: "中正區忠孝西路一段 80 號", lat: 25.0455, lng: 121.5180, sample: "便當（雞腿）", reason: "大腸桿菌群超標", severity: "major" },
	{ name: "○○便當", cat: "便當", date: "2026-01-28", addr: "內湖區內湖路一段 360 號", lat: 25.0696, lng: 121.5887, sample: "便當（豬排）", reason: "大腸桿菌群", severity: "medium" },
	{ name: "○○便當", cat: "便當", date: "2026-01-10", addr: "永和區得和路 300 號", lat: 25.0078, lng: 121.5141, sample: "便當（魚排）", reason: "組織胺超標", severity: "medium" },
	{ name: "○○便當", cat: "便當", date: "2025-12-08", addr: "萬華區漢中街 50 號", lat: 25.0432, lng: 121.5088, sample: "便當（雞腿）", reason: "大腸桿菌群", severity: "medium" },
	{ name: "○○便當", cat: "便當", date: "2026-04-30", addr: "中山區民生東路二段 90 號", lat: 25.0581, lng: 121.5325, sample: "便當（配菜）", reason: "大腸桿菌群", severity: "medium" },
	// 飲料
	{ name: "○○手搖飲", cat: "飲料", date: "2026-04-10", addr: "大安區忠孝東路四段 216 巷", lat: 25.0418, lng: 121.5526, sample: "果汁", reason: "生菌數超標", severity: "medium" },
	{ name: "○○手搖飲", cat: "飲料", date: "2026-03-12", addr: "中和區中山路二段 162 號", lat: 25.0048, lng: 121.4986, sample: "冰塊", reason: "生菌數超標", severity: "minor" },
	{ name: "○○手搖", cat: "飲料", date: "2026-02-20", addr: "南港區南港路一段 60 號", lat: 25.0540, lng: 121.6066, sample: "茶飲", reason: "農藥殘留", severity: "minor" },
	// 市場
	{ name: "○○蔬果攤", cat: "市場", date: "2026-04-02", addr: "北投區光明路 240 號", lat: 25.1370, lng: 121.5072, sample: "芹菜", reason: "農藥殘留 (達馬松) 超標", severity: "major" },
	{ name: "○○海鮮", cat: "市場", date: "2026-03-28", addr: "中山區民族東路 336 號", lat: 25.0701, lng: 121.5358, sample: "蛤蜊", reason: "重金屬鎘超標", severity: "major" },
	{ name: "○○海產", cat: "市場", date: "2026-03-02", addr: "汐止區大同路二段 280 號", lat: 25.0628, lng: 121.6624, sample: "虱目魚", reason: "硼砂檢出", severity: "major" },
	{ name: "○○蔬果", cat: "市場", date: "2026-02-15", addr: "林口區文化北路二段 30 號", lat: 25.0772, lng: 121.3941, sample: "高麗菜", reason: "農藥殘留 (益達胺) 超標", severity: "medium" },
	{ name: "○○海鮮", cat: "市場", date: "2026-01-22", addr: "樹林區中山路一段 56 號", lat: 24.9907, lng: 121.4216, sample: "蛤蜊", reason: "重金屬汞", severity: "major" },
	{ name: "○○蔬果攤", cat: "市場", date: "2025-12-15", addr: "中和區景平路 320 號", lat: 24.9994, lng: 121.4986, sample: "小白菜", reason: "農藥殘留", severity: "minor" },
	// 工廠
	{ name: "○○食品工廠", cat: "工廠", date: "2026-05-01", addr: "新莊區五工路 73 號", lat: 25.0537, lng: 121.4391, sample: "醬油", reason: "防腐劑超標", severity: "medium" },
];

export const foodFailuresGeoJSON = {
	type: "FeatureCollection",
	features: failureGeoJSONFeatures.map((f, i) => ({
		type: "Feature",
		geometry: { type: "Point", coordinates: [f.lng, f.lat] },
		properties: {
			id: i + 1,
			name: f.name,
			cat: f.cat,
			date: f.date,
			addr: f.addr,
			sample: f.sample,
			reason: f.reason,
			severity: f.severity,
		},
	})),
};
