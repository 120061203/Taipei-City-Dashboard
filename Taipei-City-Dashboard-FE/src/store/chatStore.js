import { ref, watch } from 'vue'
import { defineStore } from 'pinia'
import http from "../router/axios";

const FOOD_SAFETY_COMPONENTS = new Set([
	"food_inspection_failures",
	"food_grade_rank",
	"foodborne_illness_trend",
	"district_food_risk",
]);

const FOOD_SAFETY_KEYWORDS = [
	"食安",
	"食品",
	"抽驗",
	"不合格",
	"違規",
	"分級",
	"評核",
	"中毒",
	"病因",
	"患者",
	"風險",
	"行政區",
];

const FOOD_SAFETY_COMPONENT_MATCHERS = [
	{
		index: "foodborne_illness_trend",
		keywords: ["中毒", "病因", "患者", "案件", "事件", "趨勢"],
	},
	{
		index: "food_grade_rank",
		keywords: ["分級", "評核", "安心", "餐廳", "衛生分級"],
	},
	{
		index: "district_food_risk",
		keywords: ["風險", "風險指數", "高風險", "業者密度", "違規率"],
	},
	{
		index: "food_inspection_failures",
		keywords: ["抽驗", "抽檢", "不合格", "違規", "檢體"],
	},
];

const FOOD_SAFETY_PREVIEW_CONFIGS = {
	food_inspection_failures: {
		color: ["#ed5a5a", "#f0883e", "#eac54f", "#5a9cf8", "#7ee787", "#d2a8ff"],
		types: ["BarChart", "DonutChart"],
		unit: "件",
		height: 150,
		compact: true,
		barLimit: 5,
		donutSize: "74%",
		donutOffsetY: 0,
		donutDataLabelOffset: 8,
		categories: null,
	},
	food_grade_rank: {
		color: ["#7ee787", "#5a9cf8", "#eac54f"],
		types: ["BarChart", "ColumnChart"],
		unit: "家",
		height: 150,
		compact: true,
		barLimit: 5,
		categories: null,
	},
	foodborne_illness_trend: {
		color: ["#ed5a5a", "#f0883e", "#eac54f", "#5a9cf8", "#7ee787", "#d2a8ff"],
		types: ["FoodPoisoningYearlyChart"],
		unit: "人",
		height: 150,
		compact: true,
		categories: null,
	},
	district_food_risk: {
		color: ["#ed5a5a"],
		types: ["DistrictChart", "BarChart"],
		unit: "指數",
		height: 150,
		compact: true,
		barLimit: 6,
		categories: null,
	},
};

