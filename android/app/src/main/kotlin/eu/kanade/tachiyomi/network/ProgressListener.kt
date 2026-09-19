// From Mihon (Apache-2.0), commit 424bbc53b85c19acd3c3b7c03ec6f73f516f25bc. See THIRD_PARTY_NOTICES.md.
package eu.kanade.tachiyomi.network

interface ProgressListener {
    fun update(bytesRead: Long, contentLength: Long, done: Boolean)
}
