# AICompanion Project Structure

```text
AICompanion/
|-- AICompanion/
|   |-- AICompanionApp.swift (app entry point)
|   |-- TaskForTodayView.swift (daily task overview after onboarding)
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
|   |-- DesignSystem/
|   |   |-- Colors.swift
|   |   |-- Fonts.swift
|   |   |-- Components/
|   |       |-- PrimaryButton.swift
|   |       |-- AppTextField.swift
|   |       |-- VoiceInputButton.swift
|   |       |-- AppDialog.swift
|   |       |-- FloatingChatButton.swift (floating action button for chat)
|   |       |-- Toast.swift (toast notification component)
|   |
|   |-- Networking/
|   |   |-- CitiesAPI.swift
|   |   |-- OnboardingAPI.swift
|   |   |-- ProfileAPI.swift
|   |   |-- GoalsAPI.swift
|   |   |-- CalendarAPI.swift (GET /api/v1/utils/calendar/today)
|   |   |-- FortuneAPI.swift (GET /api/v1/fortune/daily)
|   |   |-- ExecutionsAPI.swift (PATCH /api/v1/executions/{execution_id})
|   |   |-- ChatAPI.swift (POST /api/v1/chat/message)
|   |
|   |-- Services/
|   |   |-- LocationService.swift
|   |   |-- PermissionManager.swift (JIT permission requests for iOS native tools)
|   |   |-- NativeToolExecutor.swift (executes calendar, alarm, health, screen time actions)
|   |
|   |-- Onboarding/
|   |   |-- OnboardingState.swift
|   |   |-- OnboardingScaffold.swift
|   |   |-- OnboardingHeader.swift
|   |   |-- OnboardingIntroView.swift
|   |   |-- OnboardingNicknameView.swift
|   |   |-- OnboardingProfileView.swift
|   |   |-- OnboardingLoadingView.swift
|   |   |-- BaziAnalysisResultView.swift
|   |   |-- KYCIntroView.swift
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
|   |   |-- HomeDailyTasksViewModel.swift (view model for home tabs: daily tasks, goals, fortune)
|   |   |-- DailyTasks/
|   |   |   |-- DailyTasksPageView.swift (page body for "每日待办" tab)
|   |   |-- GoalTracking/
|   |   |   |-- GoalTrackingPageView.swift (page body for "目标追踪" tab)
|   |   |-- GoalTrackingSectionView.swift (goal tracking tab UI)
|   |   |-- DailyTasksSectionView.swift (daily tasks list and empty state)
|   |   |-- DailyFortuneCardView.swift (overlay card for fortune details)
|   |   |-- TaskExecutionCardView.swift (modal card for executing a single task)
|   |-- HomeDailyTasksView.swift (homepage shell with tabs for daily tasks, goals, etc.)
|   |-- Chat/
|   |   |-- ChatView.swift (main AI companion chat page)
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
