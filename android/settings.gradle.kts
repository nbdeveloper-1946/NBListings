// Add shim for Gradle 9+ compatibility with older plugins using jcenter()
try {
    val registry = groovy.lang.GroovySystem.getMetaClassRegistry()
    val targetClass = org.gradle.api.artifacts.dsl.RepositoryHandler::class.java
    val expando = groovy.lang.ExpandoMetaClass(targetClass, true, true)
    expando.initialize()
    expando.registerInstanceMethod("jcenter", object : groovy.lang.Closure<Any>(null) {
        fun doCall(): Any {
            val handler = delegate as org.gradle.api.artifacts.dsl.RepositoryHandler
            return handler.mavenCentral()
        }
    })
    registry.setMetaClass(targetClass, expando)
} catch (e: Throwable) {
    // Fail-silent
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
