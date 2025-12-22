package com.junction

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.junction.config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getGoogleMapsApiKey") {
                try {
                    val apiKey = getGoogleMapsApiKey()
                    if (apiKey.isNotEmpty()) {
                        result.success(apiKey)
                    } else {
                        result.error("API_KEY_NOT_FOUND", "Google Maps API key not found", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get API key: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getGoogleMapsApiKey(): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, android.content.pm.PackageManager.GET_META_DATA)
            val bundle = appInfo.metaData
            bundle?.getString("com.google.android.geo.API_KEY") ?: ""
        } catch (e: Exception) {
            ""
        }
    }
}
