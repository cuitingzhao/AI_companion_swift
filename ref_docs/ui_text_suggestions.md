# UI Text Suggestions

Format: `filename | original text | suggestion`

| filename | original text | suggestion |
| --- | --- | --- |
| AICompanion/Onboarding/OnboardingIntroView.swift | "不只是陪伴\n还要帮你成为更好的自己" | 改为更自然的口语："不止是陪伴，\n也想帮你成为更好的自己" |
| AICompanion/Onboarding/OnboardingIntroView.swift | "请接受" | 明确行为："请先阅读并同意" |
| AICompanion/Onboarding/OnboardingProfileView.swift | "为了做一个合格的五行伙伴，我需要以下信息计算你的生辰八字" | 补充语气和标点："为了做一个合格的五行伙伴，我需要以下信息来计算你的生辰八字。" |
| AICompanion/Onboarding/OnboardingProfileView.swift | "选择出生日期和时间" | 更贴近用户："请选择你的出生日期和时间" |
| AICompanion/Onboarding/KYCPersonalityReviewView.swift | "以下推测准确吗？" | 更具体："这些性格描述准确吗？" |
| AICompanion/Onboarding/KYCPersonalityReviewView.swift | "暂时没有可确认的性格描述" | 更口语："暂时没有需要你确认的性格描述" |
| AICompanion/Onboarding/KYCPersonalityReviewView.swift | "可以简单说明哪里不准（可选）" | 更鼓励式："如果觉得不准，可以简单说说哪里不太对（可选）" |
| AICompanion/Onboarding/KYCPersonalityReviewView.swift | 跳过确认对话框文案："了解你的性格将有助于我为你提供更好的建议，确定跳过这个环节吗？" | 稍微收短："了解你的性格能帮我给出更好的建议，确定要跳过这个环节吗？" |
| AICompanion/Onboarding/PersonalityReviewEndView.swift | 主按钮 "确认" | 更符合流程语义，改为："继续" |
| AICompanion/Onboarding/KYCEndView.swift | 次按钮 "跳过" | 采用更柔和表达："暂时跳过" |
| AICompanion/Onboarding/GoalPlanView.swift | "暂时没有可展示的目标计划" | 更清晰："目标计划尚未生成" |
| AICompanion/Onboarding/GoalPlanView.swift | Dialog message: "这是根据我们刚才的讨论为你制定的计划。请知晓这个计划会随着我们的谈话增多，我对你的了解增多而产生变化。我每天都会把计划里的部分任务插入到你的日程表里，你可以在任务主页查看。" | 拆句提高清晰度："这是为你制定的计划。随着我们聊天增多、我对你的了解加深，这个计划也会不断调整。我每天会从计划中挑选部分事项，插入到你的日程表里，你可以在每日待办页面查看。" |
| AICompanion/Onboarding/GoalOnboardingChatView.swift | 错误文案 "发送失败，请稍后重试。" | 更具体："消息发送失败，请检查网络后稍后再试。" |
| AICompanion/Onboarding/GoalOnboardingChatView.swift | 错误文案 "生成目标计划时出错，请稍后重试。" | 统一风格："生成目标计划时出了点问题，请稍后再试。" |
| AICompanion/Onboarding/GoalOnboardingChatView.swift | 错误文案 "获取目标计划失败，请稍后重试。" | 同上："暂时无法获取目标计划，请稍后再试。" |
| AICompanion/TaskForTodayView.swift | 标题 "今日任务一览" | 可改为更自然的标题："今日待执行的小行动"|
| AICompanion/TaskForTodayView.swift | 加载中文案 "正在获取今日任务，请稍候" | 增加友好语气："正在为你获取今日待办事项，请稍候…" |
| AICompanion/TaskForTodayView.swift | 错误文案 "缺少用户信息，暂时无法获取今日任务。" | 从用户视角："系统暂时无法获取你的账户信息，今日待办事项暂时无法加载，请稍后再试。" |
| AICompanion/TaskForTodayView.swift | 错误文案 "获取今日任务失败，请稍后重试。" | 统一为："暂时无法获取今日的待办事项，请稍后再试。" |
| AICompanion/HomeDailyTasksView.swift | 兜底标题 "今日运势与日程" | 更贴合功能："今日的待办与提醒" 或 "今天的任务概览" |
| AICompanion/HomeDailyTasksView.swift | 错误文案 "获取日历信息失败，请稍后重试。" | 更具体："日历信息加载失败，请检查网络后稍后再试。" |
| AICompanion/HomeDailyTasksView.swift | 错误文案 "缺少用户信息，暂时无法加载今日任务。" | 同 TaskForToday 统一："系统暂时无法获取你的账户信息，今日待办暂时无法加载，请稍后再试。" |
| AICompanion/HomeDailyTasksView.swift | 错误文案 "获取今日任务失败，请稍后重试。" | 统一："暂时无法获取今日待办事项，请稍后再试。" |
| AICompanion/HomeDailyTasksView.swift | 错误文案 "刷新任务列表失败，请稍后重试。" | 提示可重试："刷新待办事项列表失败，请稍后再试一次。" |
| AICompanion/HomeDailyTasksView.swift | 文案 "该任务为高频任务，暂不支持推迟。" | 更具体："该待办事项为每日/工作日重复事项，目前不支持推迟。" |
| AICompanion/HomeDailyTasksView.swift | 空状态文案 "还没有任务安排，\n歇一歇吧。" | 已很友好，如需更中性版本可选："今天还没有为你安排任何待办事项，可以适当休息一下啦。" |
| AICompanion/HomeDailyTasksView.swift | 进度提示 "正在更新任务状态，请稍候" | 可增加反馈："正在更新待办事项状态，请稍候…" |
| AICompanion/HomeDailyTasksView.swift | Tab 文案 "目标追踪" | 如希望与 PRD 一致，可改为 "目标追踪" 或 "目标跟踪"（根据产品统一术语选择其一） |
| AICompanion/HomeDailyTasksView.swift | Tab 文案 "流年推测" | 视产品定位，可改为更解释性的："流年运势" |
| AICompanion/Onboarding/KYCIntroView.swift | 底部按钮文案 "好的" | 更明确行动："好的，开始吧" |
| AICompanion/Onboarding/KYCIntroView.swift | 底部按钮文案 "跳过" | 更柔和："暂时跳过" |
| AICompanion/Onboarding/KYCEndView.swift | 主按钮 "确认" | 若按钮含义是进入目标设定，可改为："去设定目标" 或 "开始设定目标" |
| AICompanion/Onboarding/GoalPlanView.swift | 按钮 "明天开始也不迟" | 更精简："明天再开始" 或 "明天再说"，视品牌语气选择 |
