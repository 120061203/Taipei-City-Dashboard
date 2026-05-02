<script setup>
import { computed, ref, watch } from "vue";
import { useDialogStore } from "../../store/dialogStore";
import http from "../../router/axios";

import DialogContainer from "./DialogContainer.vue";

const dialogStore = useDialogStore();

const imageDataUrl = ref("");
const summary = ref("");
const loadingImage = ref(false);
const loadingSummary = ref(false);
const error = ref("");

const content = computed(() => dialogStore.shareComponentContent);
const component = computed(() => content.value?.config || null);
const initialChart = computed(() => content.value?.initialChart || "");
const activeCity = computed(() => content.value?.activeCity || component.value?.city);

watch(
	() => dialogStore.dialogs.shareComponent,
	async (isOpen) => {
		if (!isOpen || !component.value) return;
		imageDataUrl.value = "";
		summary.value = "";
		error.value = "";
		await Promise.all([buildImage(), buildSummary()]);
	}
);

async function buildImage() {
	loadingImage.value = true;
	try {
		imageDataUrl.value = await buildShareCardImage();
	} catch (err) {
		console.error("ShareComponentCaptureError :", err);
		error.value = "圖片產生失敗，請稍後再試";
	} finally {
		loadingImage.value = false;
	}
}

async function buildSummary() {
	loadingSummary.value = true;
	try {
		const response = await http.post("/ai/chat/twai", {
			stream: false,
			messages: [
				{
					role: "system",
					content: "你是臺北城市儀表板助理。請根據提供的圖表名稱、單位、資料與目前顯示型態，產生繁體中文解說。最多 3 句，直接講重點，不要列太長。",
				},
				{
					role: "user",
					content: buildSummaryPrompt(),
				},
			],
			max_new_tokens: 180,
			temperature: 0.2,
		});
		summary.value = response.data?.data?.content || fallbackSummary();
	} catch (err) {
		console.error("ShareComponentSummaryError :", err);
		summary.value = fallbackSummary();
	} finally {
		loadingSummary.value = false;
	}
}

function buildSummaryPrompt() {
	const chartData = Array.isArray(component.value?.chart_data)
		? component.value.chart_data.slice(0, 3).map((series) => ({
			...series,
			data: Array.isArray(series.data) ? series.data.slice(0, 30) : series.data,
		}))
		: component.value?.chart_data;

	return JSON.stringify({
		name: component.value?.name,
		index: component.value?.index,
		source: component.value?.source,
		unit: component.value?.chart_config?.unit,
		active_chart: initialChart.value || component.value?.chart_config?.types?.[0],
		short_desc: component.value?.short_desc,
		chart_data: chartData,
	});
}

function fallbackSummary() {
	return `${component.value?.name || "這張圖表"}呈現目前儀表板中的資料狀態，可用於快速比較主要項目的高低與分布。`;
}

function downloadImage() {
	if (!imageDataUrl.value) return;
	const link = document.createElement("a");
	link.href = imageDataUrl.value;
	link.download = `${component.value?.index || "dashboard-component"}.png`;
	link.click();
}

