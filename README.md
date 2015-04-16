pet-store
=========

Grails 3 example for demonstrating various integrations.

[ ![Codeship Status for double16/pet-store](https://codeship.com/projects/c2393a60-c552-0132-c695-32942c6ecf59/status?branch=master)](https://codeship.com/projects/74368)

# Heroku
The Gradle deployToHeroku task will deploy this application to Heroku by building a slug directly, uploading and releasing. This can be necessary if building the application takes longer than the maximum 15 minutes Heroku allows.

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
./gradlew deployToHeroku
check_url http://${HEROKU_APP_NAME}.herokuapp.com
```

The environment:
```
HEROKU_AUTH_TOKEN=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
HEROKU_APP_NAME=arcane-savannah-3227
```

Keep as much code in build.gradle as possible. This allows local testing and consistent behavior when using multiple CI
tools.
