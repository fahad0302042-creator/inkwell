// Adapted from Mihon (Apache-2.0), commit 424bbc53b85c19acd3c3b7c03ec6f73f516f25bc.
// Inkwell changes: remove app-only annotations/String.EMPTY imports. See THIRD_PARTY_NOTICES.md.
package eu.kanade.tachiyomi.source.model

@Suppress("UNUSED")
class SMangaUpdate(val manga: SManga, val chapters: List<SChapter>)
