package com.genai

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName

data class GenAIRequest(
    val question: String,
    val namespace: String,
    @SerializedName("top_k")
    val topK: Int = 6
)

data class GenAISource(
    @SerializedName("file_path")
    val filePath: String,
    val score: Double,
    val language: String
)

data class GenAIResponse(
    val answer: String,
    val sources: List<GenAISource>
)

class GenAIClient(private val apiUrl: String) {
    private val client = OkHttpClient()
    private val gson = Gson()

    fun ask(question: String, namespace: String, topK: Int = 6): GenAIResponse {
        val request = GenAIRequest(question, namespace, topK)
        val json = gson.toJson(request)
        val body = json.toRequestBody()

        val httpRequest = Request.Builder()
            .url(apiUrl)
            .post(body)
            .addHeader("Content-Type", "application/json")
            .build()

        client.newCall(httpRequest).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("API request failed: ${response.code}")
            }

            val responseBody = response.body?.string()
                ?: throw Exception("Empty response")

            return gson.fromJson(responseBody, GenAIResponse::class.java)
        }
    }
}
