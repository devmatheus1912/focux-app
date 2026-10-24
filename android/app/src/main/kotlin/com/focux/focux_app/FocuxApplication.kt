package com.focux.focux_app

import android.app.Application
import android.util.Log
import io.intercom.android.sdk.Intercom

/**
 * O SDK do Intercom abre vídeo e galeria direto pelo Android, antes do Dart
 * chamar [io.maido.intercom.IntercomFlutterPlugin]. Sem este initialize, essas
 * telas derrubam o processo.
 *
 * App id e chave Android vêm do build (env ou android/local.properties), nunca do
 * código. Os mesmos valores ficam em [lib/core/support/intercom_config.dart].
 */
class FocuxApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (BuildConfig.INTERCOM_APP_ID.isBlank() || BuildConfig.INTERCOM_ANDROID_API_KEY.isBlank()) {
            Log.w("FocuxApplication", "Intercom não inicializado: chaves ausentes no build.")
            return
        }
        Intercom.initialize(this, BuildConfig.INTERCOM_ANDROID_API_KEY, BuildConfig.INTERCOM_APP_ID)
    }
}
