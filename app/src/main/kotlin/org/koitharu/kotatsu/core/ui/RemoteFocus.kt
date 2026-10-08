package org.koitharu.kotatsu.core.ui

import android.view.View
import androidx.appcompat.content.res.AppCompatResources
import org.koitharu.kotatsu.R

/**
 * Fork (Ktv): Android TV / D-pad support.
 *
 * On a TV there is no touch input to fall back on, so anything that responds to a click must also
 * be reachable by moving focus with a remote. Non-interactive views (headers, loading footers,
 * empty states) are deliberately left alone so focus cannot get stuck on something that does
 * nothing when clicked.
 *
 * A focus ring is applied as a foreground overlay, which leaves the item's own background
 * (ripple / surface colour) untouched. Views that already define a foreground are left as they
 * are, since they most likely handle their own states.
 */
internal fun View.enableRemoteFocus() {
	if (!isClickable) {
		return
	}
	isFocusable = true
	if (foreground == null) {
		foreground = AppCompatResources.getDrawable(context, R.drawable.ktv_focus_highlight)
	}
}
