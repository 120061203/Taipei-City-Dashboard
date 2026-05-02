<!-- Food Safety Hackathon Team 20: Monthly / Yearly stacked mode -->

<script setup>
import { ref, computed } from "vue";

const props = defineProps(["chart_config", "activeChart", "series"]);

const MONTHS = ["1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月"];
const GROUP_SIZE = 5;
const MONTHLY_YEAR_WINDOW_SIZE = 3;
const POLAR_CENTER_X = 130;
const POLAR_CENTER_Y = 146;
const POLAR_INNER_RADIUS = 24;
const POLAR_CORE_RADIUS = ((POLAR_INNER_RADIUS - 5) / 2) * 1.5;
const POLAR_BAR_INNER_RADIUS = POLAR_CORE_RADIUS;
const POLAR_MAX_RADIUS = 100;
const POLAR_LABEL_RADIUS = 114;
const POLAR_MONTH_BAR_WIDTH = 10;
const POLAR_MONTH_BAR_OVERLAP = POLAR_MONTH_BAR_WIDTH / 4;
const POLAR_CASE_BAR_SCALE = 2;
const YEARLY_SVG_WIDTH = 260;
const YEARLY_SVG_HEIGHT = 190;
const YEARLY_PLOT = {
	left: 36,
	right: 10,
	top: 8,
	bottom: 28,
};

const PATHOGENS = [
	{ name: "諾羅病毒",       color: "#ed5a5a" },
	{ name: "金黃色葡萄球菌", color: "#f0883e" },
	{ name: "仙人掌桿菌",     color: "#eac54f" },
	{ name: "沙門氏桿菌",     color: "#5a9cf8" },
	{ name: "腸炎弧菌",       color: "#7ee787" },
	{ name: "病原性大腸桿菌", color: "#d2a8ff" },
	{ name: "肉毒桿菌",       color: "#a78bfa" },
	{ name: "輪狀病毒",       color: "#fb923c" },
	{ name: "病因不明",       color: "#4b5563" },
];

// ── mode ──────────────────────────────────────────────────────
const mode = ref("monthly");
const monthlyTooltip = ref({
	show: false,
	x: 0,
	y: 0,
	year: "",
	month: "",
	cases: 0,
	patients: 0,
	activeType: "",
});
const yearlyTooltip = ref({
	show: false,
	x: 0,
	y: 0,
	year: "",
	total: 0,
	rows: [],
	transform: "",
	maxHeight: 220,
});

// ── monthly mode ──────────────────────────────────────────────
const monthlyYears = computed(() => props.series.filter((d) => d.monthly));
const selectedYearIdx = ref(monthlyYears.value.length - 1);
const currentMonthly = computed(() => monthlyYears.value[selectedYearIdx.value] || {});
const monthlyYearWindowStart = computed(() => {
	const maxStart = Math.max(0, monthlyYears.value.length - MONTHLY_YEAR_WINDOW_SIZE);
	return Math.min(Math.max(0, selectedYearIdx.value - 1), maxStart);
});
const visibleMonthlyYears = computed(() => {
	const start = monthlyYearWindowStart.value;
	return monthlyYears.value
		.slice(start, start + MONTHLY_YEAR_WINDOW_SIZE)
		.map((item, idx) => ({ item, index: start + idx }));
});
const moveMonthlyYearWindow = (direction) => {
	const nextIdx = selectedYearIdx.value + direction * MONTHLY_YEAR_WINDOW_SIZE;
	selectedYearIdx.value = Math.min(
		Math.max(nextIdx, 0),
		monthlyYears.value.length - 1,
	);
};

const polarPoint = (angle, radius) => {
	const radian = ((angle - 90) * Math.PI) / 180;
	return {
		x: POLAR_CENTER_X + radius * Math.cos(radian),
		y: POLAR_CENTER_Y + radius * Math.sin(radian),
	};
};

const polarSectorPath = (startAngle, endAngle, outerRadius, innerRadius = POLAR_BAR_INNER_RADIUS) => {
	const outerStart = polarPoint(startAngle, outerRadius);
	const outerEnd = polarPoint(endAngle, outerRadius);
	const innerEnd = polarPoint(endAngle, innerRadius);
	const innerStart = polarPoint(startAngle, innerRadius);
	const largeArcFlag = endAngle - startAngle <= 180 ? 0 : 1;

	return [
		`M ${outerStart.x.toFixed(2)} ${outerStart.y.toFixed(2)}`,
		`A ${outerRadius} ${outerRadius} 0 ${largeArcFlag} 1 ${outerEnd.x.toFixed(2)} ${outerEnd.y.toFixed(2)}`,
		`L ${innerEnd.x.toFixed(2)} ${innerEnd.y.toFixed(2)}`,
		`A ${innerRadius} ${innerRadius} 0 ${largeArcFlag} 0 ${innerStart.x.toFixed(2)} ${innerStart.y.toFixed(2)}`,
		"Z",
	].join(" ");
};

