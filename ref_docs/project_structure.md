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
|   |   |-- APIClient.swift (shared API client with auth header injection)
|   |   |-- AuthAPI.swift (authentication endpoints: SMS, verify, refresh, me)
|   |   |-- CitiesAPI.swift
|   |   |-- OnboardingAPI.swift
|   |   |-- ProfileAPI.swift
|   |   |-- GoalsAPI.swift
|   |   |-- CalendarAPI.swift (GET /api/v1/utils/calendar/today)
|   |   |-- FortuneAPI.swift (GET /api/v1/fortune/daily)
|   |   |-- ExecutionsAPI.swift (PATCH /api/v1/executions/{execution_id})
|   |   |-- ChatAPI.swift (POST /api/v1/chat/message)
|   |   |-- MediaAPI.swift (POST /api/v1/media/upload/image for image uploads)
|   |   |-- NotificationsAPI.swift (POST /api/v1/notifications/device-token for push notifications)
|   |
|   |-- Services/
|   |   |-- AuthManager.swift (Keychain token storage, auth state management)
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
