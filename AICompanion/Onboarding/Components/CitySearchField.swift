import SwiftUI

public struct CitySearchField: View {
    @Binding private var text: String
    private let onSelect: (City) -> Void

    @State private var results: [City] = []
    @State private var isLoading: Bool = false
    @State private var showDropdown: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil
    @FocusState private var isTextFieldFocused: Bool

    public init(text: Binding<String>, onSelect: @escaping (City) -> Void) {
        self._text = text
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                TextField("", text: $text)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textDark)
                    .placeholder(when: text.isEmpty) {
                        Text("出生地点")
                            .foregroundStyle(AppColors.textLight)
                            .font(AppFonts.body)
                    }
                    .focused($isTextFieldFocused)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppColors.bgCream)
            .cornerRadius(CuteClean.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: CuteClean.radiusMedium)
                    .stroke(AppColors.cutePink.opacity(0.2), lineWidth: 1)
            )
            .onAppear {
                // Auto-focus the text field when the view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
            .onChange(of: text) { _, newValue in
                performSearchDebounced(for: newValue)
            }

            if showDropdown {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(results) { city in
                        Button {
                            text = city.name
                            showDropdown = false
                            onSelect(city)
                        } label: {
                            HStack {
                                Text(city.name)
                                    .foregroundStyle(AppColors.textBlack)
                                    .font(AppFonts.small)
                                if let admin = city.admin, !admin.isEmpty {
                                    Text("·")
                                        .foregroundStyle(AppColors.neutralGray)
                                    Text(admin)
                                        .foregroundStyle(AppColors.neutralGray)
                                        .font(AppFonts.small)
                                }
                                Spacer()
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)

                        if city.id != results.last?.id {
                            Divider()
                        }
                    }

                    if results.isEmpty && !text.isEmpty && !isLoading {
                        Text("没有匹配的城市")
                            .foregroundStyle(AppColors.neutralGray)
                            .font(AppFonts.small)
                            .padding(14)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16).fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(AppColors.textBlack, lineWidth: 1)
                )
            }
        }
        .onDisappear { searchTask?.cancel() }
    }

    private func performSearchDebounced(for query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            showDropdown = false
            isLoading = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await search(query: query)
        }
    }

    @MainActor
    private func search(query: String) async {
        isLoading = true
        do {
            let cities = try await CitiesAPI.shared.searchCities(query: query, limit: 10)
            if Task.isCancelled { return }
            results = cities
            showDropdown = true
        } catch {
            results = []
            showDropdown = true
        }
        isLoading = false
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                content()
            }
            self
        }
    }
}
