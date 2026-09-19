package dev.inkwell.inkwell

import eu.kanade.tachiyomi.network.ProgressListener
import eu.kanade.tachiyomi.network.newCachelessCallWithProgress
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.TimeUnit

class TransportTest {
    @Test fun progressWrapperPreservesBridgeHeadersAndCookie() {
        val server = MockWebServer()
        server.start()
        try {
            server.enqueue(MockResponse().setBody("image bytes"))
            val client = OkHttpClient.Builder().cookieJar(object : CookieJar {
                override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {}
                override fun loadForRequest(url: HttpUrl) = listOf(Cookie.Builder().name("session").value("test-only").hostOnlyDomain(url.host).build())
            }).build()
            var observed = 0L
            val listener = object : ProgressListener {
                override fun update(bytesRead: Long, contentLength: Long, done: Boolean) { observed = bytesRead }
            }
            client.newCachelessCallWithProgress(Request.Builder().url(server.url("/image")).build(), listener)
                .execute().use { assertEquals("image bytes", it.body.string()) }
            val request = server.takeRequest(5, TimeUnit.SECONDS)!!
            assertNotNull("HTTP authority must not be stripped", request.getHeader("Host"))
            assertEquals("session=test-only", request.getHeader("Cookie"))
            assertNotNull(request.getHeader("Accept-Encoding"))
            assertEquals(11L, observed)
        } finally { server.shutdown() }
    }
}