const monthLabelPoints = computed(() =>
	MONTHS.map((month, index) => ({
		month,
		...polarPoint(index * 30, POLAR_LABEL_RADIUS),
	})),
);

const monthlyPolarBars = computed(() => {
	const cases = currentMonthly.value.monthly_cases || [];
	const patients = currentMonthly.value.monthly_patients || currentMonthly.value.monthly || [];
	const maxValue = Math.max(...cases, ...patients, 1);
	const radiusRange = POLAR_MAX_RADIUS - POLAR_BAR_INNER_RADIUS;

	return MONTHS.flatMap((month, index) => {
		const baseAngle = index * 30;
		const caseStartAngle = baseAngle - POLAR_MONTH_BAR_WIDTH + POLAR_MONTH_BAR_OVERLAP / 2;
		const caseEndAngle = baseAngle + POLAR_MONTH_BAR_OVERLAP / 2;
		const patientStartAngle = baseAngle - POLAR_MONTH_BAR_OVERLAP / 2;
		const patientEndAngle = baseAngle + POLAR_MONTH_BAR_WIDTH - POLAR_MONTH_BAR_OVERLAP / 2;
		const caseValue = cases[index] || 0;
		const patientValue = patients[index] || 0;
		const caseRadius = POLAR_BAR_INNER_RADIUS + (caseValue / maxValue) * radiusRange * POLAR_CASE_BAR_SCALE;
		const patientRadius = POLAR_BAR_INNER_RADIUS + (patientValue / maxValue) * radiusRange;

		return [
			{
				key: `${month}-cases`,
				month,
				type: "案件數",
				value: caseValue,
				unit: "件",
				cases: caseValue,
				patients: patientValue,
				className: "cases",
				path: polarSectorPath(caseStartAngle, caseEndAngle, caseRadius),
			},
			{
				key: `${month}-patients`,
				month,
				type: "患者數",
				value: patientValue,
				unit: "人",
				cases: caseValue,
				patients: patientValue,
				className: "patients",
				path: polarSectorPath(patientStartAngle, patientEndAngle, patientRadius),
			},
		];
	});
});

const moveMonthlyTooltip = (event) => {
	const container = event.currentTarget.closest(".fpyc-polar");
	if (!container) return;
	const rect = container.getBoundingClientRect();
	monthlyTooltip.value.x = event.clientX - rect.left + 12;
	monthlyTooltip.value.y = event.clientY - rect.top + 12;
};

const showMonthlyTooltip = (event, bar) => {
	moveMonthlyTooltip(event);
	monthlyTooltip.value = {
		...monthlyTooltip.value,
		show: true,
		year: currentMonthly.value.name || "",
		month: bar.month,
		cases: bar.cases,
		patients: bar.patients,
		activeType: bar.type,
	};
};

const hideMonthlyTooltip = () => {
	monthlyTooltip.value.show = false;
};

// ── yearly mode ────────────────────────────────────────────────
const groupIdx = ref(Math.floor((props.series.length - 1) / GROUP_SIZE));
const totalGroups = computed(() => Math.ceil(props.series.length / GROUP_SIZE));

const currentGroup = computed(() => {
	const start = groupIdx.value * GROUP_SIZE;
	return props.series.slice(start, start + GROUP_SIZE);
});

const groupLabel = computed(() => {
	const g = currentGroup.value;
	return `${g[0].name} ～ ${g[g.length - 1].name}`;
});

const yearlyPlotWidth = YEARLY_SVG_WIDTH - YEARLY_PLOT.left - YEARLY_PLOT.right;
const yearlyPlotHeight = YEARLY_SVG_HEIGHT - YEARLY_PLOT.top - YEARLY_PLOT.bottom;
const yearlyBaseline = YEARLY_PLOT.top + yearlyPlotHeight;

