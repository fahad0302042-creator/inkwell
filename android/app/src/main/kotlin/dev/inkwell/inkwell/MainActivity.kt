package dev.inkwell.inkwell

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import dev.inkwell.inkwell.runtime.ExtensionRuntime
import dev.inkwell.inkwell.runtime.HostServices
import dev.inkwell.inkwell.runtime.RuntimeFailure
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var runtime: ExtensionRuntime
    private var channel: MethodChannel? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HostServices.initialize(application)
        runtime = ExtensionRuntime(applicationContext)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.inkwell/extensions")
        channel?.setMethodCallHandler { call, result ->
            scope.launch {
                try {
                    val response: Any? = withContext(Dispatchers.IO) {
                        when (call.method) {
                            "listInstalled" -> runtime.installed()
                            "capabilities" -> mapOf("discovery" to true, "sourceExecution" to true,
                                "experimental" to true, "apiVersions" to listOf("1.4", "1.6"), "protocolVersion" to 2)
                            "trustAndLoad" -> runtime.trustAndLoad(call.text("packageName"), call.text("identity"))
                            "revokeTrust" -> { runtime.revoke(call.text("packageName")); null }
                            "sources" -> runtime.sources(call.text("packageName"))
                            "search" -> runtime.search(call.text("packageName"), call.text("sourceId"),
                                call.argument<String>("query") ?: "", call.argument<Int>("page") ?: 1,
                                call.argument<Boolean>("latest") ?: false)
                            "details" -> runtime.details(call.text("handle"))
                            "chapters" -> runtime.chapters(call.text("handle"))
                            "pages" -> runtime.pages(call.text("handle"))
                            "image" -> runtime.image(call.text("handle"), call.argument<Boolean>("cover") ?: false)
                            "openAppSettings" -> {
                                val name = call.text("packageName")
                                require(runtime.installed().any { it["packageName"] == name }) { "Extension is not installed" }
                                withContext(Dispatchers.Main) { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$name"))) }
                                null
                            }
                            "openExtensionWebsite" -> {
                                withContext(Dispatchers.Main) { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://keiyoushi.github.io/extensions/"))) }
                                null
                            }
                            else -> throw RuntimeFailure("METHOD_NOT_SUPPORTED", "Unknown runtime method")
                        }
                    }
                    result.success(response)
                } catch (e: TimeoutCancellationException) {
                    result.error("SOURCE_TIMEOUT", "The source took too long. Try again later.", null)
                } catch (e: CancellationException) { throw e }
                catch (e: RuntimeFailure) { result.error(e.code, e.message, null) }
                catch (e: LinkageError) { result.error("COMPATIBILITY_ERROR", "Missing host API: ${e.message?.take(350)}", null) }
                catch (e: Exception) {
                    val root = generateSequence<Throwable>(e) { it.cause }.take(8).last()
                    result.error(if (root is LinkageError) "COMPATIBILITY_ERROR" else "SOURCE_ERROR",
                        "${root.javaClass.simpleName}: ${root.message?.take(350) ?: "Source request failed"}", null)
                }
            }
        }
    }
    private fun MethodCall.text(key: String): String = argument<String>(key)?.takeIf { it.isNotBlank() }
        ?: throw RuntimeFailure("INVALID_ARGUMENT", "Missing $key")
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        scope.cancel()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
