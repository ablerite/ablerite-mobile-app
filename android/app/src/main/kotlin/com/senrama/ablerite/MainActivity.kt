package com.senrama.ablerite

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun attachBaseContext(newBase: Context) {
        val configuration = Configuration(newBase.resources.configuration)
        configuration.uiMode =
            (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                Configuration.UI_MODE_NIGHT_NO
        super.attachBaseContext(newBase.createConfigurationContext(configuration))
    }
}