const yearPathogenValue = (yearData, pathogenName) => {
	const found = yearData.pathogens?.find((x) => x.x === pathogenName);
	return found ? found.y : 0;
};

const yearlyMax = computed(() => {
	const maxValue = Math.max(
		...currentGroup.value.map((yearData) =>
			PATHOGENS.reduce((sum, pathogen) => sum + yearPathogenValue(yearData, pathogen.name), 0),
		),
		1,
	);
	const base = maxValue > 1000 ? 1000 : maxValue > 100 ? 100 : 10;
	const step = Math.max(base, Math.ceil(maxValue / 4 / base) * base);
	return step * 4;
});

const yearlyTicks = computed(() =>
	Array.from({ length: 5 }, (_, index) => {
		const value = (yearlyMax.value / 4) * index;
		return {
			value,
			y: yearlyBaseline - (value / yearlyMax.value) * yearlyPlotHeight,
		};
	}),
);

const yearlyBars = computed(() => {
	const count = Math.max(currentGroup.value.length, 1);
	const barWidth = 34;
	const gap = (yearlyPlotWidth - barWidth * count) / (count + 1);

	return currentGroup.value.map((yearData, yearIndex) => {
		const x = YEARLY_PLOT.left + gap + yearIndex * (barWidth + gap);
		let cursorY = yearlyBaseline;
		const segments = PATHOGENS.map((pathogen) => {
			const value = yearPathogenValue(yearData, pathogen.name);
			const height = (value / yearlyMax.value) * yearlyPlotHeight;
			const y = cursorY - height;
			cursorY = y;
			return {
				key: `${yearData.name}-${pathogen.name}`,
				name: pathogen.name,
				color: pathogen.color,
				value,
				x,
				y,
				width: barWidth,
				height,
			};
		});
		const topY = Math.min(...segments.map((segment) => segment.y), yearlyBaseline);
		const totalHeight = yearlyBaseline - topY;

		return {
			key: yearData.name,
			yearData,
			x,
			width: barWidth,
			topY,
			totalHeight,
			segments,
		};
	});
});

const moveYearlyTooltip = (event) => {
	const container = event.currentTarget.closest(".fpyc-yearly");
	if (!container) return;
	const rect = container.getBoundingClientRect();
	const localX = event.clientX - rect.left;
	const localY = event.clientY - rect.top;
	const flipX = localX > rect.width * 0.58;
	const margin = 6;
	const maxHeight = Math.max(150, rect.height - margin * 2);
	const preferredY = localY + 18;
	const maxY = rect.height - maxHeight - margin;

	yearlyTooltip.value.x = localX + (flipX ? -18 : 18);
	yearlyTooltip.value.y = Math.min(Math.max(preferredY, margin), Math.max(margin, maxY));
	yearlyTooltip.value.transform = flipX ? "translateX(-100%)" : "";
	yearlyTooltip.value.maxHeight = maxHeight;
};

const showYearlyTooltip = (event, bar) => {
	moveYearlyTooltip(event);
	const total = bar.yearData.patients || 0;
	yearlyTooltip.value = {
		...yearlyTooltip.value,
		show: true,
		year: bar.yearData.name,
		total,
		rows: PATHOGENS.map((pathogen) => {
			const value = yearPathogenValue(bar.yearData, pathogen.name);
			return {
				name: pathogen.name,
				color: pathogen.color,
				percent: total ? ((value / total) * 100).toFixed(1) : "0.0",
			};
		}),
	};
};

const hideYearlyTooltip = () => {
	yearlyTooltip.value.show = false;
};
</script>

