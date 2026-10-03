package com.gmstyle.family_finance

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification

/**
 * Captures bank / wallet notifications for packages in the allowlist.
 *
 * Only structured fields (package, title, text, postTime) are forwarded to
 * Flutter — never persisted as raw text by the Dart layer.
 */
class BankNotificationListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return
        if (!NotificationBridge.isPackageAllowed(packageName)) return

        // Ignore ongoing / group summaries that are not payment alerts.
        val notification = sbn.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
        val body = when {
            bigText.isNotBlank() -> bigText
            text.isNotBlank() -> text
            else -> extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString().orEmpty()
        }

        if (title.isBlank() && body.isBlank()) return

        NotificationBridge.emit(
            mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to body,
                "postTime" to sbn.postTime,
            ),
        )
    }
}
