import SwiftUI

struct TranslationOptionsView: View {
    @ObservedObject var viewModel: FactViewModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.backgroundColor)
                
                Text("Translate to")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Language options
            VStack(spacing: 12) {
                ForEach(TranslationLanguage.allCases) { language in
                    LanguageButton(
                        language: language,
                        isSelected: viewModel.currentTranslationLanguage == language,
                        accentColor: viewModel.backgroundColor
                    ) {
                        viewModel.translateCurrentFact(to: language)
                        isPresented = false
                    }
                }
                
                // Reset translation option (only show if currently translated)
                if viewModel.isCurrentFactTranslated {
                    Button(action: {
                        viewModel.resetTranslation()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.backgroundColor)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(viewModel.backgroundColor.opacity(0.1))
                                )
                            
                            Text("Show Original")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal)
        .overlay(
            // Loading indicator
            Group {
                if viewModel.isTranslating {
                    ZStack {
                        Color.black.opacity(0.5)
                            .cornerRadius(20)
                        
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Translating...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        )
    }
}

struct LanguageButton: View {
    let language: TranslationLanguage
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Language flag or icon
                LanguageIcon(language: language)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.1))
                    )
                
                // Language name
                Text(language.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Selected indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 18))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

struct LanguageIcon: View {
    let language: TranslationLanguage
    
    var body: some View {
        Group {
            switch language {
            case .spanish:
                Text("🇪🇸")
                    .font(.system(size: 16))
            case .russian:
                Text("🇷🇺")
                    .font(.system(size: 16))
            case .swedish:
                Text("🇸🇪")
                    .font(.system(size: 16))
            }
        }
    }
} 