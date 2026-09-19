// Adapted from Mihon (Apache-2.0), commit 424bbc53b85c19acd3c3b7c03ec6f73f516f25bc.
// Inkwell changes: remove app-only annotations/String.EMPTY imports. See THIRD_PARTY_NOTICES.md.
package eu.kanade.tachiyomi.source

/**
 * A source that explicitly doesn't require traffic considerations.
 *
 * This typically applies for self-hosted sources.
 */
interface UnmeteredSource
