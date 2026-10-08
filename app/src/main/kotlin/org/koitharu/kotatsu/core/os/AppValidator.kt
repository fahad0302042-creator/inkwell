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
		// Fork (Ktv): the fork's own release certificates. More than one is trusted because the
		// first key generated for this fork was lost before it reached any durable storage:
		// keeping its fingerprint costs nothing (nobody holds that private key any more) and means
		// an install already signed with it can still self-update. matchAny = true accepts a match
		// on any single certificate.
		val certificates = RELEASE_CERT_SHA256.associate {
			it.hexToByteArray() to PackageManager.CERT_INPUT_SHA256
		}
		PackageInfoCompat.hasSignatures(context.packageManager, context.packageName, certificates, true)
	}

	private companion object {
		// Fork (Ktv): upstream checks its own release certificate here to decide whether app updates
		// are supported. Replaced with this fork's certificates so Ktv builds are treated as
		// official Ktv builds — upstream APKs can no longer be installed over this app.
		private val RELEASE_CERT_SHA256 = listOf(
			// Superseded: generated 2026-10-08, lost before it reached the repository secrets.
			"3da8e978290e410b8b208f5c42c7299aa417fd64e2f7fd49f8a8be35aff594f3",
			// Current: staged in .secrets-handoff/ktv-release.p12
			"5d17e915ac51e1e073035ec9532272ae9d5d7dde79f6c9573ec97ec3a2787f4b",
		)
	}
}
