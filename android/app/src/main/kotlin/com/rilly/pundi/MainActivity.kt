package com.rilly.pundi

import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pundi/security")
            .setMethodCallHandler { call, result ->
                if (call.method == "getBootSessionId") {
                    val bootCount = Settings.Global.getInt(
                        contentResolver,
                        Settings.Global.BOOT_COUNT,
                        -1,
                    )
                    val bootMarker = if (bootCount >= 0) {
                        "boot-$bootCount"
                    } else {
                        val bootEpoch = System.currentTimeMillis() - SystemClock.elapsedRealtime()
                        "epoch-${bootEpoch / 60000}"
                    }
                    result.success(bootMarker)
                } else {
                    result.notImplemented()
                }
            }
    }
}
