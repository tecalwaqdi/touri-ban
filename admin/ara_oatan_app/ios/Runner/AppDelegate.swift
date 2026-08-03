import UIKit
import Braintree

import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM")
    GeneratedPluginRegistrant.register(with: self)
    BTAppContextSwitcher.setReturnURLScheme("com.mycompany.araoatanapp2.braintree")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
