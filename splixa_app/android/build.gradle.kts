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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Some Flutter plugins still publish Kotlin compiler settings that target the
// removed Kotlin 1.6 language level. Keep third-party Android modules on a
// supported, bytecode-compatible baseline while the app module remains on
// Java/Kotlin 17 as configured in android/app/build.gradle.kts.
gradle.projectsEvaluated {
    subprojects {
        if (name != "app") {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                val javaTaskName = name.replace("Kotlin", "JavaWithJavac")
                val javaTarget =
                    (tasks.findByName(javaTaskName) as? org.gradle.api.tasks.compile.JavaCompile)
                        ?.targetCompatibility
                        ?: JavaVersion.VERSION_17.toString()

                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget))
                    languageVersion.set(
                        org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9,
                    )
                }
            }
        }
    }
}
