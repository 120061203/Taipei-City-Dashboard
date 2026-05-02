<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { computed, ref } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { districtTopRestaurants } from "../../store/foodSafetyMock";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
]);

const emits = defineEmits([
	"filterByParam",
	"filterByLayer",
	"clearByParamFilter",
	"clearByLayerFilter",
	"fly"
]);

// Team 20: 食安守護 - 餐飲衛生分級榜 drilldown
const drilldownDistrict = ref(null);
const drilldownData = computed(() => {
	if (!drilldownDistrict.value) return [];
	return districtTopRestaurants[drilldownDistrict.value] || [];
});
function closeDrilldown() {
	drilldownDistrict.value = null;
}

const isLargeDataSet = computed(() => {
	return props.series[0].data.length > 12
})

// Calculate initial width for large datasets only
const initialWidth = computed(() => {
	const WIDTH_PER_ITEM = 32
	const itemCount = props.series[0].data.length;
	return itemCount * WIDTH_PER_ITEM;
});

const widthValue = ref(initialWidth.value);

// Convert to a string with unit for ApexCharts
const chartWidth = computed(() => {
	return isLargeDataSet.value ? `${widthValue.value}px` : "100%";
});

const chartHeight = computed(() => {
	return props.chart_config.height ? `${props.chart_config.height}px` : "250px";
});

const chartOptions = ref({
	chart: {
		stacked: true,
		zoom: {
			allowMouseWheelZoom: false,
		},
		toolbar: isLargeDataSet.value 
			? {
				show: true,
				tools: {
					download: false,
					pan: false,
					reset: "<p>" + "重置" + "</p>",
					zoomin: false,
					zoomout: false,
				}
			  }
			: {
				show: false,
			}
	},
	colors: [...props.chart_config.color],
	dataLabels: {
		enabled: props.chart_config.categories ? false : true,
		offsetY: 20,
	},
	grid: {
		show: false,
	},
	legend: isLargeDataSet.value
		? {
			show: props.chart_config.categories ? true : false,
			horizontalAlign: "left",
			offsetX: 20,
			floating: true,
		  }
		: {
			show: props.chart_config.categories ? true : false,
		  },
	plotOptions: {
		bar: {
			borderRadius: 5,
			dataLabels: {
				hideOverflowingLabels: false
			},
		},
	},
	stroke: {
		colors: ["#282a2c"],
		show: true,
		width: 2,
	},
	tooltip: {
		// The class "chart-tooltip" could be edited in /assets/styles/chartStyles.css
		custom: function ({
			series,
			seriesIndex,
			dataPointIndex,
			w,
		}) {
			return (
				'<div class="chart-tooltip">' +
					"<h6>" +
						w.globals.labels[dataPointIndex] +
						`${
							props.chart_config.categories
								? "-" + w.globals.seriesNames[seriesIndex]
								: ""
						}` +
					"</h6>" +
					"<span>" +
						series[seriesIndex][dataPointIndex] +
						` ${props.chart_config.unit}` +
					"</span>" +
				"</div>"
			);
		},
	},
	xaxis: {
		axisBorder: {
			show: false,
		},
		axisTicks: {
			show: false,
		},
		categories: props.chart_config.categories
			? props.chart_config.categories
			: [],
		labels: {
			offsetY: 2,
		},
		type: "category",
	},
});

const selectedIndex = ref(null);

function handleDataSelection(_e, _chartContext, config) {
	const label = config.w?.globals?.labels?.[config.dataPointIndex];
	if (label && districtTopRestaurants[label]) {
		drilldownDistrict.value = label;
		return;
	}

	if (!props.map_filter || !props.map_filter_on) {
		return;
	}
	if (
		`${config.dataPointIndex}-${config.seriesIndex}` !== selectedIndex.value
	) {
		// Supports filtering by xAxis + yAxis
		if (props.map_filter.mode === "byParam") {
			emits(
				"filterByParam",
				props.map_filter,
				props.map_config,
				config.w.globals.labels[config.dataPointIndex],
				config.w.globals.seriesNames[config.seriesIndex]
			);
		}
		// Supports filtering by xAxis
		else if (props.map_filter.mode === "byLayer") {
			emits(
				"filterByLayer",
				props.map_config,
				config.w.globals.labels[config.dataPointIndex]
			);
		}
		selectedIndex.value = `${config.dataPointIndex}-${config.seriesIndex}`;
	} else {
		if (props.map_filter.mode === "byParam") {
			emits("clearByParamFilter", props.map_config);
		} else if (props.map_filter.mode === "byLayer") {
			emits("clearByLayerFilter", props.map_config);
		}
		selectedIndex.value = null;
	}
}

function increaseWidth() {
	widthValue.value += 50;
}

function decreaseWidth() {
	if (widthValue.value > 150) {
		widthValue.value -= 50;
	}
}

function resetWidth() {
	widthValue.value = initialWidth.value;
}
</script>

