package tachiyomi.core.common.util.lang

import kotlinx.coroutines.suspendCancellableCoroutine
import rx.Observable
import rx.SingleSubscriber
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

suspend fun <T : Any> Observable<T>.awaitSingle(): T = suspendCancellableCoroutine { continuation ->
    val subscriber = object : SingleSubscriber<T>() {
        override fun onSuccess(value: T) { if (continuation.isActive) continuation.resume(value) }
        override fun onError(error: Throwable) { if (continuation.isActive) continuation.resumeWithException(error) }
    }
    continuation.invokeOnCancellation { subscriber.unsubscribe() }
    toSingle().subscribe(subscriber)
}
