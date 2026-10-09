package org.koitharu.kotatsu.core.ui

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.Toast
import org.koitharu.kotatsu.R

/**
 * Process-wide pointer state, so turning the pointer on survives moving between activities.
 * It is deliberately not persisted: the pointer is a mode you enter, not a preference, and it
 * should never still be on the next time the app is launched.
 */
internal object RemotePointerState {

	@Volatile
	var isEnabled = false

	@Volatile
	var lastX = Float.NaN

	@Volatile
	var lastY = Float.NaN
}

/**
 * Fork (Ktv): a mouse pointer driven by the D-pad, for Android TV / Google TV.
 *
 * The screens a remote genuinely cannot operate are the WebView ones — the Cloudflare challenge
 * and the source login pages. Focus navigation cannot click a canvas element, and a control that
 * has to be *held and dragged* cannot be passed at all. This draws a cursor into the activity's
 * own window and feeds synthetic touch events back into that same window, which is why it needs
 * no permission: an app is always allowed to dispatch input to itself. The usual way to do this,
 * [android.hardware.input.InputManager.injectInputEvent], is system-signed and unavailable here.
 *
 * It has to be a mode rather than always-on, because a D-pad that moves a cursor cannot also move
 * focus, and the rest of the app is built around focus. The toggle is a hold of OK:
 *
 * - hold OK with the pointer off  -> pointer on, and the release is swallowed
 * - tap OK                        -> click at the cursor
 * - hold OK and move              -> drag
 * - hold OK without moving        -> pointer off (symmetric with turning it on)
 * - Back                          -> pointer off
 *
 * The hold is detected here rather than through [Activity.onKeyLongPress] because that callback
 * is only delivered when the activity itself gets the key down. On TV a view almost always has
 * focus and consumes it first, so the framework never starts tracking the key and the callback
 * never fires. Tracking it here, in [Activity.dispatchKeyEvent], happens before the view
 * hierarchy sees anything.
 */
internal class RemotePointer(private val activity: Activity) {

	private var cursor: ImageView? = null
	private var x = RemotePointerState.lastX
	private var y = RemotePointerState.lastY

	private var isHolding = false
	private var hasDragged = false
	private var downTime = 0L
	private var longPressFired = false

	private val handler = Handler(Looper.getMainLooper())

	/**
	 * Fires slightly ahead of the framework's own long-press timeout. Getting there first is what
	 * lets a clean hold be told apart from a drag: whichever timer lands first decides, and if the
	 * view under the cursor won a long press of its own while we were waiting, the gesture could
	 * never be a drag.
	 */
	private val longPressTimeout = ViewConfiguration.getLongPressTimeout() - 100L

	private val longPressRunnable = Runnable(::onLongPress)

	private val isActive: Boolean
		get() = cursor != null

	fun onResume() {
		if (RemotePointerState.isEnabled && !isActive) {
			attach()
		}
	}

	/**
	 * Returns true when the event was consumed and must not reach the view hierarchy.
	 */
	fun handleKeyEvent(event: KeyEvent): Boolean = when (event.keyCode) {
		KeyEvent.KEYCODE_DPAD_CENTER,
		KeyEvent.KEYCODE_ENTER,
		KeyEvent.KEYCODE_NUMPAD_ENTER -> handleOkKey(event)

		KeyEvent.KEYCODE_DPAD_LEFT,
		KeyEvent.KEYCODE_DPAD_RIGHT,
		KeyEvent.KEYCODE_DPAD_UP,
		KeyEvent.KEYCODE_DPAD_DOWN -> handleMoveKey(event)

		KeyEvent.KEYCODE_BACK -> handleBackKey(event)

		else -> false
	}

	fun setActive(active: Boolean) {
		RemotePointerState.isEnabled = active
		if (active) {
			attach()
			Toast.makeText(activity, R.string.pointer_mode_hint, Toast.LENGTH_SHORT).show()
		} else {
			detach()
		}
	}

	// --- the OK key ---------------------------------------------------------------------------

	private fun handleOkKey(event: KeyEvent): Boolean {
		// Captured before anything can change it: a hold may switch modes mid-gesture, and the
		// release that follows has to be handled by the branch that started it.
		return if (isActive) handleOkKeyActive(event) else handleOkKeyInactive(event)
	}

	private fun handleOkKeyInactive(event: KeyEvent): Boolean = when (event.action) {
		KeyEvent.ACTION_DOWN -> {
			if (event.repeatCount == 0 && !hasFocusedEditor()) {
				scheduleLongPress()
			}
			false // a normal press must still reach the focused view untouched
		}

		KeyEvent.ACTION_UP -> {
			cancelLongPress()
			if (longPressFired) {
				// The hold already turned the pointer on, so swallow the release — otherwise the
				// view that was focused when the hold started also registers a click.
				longPressFired = false
				true
			} else {
				false
			}
		}

		else -> false
	}

	private fun handleOkKeyActive(event: KeyEvent): Boolean = when (event.action) {
		KeyEvent.ACTION_DOWN -> {
			if (event.repeatCount == 0) {
				isHolding = true
				hasDragged = false
				downTime = SystemClock.uptimeMillis()
				sendTouch(MotionEvent.ACTION_DOWN, x, y)
				scheduleLongPress()
			}
			true // repeats carry no information once the button is down
		}

		KeyEvent.ACTION_UP -> {
			cancelLongPress()
			if (longPressFired) {
				// A hold with no movement is the "put the mouse away" gesture, and the cancel
				// already sent on the long press released the view. Nothing left to do.
				longPressFired = false
			} else if (isHolding) {
				sendTouch(MotionEvent.ACTION_UP, x, y)
			}
			isHolding = false
			true
		}

		else -> true
	}

