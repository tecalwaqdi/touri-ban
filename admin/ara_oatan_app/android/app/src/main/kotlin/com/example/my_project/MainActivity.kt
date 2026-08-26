package com.mycompany.araoatanapp

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import payment.sdk.android.PaymentClient
import payment.sdk.android.cardpayment.CardPaymentData
import payment.sdk.android.cardpayment.CardPaymentRequest

/**
 * Official N-Genius Android SDK bridge.
 * Never receives PAN/CVV or merchant API keys — only auth URL + HPP code.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "touri/ngenius_payment"
    private val cardRequestCode = 9911
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(true)
                    "startCardPayment" -> {
                        if (pendingResult != null) {
                            result.error(
                                "IN_PROGRESS",
                                "Another payment is already in progress",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val authUrl =
                            call.argument<String>("gatewayAuthorizationUrl")?.trim().orEmpty()
                        val payPageUrl =
                            call.argument<String>("payPageUrl")?.trim().orEmpty()
                        val paymentCode =
                            call.argument<String>("paymentCode")?.trim().orEmpty()
                        // languageCode reserved for future SDK locale API; 5.2.x uses device locale.

                        if (authUrl.isEmpty() || paymentCode.isEmpty()) {
                            result.error(
                                "INVALID_SDK_SESSION",
                                "Missing gatewayAuthorizationUrl or paymentCode",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        // payPageUrl validated on Flutter side; code must match.
                        if (payPageUrl.isNotEmpty() && !payPageUrl.contains(paymentCode)) {
                            // Soft check only — do not block if query encoding differs.
                        }

                        try {
                            // SDK 5.2.x follows device/app locale; no setSDKLanguage API.
                            val request = CardPaymentRequest.builder()
                                .gatewayUrl(authUrl)
                                .code(paymentCode)
                                .build()
                            pendingResult = result
                            // serviceId is required by SDK 5.2.x (used for Samsung Pay);
                            // card flow only needs a non-null id — package name is fine.
                            PaymentClient(this, packageName)
                                .launchCardPayment(request, cardRequestCode)
                        } catch (t: Throwable) {
                            pendingResult = null
                            result.error(
                                "SDK_LAUNCH_ERROR",
                                t.message ?: "Failed to launch N-Genius SDK",
                                null,
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != cardRequestCode) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val reply = pendingResult
        pendingResult = null
        if (reply == null) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        if (resultCode == Activity.RESULT_CANCELED || data == null) {
            reply.success(
                mapOf(
                    "status" to "cancelled",
                    "errorCategory" to "USER_CANCELLED",
                ),
            )
            return
        }

        try {
            val paymentData = CardPaymentData.getFromIntent(data)
            when (paymentData.code) {
                CardPaymentData.STATUS_PAYMENT_AUTHORIZED,
                CardPaymentData.STATUS_PAYMENT_CAPTURED,
                -> {
                    reply.success(
                        mapOf(
                            "status" to "success",
                            "errorCategory" to null,
                        ),
                    )
                }
                CardPaymentData.STATUS_PAYMENT_FAILED -> {
                    reply.success(
                        mapOf(
                            "status" to "failed",
                            "errorCategory" to "DECLINED",
                        ),
                    )
                }
                else -> {
                    reply.success(
                        mapOf(
                            "status" to "failed",
                            "errorCategory" to "GENERIC_ERROR",
                            "detail" to (paymentData.reason ?: ""),
                        ),
                    )
                }
            }
        } catch (t: Throwable) {
            reply.error(
                "SDK_RESULT_ERROR",
                t.message ?: "Failed to parse payment result",
                null,
            )
        }
    }
}
