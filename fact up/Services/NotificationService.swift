import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    // UserDefaults keys
    private let notificationsEnabledKey = "notificationsEnabled"
    private let notificationFrequencyKey = "notificationFrequency"
    private let notificationStartTimeKey = "notificationStartTime"
    private let notificationEndTimeKey = "notificationEndTime"
    
    // Default values
    private let defaultFrequency = 5
    private let defaultStartHour = 8
    private let defaultEndHour = 22
    
    // Computed properties for settings
    var startHour: Int {
        return UserDefaults.standard.integer(forKey: notificationStartTimeKey)
    }
    
    var endHour: Int {
        return UserDefaults.standard.integer(forKey: notificationEndTimeKey)
    }
    
    // Sample facts for notifications
    private let sampleFacts = [
        "Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible.",
        "The shortest war in history was between Britain and Zanzibar on August 27, 1896. Zanzibar surrendered after 38 minutes.",
        "The average person will spend six months of their life waiting for red lights to turn green.",
        "A day on Venus is longer than a year on Venus. Venus rotates so slowly that it takes 243 Earth days to complete one rotation, but it orbits the Sun every 225 Earth days.",
        "Octopuses have three hearts, nine brains, and blue blood.",
        "The world's oldest known living tree is a Great Basin bristlecone pine in the White Mountains of California. It's estimated to be over 5,000 years old.",
        "Cows have best friends and get stressed when they are separated.",
        "A bolt of lightning is about 54,000°F (30,000°C), which is six times hotter than the surface of the sun.",
        "The Hawaiian alphabet has only 12 letters: A, E, I, O, U, H, K, L, M, N, P, and W.",
        "Bananas are berries, but strawberries are not."
    ]
    
    private init() {
        // Set default values if not already set
        if UserDefaults.standard.object(forKey: notificationFrequencyKey) == nil {
            UserDefaults.standard.set(defaultFrequency, forKey: notificationFrequencyKey)
        }
        
        if UserDefaults.standard.object(forKey: notificationStartTimeKey) == nil {
            UserDefaults.standard.set(defaultStartHour, forKey: notificationStartTimeKey)
        }
        
        if UserDefaults.standard.object(forKey: notificationEndTimeKey) == nil {
            UserDefaults.standard.set(defaultEndHour, forKey: notificationEndTimeKey)
        }
    }
    
    // MARK: - Permission Handling
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // If permission granted, schedule notifications
                    if self.isNotificationsEnabled {
                        self.scheduleNotifications()
                    }
                }
                completion(granted)
            }
        }
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isEnabled = settings.authorizationStatus == .authorized
                completion(isEnabled)
            }
        }
    }
    
    // MARK: - Notification Management
    
    func toggleNotifications(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: notificationsEnabledKey)
        
        if enabled {
            // Schedule notifications if enabled
            scheduleNotifications(sendConfirmation: true)
        } else {
            // Remove all pending notifications if disabled
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    func updateNotificationSettings(enabled: Bool, frequency: Int, startHour: Int, endHour: Int) {
        // Validate input
        let validFrequency = max(1, min(frequency, 10)) // Between 1 and 10
        let validStartHour = max(0, min(startHour, 23)) // Between 0 and 23
        let validEndHour = max(validStartHour + 1, min(endHour, 24)) // At least 1 hour after start, max 24
        
        // Save settings
        UserDefaults.standard.set(enabled, forKey: notificationsEnabledKey)
        UserDefaults.standard.set(validFrequency, forKey: notificationFrequencyKey)
        UserDefaults.standard.set(validStartHour, forKey: notificationStartTimeKey)
        UserDefaults.standard.set(validEndHour, forKey: notificationEndTimeKey)
        
        if enabled {
            // Reschedule notifications with new settings
            scheduleNotifications(sendConfirmation: true)
            
            // Also schedule a notification to happen soon
            scheduleNextNotificationSoon()
        } else {
            // Remove all pending notifications if disabled
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotifications(sendConfirmation: Bool = false) {
        // First, remove any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // If notifications are not enabled, don't schedule any
        if !isNotificationsEnabled {
            return
        }
        
        // Get settings
        let frequency = notificationFrequency
        let startTime = startHour
        let endTime = endHour
        
        // Calculate time window in hours
        let timeWindowHours = endTime - startTime
        
        // If time window is invalid, don't schedule
        if timeWindowHours <= 0 {
            return
        }
        
        // If we should send a confirmation, do it first
        if sendConfirmation {
            sendConfirmationNotification()
        }
        
        // Schedule for the next 7 days
        for day in 0..<7 {
            // Schedule 'frequency' notifications per day
            for notificationIndex in 0..<frequency {
                // Calculate time interval between notifications
                let intervalHours = Double(timeWindowHours) / Double(frequency)
                
                // Calculate hour of the day for this notification (distribute evenly)
                let notificationHour = Double(startTime) + (Double(notificationIndex) * intervalHours)
                
                // Add some randomness within the hour
                let minutesOffset = Int.random(in: 0..<60)
                
                // Create date components for the notification
                var dateComponents = DateComponents()
                dateComponents.hour = Int(notificationHour)
                dateComponents.minute = minutesOffset
                
                // Get the current date components
                let currentDate = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                
                // Add the day offset
                if let currentDay = currentDate.day {
                    dateComponents.day = currentDay + day
                }
                dateComponents.month = currentDate.month
                dateComponents.year = currentDate.year
                
                // Create the trigger
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                // Get a random fact
                let factText = sampleFacts.randomElement() ?? "Did you know? Facts are interesting!"
                
                // Create the notification content
                let content = UNMutableNotificationContent()
                content.title = "Fact Up!"
                content.body = factText
                content.sound = UNNotificationSound.default
                
                // Create the request
                let identifier = "FactNotification-\(day)-\(notificationIndex)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Add the notification request using async/await
                Task {
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        print("Scheduled \(frequency * 7) notifications for the next 7 days")
    }
    
    // MARK: - Test Notification
    
    func sendTestNotification(completion: @escaping (Bool) -> Void) {
        // First check if notifications are permitted
        checkNotificationStatus { isEnabled in
            if !isEnabled {
                // Request permission if not already granted
                self.requestNotificationPermission { granted in
                    if granted {
                        self.triggerTestNotification(completion: completion)
                    } else {
                        completion(false)
                    }
                }
            } else {
                self.triggerTestNotification(completion: completion)
            }
        }
    }
    
    private func triggerTestNotification(completion: @escaping (Bool) -> Void) {
        // Get a random fact for the test notification
        let factText = sampleFacts.randomElement() ?? "This is a test notification from Fact Up!"
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Fact Up! (Test)"
        content.body = factText
        content.sound = UNNotificationSound.default
        
        // Create a trigger for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create the request
        let identifier = "TestNotification-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the notification request using async/await
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
                DispatchQueue.main.async {
                    print("Test notification scheduled successfully!")
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error sending test notification: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Settings Management
    
    var isNotificationsEnabled: Bool {
        return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }
    
    var notificationFrequency: Int {
        return UserDefaults.standard.integer(forKey: notificationFrequencyKey)
    }
    
    // MARK: - Helper Methods
    
    private func sendConfirmationNotification() {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Notifications Enabled"
        content.body = "You'll receive \(notificationFrequency) interesting facts per day between \(formatHour(startHour)) and \(formatHour(endHour))."
        content.sound = UNNotificationSound.default
        
        // Create a trigger for 3 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        // Create the request
        let identifier = "ConfirmationNotification-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the notification request using async/await
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("Confirmation notification scheduled")
            } catch {
                print("Error scheduling confirmation notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNextNotificationSoon() {
        // Get a random fact
        let factText = sampleFacts.randomElement() ?? "Did you know? Facts are interesting!"
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Fact Up!"
        content.body = factText
        content.sound = UNNotificationSound.default
        
        // Create a trigger for 10-20 minutes from now
        let minutes = Int.random(in: 10...20)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        
        // Create the request
        let identifier = "FirstScheduledNotification-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the notification request using async/await
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("First scheduled notification set for \(minutes) minutes from now")
            } catch {
                print("Error scheduling first notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let hourValue = hour % 24
        let isPM = hourValue >= 12
        let hour12 = hourValue == 0 ? 12 : (hourValue > 12 ? hourValue - 12 : hourValue)
        return "\(hour12) \(isPM ? "PM" : "AM")"
    }
} 