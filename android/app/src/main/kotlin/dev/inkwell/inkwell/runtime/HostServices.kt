package dev.inkwell.inkwell.runtime

import android.app.Application
import android.content.Context
import eu.kanade.tachiyomi.network.NetworkHelper
import kotlinx.serialization.json.Json
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.addSingleton

object HostServices {
    @Volatile private var ready = false
    /** Call on Android's main thread before loading any third-party class. */
    @Synchronized fun initialize(application: Application) {
        if (ready) return
        Injekt.addSingleton<Application>(application)
        Injekt.addSingleton<Context>(application)
        Injekt.addSingleton(NetworkHelper(application))
        Injekt.addSingleton(Json { ignoreUnknownKeys = true; isLenient = true; explicitNulls = false })
        ready = true
    }
}
