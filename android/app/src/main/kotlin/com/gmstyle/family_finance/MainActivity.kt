package com.gmstyle.family_finance

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationBridge.METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            NotificationBridge.handleMethodCall(this, call, result)
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationBridge.EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationBridge.attachEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    NotificationBridge.attachEventSink(null)
                }
            },
        )
    }
}
