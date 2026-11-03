package com.nezit.customer

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.LabeledIntent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.chooser.ChooserAction

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hyperlocal/cart_share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareCart") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                val message = call.argument<String>("message") ?: url
                if (url.isNullOrBlank()) {
                    result.error("invalid_url", "Missing sharing URL", null)
                    return@setMethodCallHandler
                }
                try {
                    val title = call.argument<String>("title") ?: "Share cart"
                    val copyLabel = call.argument<String>("copyLabel") ?: "Copy link"
                    val copyIntent = Intent(this, CopySharedCartActivity::class.java).apply {
                        putExtra(Intent.EXTRA_TEXT, url)
                        putExtra("copiedLabel", call.argument<String>("copiedLabel") ?: "Link copied")
                    }
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, message)
                        putExtra(Intent.EXTRA_TITLE, title)
                    }
                    val chooser = Intent.createChooser(send, title)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val copyAction = ChooserAction.Builder(
                            Icon.createWithResource(this, android.R.drawable.ic_menu_set_as),
                            copyLabel,
                            PendingIntent.getActivity(this, url.hashCode(), copyIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                        ).build()
                        chooser.putExtra(Intent.EXTRA_CHOOSER_CUSTOM_ACTIONS, arrayOf(copyAction))
                    } else {
                        chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(
                            LabeledIntent(copyIntent, "android", copyLabel, android.R.drawable.ic_menu_set_as)
                        ))
                    }
                    startActivity(chooser)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_failed", error.message, null)
                }
            }
    }
}
