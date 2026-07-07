package com.focusflow.focus_flow

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focus_flow/usage")
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "hasUsagePermission" -> {
                        val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = ops.checkOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(),
                            packageName
                        )
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    }

                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }

                    "getAppUsage" -> {
                        val startTime = call.argument<Long>("startTime") ?: 0L
                        val endTime = call.argument<Long>("endTime")
                            ?: System.currentTimeMillis()
                        try {
                            val usm = getSystemService(Context.USAGE_STATS_SERVICE)
                                as UsageStatsManager
                            val statsMap = usm.queryAndAggregateUsageStats(startTime, endTime)
                            val pm = packageManager
                            val list = mutableListOf<Map<String, Any>>()

                            for ((pkg, stat) in statsMap) {
                                val ms = stat.totalTimeInForeground
                                if (ms < 60_000L) continue
                                try {
                                    val ai = pm.getApplicationInfo(pkg, 0)
                                    val name = pm.getApplicationLabel(ai).toString()
                                    val isSystem = (ai.flags and
                                        android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                                    list.add(
                                        mapOf(
                                            "packageName" to pkg,
                                            "appName" to name,
                                            "totalTimeMs" to ms,
                                            "isSystem" to isSystem,
                                        )
                                    )
                                } catch (_: PackageManager.NameNotFoundException) {
                                    // app uninstalled — skip
                                }
                            }
                            result.success(list)
                        } catch (e: Exception) {
                            result.error("USAGE_ERROR", e.message, null)
                        }
                    }

                    "getAppIcon" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        try {
                            val drawable = packageManager.getApplicationIcon(pkg)
                            val bmp = drawableToBitmap(drawable, 96)
                            val out = ByteArrayOutputStream()
                            bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
                            result.success(out.toByteArray())
                        } catch (_: Exception) {
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun drawableToBitmap(drawable: Drawable, size: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        }
        val w = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else size
        val h = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else size
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return Bitmap.createScaledBitmap(bmp, size, size, true)
    }
}
