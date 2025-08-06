import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var isNotificationsEnabled = false
    @State private var notificationFrequency: Double = 5
    @State private var startHour: Double = 8
    @State private var endHour: Double = 22
    
    @State private var showingPermissionAlert = false
    @State private var showingConfirmationAlert = false
    @State private var showingTestNotificationAlert = false
    @State private var testNotificationSuccess = false
    @State private var isTestingNotification = false
    
    private func formatHour(_ hour: Int) -> String {
        let hourValue = hour % 24
        let isPM = hourValue >= 12
        let hour12 = hourValue == 0 ? 12 : (hourValue > 12 ? hourValue - 12 : hourValue)
        return "\(hour12) \(isPM ? "PM" : "AM")"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Enable Notifications Card
                        NotificationCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: isNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(isNotificationsEnabled ? .blue : .gray)
                                        .frame(width: 30)
                                    
                                    Toggle("Enable Notifications", isOn: $isNotificationsEnabled)
                                        .onChange(of: isNotificationsEnabled) { oldValue, newValue in
                                            if newValue {
                                                // Request permission if enabling
                                                notificationService.requestNotificationPermission { granted in
                                                    if !granted {
                                                        // Show alert if permission denied
                                                        showingPermissionAlert = true
                                                        isNotificationsEnabled = false
                                                    }
                                                }
                                            } else {
                                                // Disable notifications
                                                notificationService.toggleNotifications(enabled: false)
                                            }
                                        }
                                }
                                
                                Text("Get interesting facts delivered throughout the day, even when the app isn't open.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // Test Notification Card
                        NotificationCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.orange)
                                        .frame(width: 30)
                                    
                                    Text("Test Notifications")
                                        .font(.headline)
                                }
                                
                                Text("Send a test notification to verify that notifications are working correctly. The notification will appear in about 5 seconds.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Button(action: {
                                    isTestingNotification = true
                                    notificationService.sendTestNotification { success in
                                        isTestingNotification = false
                                        testNotificationSuccess = success
                                        showingTestNotificationAlert = true
                                    }
                                }) {
                                    HStack {
                                        Text("Send Test Notification")
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        if isTestingNotification {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Image(systemName: "paperplane.fill")
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue)
                                    )
                                    .foregroundColor(.white)
                                }
                                .disabled(isTestingNotification)
                            }
                        }
                        
                        if isNotificationsEnabled {
                            // Frequency Card
                            NotificationCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "number.circle.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.blue)
                                            .frame(width: 30)
                                        
                                        Text("Daily Frequency")
                                            .font(.headline)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\(Int(notificationFrequency)) notifications per day")
                                            .fontWeight(.medium)
                                        
                                        Slider(value: $notificationFrequency, in: 1...10, step: 1)
                                            .accentColor(.blue)
                                        
                                        Text("How many facts would you like to receive each day?")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Time Window Card
                            NotificationCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.blue)
                                            .frame(width: 30)
                                        
                                        Text("Time Window")
                                            .font(.headline)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Start Time
                                        Text("Start time: \(formatHour(Int(startHour)))")
                                            .fontWeight(.medium)
                                        
                                        HStack {
                                            Image(systemName: "sunrise.fill")
                                                .foregroundColor(.orange)
                                            
                                            Slider(value: $startHour, in: 0...23, step: 1)
                                                .accentColor(.orange)
                                                .onChange(of: startHour) { oldValue, newValue in
                                                    // Make sure end time is always after start time
                                                    if endHour <= newValue {
                                                        endHour = newValue + 1
                                                    }
                                                }
                                        }
                                        
                                        // End Time
                                        Text("End time: \(formatHour(Int(endHour)))")
                                            .fontWeight(.medium)
                                        
                                        HStack {
                                            Image(systemName: "sunset.fill")
                                                .foregroundColor(.purple)
                                            
                                            Slider(value: $endHour, in: (startHour + 1)...24, step: 1)
                                                .accentColor(.purple)
                                        }
                                        
                                        Text("Notifications will only be sent during this time window.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Preview Card
                            NotificationCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "eye.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.blue)
                                            .frame(width: 30)
                                        
                                        Text("Preview")
                                            .font(.headline)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("You'll receive \(Int(notificationFrequency)) notifications per day")
                                            .fontWeight(.medium)
                                        
                                        Text("Between \(formatHour(Int(startHour))) and \(formatHour(Int(endHour)))")
                                            .foregroundColor(.secondary)
                                        
                                        Text("After saving, you'll receive a confirmation notification and your first fact notification will arrive within 10-20 minutes.")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .padding(.vertical, 8)
                                        
                                        HStack {
                                            Spacer()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Image(systemName: "bell.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.blue)
                                                    
                                                    Text("Fact Up!")
                                                        .font(.system(size: 14, weight: .semibold))
                                                }
                                                
                                                Text("Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible.")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(UIColor.secondarySystemBackground))
                                            )
                                            .frame(width: 280)
                                            
                                            Spacer()
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Update notification settings
                        notificationService.updateNotificationSettings(
                            enabled: isNotificationsEnabled,
                            frequency: Int(notificationFrequency),
                            startHour: Int(startHour),
                            endHour: Int(endHour)
                        )
                        
                        showingConfirmationAlert = true
                    }
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load current notification settings
                isNotificationsEnabled = notificationService.isNotificationsEnabled
                notificationFrequency = Double(notificationService.notificationFrequency)
                startHour = Double(notificationService.startHour)
                endHour = Double(notificationService.endHour)
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable notifications in Settings to receive fact updates.")
            }
            .alert(testNotificationSuccess ? "Test Notification Sent" : "Test Failed", isPresented: $showingTestNotificationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(testNotificationSuccess ? 
                     "A test notification has been sent. You should receive it in a few seconds." : 
                     "Failed to send test notification. Please check notification permissions in Settings.")
            }
            .alert("Notification Settings Saved", isPresented: $showingConfirmationAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your notification preferences have been saved. You'll receive a confirmation notification shortly, and your first scheduled notification will arrive within 10-20 minutes.")
            }
        }
    }
}

struct NotificationCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NotificationSettingsView()
} 