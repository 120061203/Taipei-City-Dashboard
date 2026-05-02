<script setup>
import { ref, watch, nextTick } from "vue";
import { storeToRefs } from "pinia";
import SendIcon from "../icons/SendIcon.vue";
import BotLogo from "../icons/BotLogo.vue";
import UserLogo from "../icons/UserLogo.vue";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";

import { useChatStore } from "../../store/chatStore";
import { useContentStore } from "../../store/contentStore";
import { useAuthStore } from "../../store/authStore";
import { useDialogStore } from "../../store/dialogStore";
import http from "../../router/axios";

const chatStore = useChatStore();
const contentStore = useContentStore();
const authStore = useAuthStore();
const dialogStore = useDialogStore();
const { addChatData, addQueryData, saveChatLog } = chatStore;
const { createDashboard } = contentStore;
const { chatData } = storeToRefs(chatStore);
const { editDashboard } = storeToRefs(contentStore);
const { user } = storeToRefs(authStore);

const userMessage = ref("");
const chatAreaRef = ref(null);
const isStickyOpen = ref(false);
const dashboardCreationLoading = ref(false);

const qaBtnHandler = async (text, relations) => {
	if (text === "建立儀表板") {
		if (dashboardCreationLoading.value === true) return;
		dashboardCreationLoading.value = true;
		// 確認個人儀表板是否超過20個
		const response = await http.get(`/dashboard/`);
		if (response.data?.data?.personal?.length > 20) {
			addChatData({
				role: "bot",
				content:
					"您的個人儀表板已超出限制 20 個，請先移除既有儀表板後，重新執行本功能！",
			});
			dashboardCreationLoading.value = false;
			return;
		}
		const components = Array.from(new Set(relations.map((r) => r.id))).map(
			(id) => ({ id }),
		);

		if (user.value.user_id) {
			editDashboard.value = {
				index: "",
				name: "推薦儀表板",
				icon: "star",
				components: components,
			};
			await createDashboard();
			saveChatLog("建立儀表板", "使用者成功建立儀表板!");
		} else {
			addChatData({
				role: "bot",
				content: "請先登入會員以使用此功能喔！",
			});
		}
		dashboardCreationLoading.value = false;
	}
};

const sendBtnHandler = (text) => {
	if (!text.trim()) return;
	addQueryData({
		role: "user",
		content: text,
	});
	userMessage.value = "";
};

const toggleSticky = () => {
	isStickyOpen.value = !isStickyOpen.value;
};

const openShareComponent = (chat) => {
	const { componentData } = chat;
	const previewConfig = componentData?.previewConfig;
	if (!previewConfig) return;
	dialogStore.showShareComponent({
		config: JSON.parse(JSON.stringify(previewConfig)),
		activeCity: previewConfig.city || componentData?.cityCode,
		initialChart: previewConfig.chart_config?.types?.[0],
	});
};

watch(
	() => chatData.value.length,
	async () => {
		await nextTick();
		const chat = chatAreaRef.value;
		if (!chat) return;
		chat.scrollTop = chat.scrollHeight - chat.clientHeight;
	},
	{ deep: true },
);
</script>

