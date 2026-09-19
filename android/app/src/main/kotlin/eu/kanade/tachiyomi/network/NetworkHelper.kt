package eu.kanade.tachiyomi.network

import android.content.Context
import okhttp3.Cache
import okhttp3.OkHttpClient
import java.io.File
import java.util.concurrent.TimeUnit

/** Inkwell host services. No automatic Cloudflare challenge solving or JS engine. */
class NetworkHelper(context: Context) {
    val cookieJar = AndroidCookieJar()
    val client: OkHttpClient = OkHttpClient.Builder()
        .cookieJar(cookieJar)
        .connectTimeout(25, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .callTimeout(60, TimeUnit.SECONDS)
        .cache(Cache(File(context.cacheDir, "source_http"), 20L * 1024 * 1024))
        .build()
    // Binary compatibility alias only. It cannot bypass a site's verification page.
    val cloudflareClient: OkHttpClient get() = client
    fun defaultUserAgentProvider(): String = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36"
}
