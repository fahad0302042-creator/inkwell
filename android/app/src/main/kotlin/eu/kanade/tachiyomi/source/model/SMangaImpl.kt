// Adapted from Mihon (Apache-2.0), commit 424bbc53b85c19acd3c3b7c03ec6f73f516f25bc.
// Inkwell changes: remove app-only annotations/String.EMPTY imports. See THIRD_PARTY_NOTICES.md.
@file:Suppress("PropertyName")

package eu.kanade.tachiyomi.source.model

import kotlinx.serialization.json.JsonObject

class SMangaImpl : SManga {

    override lateinit var url: String

    override lateinit var title: String

    override var thumbnail_url: String? = null

    override var artist: String? = null

    override var author: String? = null

    override var status: Int = 0

    override var description: String? = null

    override var genre: String? = null

    override var update_strategy: UpdateStrategy = UpdateStrategy.ALWAYS_UPDATE

    override var initialized: Boolean = false

    override var memo: JsonObject = JsonObject.EMPTY
}
