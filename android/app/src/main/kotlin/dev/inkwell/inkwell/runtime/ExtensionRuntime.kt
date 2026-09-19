package dev.inkwell.inkwell.runtime

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import dalvik.system.DexClassLoader
import eu.kanade.tachiyomi.source.Source
import eu.kanade.tachiyomi.source.SourceFactory
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga
import eu.kanade.tachiyomi.source.online.HttpSource
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout
import java.io.File
import java.security.MessageDigest
import java.util.UUID

class RuntimeFailure(val code: String, message: String) : Exception(message)

/** Experimental in-process source host. APK trust is NOT an execution sandbox. */
class ExtensionRuntime(private val context: Context) {
    private val preferences = context.getSharedPreferences("extension_trust_v1", Context.MODE_PRIVATE)
    private val mutex = Mutex()
    private data class Loaded(val digest: String, val sources: List<Source>)
    private data class Entry<T>(val owner: String, val source: Source, val value: T)
    private val loaded = mutableMapOf<String, Loaded>()
    private val mangas = linkedMapOf<String, Entry<SManga>>()
    private val chapters = linkedMapOf<String, Entry<SChapter>>()
    private val pages = linkedMapOf<String, Entry<Page>>()

    @Suppress("DEPRECATION")
    private fun packages(): List<PackageInfo> {
        val flags = PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS or
            if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
        val list = if (Build.VERSION.SDK_INT >= 33)
            context.packageManager.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags.toLong()))
        else context.packageManager.getInstalledPackages(flags)
        return list.filter { info -> info.reqFeatures?.any { it.name == "tachiyomi.extension" } == true }
    }
    private fun packageInfo(name: String): PackageInfo = packages().firstOrNull { it.packageName == name }
        ?: throw RuntimeFailure("NOT_INSTALLED", "This extension is no longer installed. Rescan extensions.")
    private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it.toInt() and 255) }
    private fun digest(file: File): String {
        val hash = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { stream ->
            val buffer = ByteArray(8192)
            while (true) { val n = stream.read(buffer); if (n < 0) break; hash.update(buffer, 0, n) }
        }
        return hex(hash.digest())
    }
    @Suppress("DEPRECATION")
    private fun describe(info: PackageInfo): Map<String, Any> {
        val app = info.applicationInfo ?: throw RuntimeFailure("MALFORMED", "Missing application metadata")
        val meta = app.metaData
        val api = meta?.getFloat("tachiyomix.extensionLib", 0f)?.takeIf { it > 0f }?.toString()
            ?: info.versionName?.substringBeforeLast('.') ?: "unknown"
        val signers = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
        val fingerprints = signers?.map { hex(MessageDigest.getInstance("SHA-256").digest(it.toByteArray())) }?.sorted() ?: emptyList()
        val entry = meta?.getString("tachiyomi.extension.class") ?: ""
        val apkHash = digest(File(app.sourceDir))
        val version = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
        // Trust is bound to this exact package, signer set, version AND APK bytes.
        val identity = "$version:$apkHash:${fingerprints.joinToString(",")}"
        val supported = api in setOf("1.4", "1.6") && fingerprints.isNotEmpty() && entry.isNotBlank()
        return mapOf(
            "name" to (meta?.getString("tachiyomix.name") ?: context.packageManager.getApplicationLabel(app).toString()),
            "packageName" to info.packageName, "version" to (info.versionName ?: "Unknown"),
            "entryPoint" to entry, "fingerprints" to fingerprints, "apiVersion" to api,
            "nsfw" to ((meta?.getInt("tachiyomi.extension.nsfw", 0) ?: 0) == 1 || (meta?.getInt("tachiyomix.contentWarning", 0) ?: 0) > 1),
            "apkHash" to apkHash, "identity" to identity, "supported" to supported,
            "trusted" to (supported && preferences.getString(info.packageName, null) == identity),
            "runtimeAvailable" to supported,
        )
    }
    suspend fun installed(): List<Map<String, Any>> = mutex.withLock {
        packages().mapNotNull { try { describe(it) } catch (_: java.io.FileNotFoundException) { null } }
            .sortedBy { it["name"].toString().lowercase() }
    }
    private fun checkTrust(name: String): Pair<PackageInfo, Map<String, Any>> {
        val info = packageInfo(name)
        val descriptor = describe(info)
        if (descriptor["supported"] != true) throw RuntimeFailure("UNSUPPORTED_API", "Only extension API 1.4 and 1.6 are experimental targets. This package cannot be loaded.")
        if (descriptor["trusted"] != true) {
            loaded.remove(name)
            throw RuntimeFailure("TRUST_REQUIRED", "Extension is untrusted or its APK/version/signature changed. Review and trust it again.")
        }
        return info to descriptor
    }
    suspend fun trustAndLoad(name: String, expectedIdentity: String): List<Map<String, Any>> = mutex.withLock {
        val current = describe(packageInfo(name))
        if (current["identity"] != expectedIdentity) throw RuntimeFailure("APK_CHANGED", "APK changed since the trust dialog was opened. Rescan and review it again.")
        if (current["supported"] != true) throw RuntimeFailure("UNSUPPORTED_API", "This extension API is unsupported or the package is malformed/unsigned.")
        if (!preferences.edit().putString(name, expectedIdentity).commit()) throw RuntimeFailure("STORAGE_ERROR", "Could not save extension trust")
        sourcesUnlocked(name)
    }
    suspend fun revoke(name: String) = mutex.withLock {
        if (!preferences.edit().remove(name).commit()) throw RuntimeFailure("STORAGE_ERROR", "Could not remove extension trust")
        loaded.remove(name)
        mangas.entries.removeAll { it.value.owner == name }
        chapters.entries.removeAll { it.value.owner == name }
        pages.entries.removeAll { it.value.owner == name }
        // Constructors may have spawned code in this process. Restart to fully unload it.
    }
    private fun load(name: String): List<Source> {
        val (info, descriptor) = checkTrust(name)
        val hash = descriptor["apkHash"] as String
        loaded[name]?.takeIf { it.digest == hash }?.let { return it.sources }
        // Load a verified read-only snapshot, not a potentially replaced package path.
        val directory = File(context.codeCacheDir, "extension_apks").apply { mkdirs() }
        val apk = File(directory, "$hash.apk")
        if (apk.exists() && digest(apk) != hash) apk.delete()
        if (!apk.exists()) {
            apk.outputStream().use { out ->
                // Android 14 dynamic-code requirement: mark read-only before writing through the open fd.
                check(apk.setReadOnly()) { "Could not protect APK snapshot" }
                File(info.applicationInfo!!.sourceDir).inputStream().use { it.copyTo(out) }
            }
        }
        if (digest(apk) != hash) { apk.delete(); throw RuntimeFailure("APK_CHANGED", "APK changed while copying. No code was loaded.") }
        val loader = DexClassLoader(apk.absolutePath, context.codeCacheDir.absolutePath, null, context.classLoader)
        val sourceList = (descriptor["entryPoint"] as String).split(';').filter { it.isNotBlank() }.flatMap {
            val className = it.trim().let { value -> if (value.startsWith('.')) name + value else value }
            when (val instance = Class.forName(className, false, loader).getDeclaredConstructor().newInstance()) {
                is Source -> listOf(instance)
                is SourceFactory -> instance.createSources()
                else -> throw RuntimeFailure("COMPATIBILITY_ERROR", "Entry point is not a Source or SourceFactory")
            }
        }
        if (sourceList.isEmpty() || sourceList.map { it.id }.distinct().size != sourceList.size)
            throw RuntimeFailure("COMPATIBILITY_ERROR", "Extension returned no sources or duplicate source IDs")
        loaded[name] = Loaded(hash, sourceList)
        return sourceList
    }
    private fun sourcesUnlocked(name: String): List<Map<String, Any>> = load(name).map {
        mapOf("id" to it.id.toString(), "name" to it.name, "lang" to it.lang,
            "supportsLatest" to it.supportsLatest, "imageSupported" to (it is HttpSource),
            "packageName" to name)
    }
    suspend fun sources(name: String) = mutex.withLock { sourcesUnlocked(name) }
    private fun source(name: String, id: String): Source = load(name).firstOrNull { it.id.toString() == id }
        ?: throw RuntimeFailure("SOURCE_MISSING", "Source no longer exists. Reload the extension.")
    private fun <T> remember(map: LinkedHashMap<String, Entry<T>>, item: Entry<T>): String {
        // Session handles keep source-specific memo and chapter objects on the native side.
        while (map.size >= 16000) map.remove(map.keys.first())
        val handle = UUID.randomUUID().toString(); map[handle] = item; return handle
    }
    private fun <T> resolve(map: Map<String, Entry<T>>, handle: String): Entry<T> {
        val entry = map[handle] ?: throw RuntimeFailure("SESSION_EXPIRED", "This result expired. Return to the source and reopen it.")
        checkTrust(entry.owner)
        return entry
    }
    private fun mangaMap(handle: String, item: SManga) = mapOf(
        "handle" to handle, "title" to item.title, "url" to item.url,
        "description" to (item.description ?: ""), "author" to (item.author ?: ""),
        "genre" to (item.genre ?: ""), "hasCover" to !item.thumbnail_url.isNullOrBlank(),
    )
    suspend fun search(name: String, id: String, query: String, page: Int, latest: Boolean = false): Map<String, Any> = mutex.withLock {
        require(page >= 1)
        val s = source(name, id)
        val result = withTimeout(90_000) {
            if (latest) s.getLatestUpdates(page)
            else if (query.isBlank()) s.getPopularManga(page)
            else s.getSearchManga(page, query, s.getFilterList())
        }
        mapOf("hasNextPage" to result.hasNextPage, "items" to result.mangas.map { item ->
            val handle = remember(mangas, Entry(name, s, item)); mangaMap(handle, item)
        })
    }
    suspend fun details(handle: String): Map<String, Any> = mutex.withLock {
        val item = resolve(mangas, handle)
        val update = withTimeout(90_000) { item.source.getMangaUpdate(item.value, emptyList(), true, false) }
        // Keep canonical identity if a source only supplies updated fields.
        if (update.manga.url.isBlank()) update.manga.url = item.value.url
        if (update.manga.title.isBlank()) update.manga.title = item.value.title
        if (update.manga.thumbnail_url == null) update.manga.thumbnail_url = item.value.thumbnail_url
        mangas[handle] = item.copy(value = update.manga)
        mangaMap(handle, update.manga)
    }
    suspend fun chapters(handle: String): List<Map<String, Any>> = mutex.withLock {
        val item = resolve(mangas, handle)
        val update = withTimeout(90_000) { item.source.getMangaUpdate(item.value, emptyList(), false, true) }
        update.chapters.map { chapter ->
            val token = remember(chapters, Entry(item.owner, item.source, chapter))
            mapOf("handle" to token, "name" to chapter.name, "url" to chapter.url,
                "date" to chapter.date_upload,
                "progressKey" to hex(MessageDigest.getInstance("SHA-256").digest("${item.owner}|${item.source.id}|${chapter.url}".toByteArray())))
        }
    }
    suspend fun pages(handle: String): List<Map<String, Any>> = mutex.withLock {
        val entry = resolve(chapters, handle)
        val list = withTimeout(90_000) { entry.source.getPageList(entry.value) }
        if (list.size > 2000) throw RuntimeFailure("TOO_MANY_PAGES", "This chapter exceeds the experimental 2,000-page limit")
        list.mapIndexed { index, page -> mapOf("handle" to remember(pages, Entry(entry.owner, entry.source, page)), "index" to index) }
    }
    suspend fun image(handle: String, cover: Boolean): ByteArray = mutex.withLock {
        val entry = if (cover) {
            val item = resolve(mangas, handle)
            val url = item.value.thumbnail_url?.takeIf { it.isNotBlank() }
                ?: throw RuntimeFailure("NO_COVER", "No cover available")
            Entry(item.owner, item.source, Page(0, imageUrl = url))
        } else resolve(pages, handle)
        val http = entry.source as? HttpSource ?: throw RuntimeFailure("UNSUPPORTED_IMAGES", "Only HttpSource image loading is supported in this milestone")
        val page = entry.value
        withTimeout(90_000) {
            if (page.imageUrl.isNullOrBlank()) page.imageUrl = http.getImageUrl(page)
            http.getImage(page).use { response ->
                // Honor source interceptors/cookies/headers, and cap bytes before crossing the channel.
                val maximum = 16L * 1024 * 1024
                if (response.body.contentLength() > maximum) throw RuntimeFailure("IMAGE_TOO_LARGE", "Image exceeds the 16 MB preview limit")
                val source = response.body.source()
                if (source.request(maximum + 1)) throw RuntimeFailure("IMAGE_TOO_LARGE", "Image exceeds the 16 MB preview limit")
                source.readByteArray()
            }
        }
    }
}