<template>
  <div class="chat-widget">
    <!-- 標題 -->
    <div class="header">
      <h3>臺北城市儀表板小幫手</h3>
    </div>

    <!-- 聊天區 -->
    <div
      ref="chatAreaRef"
      class="chat-area scrollbar-custom"
    >
      <!-- 置頂訊息 -->
      <div class="chat-message sticky-message">
        <div
          class="sticky-header"
          @click="toggleSticky"
        >
          <span>置頂公告：小幫手使用須知</span>
          <button class="toggle-btn">
            {{ isStickyOpen ? "-" : "+" }}
          </button>
        </div>
        <div
          v-show="isStickyOpen"
          class="sticky-body"
        >
          <span>小幫手會依據您輸入的內容，自動檢索本站臺的組件資料庫，並回傳相似度較高的組件清單，協助您快速找到符合需求的元件或資訊。<br><br>
            目前小幫手僅提供組件比對與分析服務，不支援一般聊天功能。如造成不便，敬請見諒！</span>
        </div>
      </div>
      <div
        v-for="chat in chatData"
        :key="chat.id"
        class="message"
      >
        <!-- 機器人訊息 -->
        <div
          v-if="chat.role === 'bot'"
          class="bot"
        >
          <div class="avatar">
            <BotLogo />
          </div>
          <div class="content">
            <div
              v-if="chat.content"
              class="message--bubble"
            >
              <p>{{ chat.content }}</p>
            </div>
            <div
              v-if="chat.componentData?.previewConfig"
              class="component-preview-card"
            >
              <DashboardComponent
                :config="chat.componentData.previewConfig"
                mode="default"
                :footer="false"
                :active-city="chat.componentData.previewConfig.city"
                :toggle-on="false"
              />
            </div>
            <div
              v-else-if="chat.componentData"
              class="component-data-card"
            >
              <div class="component-data-card__header">
                <span class="component-data-card__title">{{ chat.componentData.title }}</span>
                <span class="component-data-card__city">{{ chat.componentData.city }}</span>
              </div>
              <div
                v-if="chat.componentData.summary"
                class="component-data-card__summary"
              >
                <span>{{ chat.componentData.summary.label }}</span>
                <strong>{{ chat.componentData.summary.value }}</strong>
                <span>{{ chat.componentData.summary.unit }}</span>
              </div>
              <table class="component-data-card__table">
                <thead>
                  <tr>
                    <th>{{ chat.componentData.columns.label }}</th>
                    <th>{{ chat.componentData.columns.value }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="row in chat.componentData.rows"
                    :key="row.label"
                  >
                    <td>{{ row.label }}</td>
                    <td>{{ row.value }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div
              v-if="chat.componentData?.previewConfig"
              class="component-share"
            >
              <button
                class="component-share__button"
                @click="openShareComponent(chat)"
              >
                分享圖表
              </button>
            </div>
            <!-- 表格區 -->
            <div
              v-if="chat.relations"
              v-horizontal-wheel
              class="relation-area"
            >
              <table class="relation-table">
                <thead>
                  <tr>
                    <th>排名</th>
                    <th>城市名</th>
                    <th>組件名</th>
                    <th>關聯性</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="(item, index) in chat.relations"
                    :key="index"
                  >
                    <td>{{ index + 1 }}</td>
                    <td>
                      {{
                        item.city === "taipei"
                          ? "臺北"
                          : "雙北"
                      }}
                    </td>
                    <td>{{ item.name }}</td>
                    <td>{{ item.score }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div
              v-if="chat.button"
              v-horizontal-wheel
              class="message--button scrollbar-x-hide"
            >
              <button
                v-for="btn in chat.button"
                :key="btn.id"
                @click="qaBtnHandler(btn.text, chat.relations)"
              >
                {{ btn.text }}
              </button>
            </div>
          </div>
        </div>
        <!-- 使用者訊息 -->
        <div
          v-else
          class="user"
        >
          <div class="avatar">
            <UserLogo />
          </div>
          <div
            v-if="chat.content"
            class="content"
          >
            <div class="message--bubble">
              <p>{{ chat.content }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 輸入區 -->
    <div class="input-area">
      <input
        v-model="userMessage"
        type="text"
        placeholder="輸入訊息..."
        @keyup.enter="sendBtnHandler(userMessage)"
      >
      <button @click="sendBtnHandler(userMessage)">
        <SendIcon />
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
/* === 變數設定 === */
$bg-dark: #090909;
$panel-bg: #494b4e;
$card-bg: #282a2c;
$border-color: #888787;
$input-bg: #d9d9d9;
$white: #ffffff;
$scroll-thumb-hover: #ababab;
$radius-10: 10px;
$radius-15: 15px;
$radius-20: 20px;

/* === Scrollbar === */
.scrollbar-x-hide {
	scrollbar-width: none;

	&::-webkit-scrollbar {
		display: none;
	}
}

.scrollbar-custom {
	&::-webkit-scrollbar {
		width: 2px;
		background: transparent;
	}

	&::-webkit-scrollbar-thumb {
		background: $white;
		border-radius: 8px;
	}

	&::-webkit-scrollbar-thumb:hover {
		background: $scroll-thumb-hover;
	}
}

/* === 主要樣式 === */
.chat-widget {
	width: 400px;
	border-radius: $radius-20;
	overflow: hidden;
	background: $bg-dark;
	border: 1px solid $border-color;
	display: flex;
	flex-direction: column;

	.header {
		padding: 1rem;
		background: $panel-bg;
		border-bottom: 3px solid $border-color;

		h3 {
			font-size: 18px;
			font-weight: 700;
			color: $white;
			margin: 0;
		}
	}

	.chat-area {
		flex: 1;
		margin: 0.25rem;
		padding: 0.75rem;
		overflow-y: auto;
		background: $bg-dark;

		.chat-message {
			padding: 4px 10px;
			margin: 0px 8px;
			border-radius: 8px;
			background-color: $bg-dark;
		}

		// 置頂訊息
		.sticky-message {
			border: 1px solid #ffffff;
			position: sticky;
			top: 0;
			z-index: 10;

			.sticky-header {
				display: flex;
				font-weight: bold;
				justify-content: space-between;
				align-items: center;
				cursor: pointer;
				padding: 8px 12px;
			}

			.sticky-body {
				padding: 8px 12px;
				font-weight: 400;
				font-size: 14px;
			}

			.toggle-btn {
				background: none;
				border: none;
				font-size: 14px;
				cursor: pointer;
				color: #ffffff;
			}
		}

		.message {
			padding: 8px;

			.bot,
			.user {
				display: flex;
				gap: 0.5rem;
				align-items: flex-start;

				&.user {
					flex-direction: row-reverse;
				}

				.avatar {
					width: 40px;
					height: 40px;
					display: flex;
					align-items: center;
					justify-content: center;
					flex-shrink: 0;

					svg {
						width: 100%;
						height: auto;
					}
				}

				.content {
					display: flex;
					flex-direction: column;
					gap: 0.5rem;

					.relation-area {
						width: 100%;
						display: flex;
						align-items: center;
						margin-top: 8px;
						margin-bottom: 8px;

						.relation-table {
							min-width: max-content;
							font-size: 13px;
						}

						.relation-table th,
						.relation-table td {
							border: 1px solid #ccc;
							text-align: left;
							padding: 0px 8px;
							line-height: 1.1;
							vertical-align: middle;
						}

						.relation-table td {
							height: 2.5rem;
						}

						.relation-table th {
							font-weight: bold;
							text-align: center;
						}
					}

					.message--bubble {
						border: 1px solid $white;
						border-radius: $radius-10;
						background: $card-bg;

						p {
							color: $white;
							white-space: pre-line;
							margin: 0;
							padding-top: 8px;
							padding-bottom: 8px;
							padding-left: 16px;
							padding-right: 16px;
							font-size: 16px;
						}
					}

					.component-data-card {
						width: 100%;
						max-width: 320px;
						border: 1px solid #666;
						border-radius: $radius-10;
						background: #202224;
						color: $white;
						padding: 12px;
						box-sizing: border-box;

						&__header {
							display: flex;
							align-items: center;
							justify-content: space-between;
							gap: 8px;
							margin-bottom: 10px;
						}

						&__title {
							font-weight: 700;
							font-size: 15px;
						}

						&__city {
							flex-shrink: 0;
							padding: 2px 8px;
							border-radius: 6px;
							background: #2252d6;
							font-weight: 700;
							font-size: 13px;
						}

						&__summary {
							display: flex;
							align-items: baseline;
							gap: 6px;
							color: #b5b5b5;
							margin-bottom: 10px;

							strong {
								color: $white;
								font-size: 24px;
							}
						}

						&__table {
							width: 100%;
							border-collapse: collapse;
							font-size: 13px;

							th,
							td {
								padding: 6px 4px;
								border-bottom: 1px solid #3b3d40;
								text-align: left;
							}

							th:last-child,
							td:last-child {
								text-align: right;
							}
						}
					}

					.component-preview-card {
						width: 100%;
						max-width: 330px;
						border-radius: $radius-10;
						overflow: hidden;

						:deep(.dashboardcomponent) {
							width: 100%;
							max-width: 100%;
							height: 330px;
							max-height: 330px;
							box-sizing: border-box;
							padding: 12px;
							background-color: $card-bg;
							border: 1px solid #666;
						}

						:deep(.dashboardcomponent-header h3) {
							font-size: 18px;
							line-height: 1.2;
						}

						:deep(.dashboardcomponent-meta) {
							grid-template-columns: minmax(0, 1fr);
						}

						:deep(.dashboardcomponent-source) {
							font-size: 13px;
							-webkit-line-clamp: 1;
						}

						:deep(.dashboardcomponent-control) {
							padding: 4px 0;
						}

						:deep(.dashboardcomponent-control-group) {
							transform: none;
						}

						:deep(.dashboardcomponent-chart) {
							height: auto;
							flex: 1 1 auto;
							min-height: 0;
							overflow: hidden;
						}

						:deep(.districtchart-title h5) {
							font-size: 16px;
						}

						:deep(.districtchart-title h6) {
							font-size: 24px;
						}
					}

					.component-share {
						width: 100%;
						max-width: 330px;
						display: flex;
						flex-direction: column;
						gap: 6px;

						&__button {
							align-self: flex-start;
							border: 1px solid #6aa4ff;
							border-radius: 8px;
							background: #1f5fbf;
							color: $white;
							font-size: 14px;
							font-weight: 700;
							padding: 7px 12px;
							cursor: pointer;

							&:disabled {
								cursor: wait;
								opacity: 0.65;
							}
						}

						&__link,
						&__error {
							margin: 0;
							font-size: 12px;
							line-height: 1.4;
						}

						&__link {
							color: #9bc3ff;

							span {
								display: block;
								max-width: 100%;
								overflow-wrap: anywhere;
							}
						}

						&__error {
							color: #ff9b9b;
						}
					}

					.message--button {
						display: flex;
						gap: 0.5rem;
						overflow-x: auto;

						button {
							flex-shrink: 0;
							background: $panel-bg;
							color: $white;
							font-size: 14px;
							padding: 0.5rem 1rem;
							border-radius: $radius-15;
							border: none;
							cursor: pointer;
							white-space: nowrap;

							&:hover {
								filter: brightness(0.5);
							}
						}
					}
				}
			}
		}
	}

	.input-area {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		padding: 1.5rem 1.125rem;
		background: $panel-bg;

		input[type="text"] {
			background: $white;
			height: 35px;
			width: 100%;
			border-radius: 20px;
			padding: 0 1rem;
			border: none;
			outline: none;
			color: black;
		}

		button {
			height: 35px;
			display: flex;
			align-items: center;
			justify-content: center;
			background: transparent;
			border: none;
			cursor: pointer;

			&:hover {
				filter: brightness(0.5);
			}
		}
	}
}
</style>
