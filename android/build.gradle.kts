plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
    id("com.google.firebase.crashlytics") version "3.0.3" apply false
}

// AGP 8+ / JVM: namespace e Java 11 em plugins legados (jailbreak, windowmanager, etc.).
apply(from = "legacy_android_plugins.gradle")

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // intercom_flutter 3.x usa intercom-sdk 8.2.0 que puxa flexbox:2.0.1 do JCenter (descontinuado).
    // Substitui pelo equivalente no Google Maven.
    configurations.all {
        resolutionStrategy.dependencySubstitution {
            substitute(module("com.google.android:flexbox:2.0.1"))
                .using(module("com.google.android.flexbox:flexbox:3.0.0"))
        }
    }
    // Alinha JVM target Kotlin com Java em cada subprojeto.
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            val javaTarget = tasks.findByName("compileReleaseJavaWithJavac")
                ?.let { (it as? JavaCompile)?.targetCompatibility }
                ?: tasks.findByName("compileDebugJavaWithJavac")
                    ?.let { (it as? JavaCompile)?.targetCompatibility }
                ?: "11"
            val jvmTarget = when (javaTarget) {
                "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11"       -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "17"       -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                else       -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
            compilerOptions.jvmTarget.set(jvmTarget)
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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