	// --- movement and Back --------------------------------------------------------------------

	private fun handleMoveKey(event: KeyEvent): Boolean {
		if (!isActive) {
			return false
		}
		// The matching ACTION_UP has to be swallowed too, or releasing the d-pad would move focus.
		if (event.action != KeyEvent.ACTION_DOWN) {
			return true
		}
		val decor = activity.window?.decorView ?: return true
		val step = STEP_DP * activity.resources.displayMetrics.density * acceleration(event.repeatCount)
		when (event.keyCode) {
			KeyEvent.KEYCODE_DPAD_LEFT -> x -= step
			KeyEvent.KEYCODE_DPAD_RIGHT -> x += step
			KeyEvent.KEYCODE_DPAD_UP -> y -= step
			KeyEvent.KEYCODE_DPAD_DOWN -> y += step
		}
		x = x.coerceIn(0f, (decor.width - 1).coerceAtLeast(0).toFloat())
		y = y.coerceIn(0f, (decor.height - 1).coerceAtLeast(0).toFloat())
		updateCursorPosition()
		if (isHolding) {
			hasDragged = true
			sendTouch(MotionEvent.ACTION_MOVE, x, y)
		}
		return true
	}

	private fun handleBackKey(event: KeyEvent): Boolean {
		if (!isActive) {
			return false
		}
		if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
			releaseIfHolding()
			detach()
			RemotePointerState.isEnabled = false
		}
		return true
	}

	/**
	 * Holding a direction accelerates, so crossing a 4K screen does not take all afternoon. Key
	 * repeat generates the events for free — one press is one step, holding is a glide.
	 */
	private fun acceleration(repeatCount: Int): Float {
		if (repeatCount <= ACCELERATION_THRESHOLD) {
			return 1f
		}
		return (1f + (repeatCount - ACCELERATION_THRESHOLD) * ACCELERATION_STEP).coerceAtMost(ACCELERATION_MAX)
	}

	// --- long press ---------------------------------------------------------------------------

	private fun onLongPress() {
		longPressFired = true
		if (isActive) {
			// A hold that has already moved is a drag and has to keep going; only a still hold
			// means "put the mouse away". The cancel releases whatever is under the cursor, which
			// also clears any long press the target started on our synthetic ACTION_DOWN.
			if (!hasDragged) {
				sendTouch(MotionEvent.ACTION_CANCEL, x, y)
				isHolding = false
				setActive(false)
			}
		} else {
			// The focused view started its own long-press timer on the same key down. Clearing its
			// pressed state makes that timer inert: the framework only performs the long click
			// while the view's pressed state still matches what it was when the timer was posted,
			// so no context menu opens behind a cursor that is about to appear.
			(activity.window?.decorView as? ViewGroup)?.findFocus()?.isPressed = false
			setActive(true)
		}
	}

	private fun scheduleLongPress() {
		longPressFired = false
		handler.postDelayed(longPressRunnable, longPressTimeout)
	}

	private fun cancelLongPress() {
		handler.removeCallbacks(longPressRunnable)
	}

	// --- the cursor ---------------------------------------------------------------------------

	private fun attach() {
		if (isActive) {
			return
		}
		val decor = activity.window?.decorView as? ViewGroup ?: return
		val view = ImageView(activity).apply {
			setImageResource(R.drawable.ktv_pointer)
			contentDescription = null
			importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
			isFocusable = false
			isClickable = false
			isFocusableInTouchMode = false
		}
		// Added to the decor rather than to the content view so the cursor shares a coordinate
		// space with the view the synthetic touches are dispatched to. Adding last keeps it on top.
		try {
			decor.addView(
				view,
				FrameLayout.LayoutParams(
					FrameLayout.LayoutParams.WRAP_CONTENT,
					FrameLayout.LayoutParams.WRAP_CONTENT,
					Gravity.TOP or Gravity.START,
				),
			)
		} catch (e: RuntimeException) {
			return
		}
		cursor = view
		if (x.isNaN() || y.isNaN()) {
			x = decor.width / 2f
			y = decor.height / 2f
		}
		updateCursorPosition()
	}

	private fun detach() {
		cancelLongPress()
		releaseIfHolding()
		RemotePointerState.lastX = x
		RemotePointerState.lastY = y
		val view = cursor ?: return
		(view.parent as? ViewGroup)?.removeView(view)
		cursor = null
	}

	private fun updateCursorPosition() {
		cursor?.translationX = x
		cursor?.translationY = y
	}

	// --- synthetic touch ----------------------------------------------------------------------

	private fun sendTouch(action: Int, px: Float, py: Float) {
		val decor = activity.window?.decorView ?: return
		val event = MotionEvent.obtain(downTime, SystemClock.uptimeMillis(), action, px, py, 0)
		event.source = InputDevice.SOURCE_TOUCHSCREEN
		try {
			decor.dispatchTouchEvent(event)
		} finally {
			event.recycle()
		}
	}

	private fun releaseIfHolding() {
		if (isHolding) {
			sendTouch(MotionEvent.ACTION_CANCEL, x, y)
			isHolding = false
		}
	}

	/**
	 * Typing keeps the d-pad: holding OK inside a text field should not summon a cursor.
	 */
	private fun hasFocusedEditor(): Boolean = activity.currentFocus is EditText

	private companion object {

		const val STEP_DP = 14f
		const val ACCELERATION_THRESHOLD = 3
		const val ACCELERATION_STEP = 0.25f
		const val ACCELERATION_MAX = 4f
	}
}
