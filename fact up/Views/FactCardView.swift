import SwiftUI

struct FactCardView: View {
    @ObservedObject var viewModel: FactViewModel
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isTransitioning = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with gradient overlay
                ZStack {
                    viewModel.backgroundColor
                    
                    // Gradient overlay for better text readability
                    LinearGradient(
                        gradient: Gradient(colors: [
                            viewModel.backgroundColor.opacity(0.1),
                            viewModel.backgroundColor.opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
                
                // Subtle pattern overlay
                Color.white.opacity(0.03)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Fact Text
                    if let fact = viewModel.currentFact {
                        VStack(spacing: 60) {
                            // Add spacer at the top to push content down
                            Spacer().frame(height: 40)
                            
                            // Fact card with text
                            VStack(spacing: 16) {
                                // Show translated text if available, otherwise show original
                                Text(fact.translatedText ?? fact.text)
                                    .font(.system(size: 24, weight: .medium, design: .serif))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                                    .lineSpacing(8)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                // Show translation language indicator if translated
                                if let language = viewModel.currentTranslationLanguage {
                                    HStack {
                                        Image(systemName: "globe")
                                            .font(.caption)
                                        Text("Translated to \(language.displayName)")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Action buttons that move with the fact - reduced spacing to move buttons lower
                            HStack(spacing: 25) {
                                // Favorite button
                                ActionButton(
                                    icon: fact.isFavorite ? "heart.fill" : "heart",
                                    isActive: fact.isFavorite,
                                    action: { viewModel.toggleFavorite() }
                                )
                                
                                // Speech button - made larger and more prominent
                                ActionButton(
                                    icon: viewModel.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2",
                                    isActive: viewModel.isSpeaking,
                                    size: 22,
                                    action: {
                                        if viewModel.isSpeaking {
                                            viewModel.stopSpeaking()
                                        } else {
                                            viewModel.speakCurrentFact()
                                        }
                                    }
                                )
                                
                                // Translate button
                                ActionButton(
                                    icon: "translate",
                                    isActive: viewModel.isCurrentFactTranslated,
                                    action: { viewModel.showTranslationOptions = true }
                                )
                                
                                // Share button
                                ActionButton(
                                    icon: "square.and.arrow.up",
                                    action: { viewModel.shareFact() }
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30) // Add padding at the bottom to position buttons closer to bottom
                        }
                        .offset(y: dragOffset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Allow swiping up and down
                                    dragOffset = value.translation
                                    isDragging = true
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 60
                                    
                                    if value.translation.height < -threshold {
                                        // Swipe up to get new fact
                                        isTransitioning = true
                                        
                                        // Stop any ongoing speech when changing facts
                                        if viewModel.isSpeaking {
                                            viewModel.stopSpeaking()
                                        }
                                        
                                        // Slide current fact up and off screen
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            dragOffset.height = -geometry.size.height - 100
                                        }
                                        
                                        // Load new fact after current one slides off
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.loadNewFact()
                                            
                                            // Reset position for new fact (slides up from bottom)
                                            dragOffset.height = geometry.size.height + 100
                                            
                                            // Slide new fact into position
                                            withAnimation(.easeOut(duration: 0.4)) {
                                                dragOffset = .zero
                                                isDragging = false
                                                isTransitioning = false
                                            }
                                        }
                                    } else if value.translation.height > threshold && viewModel.canGoBack() {
                                        // Swipe down to get previous fact
                                        isTransitioning = true
                                        
                                        // Stop any ongoing speech when changing facts
                                        if viewModel.isSpeaking {
                                            viewModel.stopSpeaking()
                                        }
                                        
                                        // Slide current fact down and off screen
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            dragOffset.height = geometry.size.height + 100
                                        }
                                        
                                        // Load previous fact after current one slides off
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            viewModel.loadPreviousFact()
                                            
                                            // Reset position for previous fact (slides down from top)
                                            dragOffset.height = -geometry.size.height - 100
                                            
                                            // Slide previous fact into position
                                            withAnimation(.easeOut(duration: 0.4)) {
                                                dragOffset = .zero
                                                isDragging = false
                                                isTransitioning = false
                                            }
                                        }
                                    } else {
                                        // Return to center if not past threshold
                                        withAnimation(.spring()) {
                                            dragOffset = .zero
                                            isDragging = false
                                        }
                                    }
                                }
                        )
                        
                        // Add an invisible overlay that extends the swipe area to the bottom of the screen
                        // This doesn't affect visual layout but makes the entire area swipeable
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .frame(height: geometry.size.height * 0.4)
                            .position(x: geometry.size.width / 2, y: geometry.size.height - 80)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Allow swiping up and down
                                        dragOffset = value.translation
                                        isDragging = true
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 60
                                        
                                        if value.translation.height < -threshold {
                                            // Swipe up to get new fact
                                            isTransitioning = true
                                            
                                            // Stop any ongoing speech when changing facts
                                            if viewModel.isSpeaking {
                                                viewModel.stopSpeaking()
                                            }
                                            
                                            // Slide current fact up and off screen
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                dragOffset.height = -geometry.size.height - 100
                                            }
                                            
                                            // Load new fact after current one slides off
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                viewModel.loadNewFact()
                                                
                                                // Reset position for new fact (slides up from bottom)
                                                dragOffset.height = geometry.size.height + 100
                                                
                                                // Slide new fact into position
                                                withAnimation(.easeOut(duration: 0.4)) {
                                                    dragOffset = .zero
                                                    isDragging = false
                                                    isTransitioning = false
                                                }
                                            }
                                        } else {
                                            // Return to center if not past threshold
                                            withAnimation(.spring()) {
                                                dragOffset = .zero
                                                isDragging = false
                                            }
                                        }
                                    }
                            )
                    } else if viewModel.isLoading {
                        // Loading state
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Loading fact...")
                                .foregroundColor(.white)
                                .padding(.top, 20)
                        }
                    } else {
                        // Error state
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text("Failed to load fact")
                                .foregroundColor(.white)
                                .font(.title3)
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                viewModel.loadNewFact()
                            }) {
                                Text("Try Again")
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.backgroundColor)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    
                    // Bottom controls (fixed position)
                    HStack {
                        // Category button
                        Button(action: {
                            viewModel.showingSettings = true
                        }) {
                            HStack(spacing: 6) {
                                Text(viewModel.selectedCategory.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                        }
                        
                        Spacer()
                        
                        // Wallpaper customization button
                        Button(action: {
                            // Cycle through colors
                            let colors: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .indigo]
                            if let currentIndex = colors.firstIndex(of: viewModel.backgroundColor) {
                                let nextIndex = (currentIndex + 1) % colors.count
                                viewModel.changeBackgroundColor(colors[nextIndex])
                            }
                        }) {
                            Image(systemName: "paintbrush")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                        .padding(.trailing, 10)
                        
                        // Settings button
                        Button(action: {
                            viewModel.showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
                
                // Translation options popup
                if viewModel.showTranslationOptions {
                    VStack {
                        Spacer()
                        
                        TranslationOptionsView(
                            viewModel: viewModel,
                            isPresented: $viewModel.showTranslationOptions
                        )
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 80)
                    }
                    .background(
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                viewModel.showTranslationOptions = false
                            }
                    )
                    .zIndex(1)
                    .animation(.easeInOut, value: viewModel.showTranslationOptions)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

// Action button component
struct ActionButton: View {
    let icon: String
    var isActive: Bool = false
    var size: CGFloat = 20
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(isActive ? .white : .white.opacity(0.9))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    FactCardView(viewModel: FactViewModel())
} 
