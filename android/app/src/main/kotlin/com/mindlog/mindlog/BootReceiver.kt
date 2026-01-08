package com.mindlog.mindlog

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 부팅 완료 시 알림 재스케줄링을 위한 BroadcastReceiver
 *
 * Android는 기기 재부팅 시 모든 예약된 알람을 삭제합니다.
 * 이 Receiver는 부팅 완료 후 앱을 깨워서 Flutter에서 알람을 재스케줄하도록 합니다.
 *
 * 실제 알람 재스케줄링은 Flutter의 main.dart에서 앱 시작 시 수행됩니다.
 * 이 Receiver는 시스템에 앱이 부팅 이벤트에 관심이 있음을 알리고,
 * 필요 시 앱을 백그라운드에서 시작할 수 있게 합니다.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "MindLogBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {

            Log.d(TAG, "Boot completed - alarm rescheduling will happen on app launch")

            // SharedPreferences에서 리마인더 설정 확인
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )

            // Flutter SharedPreferences 키 형식: flutter.{key}
            val reminderEnabled = prefs.getBoolean("flutter.notification_reminder_enabled", false)

            if (reminderEnabled) {
                Log.d(TAG, "Reminder is enabled - app will reschedule on next launch")
                // 알림 스케줄링은 Flutter 앱이 시작될 때 자동으로 수행됩니다.
                // flutter_local_notifications 플러그인이 자체적으로 부팅 후
                // 알림을 재스케줄하지 않으므로, 앱 시작 시 main.dart에서 처리합니다.
            } else {
                Log.d(TAG, "Reminder is disabled - no action needed")
            }
        }
    }
}
