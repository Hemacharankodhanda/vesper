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
    val configureCompileSdk = {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            val setCompileSdk = androidExt.javaClass.methods.firstOrNull { 
                it.name == "setCompileSdk" && it.parameterTypes.size == 1 
            }
            if (setCompileSdk != null) {
                setCompileSdk.invoke(androidExt, 37)
            } else {
                val compileSdkVersion = androidExt.javaClass.methods.firstOrNull { 
                    it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == java.lang.Integer.TYPE 
                }
                compileSdkVersion?.invoke(androidExt, 37)
            }
        }
    }
    if (project.state.executed) {
        configureCompileSdk()
    } else {
        project.afterEvaluate { configureCompileSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
