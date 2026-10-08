package org.koitharu.kotatsu.reader.ui

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import dagger.assisted.Assisted
import dagger.assisted.AssistedFactory
import dagger.assisted.AssistedInject
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.koitharu.kotatsu.core.prefs.AppSettings
import java.util.concurrent.TimeUnit

/**
 * Fork (Ktv): auto-play for Android TV.
 *
 * Advances the reader on a timer so pages can be read without touching the remote at all. Whether
 * reaching the end of a chapter continues into the next one is decided by the listener (see
 * [ReaderControlDelegate.OnInteractionListener.onAutoPlayTick]) and the
 * [AppSettings.isReaderAutoPlayContinueChapter] setting.
 *
 * Deliberately keeps no page awareness of its own: it only ticks, and the reader decides what a
 * tick means. That keeps chapter-boundary logic in one place.
 */
class AutoPlayTimer @AssistedInject constructor(
	@Assisted private val listener: ReaderControlDelegate.OnInteractionListener,
	@Assisted lifecycleOwner: LifecycleOwner,
	private val settings: AppSettings,
) {

	private val coroutineScope = lifecycleOwner.lifecycleScope
	private val isRunning = MutableStateFlow(false)
	private var job: Job? = null

	val isActive: StateFlow<Boolean>
		get() = isRunning

	fun toggle() {
		setActive(!isRunning.value)
	}

	fun setActive(value: Boolean) {
		if (isRunning.value != value) {
			isRunning.value = value
			restartJob()
		}
	}

	private fun restartJob() {
		job?.cancel()
		job = null
		if (!isRunning.value) {
			return
		}
		job = coroutineScope.launch {
			while (isActive) {
				// Read the interval on every tick so changing the setting takes effect immediately.
				delay(TimeUnit.SECONDS.toMillis(settings.readerAutoPlayInterval.toLong()))
				if (listener.isReaderResumed()) {
					listener.onAutoPlayTick()
				}
			}
		}
	}

	@AssistedFactory
	interface Factory {

		fun create(
			lifecycleOwner: LifecycleOwner,
			listener: ReaderControlDelegate.OnInteractionListener,
		): AutoPlayTimer
	}
}
