package com.cms.cm_sample

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                val animStart = splashScreenView.iconAnimationStart?.toEpochMilli() ?: 0L
                val animDuration = splashScreenView.iconAnimationDuration?.toMillis() ?: 0L
                val remaining = (animDuration - (System.currentTimeMillis() - animStart)).coerceAtLeast(0L)
                splashScreenView.postDelayed({ splashScreenView.remove() }, remaining)
            }
        }
        super.onCreate(savedInstanceState)
    }
}
