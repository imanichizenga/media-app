allprojects {
    repositories {
        // Flutter's engine is only in Flutter's own repository. Asking these for it, once per file and build, is what
        // Maven Central answers with 429 on shared CI machines.
        google { content { excludeGroup("io.flutter") } }
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
