allprojects {
    repositories {
        // Flutter's engine is only in Flutter's own repository. Asking these for it, once per file and build, is what
        // Maven Central answers with 429 on shared CI machines.
        google { content { excludeGroup("io.flutter") } }
        // Google's copy of Maven Central first: Central itself answers 429 when many CI jobs build at once
        // (soak/final, 2026-11-26). Central stays as the fallback.
        maven("https://maven-central.storage-download.googleapis.com/maven2/") {
            content { excludeGroup("io.flutter") }
        }
        mavenCentral { content { excludeGroup("io.flutter") } }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
