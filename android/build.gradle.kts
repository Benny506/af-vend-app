allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = run {
    val isWindows = System.getProperty("os.name").lowercase().contains("win")
    val projectPath = rootProject.projectDir.absolutePath
    if (isWindows && projectPath.contains(" ")) {
        rootProject.layout.projectDirectory.dir("C:/Users/Public/build/Medusa-Admin-Flutter")
    } else {
        rootProject.layout.buildDirectory.dir("../../build").get()
    }
}
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
