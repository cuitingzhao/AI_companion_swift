import SwiftUI

// MARK: - Custom Toggle Style

/// A custom toggle style with a perfectly round knob
/// Usage: Toggle("Label", isOn: $value).toggleStyle(RoundKnobToggleStyle())
struct RoundKnobToggleStyle: ToggleStyle {
    var onColor: Color = AppColors.neoPurple
    var offColor: Color = AppColors.neutralGray.opacity(0.3)
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack {
                // Track
                Capsule()
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 50, height: 30)
                
                // Knob - perfectly round circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - App Toggle Component

/// A standalone reusable toggle component with round knob
/// Usage: AppToggle(isOn: $value) or AppToggle(isOn: $value, onColor: .green)
struct AppToggle: View {
    @Binding var isOn: Bool
    var onColor: Color = AppColors.neoPurple
    var offColor: Color = AppColors.neutralGray.opacity(0.3)
    
    var body: some View {
        ZStack {
            // Track
            Capsule()
                .fill(isOn ? onColor : offColor)
                .frame(width: 50, height: 30)
            
            // Knob - perfectly round circle
            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                .offset(x: isOn ? 10 : -10)
        }
        .animation(.easeInOut(duration: 0.2), value: isOn)
        .onTapGesture {
            isOn.toggle()
        }
    }
}

// MARK: - Preview

#Preview("AppToggle") {
    struct PreviewWrapper: View {
        @State private var isOn = false
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    Text("Default Toggle")
                    Spacer()
                    AppToggle(isOn: $isOn)
                }
                
                HStack {
                    Text("Custom Color")
                    Spacer()
                    AppToggle(isOn: $isOn, onColor: .green)
                }
                
                HStack {
                    Text("Using Toggle Style")
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .toggleStyle(RoundKnobToggleStyle())
                        .labelsHidden()
                }
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
