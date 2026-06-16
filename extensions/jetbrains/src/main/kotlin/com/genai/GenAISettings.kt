package com.genai

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.util.xmlb.XmlSerializerUtil

@State(
    name = "GenAISettings",
    storages = [Storage("genai.xml")]
)
class GenAISettings : PersistentStateComponent<GenAISettings> {
    var apiUrl: String? = null
    var apiKey: String? = null
    var defaultNamespace: String? = null

    override fun getState(): GenAISettings = this

    override fun loadState(state: GenAISettings) {
        XmlSerializerUtil.copyBean(state, this)
    }

    companion object {
        fun getInstance(): GenAISettings =
            ApplicationManager.getApplication().getService(GenAISettings::class.java)
    }
}
