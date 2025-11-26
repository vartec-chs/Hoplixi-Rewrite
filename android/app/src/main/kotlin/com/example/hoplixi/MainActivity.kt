package com.example.hoplixi

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	 private val screenProtector by lazy { AndroidScreenProtector.newInstance(this) }

    // For Android 12+
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        screenProtector.process(hasFocus.not())
    }
}
