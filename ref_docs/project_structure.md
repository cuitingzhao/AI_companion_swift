# AICompanion Project Structure

```text
AICompanion/
|-- AICompanion/
|   |-- AICompanionApp.swift (app entry point)
|   |-- SpeechRecognizer.swift
|   |-- Models/
|   |   |-- City.swift
|   |   |-- Bazi.swift
|   |   |-- PersonalityTrait.swift
|   |   |-- OnboardingModels.swift
|   |   |-- ProfileModels.swift
|   |   |-- GoalsModels.swift
|   |   |-- CalendarModels.swift (calendar info for homepage header)
|   |   |-- FortuneModels.swift (daily fortune response models)
|   |   |-- ChatModels.swift (chat API request/response models)
|   |   |-- AuthModels.swift (authentication request/response models)
|   |   |-- SubscriptionModels.swift (subscription status, verify receipt, restore models)
|   |-- DesignSystem/
|   |   |-- Colors.swift (Neobrutalism color palette)
|   |   |-- Fonts.swift (Bold typography for Neobrutalism)
|   |   |-- NeoBrutalModifiers.swift (Reusable view modifiers for borders/shadows)
|   |   |-- Components/
|   |       |-- PrimaryButton.swift (Neobrutalist button with 3D depth effect)
|   |       |-- SimpleButton.swift (Simple button with shadow, used in onboarding flow)
|   |       |-- AppTextField.swift (Neobrutalist text field)
|   |       |-- VoiceInputButton.swift
|   |       |-- AppDialog.swift
|   |       |-- FloatingChatButton.swift (floating action button for chat)
|   |       |-- Toast.swift (Neobrutalist toast notification)
|   |       |-- GIFImage.swift (animated GIF display component)
|   |       |-- AppToggle.swift (reusable toggle component with round knob: AppToggle, RoundKnobToggleStyle)
|   |       |-- DialogComponents.swift (reusable dialog components: DialogContainer, DialogHeader, LabeledTextField, OptionPicker, DateTogglePicker, DialogButtonRow, ConfirmationDialogOverlay)
|   |       |-- CachedAsyncImage.swift (cached async image loader to prevent cancellation in LazyVStack)
|   |
|   |-- Networking/
|   |   |-- APIClient.swift (centralized API client: base URL, auth headers, 401 retry, error handling)
|   |   |-- AuthAPI.swift (auth endpoints - no auth: sms/send, sms/verify, refresh, logout; auth: /me)
|   |   |-- CitiesAPI.swift (no auth required - public utility)
|   |   |-- OnboardingAPI.swift (mixed: submit=no auth, feedback/message/skip/status=auth)
|   |   |-- ProfileAPI.swift (auth required)
|   |   |-- GoalsAPI.swift (auth required)
|   |   |-- CalendarAPI.swift (no auth required - utility)
|   |   |-- FortuneAPI.swift (auth required)
|   |   |-- ExecutionsAPI.swift (auth required)
|   |   |-- ChatAPI.swift (auth required, includes SSE streaming)
|   |   |-- MediaAPI.swift (auth required)
|   |   |-- NotificationsAPI.swift (auth required)
|   |   |-- SubscriptionAPI.swift (auth required)
|   |
|   |-- Services/
|   |   |-- AuthManager.swift (Keychain token storage, auth state management)
|   |   |-- SubscriptionManager.swift (StoreKit 2 integration, subscription state, IAP purchases)
|   |   |-- LocationService.swift
|   |   |-- PermissionManager.swift (JIT permission requests for iOS native tools)
|   |   |-- NativeToolExecutor.swift (executes calendar, alarm, health, screen time actions)
|   |   |-- SpeechRecognizer.swift (speech to text service)
|   |   |-- PushNotificationManager.swift (APNs token registration and notification handling)
|   |
|   |-- Onboarding/
|   |   |-- OnboardingState.swift (includes auth flow routing logic)
|   |   |-- OnboardingScaffold.swift
|   |   |-- OnboardingHeader.swift
|   |   |-- OnboardingIntroView.swift (consolidated intro + nickname input, optional login button)
|   |   |-- OnboardingProfileView.swift
|   |   |-- LoginView.swift (SMS login/register for guest users)
|   |   |-- OnboardingLoadingView.swift
|   |   |-- BaziAnalysisResultView.swift (consolidated with KYC intro buttons)
|   |   |-- KYCIntroView.swift (deprecated, functionality moved to BaziAnalysisResultView)
|   |   |-- KYCPersonalityReviewView.swift
|   |   |-- PersonalityReviewEndView.swift
|   |   |-- KYCChatView.swift
|   |   |-- KYCEndView.swift
|   |   |-- GoalOnboardingChatView.swift
|   |   |-- Components/
|   |       |-- GenderChip.swift
|   |       |-- CitySearchField.swift
|   |       |-- ChatBubbleLoadingIndicator.swift
|   |
|   |-- Subscription/
|   |   |-- SubscriptionView.swift (paywall UI with monthly/yearly plans, restore purchase)
|   |
|   |-- Resources/
|       |-- ... (shared images/assets, etc.)
|   |-- Home/
|   |   |-- HomeDailyTasksView.swift (homepage shell with tabs for daily tasks, goals, etc.)
|   |   |-- HomeDailyTasksViewModel.swift
|   |   |-- Components/
|   |   |   |-- HomeHeaderView.swift (header with greeting, date, fortune guide)
|   |   |   |-- HomeBottomTabBar.swift (bottom tab bar with HomeTab enum)
|   |   |   |-- TaskExecutionOverlay.swift (task detail card, loading, confirmations)
|   |   |   |-- CelebrationOverlay.swift (celebration animation on task completion)
|   |   |   |-- SplashView.swift (splash screen during initial app loading)
|   |   |-- GoalWizard/
|   |   |   |-- GoalWizardView.swift (standalone goal creation wizard triggered from chat)
|   |   |-- DailyTasks/
|   |   |   |-- DailyTasksPageView.swift (page body for "每日待办" tab, includes WeeklyCalendarWidget)
|   |   |   |-- TaskForTodayView.swift (widget for today's tasks)
|   |   |-- GoalTracking/
|   |   |   |-- GoalTrackingPageView.swift (page body for "目标追踪" tab)
|   |   |   |-- GoalTrackingSectionView.swift (goal tracking section with milestone timeline)
|   |   |   |-- GoalTrackingViewModel.swift (state management and API calls for goal tracking)
|   |   |   |-- GoalEditDialogs.swift (edit dialogs for goal, milestone, task updates)
|   |   |   |-- MilestoneTimelineView.swift (horizontal scrollable milestone timeline)
|   |   |   |-- MilestoneCardView.swift (individual milestone card with tasks)
|   |   |   |-- MilestoneStateHelpers.swift (milestone state enum and styling helpers)
|   |   |   |-- ExpiredMilestoneWizardView.swift (wizard for handling expired milestones)
|   |   |-- DailyTasksSectionView.swift (daily tasks list and empty state)
|   |   |-- DailyFortuneCardView.swift (overlay card for fortune details)
|   |   |-- TaskExecutionCardView.swift (modal card for executing a single task)
|   |-- Chat/
|   |   |-- ChatView.swift (main AI companion chat page)
|   |   |-- ChatViewModel.swift (MVVM logic for ChatView)
|   |   |-- Components/
|   |       |-- ChatHeader.swift
|   |       |-- ChatBubble.swift
|   |       |-- ChatDateDivider.swift
|   |       |-- ChatInputArea.swift
|
|-- AICompanion.xcodeproj/
|   |-- ... (Xcode project configuration)
|
|-- Resources/
|   |-- ... (project-level resources)
|
|-- python_script/
|   |-- next_task.py
|
|-- ref_docs/
|   |-- api_docs/
|   |   |-- ... (API-related docs)
|   |-- onboarding_prd.md
|   |-- prd.md
|   |-- project_structure.md (this file)
|   |-- ui_text_suggestions.md (UI copy review and wording suggestions)
```
