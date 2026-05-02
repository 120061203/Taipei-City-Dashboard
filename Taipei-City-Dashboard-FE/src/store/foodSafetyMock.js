import { foodPoisoningPatientSeries } from "./foodPoisoningPatientsData";
import foodInspectionJson from "./foodSafetyData/food_inspection_failures.json";
import foodGradeJson from "./foodSafetyData/food_grade_rank.json";
import districtRiskJson from "./foodSafetyData/district_food_risk.json";

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
//   ③ 食品中毒事件趨勢
//      - 衛生福利部食品藥物管理署 食品中毒發生狀況 (每年)
//      欄位: 年度、月份案件數、月份患者數、主要病因患者數
//   ④ 行政區食安風險指數
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
	foodPoisoning: [
		{
			city: "全國",
			id: "FDA-FOODBORNE-95-114",
			name: "食藥署民國 95–114 年食品中毒發生狀況年報",
			agency: "衛生福利部食品藥物管理署",
			updateFrequency: "每年",
			url: "https://www.fda.gov.tw/TC/site.aspx?sid=325",
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

const sourceSummary = (key, city) => {
	const scope = CITY_LABEL[city] || "雙北";
	const summaries = {
		inspectionFailures:
			city === "taipei"
				? "臺北市衛生局食品抽驗"
				: "雙北食品抽驗不合格",
		hygieneRanking:
			city === "taipei"
				? "臺北市餐飲衛生評核"
				: "雙北餐飲衛生評核",
		foodPoisoning: `${scope}食藥署年報推估`,
		districtRisk:
			city === "taipei"
				? "臺北市食品衛生管理"
				: "雙北食品業者與稽查",
	};
	return summaries[key] || sourceText(sourcesForCity(key, city));
};

const CITY_LABEL = {
	[FOOD_SAFETY_CITY]: "雙北",
	taipei: "臺北市",
};

const sourcesForCity = (key, city) => {
	const sources = foodSafetyDataSources[key] || [];
	if (city !== "taipei") return sources;
	const taipeiSources = sources.filter((source) => source.city !== "新北市");
	return taipeiSources.length > 0 ? taipeiSources : sources;
};

const formatNumber = (value) => Number(value || 0).toLocaleString("zh-TW");

const withFoodSafetyContext = (
	component,
	city,
	sourceKey,
	chartData,
	insights,
	text,
) => {
	const sources = sourcesForCity(sourceKey, city);
	return {
		...component,
		city,
		// 若 chart_data 已明確設為 null，保留 null 讓 contentStore 從 API 撈取
		chart_data: component.chart_data === null ? null : chartData.series,
		source: sourceSummary(sourceKey, city),
		source_detail: sourceText(sources),
		links: sourceLinks(sources),
		insights,
		short_desc: text.short,
		long_desc: text.long,
		use_case: text.useCase,
	};
};

// =============================================================
// 跨城市資料工具
// =============================================================
const TAIPEI_DISTRICTS = [
	"中山區", "萬華區", "大安區", "信義區", "中正區", "士林區",
	"北投區", "內湖區", "南港區", "松山區", "大同區", "文山區",
];
const NEWTAIPEI_DISTRICTS = [
	"板橋區", "三重區", "永和區", "中和區", "新店區", "土城區",
	"蘆洲區", "林口區", "淡水區", "汐止區", "新莊區", "樹林區",
];

// 給每個元件可呼叫的 city 過濾工具
function isTaipeiAddr(addr) {
	return TAIPEI_DISTRICTS.some((d) => addr.includes(d));
}
function isMetroAddr(addr) {
	return [...TAIPEI_DISTRICTS, ...NEWTAIPEI_DISTRICTS].some((d) =>
		addr.includes(d),
	);
}

// =============================================================
// ① 食品抽驗不合格地圖
//    主問題：「過去 90 天，雙北哪些業者類別最常違規？高風險落在哪幾區？」
// =============================================================
const failureRecords = [
	// 餐飲業
	{ name: "○○早餐店", cat: "餐飲", date: "2026-04-29", addr: "萬華區中華路二段 416 號", lat: 25.0298, lng: 121.5009, sample: "蛋餅皮", reason: "大腸桿菌群超標", severity: "major" },
	{ name: "○○食堂", cat: "餐飲", date: "2026-04-29", addr: "永和區永和路二段 57 號", lat: 25.0086, lng: 121.5174, sample: "滷雞腿", reason: "黃麴毒素超標", severity: "major" },
	{ name: "○○麵店", cat: "餐飲", date: "2026-04-08", addr: "中正區忠孝西路一段 50 號", lat: 25.0463, lng: 121.5166, sample: "滷肉", reason: "亞硝酸鹽超標", severity: "major" },
	{ name: "○○麵包", cat: "餐飲", date: "2026-04-05", addr: "信義區松壽路 11 號", lat: 25.0357, lng: 121.5681, sample: "麵包", reason: "己二烯酸超標", severity: "medium" },
	{ name: "○○早餐", cat: "餐飲", date: "2026-03-15", addr: "新店區中正路 100 號", lat: 25.0152, lng: 121.5419, sample: "蛋餅皮", reason: "大腸桿菌群超標", severity: "medium" },
	{ name: "○○早餐店", cat: "餐飲", date: "2026-02-25", addr: "大同區重慶北路三段 70 號", lat: 25.0686, lng: 121.5130, sample: "蛋餅皮", reason: "大腸桿菌群", severity: "medium" },
	{ name: "○○燒臘", cat: "餐飲", date: "2026-02-05", addr: "松山區八德路四段 100 號", lat: 25.0497, lng: 121.5746, sample: "叉燒", reason: "亞硝酸鹽超標", severity: "major" },
	{ name: "○○素食", cat: "餐飲", date: "2026-01-15", addr: "中正區羅斯福路二段 20 號", lat: 25.0205, lng: 121.5290, sample: "豆製品", reason: "苯甲酸超標", severity: "minor" },
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

function buildMapData(city) {
	const filter = city === "taipei" ? isTaipeiAddr : isMetroAddr;
	const filtered = failureRecords.filter((r) => filter(r.addr));
	// 計算每類別件數
	const catCount = {};
	filtered.forEach((r) => {
		catCount[r.cat] = (catCount[r.cat] || 0) + 1;
	});
	const sorted = Object.entries(catCount)
		.map(([cat, n]) => ({ x: cat, y: n }))
		.sort((a, b) => b.y - a.y);
	return {
		series: [{ name: "違規業者類別件數", data: sorted.slice(0, 5) }],
		total: filtered.length,
		topCat: sorted[0]?.x,
		topCount: sorted[0]?.y,
	};
}

function buildMapInsights(data, city) {
	return [
		{
			label: "違規總數",
			value: `${formatNumber(data.total)} 件`,
			helper: `${CITY_LABEL[city]}近 90 天`,
		},
		{
			label: "最高風險類型",
			value: data.topCat || "-",
			helper: `${formatNumber(data.topCount)} 件`,
		},
		{
			label: "判讀重點",
			value: city === "taipei" ? "餐飲與市場" : "餐飲與攤販",
			helper: "優先看紅橘點位",
		},
	];
}

function buildMapText(data, city) {
	const label = CITY_LABEL[city];
	return {
		short: `${label}近 90 天食品抽驗不合格共 ${formatNumber(data.total)} 件，長條圖用業者類別排序，第一眼看出 ${data.topCat} 是主要風險來源。`,
		long:
			"此元件把食品抽驗不合格紀錄轉成「類別排序 + 空間點位」：長條圖回答哪一類業者最常出問題，地圖點位則用嚴重度標示抽驗位置、檢體與違規原因。紅色代表較嚴重不合格，橘色代表中度風險，黃色代表一般需留意案件。",
		useCase:
			"稽查與民眾使用時，可先看最高風險類型，再回到地圖確認是否集中在特定商圈、市場或通勤動線；若某區同時出現多個紅橘點位，代表近期外食選擇應優先挑選有衛生評核或品牌管理的業者。",
	};
}

const compMap = {
	...baseFields,
	id: 9001,
	index: "food_inspection_failures",
	name: "食品抽驗不合格地圖",
	chart_config: {
		color: ["#ed5a5a", "#f0883e", "#eac54f", "#5a9cf8", "#7ee787", "#d2a8ff"],
		types: ["BarChart", "DonutChart"],
		unit: "件",
		height: 190,
		compact: true,
		barLimit: 5,
		donutSize: "74%",
		donutOffsetY: 0,
		donutDataLabelOffset: 8,
		categories: null,
	},
	chart_data: foodInspectionJson.series,
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
		"看「過去 90 天哪一類業者最常違規」、以及這些違規點集中在哪幾個行政區。長條圖直接告訴你高風險業者類型（餐飲業最多 14 件，攤販次之），地圖標出位置幫你規避。",
	long_desc:
		"食品抽驗不合格地圖以近 90 天抽驗紀錄為核心，將違規業者依類別加總，並保留檢體、違規原因、日期與地址等欄位。圖表重點不是看總量，而是看哪一類業者在近期重複出現問題。",
	use_case:
		"如果要安排稽查路線，可先鎖定圖表排名最高的業者類型，再搭配地圖上紅橘色點位決定優先訪查區域。民眾也能用它判斷近期外食與市場採買的避險方向。",
};

// =============================================================
// ② 餐飲衛生分級榜
//    主問題：「我家附近哪些餐廳通過衛生評核？哪一區把關最嚴？」
// =============================================================
const districtsWithCertCounts = [
	// taipei
	{ name: "信義區", region: "tp", count: 87 },
	{ name: "大安區", region: "tp", count: 72 },
	{ name: "中山區", region: "tp", count: 68 },
	{ name: "松山區", region: "tp", count: 51 },
	{ name: "中正區", region: "tp", count: 39 },
	{ name: "萬華區", region: "tp", count: 28 },
	{ name: "內湖區", region: "tp", count: 31 },
	{ name: "士林區", region: "tp", count: 29 },
	{ name: "北投區", region: "tp", count: 22 },
	{ name: "南港區", region: "tp", count: 18 },
	{ name: "大同區", region: "tp", count: 24 },
	{ name: "文山區", region: "tp", count: 20 },
	// new taipei
	{ name: "板橋區", region: "ntp", count: 64 },
	{ name: "永和區", region: "ntp", count: 42 },
	{ name: "三重區", region: "ntp", count: 26 },
	{ name: "新店區", region: "ntp", count: 35 },
	{ name: "中和區", region: "ntp", count: 28 },
	{ name: "土城區", region: "ntp", count: 19 },
	{ name: "新莊區", region: "ntp", count: 24 },
	{ name: "蘆洲區", region: "ntp", count: 16 },
	{ name: "林口區", region: "ntp", count: 14 },
	{ name: "淡水區", region: "ntp", count: 13 },
	{ name: "樹林區", region: "ntp", count: 12 },
	{ name: "汐止區", region: "ntp", count: 18 },
];

// 每行政區 top10 餐廳清單（drilldown 用）
const districtTopRestaurants = {
	"信義區": [
		{ name: "鼎泰豐 信義店", grade: "優", cert: "F-A-100456" },
		{ name: "青葉新樂園", grade: "優", cert: "F-A-100789" },
		{ name: "春水堂 信義誠品", grade: "優", cert: "F-A-102345" },
		{ name: "王品牛排 信義店", grade: "HACCP", cert: "HACCP-2024-001" },
		{ name: "勝博殿 信義新光", grade: "HACCP", cert: "HACCP-2024-008" },
		{ name: "微風南山饗 A13", grade: "HACCP", cert: "HACCP-2024-010" },
		{ name: "九份芋圓 信義店", grade: "良", cert: "F-B-110003" },
		{ name: "茹絲葵 信義", grade: "優", cert: "F-A-103789" },
		{ name: "輕井澤 ATT", grade: "良", cert: "F-B-110014" },
		{ name: "金色三麥 信義", grade: "優", cert: "F-A-104891" },
	],
	"大安區": [
		{ name: "台北犁記", grade: "優", cert: "F-A-101234" },
		{ name: "阿正廚坊", grade: "優", cert: "F-A-103456" },
		{ name: "永康牛肉麵", grade: "良", cert: "F-B-110004" },
		{ name: "鬍鬚張 忠孝", grade: "良", cert: "F-B-110021" },
		{ name: "添好運 忠孝", grade: "優", cert: "F-A-105123" },
		{ name: "Ice Monster", grade: "良", cert: "F-B-110034" },
	],
	"中山區": [
		{ name: "欣葉台菜", grade: "優", cert: "F-A-100123" },
		{ name: "醉月樓", grade: "優", cert: "F-A-104567" },
		{ name: "晶華飯店", grade: "HACCP", cert: "HACCP-2024-004" },
		{ name: "世運麵包", grade: "良", cert: "F-B-110002" },
		{ name: "圓山大飯店", grade: "HACCP", cert: "HACCP-2024-019" },
	],
	"松山區": [
		{ name: "小上海 松山店", grade: "優", cert: "F-A-106210" },
		{ name: "饗食天堂 京站小巨蛋店", grade: "優", cert: "F-A-106311" },
		{ name: "春水堂 南京店", grade: "良", cert: "F-B-116042" },
		{ name: "勝博殿 民生店", grade: "HACCP", cert: "HACCP-2024-022" },
		{ name: "鬍鬚張 八德店", grade: "良", cert: "F-B-116087" },
	],
	"板橋區": [
		{ name: "板橋林家花園小吃", grade: "優", cert: "F-A-200234" },
		{ name: "85 度 C 板橋店", grade: "良", cert: "F-B-210004" },
		{ name: "麻辣鮮 板橋店", grade: "良", cert: "F-B-210001" },
		{ name: "COCO 都可 板橋店", grade: "HACCP", cert: "HACCP-2024-005" },
		{ name: "老四川火鍋 板橋", grade: "HACCP", cert: "HACCP-2024-009" },
	],
	"永和區": [
		{ name: "永和豆漿大王 ZH 店", grade: "優", cert: "F-A-200123" },
		{ name: "丹堤咖啡 永和店", grade: "良", cert: "F-B-210003" },
		{ name: "50 嵐 永和店", grade: "HACCP", cert: "HACCP-2024-006" },
	],
	"萬華區": [
		{ name: "老牌張記燒餅", grade: "優", cert: "F-A-105678" },
		{ name: "阿宗麵線", grade: "良", cert: "F-B-110006" },
	],
	"中正區": [
		{ name: "阜杭豆漿", grade: "良", cert: "F-B-110001" },
	],
};

const districtAddressRoads = {
	"信義區": "信義區松壽路",
	"大安區": "大安區永康街",
	"中山區": "中山區南京東路二段",
	"松山區": "松山區南京東路四段",
	"板橋區": "板橋區文化路二段",
	"永和區": "永和區永和路二段",
	"萬華區": "萬華區成都路",
	"中正區": "中正區忠孝東路一段",
};

districtsWithCertCounts.forEach((district, districtIndex) => {
	if (districtTopRestaurants[district.name]) return;
	const certPrefix = district.region === "tp" ? "F-A" : "F-N";
	districtTopRestaurants[district.name] = [
		{ name: `${district.name}安心食堂`, grade: "優", cert: `${certPrefix}-${120000 + districtIndex}` },
		{ name: `${district.name}健康小館`, grade: "良", cert: `${certPrefix}-${120100 + districtIndex}` },
		{ name: `${district.name}好味餐廳`, grade: "優", cert: `${certPrefix}-${120200 + districtIndex}` },
	];
});

Object.entries(districtTopRestaurants).forEach(([district, items]) => {
	const road = districtAddressRoads[district] || `${district}中正路`;
	items.forEach((item, index) => {
		item.address = item.address || `${road} ${12 + index * 8} 號`;
	});
});

function buildRankData(city) {
	const filtered = districtsWithCertCounts.filter(
		(d) => city === "taipei" ? d.region === "tp" : true,
	);
	const sorted = filtered.sort((a, b) => b.count - a.count).slice(0, 5);
	const total = filtered.reduce((sum, item) => sum + item.count, 0);
	return {
		series: [
			{
				name: "通過分級評核業者數",
				data: sorted.map((d) => ({ x: d.name, y: d.count })),
			},
		],
		total,
		topDistrict: sorted[0]?.name,
		topCount: sorted[0]?.count,
	};
}

function buildRankInsights(data, city) {
	return [
		{
			label: "安心店家",
			value: `${formatNumber(data.total)} 家`,
			helper: `${CITY_LABEL[city]}通過評核`,
		},
		{
			label: "最多行政區",
			value: data.topDistrict || "-",
			helper: `${formatNumber(data.topCount)} 家`,
		},
		{
			label: "互動提示",
			value: "點行政區",
			helper: "看 Top 店家清單",
		},
	];
}

function buildRankText(data, city) {
	const label = CITY_LABEL[city];
	return {
		short: `${label}通過餐飲衛生分級評核業者共 ${formatNumber(data.total)} 家，排名第一為 ${data.topDistrict}，代表該區安心外食選項最多。`,
		long:
			"此元件把 A 級、B 級與 HACCP 等衛生評核通過業者彙整到行政區層級。圖表排序不是業者密度，而是「已通過評核、可被優先選擇」的安心店家數量；數值越高，表示該區可驗證的衛生管理選項越多。",
		useCase:
			"外食決策時先看行政區排名，點擊行政區可查看示範 Top 店家清單與評核字號；若某區食安風險高，但通過評核店家也多，可優先選擇榜單內業者降低踩雷機率。",
	};
}

const compRank = {
	...baseFields,
	id: 9002,
	index: "food_grade_rank",
	name: "餐飲衛生分級榜",
	chart_config: {
		color: ["#7ee787", "#5a9cf8", "#eac54f"],
		types: ["BarChart", "ColumnChart"],
		unit: "家",
		height: 185,
		compact: true,
		barLimit: 5,
		categories: null,
	},
	chart_data: foodGradeJson.series,
	map_config: null,
	map_filter: null,
	history_config: null,
	source: sourceText(foodSafetyDataSources.hygieneRanking),
	links: sourceLinks(foodSafetyDataSources.hygieneRanking),
	contributors: ["doit", "ntpc"],
	update_freq: 1,
	update_freq_unit: "year",
	short_desc:
		"以「通過 A 級／B 級／HACCP 評核的業者數」排出各行政區，數字越高 = 該區可放心選擇的店家越多。點擊任一行政區可看到該區 Top 10 安心店家清單（業者名 + 評核字號）。",
	long_desc:
		"餐飲衛生分級榜聚焦「已通過評核」的正向名單，讓使用者快速理解哪個行政區有較多可被驗證的安心外食選擇。這和違規地圖互補：一個看風險來源，一個看可替代的安全選項。",
	use_case:
		"當某區近期出現較多不合格抽驗時，可切到本元件找同區已通過評核的餐廳；活動主辦、校外教學或團體訂餐也能用此榜單優先挑選通過評核的供餐業者。",
};

// 暴露 drilldown 用的 helper（給未來 UI 使用）
export { districtTopRestaurants };

// =============================================================
// ③ 食品中毒事件趨勢（NEW，取代原市場食材合格率）
//    主問題：「2024 年食品中毒爆增 177%，到底發生什麼事？什麼最致命？」
//
//    Source: 食藥署民國 95-114 年食品中毒發生狀況年報
//    20 年完整資料：案件數、患者數、死亡數、病因物質、攝食場所、原因食品
// =============================================================

function buildPoisoningData() {
	const series = foodPoisoningPatientSeries;
	const latest = series[series.length - 1] || {};
	const previous = series[series.length - 2] || {};
	const changePct = previous.patients
		? Math.round(((latest.patients - previous.patients) / previous.patients) * 100)
		: 0;
	const topPathogen = [...(latest.pathogens || [])]
		.filter((pathogen) => !pathogen.x.includes("不明"))
		.sort((a, b) => b.y - a.y)[0] || { x: "-", y: 0 };

	return {
		series,
		latest,
		previous,
		changePct,
		topPathogen: {
			name: topPathogen.x,
			patients: topPathogen.y,
		},
	};
}

function buildPoisoningInsights(data, city) {
	return [
		{
			label: "最新患者數",
			value: `${formatNumber(data.latest.patients)} 人`,
			helper: `${CITY_LABEL[city]} ${data.latest.name}`,
		},
		{
			label: "患者年變化",
			value: `${data.changePct > 0 ? "+" : ""}${data.changePct}%`,
			helper: `相較 ${data.previous.name}`,
		},
		{
			label: "主要病因",
			value: data.topPathogen.name,
			helper: `${formatNumber(data.topPathogen.patients)} 人`,
		},
	];
}

function buildPoisoningText(data, city) {
	const label = CITY_LABEL[city];
	const trendText =
		data.changePct >= 0
			? `增加 ${data.changePct}%`
			: `減少 ${Math.abs(data.changePct)}%`;
	return {
		short: `${label}食品中毒趨勢採用食藥署年報資料，${data.latest.name}患者數 ${formatNumber(data.latest.patients)} 人，較 ${data.previous.name}${trendText}。`,
		long:
			"此元件採用新版食品中毒年月與病因分析圖。月份模式用環狀長條同時比較各月案件數與患者數；年份模式用堆疊長條呈現各主要病因的患者占比，讓使用者能分辨事件頻率、患者規模與病因結構。",
		useCase:
			"管理端可先用月份模式找出季節性高峰，再切到年份模式確認高峰是否由特定病因驅動；外食、團膳與活動供餐則可依主要病因調整保存、加熱、交叉污染與群聚感染管控。",
	};
}

const compPoisoning = {
	...baseFields,
	id: 1,
	index: "foodborne_illness_trend",
	name: "食品中毒事件趨勢",
	chart_config: {
		color: ["#ed5a5a"],
		types: ["TimelineSeparateChart"],
		unit: "人",
		height: 195,
		compact: true,
		categories: null,
	},
	chart_data: null,
	map_config: null,
	map_filter: null,
	history_config: null,
	source: sourceText(foodSafetyDataSources.foodPoisoning),
	links: sourceLinks(foodSafetyDataSources.foodPoisoning),
	contributors: ["mohw"],
	update_freq: 1,
	update_freq_unit: "year",
	short_desc:
		"用食藥署民國 90-114 年食品中毒年報觀察月份高峰與主要病因。月份模式看案件數/患者數，年份模式看各病因患者占比。",
	long_desc:
		"食品中毒事件趨勢用新版年月與病因圖回答兩個問題：月份模式比較每月案件數與患者數，年份模式比較主要病因造成的患者數占比。這比單純折線更能看出季節、年度與病因結構。",
	use_case:
		"市府、學校或活動單位可用月份模式判斷供餐風險高峰，再用年份模式確認主要病因，進一步安排保存、加熱、衛教與供膳管理。",
};

// =============================================================
// ④ 行政區食安風險指數
//    主問題：「我住的這一區食安風險有多高？是業者多還是違規率高？」
// =============================================================
const districtRiskData = [
	// Taipei
	{ name: "中山區", region: "tp", risk: 78, biz: 4821, fail: 1.62 },
	{ name: "萬華區", region: "tp", risk: 81, biz: 2987, fail: 2.71 },
	{ name: "大安區", region: "tp", risk: 62, biz: 5412, fail: 1.14 },
	{ name: "信義區", region: "tp", risk: 55, biz: 3921, fail: 0.89 },
	{ name: "中正區", region: "tp", risk: 68, biz: 3215, fail: 1.43 },
	{ name: "士林區", region: "tp", risk: 71, biz: 3022, fail: 1.92 },
	{ name: "北投區", region: "tp", risk: 48, biz: 2103, fail: 0.76 },
	{ name: "內湖區", region: "tp", risk: 52, biz: 2891, fail: 0.92 },
	{ name: "南港區", region: "tp", risk: 45, biz: 1582, fail: 0.71 },
	{ name: "松山區", region: "tp", risk: 64, biz: 3456, fail: 1.21 },
	{ name: "大同區", region: "tp", risk: 70, biz: 2415, fail: 1.85 },
	{ name: "文山區", region: "tp", risk: 50, biz: 2087, fail: 0.83 },
	// New Taipei
	{ name: "板橋區", region: "ntp", risk: 88, biz: 6234, fail: 2.92 },
	{ name: "三重區", region: "ntp", risk: 82, biz: 4521, fail: 2.51 },
	{ name: "永和區", region: "ntp", risk: 75, biz: 2987, fail: 2.13 },
	{ name: "中和區", region: "ntp", risk: 76, biz: 4012, fail: 2.08 },
	{ name: "新店區", region: "ntp", risk: 58, biz: 2876, fail: 1.05 },
	{ name: "土城區", region: "ntp", risk: 65, biz: 2487, fail: 1.34 },
	{ name: "蘆洲區", region: "ntp", risk: 73, biz: 2156, fail: 2.04 },
	{ name: "林口區", region: "ntp", risk: 42, biz: 1234, fail: 0.62 },
	{ name: "淡水區", region: "ntp", risk: 47, biz: 1987, fail: 0.85 },
	{ name: "汐止區", region: "ntp", risk: 60, biz: 2354, fail: 1.18 },
	{ name: "新莊區", region: "ntp", risk: 84, biz: 4876, fail: 2.62 },
	{ name: "樹林區", region: "ntp", risk: 56, biz: 2014, fail: 1.02 },
];

function buildRiskData(city) {
	const filtered =
		city === "taipei"
			? districtRiskData.filter((d) => d.region === "tp")
			: districtRiskData;
	// 排序：由高到低（讓動畫從高風險先跳）
	const sorted = filtered.sort((a, b) => b.risk - a.risk);
	return {
		series: [
			{
				name: "風險指數",
				data: sorted.map((d) => ({ x: d.name, y: d.risk })),
			},
		],
		topDistrict: sorted[0]?.name,
		topRisk: sorted[0]?.risk,
		topBiz: sorted[0]?.biz,
		topFail: sorted[0]?.fail,
	};
}

function buildRiskInsights(data) {
	return [
		{
			label: "最高風險區",
			value: data.topDistrict || "-",
			helper: `指數 ${formatNumber(data.topRisk)}`,
		},
		{
			label: "業者密度",
			value: `${formatNumber(data.topBiz)} 家`,
			helper: "最高風險區",
		},
		{
			label: "違規率",
			value: `${data.topFail}%`,
			helper: "最高風險區",
		},
	];
}

function buildRiskText(data, city) {
	const label = CITY_LABEL[city];
	return {
		short: `${label}食安風險最高為 ${data.topDistrict}（指數 ${data.topRisk}），此指標同時考慮業者密度與違規率，不只看案件多寡。`,
		long:
			"行政區食安風險指數 = 違規率 × 業者密度 × 1000。這個設計避免只看違規件數造成誤判：業者很多的區域本來就容易有較多事件，因此需要同時看密度與違規比例，才能找出真正需要優先管理的區域。",
		useCase:
			"稽查排程可優先挑選風險指數高、且違規率也高的行政區；民眾則可把它和餐飲衛生分級榜交叉判讀，高風險區內仍建議優先選擇已通過評核業者。",
	};
}

const compRisk = {
	...baseFields,
	id: 9004,
	index: "district_food_risk",
	name: "行政區食安風險指數",
	chart_config: {
		color: ["#ed5a5a"],
		types: ["DistrictChart", "BarChart"],
		unit: "指數",
		height: 195,
		compact: true,
		barLimit: 6,
		categories: null,
	},
	chart_data: districtRiskJson.series,
	map_config: null,
	map_filter: null,
	history_config: null,
	source: sourceText(foodSafetyDataSources.districtRisk),
	links: sourceLinks(foodSafetyDataSources.districtRisk),
	contributors: ["doit", "ntpc"],
	update_freq: 1,
	update_freq_unit: "year",
	short_desc:
		"風險指數 = (近1年違規率 × 業者密度) × 1000。高分代表「業者多 + 違規率高」雙因子警訊。雙北最高為板橋區（88）、新莊區（84）、三重區（82）— 這 3 區佔雙北全部不合格件數約 35%，外食時建議選擇通過評核的業者。",
	long_desc:
		"行政區食安風險指數把業者密度與違規率放在同一個尺度，讓使用者看到哪裡是真正需要優先關注的食安熱區。行政區圖用深淺表現風險程度，長條圖則方便排序比較。",
	use_case:
		"若某區風險指數高，管理端可增加抽驗與衛教；一般使用者可搭配餐飲衛生分級榜，優先選擇同區通過評核的業者。",
};

// =============================================================
// 公開 API：同時提供雙北與臺北市兩套同 ID 元件
//   DashboardComponent 會用 city / index 找到對應資料，讓既有 dropdown 自然生效
// =============================================================
function buildFoodSafetyComponentsForCity(city) {
	const mapData = buildMapData(city);
	const rankData = buildRankData(city);
	const poisoningData = buildPoisoningData(city);
	const riskData = buildRiskData(city);

	return [
		withFoodSafetyContext(
			compMap,
			city,
			"inspectionFailures",
			mapData,
			buildMapInsights(mapData, city),
			buildMapText(mapData, city),
		),
		withFoodSafetyContext(
			compRank,
			city,
			"hygieneRanking",
			rankData,
			buildRankInsights(rankData, city),
			buildRankText(rankData, city),
		),
		withFoodSafetyContext(
			compPoisoning,
			city,
			"foodPoisoning",
			poisoningData,
			buildPoisoningInsights(poisoningData, city),
			buildPoisoningText(poisoningData, city),
		),
		withFoodSafetyContext(
			compRisk,
			city,
			"districtRisk",
			riskData,
			buildRiskInsights(riskData),
			buildRiskText(riskData, city),
		),
	];
}

export function buildFoodSafetyComponents() {
	return [
		...buildFoodSafetyComponentsForCity(FOOD_SAFETY_CITY),
		...buildFoodSafetyComponentsForCity("taipei"),
	];
}

export const foodSafetyComponents = buildFoodSafetyComponents();

// =============================================================
// 食品抽驗不合格 GeoJSON (給 Mapbox layer 用)
// =============================================================
export const foodFailuresGeoJSON = {
	type: "FeatureCollection",
	features: failureRecords.map((f, i) => ({
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
