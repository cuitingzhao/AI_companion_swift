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
|   |-- DesignSystem/
|   |   |-- Colors.swift
|   |   |-- Fonts.swift
|   |   |-- Components/
|   |       |-- PrimaryButton.swift
|   |       |-- AppTextField.swift
|   |       |-- VoiceInputButton.swift
|   |       |-- AppDialog.swift
|   |
|   |-- Networking/
|   |   |-- CitiesAPI.swift
|   |   |-- OnboardingAPI.swift
|   |   |-- ProfileAPI.swift
|   |   |-- GoalsAPI.swift
|   |   |-- CalendarAPI.swift (GET /api/v1/utils/calendar/today)
|   |   |-- ExecutionsAPI.swift (PATCH /api/v1/executions/{execution_id})
|   |
|   |-- Services/
|   |   |-- LocationService.swift
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
|   |-- HomeDailyTasksView.swift (homepage "每日任务" tab using calendar + today-plan + executions APIs)
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