async function buildShareCardImage() {
	const width = 920;
	const height = 560;
	const rows = getChartRows().slice(0, 12);
	const chartType = initialChart.value || component.value?.chart_config?.types?.[0] || "";
	const chartSvg = chartType === "FoodRiskDrilldownChart"
		? renderTileChart(rows)
		: renderBarChart(rows);
	const unit = component.value?.chart_config?.unit || "";
	const city = activeCity.value === "metrotaipei" ? "雙北" : "臺北市";
	const svg = `
		<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
			<rect width="${width}" height="${height}" rx="18" fill="#262829"/>
			<text x="44" y="62" fill="#ffffff" font-size="31" font-weight="700" font-family="Microsoft JhengHei, Arial, sans-serif">${escapeXml(component.value?.name || "圖表")}</text>
			<rect x="44" y="86" width="${city.length > 2 ? 72 : 52}" height="28" rx="6" fill="#244ed6"/>
			<text x="56" y="107" fill="#ffffff" font-size="19" font-weight="700" font-family="Microsoft JhengHei, Arial, sans-serif">${escapeXml(city)}</text>
			<text x="44" y="148" fill="#a7a7a7" font-size="20" font-weight="700" font-family="Microsoft JhengHei, Arial, sans-serif">${escapeXml(component.value?.source || "")}</text>
			${unit ? `<text x="44" y="186" fill="#8f8f8f" font-size="18" font-family="Microsoft JhengHei, Arial, sans-serif">單位：${escapeXml(unit)}</text>` : ""}
			${chartSvg}
			<text x="44" y="522" fill="#6ea7ff" font-size="17" font-weight="700" font-family="Microsoft JhengHei, Arial, sans-serif">臺北城市儀表板</text>
		</svg>`;

	const svgBlob = new Blob([svg], { type: "image/svg+xml;charset=utf-8" });
	const url = URL.createObjectURL(svgBlob);
	try {
		const image = await loadImage(url);
		const scale = 2;
		const canvas = document.createElement("canvas");
		canvas.width = width * scale;
		canvas.height = height * scale;
		const ctx = canvas.getContext("2d");
		ctx.fillStyle = "#262829";
		ctx.fillRect(0, 0, canvas.width, canvas.height);
		ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
		return canvas.toDataURL("image/png");
	} finally {
		URL.revokeObjectURL(url);
	}
}

function getChartRows() {
	const series = Array.isArray(component.value?.chart_data)
		? component.value.chart_data
		: [];
	const data = series.flatMap((item) => Array.isArray(item.data) ? item.data : []);
	return data.map((item) => ({
		label: String(item.x ?? item.name ?? item.label ?? ""),
		value: Number(item.y ?? item.value ?? item.data ?? 0),
	})).filter((item) => item.label && Number.isFinite(item.value));
}

function renderTileChart(rows) {
	const palette = ["#c9171d", "#c9171d", "#d13a0b", "#ff8f35", "#ff8f35", "#f5a10a", "#f5a10a", "#f5a10a", "#ffc326", "#ffd319"];
	return rows.slice(0, 10).map((row, index) => {
		const col = index % 3;
		const line = Math.floor(index / 3);
		const x = 44 + col * 270;
		const y = 220 + line * 76;
		const width = index >= 9 ? 250 : 250;
		return `
			<rect x="${x}" y="${y}" width="${width}" height="58" rx="8" fill="${palette[index] || "#ffd319"}"/>
			<text x="${x + 14}" y="${y + 24}" fill="${index >= 6 ? "#172033" : "#ffffff"}" font-size="17" font-weight="700" font-family="Microsoft JhengHei, Arial, sans-serif">${escapeXml(truncate(row.label, 9))}</text>
			<text x="${x + 14}" y="${y + 50}" fill="${index >= 6 ? "#172033" : "#ffffff"}" font-size="27" font-weight="800" font-family="Microsoft JhengHei, Arial, sans-serif">${formatValue(row.value)}</text>
		`;
	}).join("");
}

function renderBarChart(rows) {
	const maxValue = Math.max(...rows.map((row) => row.value), 1);
	return rows.slice(0, 10).map((row, index) => {
		const x = 290 + index * 55;
		const barHeight = Math.max((row.value / maxValue) * 230, 4);
		const y = 455 - barHeight;
		return `
			<rect x="${x}" y="${y}" width="31" height="${barHeight}" rx="6" fill="#6fc777"/>
			<text x="${x + 15}" y="${y - 10}" fill="#ffffff" font-size="16" font-weight="700" text-anchor="middle" font-family="Microsoft JhengHei, Arial, sans-serif">${formatValue(row.value)}</text>
			<text x="${x + 15}" y="486" fill="#a7a7a7" font-size="15" text-anchor="end" transform="rotate(-48 ${x + 15} 486)" font-family="Microsoft JhengHei, Arial, sans-serif">${escapeXml(truncate(row.label, 7))}</text>
		`;
	}).join("");
}

