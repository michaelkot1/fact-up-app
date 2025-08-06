import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: FactViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNotificationSettings = false
    @State private var selectedColorIndex: Int = 0
    
    private let backgroundColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .indigo
    ]
    
    private let backgroundColorNames: [String] = [
        "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Mint", "Teal", "Cyan", "Indigo"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                viewModel.backgroundColor.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Categories Card
                        SettingsCard(title: "Categories", icon: "folder.fill") {
                            VStack(spacing: 12) {
                                ForEach(FactCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        viewModel.changeCategory(category)
                                        dismiss()
                                    }) {
                                        HStack {
                                            Text(category.displayName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if viewModel.selectedCategory == category {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(viewModel.backgroundColor)
                                                    .font(.system(size: 18))
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    
                                    if category != FactCategory.allCases.last {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        
                        // Background Color Card
                        SettingsCard(title: "Background Color", icon: "paintpalette.fill") {
                            VStack(spacing: 16) {
                                // Color Grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                                    ForEach(0..<backgroundColors.count, id: \.self) { index in
                                        Button(action: {
                                            viewModel.changeBackgroundColor(backgroundColors[index])
                                            selectedColorIndex = index
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(backgroundColors[index])
                                                    .frame(width: 50, height: 50)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                                
                                                if backgroundColors[index] == viewModel.backgroundColor {
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Selected color name
                                Text(backgroundColorNames[selectedColorIndex])
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 5)
                        }
                        
                        // Favorites Card
                        SettingsCard(title: "Your Favorites", icon: "heart.fill", iconColor: .red) {
                            NavigationLink(destination: FavoritesView(viewModel: viewModel)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("View Favorites")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("\(viewModel.favoriteFacts.count) saved facts")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Notifications Card
                        SettingsCard(title: "Notifications", icon: "bell.fill", iconColor: .blue) {
                            Button(action: {
                                showingNotificationSettings = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notification Settings")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("Configure when you receive facts")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // About Card
                        SettingsCard(title: "About", icon: "info.circle.fill", iconColor: .gray) {
                            HStack {
                                Text("Version")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .onAppear {
                // Set the selected color index based on current background color
                if let index = backgroundColors.firstIndex(where: { $0 == viewModel.backgroundColor }) {
                    selectedColorIndex = index
                }
            }
        }
    }
}

// Custom card view for settings sections
struct SettingsCard: View {
    let title: String
    let icon: String
    var iconColor: Color = .blue
    let content: () -> AnyView
    
    init(title: String, icon: String, iconColor: Color = .blue, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Card content
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

struct FavoritesView: View {
    @ObservedObject var viewModel: FactViewModel
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        ZStack {
            viewModel.backgroundColor.opacity(0.1)
                .edgesIgnoringSafeArea(.all)
            
            if viewModel.favoriteFacts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No favorite facts yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the heart icon on any fact to add it to your favorites")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                List {
                    ForEach(viewModel.favoriteFacts) { fact in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(fact.text)
                                .font(.body)
                                .padding(.bottom, 4)
                            
                            HStack {
                                Text(fact.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.backgroundColor.opacity(0.2))
                                    )
                                    .foregroundColor(viewModel.backgroundColor)
                                
                                Spacer()
                                
                                if editMode == .inactive {
                                    Button(action: {
                                        if let index = viewModel.favoriteFacts.firstIndex(where: { $0.text == fact.text }) {
                                            withAnimation {
                                                viewModel.removeFavorite(at: index)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "heart.slash")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.removeFavorite(at: index)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .environment(\.editMode, $editMode)
            }
        }
        .navigationTitle("Favorite Facts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.favoriteFacts.isEmpty {
                    EditButton()
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: FactViewModel())
} 