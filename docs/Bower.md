Using Bower from Gradle to Manage JS/CSS Dependencies
=====================================================

Gradle (and other build systems) have done a good job of managing classpath dependencies. They are effective at pulling
new versions of packages to get bug fixes and including in packaging. JavaScript, stylesheets and the like also have tools
to manage dependencies but are not first class citizens with classpath dependencies. `bower` is one tool that handles
dependencies like JavaScript and stylesheets (and others as well). This post will show you a way to leverage bower to
manage those dependencies in similar fashion to classpath dependencies.

All source code for this blog and a working application are available on [GitHub.com/double16/pet-store](https://github.com/double16/pet-store).

TODO: Problem of default bower install including too much

TODO: Problem of having a bower install on the build machine - gradle-node-plugin

1. Use gradle-node-plugin to ensure bower is installed
2. Specify bower packages to install
3. Copy production files to destination

# Managing Node and Bower in Gradle
Bower is a NodeJS package. Although many development and CI environments have Node installed, that's not guaranteed to
be true or perhaps differing versions cause problems for your application. Ideally a Gradle build consists of having a
JDK installed, pull the repo, and run `./gradlew build`.

The gradle-node-plugin manages an install of Node and NPM (Node Package Manager) from your Gradle build to deliver
consistent behavior whenever you build. It can be configured to use an existing Node install, or always download the
specified version. Now we'll add this plugin to our build.

Add the dependency:

TODO: gist of dependency

Configure Node versions:

TODO: gist of config block

Since caching of dependencies is important for a faster build, we'll instruct the Gradle managed NPM to cache packages
into our Gradle cache. In order for this to work, the tasks we'll create later need to depend on this task.

TODO: gist of npmCacheConfig task


# Specifying Bower Packages

# Copying Production Files

# Conclusion

