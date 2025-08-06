//
//  fact_upApp.swift
//  fact up
//
//  Created by Michael Kot on 8/5/25.
//

import SwiftUI
import UserNotifications
import AVFoundation

@main
struct fact_upApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var factViewModel = FactViewModel()

    init() {
        // Configure audio session to continue playing when the screen is locked
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(factViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Check notification status and schedule if enabled
        NotificationService.shared.checkNotificationStatus { isEnabled in
            if isEnabled {
                NotificationService.shared.scheduleNotifications()
            }
        }

        return true
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap here if needed
        completionHandler()
    }
}
