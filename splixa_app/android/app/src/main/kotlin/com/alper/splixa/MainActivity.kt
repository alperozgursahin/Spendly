package net.splixa.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Android 15 enforces edge-to-edge for apps targeting SDK 35. Enabling
        // it explicitly also gives older Android versions consistent behavior.
        WindowCompat.enableEdgeToEdge(window)
    }
}
