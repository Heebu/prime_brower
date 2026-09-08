package com.idris.prime_brower

import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.idris.prime_brower/app_links"
    private var initialUrl: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialUrl" -> {
                    val url = initialUrl
                    initialUrl = null
                    result.success(url)
                }
                "openDefaultBrowserSettings" -> {
                    openDefaultBrowserPrompt(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = intent.action
        val data = intent.dataString
        if (Intent.ACTION_VIEW == action && data != null) {
            methodChannel?.invokeMethod("onUrlOpened", data)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val data = intent.dataString
        if (Intent.ACTION_VIEW == action && data != null) {
            initialUrl = data
        }
    }

    private fun openDefaultBrowserPrompt(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_BROWSER)) {
                    if (!roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)) {
                        val roleIntent = roleManager.createRequestRoleIntent(RoleManager.ROLE_BROWSER)
                        startActivityForResult(roleIntent, 1001)
                        result.success(true)
                        return
                    }
                }
            }

            // Fallback: Open Default Apps Settings
            try {
                val settingsIntent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                startActivity(settingsIntent)
                result.success(true)
            } catch (e: Exception) {
                val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                appDetails.data = Uri.parse("package:$packageName")
                startActivity(appDetails)
                result.success(true)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }
}
