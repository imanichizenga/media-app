// Google's copy of Maven Central first, for every build Gradle runs, Flutter's own plugin build included.
// Maven Central (and the Gradle Plugin Portal, which sends its downloads there) answers 429 when many CI jobs build at
// once: a soak lost a run to it after the one network retry (ADR-0048). Our settings cannot reach Flutter's included
// build (`flutter_tools/gradle`); an init script can. The original repositories stay behind it as the fallback.
// CI: copied to ~/.gradle/init.d/ by mobile-device.yml. Locally: ./gradlew -I <this file> …
val mirror = "https://maven-central.storage-download.googleapis.com/maven2/"

gradle.beforeSettings {
    pluginManagement.repositories {
        google()
        maven(mirror) { name = "MavenCentralMirror" }
        gradlePluginPortal()
    }
    dependencyResolutionManagement.repositories {
        maven(mirror) {
            name = "MavenCentralMirror"
            content { excludeGroup("io.flutter") }
        }
    }
}

// Each Flutter plugin's own buildscript block asks google() and mavenCentral() for its Android Gradle Plugin. Added
// before the block runs, the mirror comes first. (Project repositories: build.gradle.kts already puts it first.)
gradle.beforeProject {
    buildscript.repositories.maven(mirror) {
        name = "MavenCentralMirror"
        content { excludeGroup("io.flutter") }
    }
}
