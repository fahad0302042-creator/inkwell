package eu.kanade.tachiyomi.network

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import rx.Observable
import rx.subscriptions.Subscriptions
import java.io.IOException
import kotlin.coroutines.resumeWithException

fun Call.asObservable(): Observable<Response> = Observable.create { subscriber ->
    val call = clone()
    subscriber.add(Subscriptions.create { call.cancel() })
    try {
        val response = call.execute()
        if (subscriber.isUnsubscribed) response.close() else {
            subscriber.onNext(response)
            if (!subscriber.isUnsubscribed) subscriber.onCompleted()
        }
    } catch (e: Exception) { if (!subscriber.isUnsubscribed) subscriber.onError(e) }
}
fun Call.asObservableSuccess(): Observable<Response> = asObservable().map { response ->
    if (!response.isSuccessful) {
        val code = response.code
        response.close()
        throw HttpException(code)
    }
    response
}
suspend fun Call.await(): Response = suspendCancellableCoroutine { continuation ->
    continuation.invokeOnCancellation { cancel() }
    enqueue(object : Callback {
        override fun onFailure(call: Call, e: IOException) {
            if (continuation.isActive) continuation.resumeWithException(e)
        }
        override fun onResponse(call: Call, response: Response) {
            continuation.resume(response) { _, value, _ -> value.close() }
        }
    })
}
suspend fun Call.awaitSuccess(): Response {
    val response = await()
    if (!response.isSuccessful) {
        val code = response.code
        response.close()
        throw HttpException(code)
    }
    return response
}
fun OkHttpClient.newCachelessCallWithProgress(request: Request, listener: ProgressListener, existingSize: Long = 0L): Call =
    newBuilder().cache(null).addNetworkInterceptor { chain ->
        val outgoing = if (existingSize > 0 && request.header("Range") == null)
            request.newBuilder().header("Range", "bytes=$existingSize-").build() else request
        val response = chain.proceed(outgoing)
        response.newBuilder().body(ProgressResponseBody(response.body, listener,
            if (response.code == 206) existingSize else 0L)).build()
    }.build().newCall(request)
