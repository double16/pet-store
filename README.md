pet-store
=========

Grails 3 example for demonstrating various integrations.

[ ![Codeship Status for double16/pet-store](https://codeship.com/projects/c2393a60-c552-0132-c695-32942c6ecf59/status?branch=master)](https://codeship.com/projects/74368)
[![CircleCI](https://circleci.com/gh/double16/pet-store.svg?style=svg&circle-token=0f313dae899223d1d8fd9f28bdf2401d7bba98a1)](https://circleci.com/gh/double16/pet-store)

# Heroku
Heroku recommends building your application on the Heroku platform by pushing your git repo. However, there is a 15 minute
time limit on building. Larger apps will take longer that this and make deploying difficult to impossible.

The Gradle `deployToHeroku` task will deploy the application to Heroku using the jar file instead of the sources. Heroku provides
a way to publish a war but there is no control over the Java version, process command line, or additional files necessary
at runtime. The approach appears to Heroku like a source build using Maven, but an empty placeholder jar file is built. The
fat jar built by Grails is included in the sources and available in the slug. The build time is short and fairly constant.

It is possible to build a slug directly, but this requires a JDK to be included that will run on the Heroku stack and
the tarball requires GNU tar format, which Gradle doesn't create. The inclusion of the JDK must be in the Gradle build. When the
Heroku team updates the Java buildpack, those improvements are not available in the Gradle build.

# CI on Codeship
The configurations used on Codeship for CI are below. Other CI tools should work similarly.

The setup commands are mostly CI provider specific.
```shell
# Setting the TERM this way keeps the Gradle output sane for Codeship
export TERM=dumb
# ${HOME}/cache is Codeship's persistent cache, dependencies will be kept across builds
export GRADLE_USER_HOME="${HOME}/cache/gradle/"
# Set the JDK version, Codeship specific
jdk_switcher use oraclejdk8
```

The test command:
```shell
./gradlew check
```

The deployment command:
```shell
# We need to repeat the setup commands because they aren't suppose to carry over from the test setup commands
export TERM=dumb
export GRADLE_USER_HOME="${HOME}/cache/gradle/"
jdk_switcher use oraclejdk8
./gradlew deployToHeroku
check_url http://${HEROKU_APP_NAME}.herokuapp.com
```

The environment:
```
HEROKU_AUTH_TOKEN=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
HEROKU_APP_NAME=arcane-savannah-7223
```

Keep as much code in build.gradle as possible. This allows local testing and consistent behavior when using multiple CI
tools.

# Grain Static Site Generator

The project contains a static site example using [Grain](http://sysgears.com/grain), a Groovy based static site generator.
Good practice is to keep static resources on a CDN, separate from the application. This allows performance increases due to
reduced load on the application and the CDN being able to distribute network requests.

The example here eventually will show how to connect the Grails application and the static site.

