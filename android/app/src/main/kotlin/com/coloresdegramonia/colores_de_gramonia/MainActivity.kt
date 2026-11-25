package com.coloresdegramonia.colores_de_gramonia

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Abre enlaces (el blog de los cuentos) en el navegador, sin sumar
    // dependencias: lo usa lib/ui/enlaces.dart.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gramonia/enlaces")
            .setMethodCallHandler { llamada, resultado ->
                if (llamada.method != "abrir") {
                    resultado.notImplemented()
                    return@setMethodCallHandler
                }
                val url = llamada.argument<String>("url")
                if (url == null || !(url.startsWith("https://") || url.startsWith("http://"))) {
                    resultado.success(false)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(
                        Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    resultado.success(true)
                } catch (e: ActivityNotFoundException) {
                    resultado.success(false)
                }
            }
    }
}
