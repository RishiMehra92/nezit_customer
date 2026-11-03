package com.nezit.customer

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/** An explicit, app-private target for the native Sharesheet's Copy link action. */
class CopySharedCartActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val url = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!url.isNullOrBlank()) {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("Cart link", url))
            Toast.makeText(this, intent.getStringExtra("copiedLabel") ?: "Link copied",
                Toast.LENGTH_SHORT).show()
        }
        finish()
    }
}
