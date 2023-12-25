//
//  SecondShowApp.swift
//  SecondShow
//
//  Created by Alan on 11/12/23.
//

import SwiftUI
import FirebaseMessaging
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let _ = FirebaseManager.shared
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
                
        // Register for remote notifications
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions) { _, err in
                if let err = err {
                    print("Error requesting authorization for notifications: \(err.localizedDescription)")
                }
                print("Successfully registered for notifications")
            }
        application.registerForRemoteNotifications()
        
        return true;
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcm = Messaging.messaging().fcmToken {
            if let email = FirebaseManager.shared.auth.currentUser?.email {
                FirebaseManager.shared.firestore
                    .collection("users")
                    .document(email)
                    .updateData([FirebaseConstants.fcmToken: fcm])
            }
        }
//        print("AT MESSAGING FCM TOKEN FUNC")
//        if let fcm = Messaging.messaging().fcmToken {
//            print("fcm token:\(fcm)")
//        } else {
//            print("fcm token is nil")
//        }
//        guard let uid = FirebaseManager.shared.currentUser?.uid else { return }
//        let fcm = Messaging.messaging().fcmToken
//
//        FirebaseManager.shared.firestore.collection("users").document(uid).updateData(["fcmToken": fcmToken ?? ""])
    }
}

@main
struct SecondShowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
//                    print("ROOT ON APPEAR")
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                }
        }
    }
}