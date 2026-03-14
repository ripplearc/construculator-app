package com.cms.cm_sample

import android.os.Bundle
import android.graphics.drawable.AnimationDrawable
import android.widget.ImageView
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        
        // Start the animation when splash screen is shown
        splashScreen.setOnExitAnimationListener { splashScreenView ->
            // Get the animated drawable and start it
            val splashIconView = splashScreenView.iconView as? ImageView
            val drawable = splashIconView?.drawable
            
            if (drawable is AnimationDrawable) {
                drawable.start()
                
                // Calculate total animation duration
                val totalDuration = (0 until drawable.numberOfFrames)
                    .sumOf { drawable.getDuration(it).toLong() }
                
                // Remove splash screen after animation completes
                splashIconView.postDelayed({
                    splashScreenView.remove()
                }, totalDuration)
            } else {
                // Fallback: remove immediately if not an animation
                splashScreenView.remove()
            }
        }
        
        super.onCreate(savedInstanceState)
    }
}