export const useChatStore = defineStore('chat', () => {
  	// 預設訊息
  	const defaultChatData = [
    	{
      		id: 1,
      		role: 'bot',
	  		isDefault: true,
      		content:
        	'您好，我是【臺北城市儀表板】小幫手，很高興為您服務！\n 您可以： \n\n • 點擊左側既有的儀表板主題，快速查看各主題內容 \n • 輸入您感興趣的主題描述，我會自動為您組建最適合的儀表板 \n\n 如果有想了解的內容，歡迎直接告訴我，我會盡力協助！\n\n 📩 聯絡信箱：tuic@gov.taipei \n 🏢 臺北大數據中心 \n\n',
    	},
  	];

	const recommendComponents = ref(null)

  	// 從 sessionStorage 讀取
  	const savedChatData = JSON.parse(sessionStorage.getItem('chatData')) || [];

  	// 拼接預設訊息 + sessionStorage 的聊天紀錄
  	const chatData = ref([...defaultChatData, ...savedChatData]);

  	// 監聽 chatData 的變化，自動同步到 sessionStorage
  	watch(
    	chatData,
    	(newVal) => {
      	// 只存使用者與機器人的聊天訊息，不存重複的預設訊息
      	const userBotMessages = newVal.filter((item) => !item.isDefault)
      	sessionStorage.setItem('chatData', JSON.stringify(userBotMessages))
    	},
    	{ deep: true }
  	);

  	const addChatData = (newChatData) => {
    	chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });
  	};

  	const addQueryData = async (newChatData) => {

    	chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });

		recommendComponents.value = [];
		let topK = null;

		try {
			const response = await http.post(
  				"/vector/component",
  				new URLSearchParams({
    				query: newChatData.content,
    				limit: 10,
    				score: 0.8,
  				}),
  				{
    				headers: {
      					"Content-Type": "application/x-www-form-urlencoded",
    				},
  				}
			);
			if (response.data?.data?.length > 0) {
				recommendComponents.value = response.data.data;
			}

			// 去除重複項目存到 result
			const result = Array.from(
  				recommendComponents.value.reduce((map, item) => {
    				const key = item.index
    				const exist = map.get(key)

    				// 如果還沒放過，直接放
    				if (!exist) {
      					map.set(key, item)
      					return map
    				}

    				// 如果已存在，但現在的是 metrotaipei，就覆蓋
    				if (item.city === 'metrotaipei') {
      					map.set(key, item)
    				}

    				return map
  				}, new Map()).values()
			)
			// 把 result 蓋回去 recommendComponents
			recommendComponents.value = result
			recommendComponents.value = prioritizeFoodSafetyRelations(newChatData.content, recommendComponents.value);

		} catch (error) { 
			console.error("VectorAnalysisError :", error);
		}

		if (recommendComponents.value && recommendComponents.value?.length > 0) {
			topK = prioritizeFoodSafetyRelations(
				newChatData.content,
				[...recommendComponents.value].sort((a, b) => b.score - a.score)
			);
			const aiSummary = await getFoodSafetyAISummary(newChatData.content, topK);
			if (aiSummary) {
				const componentData = await getFoodSafetyComponentData(newChatData.content, topK);
				chatData.value.push({
					id: chatData.value.length + 1,
					role: 'bot',
					isDefault: false,
					content: aiSummary,
					componentData,
					relations: componentData ? null : getPrimaryFoodSafetyRelations(newChatData.content, topK),
				});
			} else {
				chatData.value.push({ id: chatData.value.length + 1, role: 'bot', isDefault: false, button: [{ id:1, text:'建立儀表板' }], content: `您好 😊 \n 以下是根據您的問題，自動為您推薦的「組件清單」。您可以將這些組件整批加入「個人儀表板」，方便日後快速查看與使用。\n`, relations: topK });
				chatData.value.push({ id: chatData.value.length + 1, role: 'bot', isDefault: false, content: `若您有任何新的查詢或想深入探索的內容，都可以隨時在對話框告訴我～\n 我很樂意再協助您 💬✨` });
			}
		} else {
			const aiSummary = await getFoodSafetyAISummary(newChatData.content, []);
			chatData.value.push({ id: chatData.value.length + 1, role: 'bot', isDefault: false, content: aiSummary || `很抱歉，您提供的描述沒有相似組件，請繼續提問 ! ` });
		}

		// 分析結束後紀錄問答log
		saveChatLog(newChatData.content, recommendComponents.value);
  	};

	const saveChatLog = async(question, answer) => {
		try {
        	const formData = new FormData();
        	const d = new Date();
        	const todayId =
          		d.getFullYear() +
          		String(d.getMonth() + 1).padStart(2, "0") +
          		String(d.getDate()).padStart(2, "0");

        	formData.append("session", "session_" + todayId);
        	formData.append("question", question);
        	formData.append("answer", JSON.stringify(answer));

        	await http.post("/chatlog/", formData, {
          		headers: {
            		"Content-Type": "multipart/form-data",
          		},
        	});
      	} catch (error) {
        	console.error("saveChatLog error:", error);
		}
	};

	const isFoodSafetyQuery = (question, relations = []) => {
		return FOOD_SAFETY_KEYWORDS.some((keyword) => question.includes(keyword)) ||
			relations.some((item) => FOOD_SAFETY_COMPONENTS.has(item.index));
	};

	const getFoodSafetyComponentIndex = (question, relations = []) => {
		const matched = FOOD_SAFETY_COMPONENT_MATCHERS.find(({ keywords }) =>
			keywords.some((keyword) => question.includes(keyword))
		);
		if (matched) return matched.index;
		return relations.find((item) => FOOD_SAFETY_COMPONENTS.has(item.index))?.index || "";
	};

	const prioritizeFoodSafetyRelations = (question, relations = []) => {
		const preferredIndex = getFoodSafetyComponentIndex(question, relations);
		if (!preferredIndex) return relations;

		return [...relations].sort((a, b) => {
			if (a.index === preferredIndex && b.index !== preferredIndex) return -1;
			if (b.index === preferredIndex && a.index !== preferredIndex) return 1;
			return (b.score || 0) - (a.score || 0);
		});
	};

	const getPrimaryFoodSafetyRelations = (question, relations = []) => {
		const preferredIndex = getFoodSafetyComponentIndex(question, relations);
		if (!preferredIndex) return relations;

		const primary = relations.find((item) => item.index === preferredIndex);
		return primary ? [primary] : relations.slice(0, 1);
	};

	const getFoodSafetyComponentData = async(question, relations = []) => {
		const [primary] = getPrimaryFoodSafetyRelations(question, relations);
		if (!primary?.id) return null;

		try {
			const response = await http.get(`/component/${primary.id}/chart`, {
				params: { city: primary.city || "metrotaipei" },
			});
			const rows = normalizeFoodSafetyChartRows(response.data?.data);
			if (!rows.length) return null;

			return {
				componentId: primary.id,
				componentIndex: primary.index,
				cityCode: primary.city || "metrotaipei",
				title: primary.name,
				city: primary.city === "taipei" ? "臺北" : "雙北",
				summary: buildFoodSafetyComponentSummary(primary.index, rows),
				columns: buildFoodSafetyComponentColumns(primary.index),
				rows: rows.slice(0, 8),
				previewConfig: buildFoodSafetyPreviewConfig(primary, response.data?.data),
			};
		} catch (error) {
			console.error("FoodSafetyComponentDataError :", error);
			return null;
		}
	};

	const buildFoodSafetyPreviewConfig = (component, chartData = []) => {
		const chartConfig = FOOD_SAFETY_PREVIEW_CONFIGS[component.index];
		if (!chartConfig) return null;

		return {
			id: component.id,
			index: component.index,
			name: component.name,
			city: component.city || "metrotaipei",
			chart_config: chartConfig,
			chart_data: chartData,
			map_config: null,
			map_filter: null,
			history_config: null,
			source: "臺北市衛生局",
			links: null,
			contributors: [],
			update_freq: 1,
			update_freq_unit: "year",
			time_from: "static",
			time_to: "static",
			short_desc: "",
			long_desc: "",
			use_case: "",
		};
	};

	const normalizeFoodSafetyChartRows = (chartData = []) => {
		const firstSeries = Array.isArray(chartData) ? chartData[0]?.data : [];
		if (!Array.isArray(firstSeries)) return [];

		return firstSeries.map((item) => ({
			label: item.x ?? item.x_axis ?? item.name ?? "",
			value: item.y ?? item.data ?? item.value ?? 0,
		})).filter((item) => item.label !== "");
	};

	const buildFoodSafetyComponentSummary = (componentIndex, rows) => {
		if (componentIndex === "district_food_risk") {
			const total = rows.reduce((sum, row) => sum + Number(row.value || 0), 0);
			return {
				label: "綜合",
				value: Number.isInteger(total) ? total : Number(total.toFixed(2)),
				unit: "指數",
			};
		}
		return null;
	};

	const buildFoodSafetyComponentColumns = (componentIndex) => {
		if (componentIndex === "district_food_risk") {
			return { label: "行政區", value: "風險指數" };
		}
		return { label: "項目", value: "數值" };
	};

	const getFoodSafetyAISummary = async(question, relations = []) => {
		if (!isFoodSafetyQuery(question, relations)) return "";
		const componentIndex = getFoodSafetyComponentIndex(question, relations);

		try {
			const response = await http.post("/ai/chat/twai", {
				stream: false,
				messages: [
					{
						role: "system",
						content: "你是臺北城市儀表板食安小幫手。必須使用工具取得目前表內資料後回答。回答繁體中文，最多 3 句，直接講重點，不要列太長。",
					},
					{
						role: "user",
						content: `問題：${question}\n建議 component_index：${componentIndex}`,
					},
				],
				tools: [
					{
						type: "function",
						function: {
							name: "get_food_safety_table_data",
							description: "讀取食安守護四張圖目前資料，包含食品抽驗不合格、餐飲衛生分級、食品中毒趨勢、行政區食安風險。",
							parameters: {
								type: "object",
								properties: {
									query: {
										type: "string",
										description: "使用者原始問題",
									},
									component_index: {
										type: "string",
										enum: ["", "food_inspection_failures", "food_grade_rank", "foodborne_illness_trend", "district_food_risk"],
										description: "若向量搜尋已找到最相關圖表，填入圖表 index；不確定則留空。",
									},
								},
								required: ["query", "component_index"],
							},
						},
					},
				],
				max_new_tokens: 160,
				temperature: 0.2,
			});

			return response.data?.data?.content || "";
		} catch (error) {
			console.error("FoodSafetyAISummaryError :", error);
			return "";
		}
	};

	return { chatData, addChatData, addQueryData, saveChatLog }
})
