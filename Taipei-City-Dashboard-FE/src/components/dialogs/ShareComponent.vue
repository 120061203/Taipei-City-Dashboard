<script setup>
import { computed, nextTick, ref, watch } from "vue";
import html2canvas from "html2canvas";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";
import { useDialogStore } from "../../store/dialogStore";
import { useContentStore } from "../../store/contentStore";
import http from "../../router/axios";

import DialogContainer from "./DialogContainer.vue";

const dialogStore = useDialogStore();
const contentStore = useContentStore();

const imageDataUrl = ref("");
const imageExtension = ref("png");
const summary = ref("");
const loadingImage = ref(false);
const loadingSummary = ref(false);
const error = ref("");
const previewRef = ref(null);
const shareComponentRef = ref(null);

const content = computed(() => dialogStore.shareComponentContent);
const component = computed(() => content.value?.config || null);
const initialChart = computed(() => content.value?.initialChart || "");
const activeCity = computed(() => content.value?.activeCity || component.value?.city);
const componentKey = computed(() => `${component.value?.index || "component"}-${initialChart.value || "default"}`);
const cityTags = computed(() => {
	if (!component.value) return [];
	return component.value.city_tag_override
		? contentStore.cityManager.getCities(component.value.city_tag_override)
		: contentStore.cityManager.getTagList(activeCity.value || component.value.city);
});

watch(
	() => dialogStore.dialogs.shareComponent,
	async (isOpen) => {
		if (!isOpen || !component.value) return;
		imageDataUrl.value = "";
		imageExtension.value = "png";
		summary.value = "";
		error.value = "";
		await buildSummary();
		await captureShareDialog();
	}
);

async function captureShareDialog() {
	loadingImage.value = true;
	try {
		await nextTick();
		await waitForPaint();
		const target = shareComponentRef.value;
		if (!target) throw new Error("share dialog element not found");
		const result = await captureElement(target);
		imageDataUrl.value = result.url;
		imageExtension.value = result.extension;
	} catch (err) {
		console.error("ShareComponentCaptureError :", err);
		error.value = "圖片下載準備失敗，請稍後再試";
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
	link.download = `${component.value?.index || "dashboard-component"}.${imageExtension.value}`;
	link.click();
}

function waitForPaint() {
	return new Promise((resolve) => {
		requestAnimationFrame(() => {
			requestAnimationFrame(() => {
				setTimeout(resolve, 250);
			});
		});
	});
}

async function captureElement(element) {
	const canvas = await html2canvas(element, {
		backgroundColor: getComputedStyle(element).backgroundColor || "#262829",
		logging: false,
		scale: Math.min(window.devicePixelRatio || 2, 2),
		useCORS: true,
		onclone: (documentClone) => {
			const cloneControl = documentClone.querySelector(".sharecomponent-info-control");
			if (cloneControl) {
				cloneControl.remove();
			}
		},
	});
	return {
		url: canvas.toDataURL("image/png"),
		extension: "png",
	};
}
</script>

<template>
  <DialogContainer
    :dialog="`shareComponent`"
    @on-close="dialogStore.hideAllDialogs"
  >
    <div
      ref="shareComponentRef"
      class="sharecomponent"
    >
      <div
        ref="previewRef"
        class="sharecomponent-preview"
      >
        <DashboardComponent
          v-if="component"
          :key="componentKey"
          :config="component"
          :active-city="activeCity"
          :city-tag="cityTags"
          :initial-chart="initialChart"
          mode="large"
        />
        <p
          v-if="error"
          class="sharecomponent-capture-error"
        >
          {{ error }}
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
            <span>download</span>{{ loadingImage ? "圖片準備中" : "下載圖片" }}
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
	overflow: hidden;
	border-radius: 5px;
	background-color: var(--color-component-background);
	color: var(--color-normal-text);

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
