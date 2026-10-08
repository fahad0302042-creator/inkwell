package org.koitharu.kotatsu.core.ui

import android.view.View

/**
 * Fork (Ktv): Android TV / D-pad support.
 *
 * On a TV there is no touch input to fall back on, so anything that responds to a click must also
 * be reachable by moving focus with a remote. Non-interactive views (headers, loading footers,
 * empty states) are deliberately left alone so focus cannot get stuck on something that does
 * nothing when clicked.
 */
internal fun View.enableRemoteFocus() {
	if (isClickable) {
		isFocusable = true
	}
}
