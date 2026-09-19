package dev.inkwell.inkwell

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.util.concurrent.Executors

/** Metadata inspection only. This intentionally does NOT load or execute extension code. */
class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.inkwell/extensions")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "listInstalled" -> executor.execute {
                    try {
                        val extensions = installedPackages()
                            .filter(::isExtension)
                            .mapNotNull { pkg ->
                                // A package can be uninstalled while a scan is in progress.
                                try { describe(pkg) } catch (_: PackageManager.NameNotFoundException) { null }
                            }
                            .sortedBy { it["name"].toString().lowercase() }
                        runOnUiThread { result.success(extensions) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("SCAN_FAILED", e.message, null) }
                    }
                }
                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    try {
                        require(!packageName.isNullOrBlank()) { "Missing package name" }
                        // Avoid allowing the bridge to operate on arbitrary packages.
                        val pkg = installedPackages().firstOrNull { it.packageName == packageName && isExtension(it) }
                        require(pkg != null) { "Extension is not installed" }
                        startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                        result.success(null)
                    } catch (e: Exception) { result.error("SETTINGS_FAILED", e.message, null) }
                }
                "capabilities" -> result.success(mapOf(
                    "discovery" to true, "sourceExecution" to false,
                    "privateExtensions" to false, "protocolVersion" to 1,
                ))
                "search", "chapters", "pages", "sources" -> result.error(
                    "RUNTIME_NOT_IMPLEMENTED",
                    "This starter inspects installed APK metadata only; a compatible source host is not implemented.",
                    null,
                )
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun installedPackages(): List<PackageInfo> {
        val signingFlag = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
        val flags = PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS or signingFlag
        return if (Build.VERSION.SDK_INT >= 33) {
            packageManager.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else packageManager.getInstalledPackages(flags)
    }

    private fun isExtension(pkg: PackageInfo): Boolean =
        pkg.reqFeatures?.any { it.name == "tachiyomi.extension" } == true

    @Suppress("DEPRECATION")
    private fun describe(pkg: PackageInfo): Map<String, Any> {
        val app = pkg.applicationInfo ?: throw PackageManager.NameNotFoundException(pkg.packageName)
        val metadata = app.metaData
        val signatures = if (Build.VERSION.SDK_INT >= 28) pkg.signingInfo?.apkContentsSigners else pkg.signatures
        val fingerprints = signatures?.map { signature ->
            MessageDigest.getInstance("SHA-256").digest(signature.toByteArray())
                .joinToString(":") { byte -> "%02X".format(byte.toInt() and 0xff) }
        } ?: emptyList()
        return mapOf(
            "name" to packageManager.getApplicationLabel(app).toString(),
            "packageName" to pkg.packageName,
            "version" to (pkg.versionName ?: "Unknown"),
            "entryPoint" to (metadata?.getString("tachiyomi.extension.class")
                ?: metadata?.getString("tachiyomi.extension.factory") ?: ""),
            "fingerprints" to fingerprints,
            "nsfw" to ((metadata?.getInt("tachiyomi.extension.nsfw", 0) ?: 0) == 1),
            "runtimeAvailable" to false,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
