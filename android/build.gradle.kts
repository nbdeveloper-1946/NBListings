allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    val configureNamespace = Action<Project> {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val ns = getNamespace.invoke(android) as? String
                    if (ns.isNullOrEmpty()) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val fallbackNamespace = if (project.group.toString().isNotEmpty()) project.group.toString() else "com.flutter.plugin.${project.name.replace("-", "_").replace(":", "_")}"
                        setNamespace.invoke(android, fallbackNamespace)
                    }
                } catch (e: Exception) {
                    // Ignore
                }

                // Force compileSdk to 36 to satisfy flutter_plugin_android_lifecycle
                try {
                    val setCompileSdk = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                    setCompileSdk.invoke(android, 36)
                } catch (e: Exception) {
                    try {
                        val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                        setCompileSdkVersion.invoke(android, 36)
                    } catch (ex: Exception) {
                        try {
                            val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", java.lang.Integer::class.java)
                            setCompileSdkVersion.invoke(android, 36)
                        } catch (ex2: Exception) {
                            // Ignore
                        }
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace.execute(this)
    } else {
        afterEvaluate(configureNamespace)
    }
}

subprojects {
    extra.set("kotlin.incremental", "false")
    extra.set("kotlin.incremental.java", "false")
    
    buildscript.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                useVersion("9.0.1")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
