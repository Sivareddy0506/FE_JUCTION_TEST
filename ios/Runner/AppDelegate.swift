import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleMaps
import AVFoundation
import CoreLocation
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps SDK
    var apiKey: String?
    
    // Try to get from GoogleService-Info.plist first
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let key = plist["API_KEY"] as? String {
      apiKey = key
    }
    
    // Fallback to Info.plist (with variable substitution)
    if apiKey == nil || apiKey?.isEmpty == true {
      if let infoPlist = Bundle.main.infoDictionary,
         let key = infoPlist["GMSApiKey"] as? String,
         !key.isEmpty && !key.contains("$(GOOGLE_MAPS_API_KEY)") {
        apiKey = key
      }
    }
    
    if let key = apiKey, !key.isEmpty {
      GMSServices.provideAPIKey(key)
      print("✅ Google Maps SDK initialized with API key")
    } else {
      print("⚠️ Warning: Could not find Google Maps API key. Please set GOOGLE_MAPS_API_KEY in Secrets.xcconfig")
    }
    
    // Note: Firebase is initialized in Flutter (main.dart), not here
    // Calling FirebaseApp.configure() here causes duplicate initialization error
    
    // Set notification center delegate BEFORE requesting permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // Set FCM messaging delegate
    // Note: This should be set after Firebase is initialized in Flutter
    // But we set it here so it's ready when Firebase initializes
    Messaging.messaging().delegate = self
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    
    // Config channel for API keys
    let configChannel = FlutterMethodChannel(
      name: "com.junction.config",
      binaryMessenger: controller.binaryMessenger
    )
    
    configChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getGoogleMapsApiKey" {
        var apiKey: String?
        
        // Try to get from GoogleService-Info.plist first
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["API_KEY"] as? String {
          apiKey = key
        }
        
        // Fallback to Info.plist
        if apiKey == nil || apiKey?.isEmpty == true {
          if let infoPlist = Bundle.main.infoDictionary,
             let key = infoPlist["GMSApiKey"] as? String,
             !key.isEmpty && !key.contains("$(GOOGLE_MAPS_API_KEY)") {
            apiKey = key
          }
        }
        
        if let key = apiKey, !key.isEmpty {
          result(key)
        } else {
          result(FlutterError(code: "API_KEY_NOT_FOUND", message: "Google Maps API key not found", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Permission channel
    let permissionChannel = FlutterMethodChannel(
      name: "com.junction.permissions",
      binaryMessenger: controller.binaryMessenger
    )
    
    permissionChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "checkPermission" else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      guard let args = call.arguments as? [String: Any],
            let permission = args["permission"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Permission name required", details: nil))
        return
      }
      
      var status: String = "denied"
      
      switch permission {
      case "camera":
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .authorized:
          status = "granted"
        case .denied, .restricted:
          status = "denied"
        case .notDetermined:
          status = "notDetermined"
        @unknown default:
          status = "denied"
        }
        
      case "location":
        let authStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
          authStatus = CLLocationManager().authorizationStatus
        } else {
          authStatus = CLLocationManager.authorizationStatus()
        }
        switch authStatus {
        case .authorizedWhenInUse, .authorizedAlways:
          status = "granted"
        case .denied, .restricted:
          status = "denied"
        case .notDetermined:
          status = "notDetermined"
        @unknown default:
          status = "denied"
        }
        
      case "notifications":
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().getNotificationSettings { settings in
            var notificationStatus: String = "denied"
            switch settings.authorizationStatus {
            case .authorized, .provisional:
              notificationStatus = "granted"
            case .denied:
              notificationStatus = "denied"
            case .notDetermined:
              notificationStatus = "notDetermined"
            case .ephemeral:
              notificationStatus = "granted"
            @unknown default:
              notificationStatus = "denied"
            }
            result(notificationStatus)
          }
          return
        } else {
          status = "granted"
        }
        
      default:
        result(FlutterError(code: "UNKNOWN_PERMISSION", message: "Unknown permission: \(permission)", details: nil))
        return
      }
      
      result(status)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNS token
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Set APNS token for FCM
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNS token registered and set for FCM")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle APNS token registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("✅ Firebase FCM registration token received: \(fcmToken?.prefix(20) ?? "nil")...")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

// MARK: - UNUserNotificationCenterDelegate
@available(iOS 10, *)
extension AppDelegate {
  // Receive displayed notifications for iOS 10+ devices when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📱 [iOS] Notification received in foreground: \(userInfo)")
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .badge, .sound]])
    } else {
      completionHandler([[.alert, .badge, .sound]])
    }
  }
  
  // Handle notification tap when app is in background or terminated
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📱 [iOS] Notification tapped: \(userInfo)")
    
    // Forward to Flutter if needed
    // The Flutter side will handle navigation via onMessageOpenedApp or getInitialMessage
    completionHandler()
  }
}
