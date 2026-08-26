import UIKit
import Flutter
import GoogleMaps
import NISdk

@main
@objc class AppDelegate: FlutterAppDelegate, CardPaymentDelegate {
  private var pendingPaymentResult: FlutterResult?
  private let channelName = "touri/ngenius_payment"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyD5G1uXTPM2DP-5ZkeLQA_7FsFjxNWOIzM")
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handlePaymentChannel(call: call, result: result, controller: controller)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handlePaymentChannel(
    call: FlutterMethodCall,
    result: @escaping FlutterResult,
    controller: FlutterViewController
  ) {
    switch call.method {
    case "isAvailable":
      result(true)
    case "startCardPayment":
      guard pendingPaymentResult == nil else {
        result(
          FlutterError(
            code: "IN_PROGRESS",
            message: "Another payment is already in progress",
            details: nil
          )
        )
        return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "INVALID_SDK_SESSION",
            message: "Missing arguments",
            details: nil
          )
        )
        return
      }

      let language = ((args["languageCode"] as? String) ?? "en").lowercased()
      NISdk.sharedInstance.setSDKLanguage(language: language.hasPrefix("ar") ? "ar" : "en")

      // Prefer full order JSON for official OrderResponse decoding.
      var orderResponse: OrderResponse?
      if let orderJson = args["orderJson"] as? String,
         let data = orderJson.data(using: .utf8)
      {
        orderResponse = try? JSONDecoder().decode(OrderResponse.self, from: data)
      }

      guard let order = orderResponse else {
        result(
          FlutterError(
            code: "INVALID_SDK_SESSION",
            message: "Missing or invalid orderJson for NISdk",
            details: nil
          )
        )
        return
      }

      pendingPaymentResult = result
      NISdk.sharedInstance.showCardPaymentViewWith(
        cardPaymentDelegate: self,
        overParent: controller,
        for: order
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - CardPaymentDelegate

  func paymentDidComplete(with status: PaymentStatus) {
    let reply = pendingPaymentResult
    pendingPaymentResult = nil
    guard let reply = reply else { return }

    switch status {
    case .PaymentSuccess:
      reply(["status": "success"])
    case .PaymentFailed:
      reply(["status": "failed", "errorCategory": "DECLINED"])
    case .PaymentCancelled:
      reply(["status": "cancelled", "errorCategory": "USER_CANCELLED"])
    @unknown default:
      reply(["status": "failed", "errorCategory": "UNKNOWN"])
    }
  }

  func authorizationDidComplete(with status: AuthorizationStatus) {
    // 3DS auth stage — final outcome still comes via paymentDidComplete.
    if status == .AuthFailed {
      // Keep pending; paymentDidComplete should follow with failure.
    }
  }
}
