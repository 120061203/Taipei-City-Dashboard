<script setup>
import { computed, ref, watch } from "vue";
import VueApexCharts from "vue3-apexcharts";

const props = defineProps([
	"chart_config",
	"activeChart",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
]);

defineEmits([
	"filterByParam",
	"filterByLayer",
	"clearByParamFilter",
	"clearByLayerFilter",
	"fly",
]);

const TOTAL_MARKER = "__total__";
const DETAIL_VISIBLE_LIMIT = 10;
const selectedGroup = ref(null);

const colorPalette = computed(() => {
	return props.chart_config.color?.length
		? props.chart_config.color
		: ["#b91c1c", "#c2410c", "#dc2626", "#ea580c", "#f97316", "#fde68a"];
});

const parsedRows = computed(() => {
	const rows = props.series?.[0]?.data ?? [];
	return rows
		.map((item) => {
			const [group, name] = String(item.x ?? "").split("｜");
			return {
				group,
				name,
				value: Number(item.y ?? 0),
			};
		})
		.filter((item) => item.group && item.name && item.value > 0);
});

const groupRows = computed(() => {
	const totals = parsedRows.value
		.filter((item) => item.name === TOTAL_MARKER)
		.map((item) => ({
			label: item.group,
			value: item.value,
		}));

	if (totals.length) {
		return totals.sort((a, b) => b.value - a.value);
	}

	const grouped = new Map();
	parsedRows.value.forEach((item) => {
		grouped.set(item.group, (grouped.get(item.group) ?? 0) + item.value);
	});
	return Array.from(grouped.entries())
		.map(([label, value]) => ({ label, value }))
		.sort((a, b) => b.value - a.value);
});

const maxGroupValue = computed(() => {
	return Math.max(...groupRows.value.map((item) => item.value), 1);
});

const selectedItemRows = computed(() => {
	if (!selectedGroup.value) {
		return [];
	}
	const rows = parsedRows.value
		.filter(
			(item) =>
				item.group === selectedGroup.value && item.name !== TOTAL_MARKER
		)
		.map((item) => ({
			label: item.name,
			value: item.value,
		}))
		.sort((a, b) => b.value - a.value);

	return rows.slice(0, DETAIL_VISIBLE_LIMIT);
});

const barSeries = computed(() => [
	{
		name: selectedGroup.value ?? "食材品項",
		data: selectedItemRows.value.map((item) => ({
			x: item.label,
			y: item.value,
		})),
	},
]);

const chartHeight = computed(() => {
	return Math.max(260, 58 + selectedItemRows.value.length * 34);
});

const barOptions = computed(() => ({
	chart: {
		offsetY: -8,
		stacked: true,
		toolbar: {
			show: false,
		},
	},
	colors: colorPalette.value,
	dataLabels: {
		offsetX: 16,
		style: {
			fontSize: "14px",
			fontWeight: 700,
		},
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
			borderRadius: 3,
			distributed: true,
			horizontal: true,
			barHeight: "70%",
			dataLabels: {
				hideOverflowingLabels: false,
			},
		},
	},
	stroke: {
		colors: ["#282a2c"],
		show: true,
		width: 0,
	},
	tooltip: {
		custom: function ({ dataPointIndex }) {
			const item = selectedItemRows.value[dataPointIndex];
			if (!item) {
				return "";
			}
			return (
				'<div class="chart-tooltip">' +
				"<h6>" +
				`${selectedGroup.value}｜${item.label}` +
				"</h6>" +
				"<span>" +
				item.value +
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
				return value.length > 7 ? `${value.slice(0, 6)}...` : value;
			},
		},
	},
}));

watch(groupRows, (rows) => {
	if (
		selectedGroup.value &&
		!rows.some((item) => item.label === selectedGroup.value)
	) {
		selectedGroup.value = null;
	}
});

function heatColor(value) {
	const ratio = Math.max(0, Math.min(1, value / maxGroupValue.value));
	const colorIndex = Math.min(
		colorPalette.value.length - 1,
		Math.floor((1 - ratio) * colorPalette.value.length)
	);
	return colorPalette.value[colorIndex];
}

function heatTextColor(value) {
	return value / maxGroupValue.value < 0.35 ? "#282a2c" : "white";
}

function selectGroup(group) {
	selectedGroup.value = group;
}

