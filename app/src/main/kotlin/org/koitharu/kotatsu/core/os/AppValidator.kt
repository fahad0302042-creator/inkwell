package org.koitharu.kotatsu.core.os

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.pm.PackageInfoCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import org.koitharu.kotatsu.parsers.util.suspendlazy.suspendLazy
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AppValidator @Inject constructor(
	@ApplicationContext private val context: Context,
) {
	@SuppressLint("InlinedApi")
	val isOriginalApp = suspendLazy(Dispatchers.Default) {
		val certificates = mapOf(CERT_SHA256.hexToByteArray() to PackageManager.CERT_INPUT_SHA256)
		PackageInfoCompat.hasSignatures(context.packageManager, context.packageName, certificates, false)
	}

	private companion object {
		// Fork (Ktv): upstream checks its own release certificate here to decide whether app updates
		// are supported. Replaced with this fork's certificate so Ktv builds are treated as official
		// Ktv builds — upstream APKs can no longer be installed over this app.
		private const val CERT_SHA256 = "3da8e978290e410b8b208f5c42c7299aa417fd64e2f7fd49f8a8be35aff594f3"
	}
}