<template>
  <div
    v-if="activeChart === 'ColumnChart'"
    class="columnChart"
  >
    <div
      v-if="isLargeDataSet"
      class="columnChart-toolbar"
    >
      <p
        class="columnChart-toolbar-item"
        @click="increaseWidth"
      >
        <span>add</span>
      </p>
      <p
        class="columnChart-toolbar-item"
        @click="decreaseWidth"
      >
        <span>remove</span>
      </p>
      <p
        class="columnChart-toolbar-item reset"
        @click="resetWidth"
      >
        重置
      </p>
    </div>
    <VueApexCharts
      :key="chartWidth"
      type="bar"
      :width="chartWidth"
      :height="chartHeight"
      :options="chartOptions"
      :series="series"
      @data-point-selection="handleDataSelection"
    />
    <div
      v-if="drilldownDistrict"
      class="drilldown-overlay"
      @click.self="closeDrilldown"
    >
      <div class="drilldown-panel">
        <div class="drilldown-head">
          <h4>
            <span class="drilldown-icon">🏆</span>
            {{ drilldownDistrict }} · 通過評核餐廳 Top 10
          </h4>
          <button
            class="drilldown-close"
            @click="closeDrilldown"
          >
            ✕
          </button>
        </div>
        <div class="drilldown-body">
          <div
            v-for="(item, idx) in drilldownData"
            :key="`${item.name}-${item.address}`"
            class="drilldown-row"
          >
            <div
              class="drilldown-rank"
              :class="`rank-${idx + 1 <= 3 ? idx + 1 : 'n'}`"
            >
              {{ idx + 1 }}
            </div>
            <div class="drilldown-info">
              <div class="drilldown-name">
                {{ item.name }}
              </div>
              <div class="drilldown-address">
                {{ item.address }}
              </div>
            </div>
            <div
              class="drilldown-grade"
              :class="`grade-${item.grade}`"
            >
              {{ item.grade === "HACCP" ? "HACCP" : item.grade + "級" }}
            </div>
          </div>
          <div
            v-if="drilldownData.length === 0"
            class="drilldown-empty"
          >
            尚無此區詳細清單
          </div>
        </div>
        <div class="drilldown-foot">
          資料來源：北市 59579c19 · NTP 8E64B205 · HACCP bb665f7f
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.columnChart {
	overflow: auto;
	position: relative;
	height: 100%;

	.vue-apexcharts {
		justify-content: unset !important;
	}

	&-toolbar {
		position: sticky;
		top: 0;
		left: 0;
		z-index: 1;
		background-color: var(--color-component-background);
		display: flex;
		justify-content: flex-end;
		align-items: center;
		gap: 4px;

		&-item {
			cursor: pointer;
			font-size: var(--font-s);
			display: flex;
			justify-content: center;
			align-items: center;

			span {
				text-align: center;
				font-family: var(--font-icon);
				font-size: var(--font-ms);
				padding: 2px;
			}

			&.reset {
				color: var(--color-highlight)
			}
		}
	}
}

.drilldown-overlay {
	position: absolute;
	inset: 0;
	background: rgba(9, 9, 9, 0.78);
	backdrop-filter: blur(3px);
	display: flex;
	align-items: center;
	justify-content: center;
	z-index: 50;
	border-radius: 5px;
}

.drilldown-panel {
	width: 92%;
	max-height: 92%;
	background: #1c1e20;
	border: 1px solid #494b4e;
	border-radius: 8px;
	overflow: hidden;
	display: flex;
	flex-direction: column;
}

.drilldown-head {
	padding: 10px 14px;
	display: flex;
	justify-content: space-between;
	align-items: center;
	border-bottom: 1px solid #494b4e;
	background: linear-gradient(90deg, rgba(126, 231, 135, 0.08), transparent);

	h4 {
		font-size: 13px;
		font-weight: 700;
		color: #fff;
		display: flex;
		align-items: center;
		gap: 6px;
	}
}

.drilldown-icon {
	font-size: 16px;
}

.drilldown-close {
	background: transparent;
	border: none;
	color: #888787;
	cursor: pointer;
	font-size: 16px;
	width: 22px;
	height: 22px;
	border-radius: 4px;

	&:hover {
		background: #2a2c2e;
		color: #fff;
	}
}

.drilldown-body {
	flex: 1;
	overflow-y: auto;
	padding: 6px 10px;
}

.drilldown-row {
	display: grid;
	grid-template-columns: 22px 1fr auto;
	gap: 8px;
	align-items: center;
	padding: 6px 8px;
	border-bottom: 1px dashed #2a2c2e;

	&:last-child {
		border-bottom: none;
	}
}

.drilldown-rank {
	width: 22px;
	height: 22px;
	border-radius: 50%;
	background: #2a2c2e;
	color: #888;
	font-weight: 800;
	font-size: 11px;
	display: flex;
	align-items: center;
	justify-content: center;

	&.rank-1 {
		background: linear-gradient(135deg, #ffd700, #ff9500);
		color: #090909;
	}

	&.rank-2 {
		background: linear-gradient(135deg, #c0c0c0, #888);
		color: #090909;
	}

	&.rank-3 {
		background: linear-gradient(135deg, #cd7f32, #8b4513);
		color: #fff;
	}
}

.drilldown-info {
	min-width: 0;
}

.drilldown-name,
.drilldown-address {
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.drilldown-name {
	font-size: 12px;
	font-weight: 600;
	color: #fff;
}

.drilldown-address {
	font-size: 9px;
	color: #888787;
	margin-top: 1px;
}

.drilldown-grade {
	font-size: 10px;
	font-weight: 700;
	padding: 2px 7px;
	border-radius: 3px;

	&.grade-優 {
		background: linear-gradient(135deg, #ffd700, #ff9500);
		color: #090909;
	}

	&.grade-良 {
		background: rgba(126, 231, 135, 0.2);
		color: #7ee787;
		border: 1px solid #7ee787;
	}

	&.grade-HACCP {
		background: rgba(86, 212, 221, 0.2);
		color: #56d4dd;
		border: 1px solid #56d4dd;
	}
}

.drilldown-foot {
	padding: 6px 14px;
	font-size: 9px;
	color: #6b7689;
	border-top: 1px solid #494b4e;
	font-family: ui-monospace, "SF Mono", monospace;
}

.drilldown-empty {
	text-align: center;
	padding: 18px;
	color: #888787;
	font-size: 12px;
}
</style>
