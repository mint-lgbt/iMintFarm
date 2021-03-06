//
//  AppDelegate.swift
//  DEV-Simple
//
//  Created by Ben Halpern on 11/1/18.
//  Copyright © 2018 DEV. All rights reserved.
//

import UIKit
import PushNotifications
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setupPushNotifications()
        configureAVAudioSession()
        setupReachability()

        return true
    }

    private func setupPushNotifications() {
        PushNotifications.shared.start(instanceId: "cdaf9857-fad0-4bfb-b360-64c1b2693ef3")
        PushNotifications.shared.registerForRemoteNotifications()
        try? PushNotifications.shared.addDeviceInterest(interest: "broadcast")
    }

    private func configureAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("Failed to set audio session category")
        }
    }

    private func setupReachability() {
        do {
            Network.reachability = try Reachability(hostname: "www.google.com")
            do {
                try Network.reachability?.start()
            } catch let error as Network.Error {
                print(error)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        //This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        //or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers,
        //and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough
        //application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution,
        //this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state;
        //here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        //If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        //See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotifications.shared.registerDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        PushNotifications.shared.handleNotification(userInfo: userInfo)
        let strUrl = userInfo["data"] as? NSDictionary
        guard let url = strUrl?.value(forKeyPath: "url") as? String else {
            return
        }

        let state = application.applicationState
        if url == "REMOVE_NOTIFICATIONS" {
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications()
        } else if state == .inactive { //Tapped by notification
            load(url)
        }

        completionHandler(.noData)
    }

    func load(_ url: String) {
        NotificationCenter.default.post(name: Notification.Name.updateWebView,
                                        object: nil,
                                        userInfo: ["url": url])
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?
        ) -> Void) -> Bool {

        // Open universal links
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              (URLComponents(url: url, resolvingAgainstBaseURL: true) != nil) else {
            return false
        }

        load(url.absoluteString)
        return false
    }
}
