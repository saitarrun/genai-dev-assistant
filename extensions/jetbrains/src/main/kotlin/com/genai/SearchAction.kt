package com.genai

import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.project.Project
import com.intellij.openapi.ui.InputValidator
import com.intellij.openapi.ui.Messages
import com.intellij.openapi.wm.ToolWindowManager
import kotlinx.coroutines.launch
import com.intellij.openapi.application.ApplicationManager

class SearchAction : AnAction() {
    override fun actionPerformed(e: AnActionEvent) {
        val project = e.project ?: return

        // Get question from user
        val question = Messages.showInputDialog(
            project,
            "Ask a question about your codebase:",
            "GenAI Search",
            Messages.getQuestionIcon(),
            "",
            null
        ) ?: return

        // Get namespace
        val namespace = Messages.showInputDialog(
            project,
            "Repository namespace:",
            "GenAI Search",
            Messages.getQuestionIcon(),
            project.name,
            null
        ) ?: return

        // Show progress and fetch result
        Messages.showInfoMessage(
            "Searching...",
            "GenAI"
        )

        ApplicationManager.getApplication().invokeLater {
            performSearch(project, question, namespace)
        }
    }

    private fun performSearch(project: Project, question: String, namespace: String) {
        val settings = GenAISettings.getInstance()
        val apiUrl = settings.apiUrl ?: return

        try {
            val client = GenAIClient(apiUrl)
            val response = client.ask(question, namespace, 6)

            // Show result in tool window
            val toolWindowManager = ToolWindowManager.getInstance(project)
            val toolWindow = toolWindowManager.getToolWindow("GenAI Search")
            if (toolWindow != null) {
                val content = toolWindow.contentManager.getContent(0)
                if (content is GenAIToolWindowContent) {
                    content.updateResult(response)
                }
                toolWindow.show()
            } else {
                Messages.showInfoMessage(
                    response.answer + "\n\nSources:\n" +
                    response.sources.joinToString("\n") { "${it.filePath} (${(it.score * 100).toInt()}%)" },
                    "GenAI Result"
                )
            }
        } catch (e: Exception) {
            Messages.showErrorDialog(
                "GenAI Error: ${e.message}",
                "GenAI"
            )
        }
    }
}