function escapeXml(value) {
	return String(value ?? "")
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
}

function truncate(value, length) {
	return value.length > length ? `${value.slice(0, length - 1)}...` : value;
}

function formatValue(value) {
	return Number.isInteger(value) ? value : Number(value.toFixed(2));
}

function loadImage(url) {
	return new Promise((resolve, reject) => {
		const image = new Image();
		image.onload = () => resolve(image);
		image.onerror = reject;
		image.src = url;
	});
}
</script>

<template>
  <DialogContainer
    :dialog="`shareComponent`"
    @on-close="dialogStore.hideAllDialogs"
  >
    <div class="sharecomponent">
      <div class="sharecomponent-preview">
        <div
          v-if="loadingImage"
          class="sharecomponent-loading"
        >
          <div />
          <p>產生圖片中</p>
        </div>
        <img
          v-else-if="imageDataUrl"
          :src="imageDataUrl"
          :alt="`${component?.name || '圖表'}分享圖片`"
        >
        <p
          v-else
          class="sharecomponent-error"
        >
          {{ error || "尚未產生圖片" }}
        </p>
      </div>
      <div class="sharecomponent-info">
        <div class="sharecomponent-info-data">
          <h3>{{ component?.name }}</h3>
          <p v-if="loadingSummary">
            AI 解說產生中...
          </p>
          <p v-else>
            {{ summary }}
          </p>
        </div>
        <div class="sharecomponent-info-control">
          <button
            :disabled="!imageDataUrl"
            @click="downloadImage"
          >
            <span>download</span>下載圖片
          </button>
        </div>
      </div>
    </div>
  </DialogContainer>
</template>

<style scoped lang="scss">
.sharecomponent {
	height: fit-content;
	width: 400px;
	display: grid;
	position: relative;

	@media (min-width: 820px) {
		width: 720px;
		height: 410px;
		grid-template-columns: 3fr 2fr;
	}

	@media (min-width: 1200px) {
		height: 440px;
		width: 820px;
	}

	@media (min-width: 2200px) {
		height: 550px;
		width: 920px;
	}

	&-preview {
		min-height: 260px;
		display: flex;
		align-items: center;
		justify-content: center;
		background-color: var(--color-component-background);

		img {
			width: 100%;
			height: 100%;
			object-fit: contain;
		}
	}

	&-info {
		display: flex;
		flex-direction: column;
		padding: var(--font-ms);
		border-top: solid 1px var(--color-border);

		@media (min-width: 820px) {
			border-left: solid 1px var(--color-border);
			border-top: none;
		}

		&-data {
			max-height: calc(100% - 2.5rem);
			overflow-y: scroll;
			padding-right: 8px;

			h3 {
				margin-bottom: 0.75rem;
			}

			p {
				color: var(--color-complement-text);
				line-height: 1.7;
				text-align: justify;
			}
		}

		&-control {
			display: flex;
			align-items: flex-end;
			justify-content: flex-end;
			flex: 1;

			span {
				margin-right: 4px;
				font-family: var(--font-icon);
				font-size: var(--font-m);
			}

			button {
				display: flex;
				align-items: center;
				margin-left: 8px;
				padding: 2px 4px;
				border-radius: 5px;
				background-color: var(--color-highlight);
				font-size: var(--font-ms);
				transition: opacity 0.2s;

				&:disabled {
					cursor: wait;
					opacity: 0.5;
				}

				&:hover:not(:disabled) {
					opacity: 0.8;
				}
			}
		}
	}

	&-loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 8px;
		color: var(--color-complement-text);

		div {
			width: 2rem;
			height: 2rem;
			border-radius: 50%;
			border: solid 4px var(--color-border);
			border-top: solid 4px var(--color-highlight);
			animation: spin 0.7s ease-in-out infinite;
		}
	}

	&-error {
		color: var(--color-complement-text);
	}

}

@keyframes spin {
	to {
		transform: rotate(360deg);
	}
}
</style>
