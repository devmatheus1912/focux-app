package com.focux.focux_app

import android.app.Application
import io.intercom.android.sdk.Intercom

/**
 * O SDK do Intercom abre vídeo e galeria direto pelo Android, antes do Dart
 * chamar [io.maido.intercom.IntercomFlutterPlugin]. Sem este initialize, essas
 * telas derrubam o processo.
 *
 * App id e chave Android são os mesmos de [lib/core/support/intercom_config.dart].
 */
class FocuxApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Intercom.initialize(this, ANDROID_API_KEY, APP_ID)
    }

    private companion object {
        const val APP_ID = "bq33wzj3"
        const val ANDROID_API_KEY = "android_sdk-a590ef918d87670e31d649000099e7c45b3a498d"
    }
}
