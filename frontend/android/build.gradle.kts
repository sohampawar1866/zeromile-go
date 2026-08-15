allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                // This is the Mapbox SDK secret token — for hackathon use only
                username = "mapbox"
                password = "pk.eyJ1IjoicmFrc2hpdGxhZGRhIiwiYSI6ImNtc3RrN2cweTBsbDEyeHIwZnA5aXY5dHkifQ.0J-JnWi4wBW3T-8Nbtmgjg"
            }
        }
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
