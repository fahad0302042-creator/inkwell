// Adapted from Mihon (Apache-2.0), commit 424bbc53b85c19acd3c3b7c03ec6f73f516f25bc.
// Inkwell changes: remove app-only annotations/app EMPTY helpers. See THIRD_PARTY_NOTICES.md.
package eu.kanade.tachiyomi.source.model

/**
 * Define the update strategy for a single [SManga].
 * The strategy used will only take effect on the library update.
 *
 * @since extensions-lib 1.4
 */
@Suppress("UNUSED")
enum class UpdateStrategy {
    /**
     * Series marked as always update will be included in the library
     * update if they aren't excluded by additional restrictions.
     */
    ALWAYS_UPDATE,

    /**
     * Series marked as only fetch once will be automatically skipped
     * during library updates. Useful for cases where the series is previously
     * known to be finished and have only a single chapter, for example.
     */
    ONLY_FETCH_ONCE,
}
