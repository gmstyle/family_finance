package com.gmstyle.family_finance

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Collections
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Shared bridge between [BankNotificationListenerService] and Flutter
 * MethodChannel / EventChannel.
 */
object NotificationBridge {
    const val METHOD_CHANNEL = "com.gmstyle.family_finance/notification_listener"
    const val EVENT_CHANNEL = "com.gmstyle.family_finance/notification_events"

    /** Default allowlist when Flutter has not pushed Remote Config yet. */
    private val defaultPackages = setOf("com.google.android.apps.walletnfcrel")

    @Volatile
    private var allowedPackages: Set<String> = defaultPackages

    private val pending = ConcurrentLinkedQueue<Map<String, Any>>()

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    fun isPackageAllowed(packageName: String): Boolean {
        return allowedPackages.contains(packageName)
    }

    fun setAllowedPackages(packages: Collection<String>) {
        val next = packages.map { it.trim() }.filter { it.isNotEmpty() }.toSet()
        allowedPackages = if (next.isEmpty()) defaultPackages else next
    }

    fun emit(event: Map<String, Any>) {
        val sink = eventSink
        if (sink != null) {
            sink.success(event)
        } else {
            pending.offer(event)
            // Bound the buffer so a long-running listener without Flutter
            // cannot grow forever.
            while (pending.size > 50) {
                pending.poll()
            }
        }
    }

    fun attachEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        if (sink == null) return
        while (true) {
            val event = pending.poll() ?: break
            sink.success(event)
        }
    }

    fun isListenerEnabled(context: Context): Boolean {
        val cn = ComponentName(context, BankNotificationListenerService::class.java)
        val flat = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(flat)
        while (colonSplitter.hasNext()) {
            val component = colonSplitter.next()
            val enabled = ComponentName.unflattenFromString(component)
            if (enabled != null && enabled == cn) return true
            // Some OEMs store the flattened string differently; also match package.
            if (component.contains(cn.flattenToString()) ||
                component.contains(cn.flattenToShortString())
            ) {
                return true
            }
        }
        return false
    }

    fun openListenerSettings(context: Context) {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun handleMethodCall(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "isListenerEnabled" -> result.success(isListenerEnabled(context))
            "openListenerSettings" -> {
                openListenerSettings(context)
                result.success(null)
            }
            "setAllowedPackages" -> {
                @Suppress("UNCHECKED_CAST")
                val list = call.arguments as? List<*>
                val packages = list?.mapNotNull { it as? String } ?: emptyList()
                setAllowedPackages(packages)
                result.success(null)
            }
            "isCaptureSupported" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    fun allowedPackagesSnapshot(): Set<String> =
        Collections.unmodifiableSet(allowedPackages)
}
