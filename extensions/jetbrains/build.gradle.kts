plugins {
    id("java")
    id("org.jetbrains.intellij") version "1.13.3"
    kotlin("jvm") version "1.8.20"
}

group = "com.genai"
version = "0.1.0"

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.10.0")
    implementation("com.google.code.gson:gson:2.8.9")
    testImplementation("junit:junit:4.13.2")
}

intellij {
    version.set("2023.1")
    plugins.set(listOf("java"))
}

tasks {
    withType<org.jetbrains.intellij.tasks.PatchPluginXmlTask> {
        changeNotes.set("""
            <ul>
                <li>Initial release</li>
            </ul>
        """.trimIndent())
    }
}
