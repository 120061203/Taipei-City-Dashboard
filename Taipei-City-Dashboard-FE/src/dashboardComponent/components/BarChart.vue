<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->
<!-- Team 20 hackathon: drilldown 支援（食安守護 餐飲衛生分級榜） -->
<script setup>
import { ref, computed } from "vue";
import VueApexCharts from "vue3-apexcharts";
import { districtTopRestaurants } from "../../store/foodSafetyMock";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
	// Team 20: 元件 index，用來判斷是否啟用 drilldown
	"componentIndex",
]);

const emits = defineEmits([
	"filterByParam",
	"filterByLayer",
	"clearByParamFilter",
	"clearByLayerFilter",
	"fly"
]);

// Team 20: drilldown state（餐飲衛生分級榜專用）
const drilldownDistrict = ref(null);
const drilldownData = computed(() => {
	if (!drilldownDistrict.value) return [];
	return districtTopRestaurants[drilldownDistrict.value] || [];
});
function closeDrilldown() {
	drilldownDistrict.value = null;
}

const chartOptions = ref({
	chart: {
		offsetY: 15,
		stacked: true,
		toolbar: {
			show: false,
		},
	},
	colors: [...props.chart_config.color],
	dataLabels: {
		offsetX: 20,
		textAnchor: "start",
	},
	grid: {
		show: false,
	},
	legend: {
		show: false,
	},
	plotOptions: {
		bar: {
			borderRadius: 2,
			distributed: true,
			horizontal: true,
			dataLabels: {
				hideOverflowingLabels: false
			},
		},
	},
	stroke: {
		colors: ["#282a2c"],
		show: true,
		width: 0,
	},
	// The class "chart-tooltip" could be edited in /assets/styles/chartStyles.css
	tooltip: {
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
				"</h6>" +
				"<span>" +
				series[seriesIndex][dataPointIndex] +
				` ${props.chart_config.unit}` +
				"</span>" +
				"</div>"
			);
		},
		followCursor: true,
	},
	xaxis: {
		axisBorder: {
			show: false,
		},
		axisTicks: {
			show: false,
		},
		labels: {
			show: false,
		},
		type: "category",
	},
	yaxis: {
		labels: {
			formatter: function (value) {
				return value.length > 7 ? value.slice(0, 6) + "..." : value;
			},
		},
	},
});

const displaySeries = computed(() => {
	const limit = props.chart_config?.barLimit;
	if (!limit || !props.series?.[0]?.data) {
		return props.series;
	}
	return props.series.map((serie) => ({
		...serie,
		data: serie.data.slice(0, limit),
	}));
});

const chartHeight = computed(() => {
	if (props.chart_config?.height) {
		return `${props.chart_config.height}px`;
	}
	return `${40 + (displaySeries.value?.[0]?.data?.length || 0) * 30}`;
});

const selectedIndex = ref(null);

function handleDataSelection(_e, _chartContext, config) {
	// Team 20: 食安守護 - 餐飲衛生分級榜 drilldown
	// 點擊行政區 → 跳出 Top 10 餐廳清單
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
		// Supports filtering by xAxis
		if (props.map_filter.mode === "byParam") {
			emits(
				"filterByParam",
				props.map_filter,
				props.map_config,
				config.w.globals.labels[config.dataPointIndex],
				null
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
</script>

<template>
  <div
    v-if="activeChart === 'BarChart'"
    class="barchart-wrap"
  >
    <VueApexCharts
      :key="`${activeChart}-${props.chart_config?.barLimit || 'all'}-${displaySeries?.[0]?.data?.length || 0}`"
      width="100%"
      :height="chartHeight"
      type="bar"
      :options="chartOptions"
      :series="displaySeries"
      @data-point-selection="handleDataSelection"
    />

    <!-- Team 20: 餐飲衛生分級榜 - 行政區 Top 10 餐廳 drilldown -->
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

<style scoped>
.barchart-wrap {
  position: relative;
  min-height: 0;
  overflow: hidden;
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
  animation: fadeIn 0.18s ease;
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.drilldown-panel {
  width: 92%;
  max-height: 92%;
  background: #1c1e20;
  border: 1px solid #494b4e;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  animation: slideIn 0.22s cubic-bezier(0.34, 1.56, 0.64, 1);
}
@keyframes slideIn {
  from { transform: translateY(8px) scale(0.96); opacity: 0; }
  to { transform: translateY(0) scale(1); opacity: 1; }
}

.drilldown-head {
  padding: 10px 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #494b4e;
  background: linear-gradient(90deg, rgba(126, 231, 135, 0.08), transparent);
}
.drilldown-head h4 {
  font-size: 13px;
  font-weight: 700;
  color: #fff;
  display: flex;
  align-items: center;
  gap: 6px;
}
.drilldown-icon { font-size: 16px; }
.drilldown-close {
  background: transparent;
  border: none;
  color: #888787;
  cursor: pointer;
  font-size: 16px;
  width: 22px;
  height: 22px;
  border-radius: 4px;
}
.drilldown-close:hover { background: #2a2c2e; color: #fff; }

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
}
.drilldown-row:last-child { border-bottom: none; }

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
}
.drilldown-rank.rank-1 {
  background: linear-gradient(135deg, #ffd700, #ff9500);
  color: #090909;
}
.drilldown-rank.rank-2 {
  background: linear-gradient(135deg, #c0c0c0, #888);
  color: #090909;
}
.drilldown-rank.rank-3 {
  background: linear-gradient(135deg, #cd7f32, #8b4513);
  color: #fff;
}

.drilldown-info { min-width: 0; }
.drilldown-name {
  font-size: 12px;
  font-weight: 600;
  color: #fff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
}
.drilldown-grade.grade-優 {
  background: linear-gradient(135deg, #ffd700, #ff9500);
  color: #090909;
}
.drilldown-grade.grade-良 {
  background: rgba(126, 231, 135, 0.2);
  color: #7ee787;
  border: 1px solid #7ee787;
}
.drilldown-grade.grade-HACCP {
  background: rgba(86, 212, 221, 0.2);
  color: #56d4dd;
  border: 1px solid #56d4dd;
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
