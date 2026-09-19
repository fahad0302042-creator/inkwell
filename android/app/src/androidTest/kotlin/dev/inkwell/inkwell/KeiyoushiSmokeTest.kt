package dev.inkwell.inkwell

import android.app.Application
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.inkwell.inkwell.runtime.ExtensionRuntime
import dev.inkwell.inkwell.runtime.HostServices
import dev.inkwell.inkwell.runtime.RuntimeFailure
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** Real installed Keiyoushi APK, not a reimplementation or a mocked source. */
@RunWith(AndroidJUnit4::class)
class KeiyoushiSmokeTest {
    private lateinit var runtime: ExtensionRuntime
    private val name = "eu.kanade.tachiyomi.extension.all.xkcd"
    @Before fun setup() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        instrumentation.runOnMainSync { HostServices.initialize(context.applicationContext as Application) }
        runtime = ExtensionRuntime(context)
        runBlocking(Dispatchers.IO) { runtime.revoke(name) }
    }
    @Test fun untrustedAndStaleApprovalAreRejected() = runBlocking(Dispatchers.IO) {
        val descriptor = runtime.installed().first { it["packageName"] == name }
        assertEquals(false, descriptor["trusted"])
        try { runtime.sources(name); fail("Must require trust before loading") }
        catch (e: RuntimeFailure) { assertEquals("TRUST_REQUIRED", e.code) }
        try { runtime.trustAndLoad(name, "stale-identity"); fail("Must reject stale approval") }
        catch (e: RuntimeFailure) { assertEquals("APK_CHANGED", e.code) }
    }
    @Test fun realExtensionSearchDetailsChaptersAndImage() = runBlocking(Dispatchers.IO) {
        val extension = runtime.installed().first { it["packageName"] == name }
        assertEquals("1.4", extension["apiVersion"])
        assertEquals("74ef6fb112925b86ec44f30624a0cb5b0451095cfc7f1a34a853132c6cc1da99", extension["apkHash"])
        Log.i("InkwellSmoke", "Loading real APK after explicit test trust")
        val sources = runtime.trustAndLoad(name, extension["identity"] as String)
        val english = sources.first { it["lang"] == "en" }
        // This extension explicitly returns an empty search result; do not invent matches.
        val search = runtime.search(name, english["id"] as String, "xkcd", 1)
        assertTrue((search["items"] as List<*>).isEmpty())
        Log.i("InkwellSmoke", "Fetching popular collection")
        val result = runtime.search(name, english["id"] as String, "", 1)
        val items = result["items"] as List<*>
        assertTrue("Popular browsing should return an actual title", items.isNotEmpty())
        val manga = items.first() as Map<*, *>
        val mangaHandle = manga["handle"] as String
        Log.i("InkwellSmoke", "Fetching manga details")
        val details = runtime.details(mangaHandle)
        assertTrue((details["title"] as String).isNotBlank())
        // Cover loading also exercises APK resources + the source's image interceptor.
        Log.i("InkwellSmoke", "Fetching source-authenticated cover")
        val cover = runtime.image(mangaHandle, true)
        assertTrue("Expected thumbnail image bytes", cover.size > 32)
        Log.i("InkwellSmoke", "Fetching chapter list")
        val chapters = runtime.chapters(mangaHandle)
        assertTrue("Expected actual chapters from xkcd", chapters.size > 10)
        val firstComic = chapters.firstOrNull { (it["name"] as String).startsWith("1:") } ?: chapters.last()
        Log.i("InkwellSmoke", "Fetching page list")
        val pages = runtime.pages(firstComic["handle"] as String)
        assertTrue("Expected real page descriptors", pages.isNotEmpty())
        for ((index, page) in pages.take(2).withIndex()) {
            Log.i("InkwellSmoke", "Fetching real image page $index")
            val image = runtime.image(page["handle"] as String, false)
            assertTrue("Expected image bytes for page $index", image.size > 100)
        }
        Log.i("InkwellSmoke", "All real source operations passed; testing revocation")
        runtime.revoke(name)
        try { runtime.sources(name); fail("Revoked extensions must not serve new calls") }
        catch (e: RuntimeFailure) { assertEquals("TRUST_REQUIRED", e.code) }
    }
}
