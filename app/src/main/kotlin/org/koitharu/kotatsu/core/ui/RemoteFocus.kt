package org.koitharu.kotatsu.core.ui

import android.graphics.drawable.Drawable
import android.graphics.drawable.LayerDrawable
import android.view.View
import android.view.ViewGroup
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
 * The focus ring is applied as a foreground overlay, which leaves the view's own background
 * (ripple / surface colour) working. If the view already has a foreground, the ring is layered on
 * top of it rather than skipped — otherwise exactly the busiest screens, the ones that style their
 * own controls, would be the ones where you cannot see where focus is.
 */
internal fun View.enableRemoteFocus() {
	if (!isClickable) {
		return
	}
	isFocusable = true
	if (getTag(R.id.ktv_focus_ring) == true) {
		return
	}
	val ring = AppCompatResources.getDrawable(context, R.drawable.ktv_focus_highlight) ?: return
	val existing = foreground
	foreground = if (existing == null) {
		ring
	} else {
		LayerDrawable(arrayOf(existing, ring))
	}
	setTag(R.id.ktv_focus_ring, true)
}

/**
 * Fork (Ktv): walks a container, makes every interactive descendant remote-focusable and returns
 * the first focusable view found, so the caller can hand focus to it.
 */
internal fun View.enableRemoteFocusRecursively(): View? {
	if (isClickable) {
		enableRemoteFocus()
	}
	var first: View? = if (isFocusable) this else null
	if (this is ViewGroup) {
		for (i in 0 until childCount) {
			val nested = getChildAt(i).enableRemoteFocusRecursively()
			if (first == null && nested != null) {
				first = nested
			}
		}
	}
	return first
}

/** Fork (Ktv): true when [view] is [this] view or one of its descendants. */
internal fun View.containsView(view: View?): Boolean {
	var current: View? = view
	while (current != null) {
		if (current === this) {
			return true
		}
		current = current.parent as? View
	}
	return false
}