<template>
  <div
    v-if="activeChart === 'FoodPoisoningYearlyChart'"
    class="fpyc"
  >
    <div class="fpyc-controls">
      <div class="fpyc-mode">
        <button
          :class="{ active: mode === 'monthly' }"
          @click="mode = 'monthly'"
        >
          月份
        </button>
        <button
          :class="{ active: mode === 'yearly' }"
          @click="mode = 'yearly'"
        >
          年份
        </button>
      </div>

      <div
        v-if="mode === 'monthly'"
        class="fpyc-year-nav"
      >
        <button
          :disabled="monthlyYearWindowStart <= 0"
          @click="moveMonthlyYearWindow(-1)"
        >
          ◀
        </button>
        <div class="fpyc-year-options">
          <button
            v-for="{ item, index } in visibleMonthlyYears"
            :key="item.name"
            :class="{ active: selectedYearIdx === index }"
            @click="selectedYearIdx = index"
          >
            {{ item.name }}
          </button>
        </div>
        <button
          :disabled="monthlyYearWindowStart >= monthlyYears.length - MONTHLY_YEAR_WINDOW_SIZE"
          @click="moveMonthlyYearWindow(1)"
        >
          ▶
        </button>
      </div>
      <div
        v-else
        class="fpyc-group-nav"
      >
        <button
          :disabled="groupIdx === 0"
          @click="groupIdx--"
        >
          ◀
        </button>
        <span>{{ groupLabel }}</span>
        <button
          :disabled="groupIdx >= totalGroups - 1"
          @click="groupIdx++"
        >
          ▶
        </button>
      </div>
    </div>

    <!-- Monthly mode：year selector + monthly bar chart only -->
    <template v-if="mode === 'monthly'">
      <div class="fpyc-polar">
        <svg
          viewBox="0 0 260 260"
          role="img"
        >
          <circle
            class="fpyc-polar-core"
            :cx="POLAR_CENTER_X"
            :cy="POLAR_CENTER_Y"
            :r="POLAR_CORE_RADIUS"
          />
          <path
            v-for="bar in monthlyPolarBars"
            :key="bar.key"
            class="fpyc-polar-bar"
            :class="bar.className"
            :d="bar.path"
            @mouseenter="showMonthlyTooltip($event, bar)"
            @mousemove="moveMonthlyTooltip"
            @mouseleave="hideMonthlyTooltip"
          />
          <text
            v-for="label in monthLabelPoints"
            :key="label.month"
            class="fpyc-polar-label"
            :x="label.x"
            :y="label.y"
            text-anchor="middle"
            dominant-baseline="middle"
          >
            {{ label.month }}
          </text>
        </svg>
        <div class="fpyc-polar-legend">
          <span><i class="cases" />案件數</span>
          <span><i class="patients" />患者數</span>
        </div>
        <div
          v-if="monthlyTooltip.show"
          class="fpyc-polar-tooltip"
          :style="{ left: `${monthlyTooltip.x}px`, top: `${monthlyTooltip.y}px` }"
        >
          <h6>{{ monthlyTooltip.year }}・{{ monthlyTooltip.month }}</h6>
          <span class="focus">{{ monthlyTooltip.activeType }}</span>
          <span>案件數：{{ monthlyTooltip.cases.toLocaleString() }} 件</span>
          <span>患者數：{{ monthlyTooltip.patients.toLocaleString() }} 人</span>
        </div>
      </div>
    </template>

    <!-- Yearly mode：stacked bar by pathogen -->
    <template v-else>
      <div class="fpyc-yearly">
        <svg
          :viewBox="`0 0 ${YEARLY_SVG_WIDTH} ${YEARLY_SVG_HEIGHT}`"
          role="img"
        >
          <g class="fpyc-yearly-axis">
            <text
              v-for="tick in yearlyTicks"
              :key="tick.value"
              :x="YEARLY_PLOT.left - 8"
              :y="tick.y"
              text-anchor="end"
              dominant-baseline="middle"
            >
              {{ tick.value.toLocaleString() }}
            </text>
          </g>
          <g
            v-for="bar in yearlyBars"
            :key="bar.key"
            class="fpyc-yearly-bar"
            @mouseenter="showYearlyTooltip($event, bar)"
            @mousemove="moveYearlyTooltip"
            @mouseleave="hideYearlyTooltip"
          >
            <rect
              class="fpyc-yearly-bar-outline"
              :x="bar.x - 1"
              :y="bar.topY - 1"
              :width="bar.width + 2"
              :height="bar.totalHeight + 2"
              rx="1"
            />
            <rect
              v-for="segment in bar.segments"
              :key="segment.key"
              class="fpyc-yearly-segment"
              :x="segment.x"
              :y="segment.y"
              :width="segment.width"
              :height="segment.height"
              :fill="segment.color"
            />
            <rect
              class="fpyc-yearly-hit"
              :x="bar.x - 5"
              :y="YEARLY_PLOT.top"
              :width="bar.width + 10"
              :height="yearlyPlotHeight"
            />
            <text
              class="fpyc-yearly-label"
              :x="bar.x + bar.width / 2"
              :y="yearlyBaseline + 18"
              text-anchor="middle"
            >
              {{ bar.yearData.name }}
            </text>
          </g>
        </svg>
        <div class="fpyc-yearly-legend">
          <span
            v-for="pathogen in PATHOGENS"
            :key="pathogen.name"
          >
            <i :style="{ background: pathogen.color }" />{{ pathogen.name }}
          </span>
        </div>
        <div
          v-if="yearlyTooltip.show"
          class="fpyc-yearly-tooltip"
          :style="{ left: `${yearlyTooltip.x}px`, top: `${yearlyTooltip.y}px`, transform: yearlyTooltip.transform, maxHeight: `${yearlyTooltip.maxHeight}px` }"
        >
          <h6>{{ yearlyTooltip.year }}・病因比例</h6>
          <span class="fpyc-yearly-tooltip-total">患者數：{{ yearlyTooltip.total.toLocaleString() }} 人</span>
          <div
            v-for="row in yearlyTooltip.rows"
            :key="row.name"
            class="fpyc-yearly-tooltip-row"
          >
            <i :style="{ background: row.color }" />
            <span>{{ row.name }}</span>
            <strong>{{ row.percent }}%</strong>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.fpyc {
	width: 100%;
	height: 100%;
	min-height: 0;
	display: flex;
	flex-direction: column;
	overflow: hidden;

	&-controls {
		flex: 0 0 auto;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
		margin-bottom: 4px;
		min-width: 0;
	}

	&-mode {
		display: flex;
		gap: 4px;
		flex: 0 0 auto;

		button {
			padding: 2px 10px;
			border-radius: 4px;
			background: rgb(77, 77, 77);
			opacity: 0.6;
			color: var(--color-complement-text);
			font-size: var(--font-s);
			transition: opacity 0.2s;

			&:hover { opacity: 1; }
			&.active { background: var(--color-complement-text); color: white; opacity: 1; }
		}
	}

	&-year-nav {
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 4px;
		flex: 1 1 auto;
		min-width: 0;

		button {
			padding: 2px 8px;
			border-radius: 4px;
			background: rgb(77, 77, 77);
			opacity: 0.6;
			color: var(--color-complement-text);
			font-size: var(--font-s);
			transition: opacity 0.2s;

			&:hover:not(:disabled) { opacity: 1; }
			&:disabled { opacity: 0.2; cursor: default; }
			&.active { background: var(--color-complement-text); color: white; opacity: 1; }
		}
	}

	&-year-options {
		display: grid;
		grid-template-columns: repeat(3, minmax(42px, 1fr));
		gap: 4px;
		min-width: 142px;

		button {
			width: 100%;
		}
	}

	&-polar {
		width: 100%;
		flex: 1 1 auto;
		min-height: 0;
		height: auto;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		position: relative;

		svg {
			width: min(100%, 330px);
			height: min(100%, 208px);
			max-height: 208px;
			overflow: visible;
		}

		&-core {
			fill: #24272a;
			stroke: #3d4146;
			stroke-width: 2;
		}

		&-bar {
			stroke: #282a2c;
			stroke-width: 1.5;
			transition: opacity 0.2s, stroke 0.2s, filter 0.2s;

			&:hover {
				opacity: 0.9;
				stroke: #ffffff;
				stroke-width: 0.6;
				filter: drop-shadow(0 0 3px rgba(255, 255, 255, 0.95));
				animation: fpyc-glow-pulse 0.9s ease-in-out infinite;
			}

			&.cases {
				fill: #fff1a8;
			}

			&.patients {
				fill: #f4c414;
			}
		}

		&-label {
			fill: #9ca3af;
			font-size: 12px;
			font-weight: 700;
		}

		&-legend {
			display: flex;
			justify-content: center;
			gap: 18px;
			margin-top: 4px;
			color: #9ca3af;
			font-size: var(--font-s);

			span {
				display: inline-flex;
				align-items: center;
				gap: 6px;
			}

			i {
				width: 12px;
				height: 12px;
				border-radius: 3px;
				display: inline-block;

				&.cases {
					background: #fff1a8;
				}

				&.patients {
					background: #f4c414;
				}
			}
		}

		&-tooltip {
			position: absolute;
			z-index: 2;
			min-width: 132px;
			padding: 8px 10px;
			border-radius: 6px;
			background: rgba(23, 25, 28, 0.96);
			border: 1px solid rgba(255, 255, 255, 0.14);
			box-shadow: 0 8px 18px rgba(0, 0, 0, 0.32);
			color: #d1d5db;
			font-size: 12px;
			line-height: 1.55;
			pointer-events: none;

			h6 {
				margin: 0 0 4px;
				color: #f9fafb;
				font-size: 12px;
				font-weight: 700;
			}

			span {
				display: block;

				&.focus {
					color: #f4c414;
					font-weight: 700;
				}
			}
		}
	}

	&-group-nav {
		display: flex;
		align-items: center;
		justify-content: flex-end;
		gap: 6px;
		flex: 1 1 auto;
		min-width: 0;

		span {
			font-size: var(--font-s);
			color: var(--color-complement-text);
			min-width: 96px;
			text-align: center;
		}

		button {
			padding: 2px 8px;
			border-radius: 4px;
			background: rgb(77, 77, 77);
			opacity: 0.6;
			color: var(--color-complement-text);
			font-size: var(--font-s);
			transition: opacity 0.2s;

			&:hover:not(:disabled) { opacity: 1; }
			&:disabled { opacity: 0.2; cursor: default; }
		}
	}

	&-yearly {
		position: relative;
		width: 100%;
		flex: 1 1 auto;
		min-height: 0;
		height: auto;
		display: flex;
		flex-direction: column;
		align-items: center;

		svg {
			width: 100%;
			flex: 1 1 auto;
			min-height: 0;
			max-height: 178px;
			overflow: visible;
		}

		&-axis {
			fill: #9ca3af;
			font-size: 10px;
			font-weight: 700;
		}

		&-bar {
			cursor: pointer;

			&:hover {
				.fpyc-yearly-bar-outline {
					opacity: 1;
					animation: fpyc-glow-pulse 0.9s ease-in-out infinite;
				}

				.fpyc-yearly-segment {
					filter: drop-shadow(0 0 4px rgba(255, 255, 255, 0.9));
					animation: fpyc-glow-pulse 0.9s ease-in-out infinite;
				}
			}
		}

		&-segment {
			transition: filter 0.18s;
		}

		&-bar-outline {
			fill: none;
			opacity: 0;
			stroke: #ffffff;
			stroke-width: 0.9px;
			vector-effect: non-scaling-stroke;
			pointer-events: none;
			filter: drop-shadow(0 0 5px rgba(255, 255, 255, 1));
			transition: opacity 0.18s;
		}

		&-hit {
			fill: transparent;
		}

		&-label {
			fill: #9ca3af;
			font-size: 11px;
			font-weight: 700;
		}

		&-legend {
			display: flex;
			flex-wrap: wrap;
			justify-content: center;
			gap: 6px 12px;
			margin-top: 0;
			color: #9ca3af;
			font-size: 10px;
			line-height: 1.25;

			span {
				display: inline-flex;
				align-items: center;
				gap: 5px;
			}

			i {
				width: 8px;
				height: 8px;
				border-radius: 2px;
				display: inline-block;
			}
		}

		&-tooltip {
			position: absolute;
			z-index: 2;
			min-width: 174px;
			max-width: min(220px, calc(100% - 12px));
			padding: 8px 10px;
			border-radius: 6px;
			background: rgba(23, 25, 28, 0.96);
			border: 1px solid rgba(255, 255, 255, 0.14);
			box-shadow: 0 8px 18px rgba(0, 0, 0, 0.32);
			color: #d1d5db;
			font-size: 12px;
			line-height: 1.45;
			overflow-y: auto;
			pointer-events: none;
			transition: transform 0.08s;

			h6 {
				margin: 0 0 4px;
				color: #f9fafb;
				font-size: 12px;
				font-weight: 700;
				white-space: nowrap;
			}

			&-total {
				display: block;
				margin-bottom: 4px;
				color: #d1d5db;
			}

			&-row {
				display: grid;
				grid-template-columns: 8px 1fr auto;
				align-items: center;
				gap: 6px;
				color: #d1d5db;
				font-size: 11px;
				line-height: 1.45;
				min-width: 0;

				span {
					min-width: 0;
					overflow: hidden;
					text-overflow: ellipsis;
					white-space: nowrap;
				}

				i {
					width: 8px;
					height: 8px;
					border-radius: 2px;
				}

				strong {
					color: #f9fafb;
					font-weight: 700;
				}
			}
		}
	}
}

@keyframes fpyc-glow-pulse {
	0%, 100% {
		filter: drop-shadow(0 0 2px rgba(255, 255, 255, 0.7));
	}

	50% {
		filter: drop-shadow(0 0 4px rgba(255, 255, 255, 1));
	}
}
</style>