function resetGroup() {
	selectedGroup.value = null;
}
</script>

<template>
  <div
    v-if="activeChart === 'FoodRiskDrilldownChart'"
    class="food-risk-drilldown"
  >
    <div
      v-if="selectedGroup"
      class="food-risk-drilldown-toolbar"
    >
      <button
        type="button"
        class="food-risk-drilldown-back"
        aria-label="返回食材大類"
        title="返回食材大類"
        @click="resetGroup"
      >
        <span>keyboard_backspace</span>
      </button>
      <h6>
        {{ selectedGroup }}
      </h6>
    </div>

    <div class="food-risk-drilldown-body">
      <div
        v-if="!selectedGroup"
        class="food-risk-drilldown-heatmap"
      >
        <button
          v-for="item in groupRows"
          :key="item.label"
          type="button"
          class="food-risk-drilldown-heatmap-tile"
          :style="{ backgroundColor: heatColor(item.value), color: heatTextColor(item.value) }"
          :title="`${item.label}: ${item.value} ${chart_config.unit}`"
          @click="selectGroup(item.label)"
        >
          <p>{{ item.label }}</p>
          <h6>{{ item.value }}</h6>
        </button>
      </div>

      <VueApexCharts
        v-else
        :key="selectedGroup"
        width="100%"
        :height="chartHeight"
        type="bar"
        :options="barOptions"
        :series="barSeries"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.food-risk-drilldown {
	height: 100%;
	display: flex;
	flex-direction: column;
	justify-content: flex-start;
	overflow: hidden;

	&-toolbar {
		width: 100%;
		flex: 0 0 auto;
		min-height: 32px;
		display: grid;
		grid-template-columns: 32px minmax(0, 1fr);
		align-items: center;
		gap: 8px;
		box-sizing: border-box;
		margin-bottom: 8px;
		overflow: visible;

		.food-risk-drilldown-back {
			width: 32px;
			height: 28px;
			flex: 0 0 32px;
			display: inline-flex;
			align-items: center;
			justify-content: center;
			box-sizing: border-box;
			padding: 0;
			border-radius: 5px;
			background-color: rgb(77, 77, 77);
			color: var(--color-complement-text);
			transition: color 0.2s, background-color 0.2s;
			overflow: hidden;

			&:hover {
				background-color: rgb(96, 96, 96);
				color: white;
			}

			span {
				width: 20px;
				height: 20px;
				display: inline-block;
				font-family: var(--font-icon);
				font-size: 1.25rem;
				font-weight: 400;
				line-height: 20px;
				text-align: center;
				overflow: hidden;
				color: inherit;
				user-select: none;
			}
		}

		h6 {
			min-width: 0;
			margin: 0;
			color: var(--color-normal-text);
			font-size: var(--font-s);
			font-weight: 700;
			overflow: hidden;
			white-space: nowrap;
			text-overflow: ellipsis;
		}
	}

	&-body {
		width: 100%;
		min-height: 0;
		flex: 1 1 auto;
		box-sizing: border-box;
		padding-right: 2px;
		overflow-x: hidden;
		overflow-y: auto;
		scrollbar-color: rgb(96, 96, 96) transparent;
		scrollbar-width: thin;

		&::-webkit-scrollbar {
			width: 6px;
		}

		&::-webkit-scrollbar-thumb {
			border-radius: 999px;
			background-color: rgb(96, 96, 96);
		}
	}

	&-heatmap {
		width: 100%;
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(96px, 1fr));
		gap: 6px;
		padding: 4px 2px 0;
		overflow: hidden;

		&-tile {
			min-height: 46px;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: flex-start;
			padding: 6px 8px;
			border-radius: 5px;
			color: white;
			text-align: left;
			transition: opacity 0.2s, transform 0.2s;

			&:hover {
				opacity: 0.85;
				transform: translateY(-1px);
			}

			p {
				width: 100%;
				margin: 0;
				color: inherit;
				font-size: var(--font-s);
				font-weight: 700;
				overflow: hidden;
				white-space: nowrap;
				text-overflow: ellipsis;
			}

			h6 {
				margin: 0;
				color: inherit;
				font-size: var(--font-m);
				font-weight: 700;
				line-height: 1.1;
			}
		}
	}
}
</style>
