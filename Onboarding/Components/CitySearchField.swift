import SwiftUI

public struct CitySearchField: View {
    @Binding private var text: String
    private let onSelect: (City) -> Void

    @State private var results: [City] = []
    @State private var isLoading: Bool = false
    @State private var showDropdown: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    public init(text: Binding<String>, onSelect: @escaping (City) -> Void) {
        self._text = text
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 8) {
            AppTextField("出生地点", text: $text) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .onChange(of: text) { new in
                performSearchDebounced(for: new)
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
                                    .font(AppFonts.body)
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
