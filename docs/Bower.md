Using Gradle and Bower to Manage JS/CSS Dependencies
====================================================

[Gradle](http://gradle.org) (and other build systems) have done a good job of managing classpath dependencies. They are effective at pulling
new versions of packages to get bug fixes, et al and including dependencies in packaging. JavaScript, stylesheets and the like also have tools
to manage dependencies but are not first class citizens with classpath dependencies. [Bower](http://bower.io) is one tool that handles
dependencies like JavaScript and stylesheets. This post will show you a way to leverage Bower to
manage those dependencies using Gradle tasks.

There are other solutions that handle the dependency problem. For example, there are [Grails](http://grails.org) plugins for a few popular
frameworks. The drawback is that when the source project releases a new version, the plugin author must release a new
plugin. It's very likely Bower will be updated by the source project, so the approach here will provide better dependency
management.

One problem with Bower is that the packages usually have more files than one would want on a production server. We'll
use the Gradle [Sync](http://gradle.org/docs/current/javadoc/org/gradle/api/tasks/Sync.html) task to handle that. It's a bit more work, but worth it.

Another issue with using Bower is that it's a [NodeJS](https://nodejs.org) application. That means we need Node and NPM installed. We'll solve
that using the [gradle-node-plugin](https://github.com/srs/gradle-node-plugin).

In summary, here's what we'll be doing:

1. Use gradle-node-plugin to ensure bower is installed
2. Specify bower packages to install
3. Copy production files to the web application destination

All source code for this post and a working application are available on [GitHub.com/double16/pet-store](https://github.com/double16/pet-store).

# Managing Node and Bower in Gradle
Bower is a NodeJS package. Although many development and CI environments have Node installed, that's not guaranteed to
be true or perhaps differing versions cause problems for your application. Ideally a Gradle build consists of having a
JDK installed, pull the repo, and run `./gradlew build`.

The gradle-node-plugin manages an install of Node and NPM (Node Package Manager) from your Gradle build to deliver
consistent behavior whenever you build. It can be configured to use an existing Node install, or always download the
specified version. Now we'll add this plugin to our build.

Add the dependency:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=gradle-node-plugin-dep.gradle"]

Configure Node versions:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=node-config.gradle"]

Since caching of dependencies is important for a faster build, we'll instruct the Gradle managed NPM to cache packages
into our Gradle cache. In order for this to work, the tasks we'll create later need to depend on this task.

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=npmCacheConfig.gradle"]

## Installing Bower
We'll use the `package.json` file to specify dependencies for NPM and then invoke it to install those dependencies. This file
belongs in the root of the project. You can read about the contents of the file at [docs.npmjs.com](https://docs.npmjs.com/files/package.json).

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=package.json"]

Now we need a task to install NPM dependencies. There is an `npmInstall` task provided with the gradle-node-plugin, but
it doesn't install into our local `node_modules` folder and we want that to avoid version conflicts and also to be able
to find the `bower` command without depending on the search path. It looks like the location of the `node_modules` folder
can be specified in the latest plugin, but that code was not released as of this writing.

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=npmInstall-dep.gradle"]

Run `./gradlew npmPackages` and Gradle will install Node, NPM and Bower. All will be cached in the Gradle user home. This
should work across operating systems and not depend on anything but a properly installed JDK 1.7+.

# Specifying Bower Packages
Bower uses a file named `bower.json` to specify package dependencies. In this project we're bringing in [AngularJS](https://angularjs.org)
and [Animate.css](http://daneden.github.io/animate.css/).

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=bower.json"]

The following task will invoke Bower to download, cache and install the packages at `bower_components`:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=bowerInstall.gradle"]

# Copying Production Files
The most difficult part of this process is how to get the files Bower has fetched for us into our application. Bower
fetches the entire repository so we have more files than we want in production. There is no definitive way to determine
which files we need out of each repo automatically, so we'll use a Gradle Sync task to copy over the files.

You will need to inspect each package for the files you want. In this example we've excluded the minified versions because
we're using the `asset-pipeline` plugin to minify things for us. We're including all of the files in one `application.js`
file and they will be minified together. This part isn't necessary, you can include the minified versions and include each
individually. The important part is that you need to identify which files will be installed in production.

Here is the task for the JavaScript files:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=bowerSyncJavascript.gradle"]

Here is the task for the Stylesheets:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=bowerSyncStylesheets.gradle"]

For convenience we'll have one task that depends on both:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=bowerPackages.gradle"]

Now we'll have the `processResources` and `assetCompile` tasks depend on the `bowerPackages` task so our files will be
copied before running the application or compiling. `processResources` is specific to the `java` Gradle plugin, and
`assetCompile` is specific to the `asset-pipeline` plugin used by Grails. You might need to
adjust these dependencies to ensure the files are available when needed. It's a good idea to use the `--dry-run` flag to
verify the tasks are called at the correct time and try your builds on a clean workspace.

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=bowerPackages-dep.gradle"]

The final Gradle change is to augment the `clean` task to remove the `node_modules` and `bower_components` folders.

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=clean.gradle"]

You'll want to add the following to your `.gitignore` file:

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=gitignore"]

# Include the File in the Grails Application
One more thing to do and that's include the bower-managed dependencies in our application. This is a Grails 3 application,
when you're using another stack including the files will be different.

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=application.js"]

[addjs src="https://gist.github.com/double16/c27be33bacf83fa5d626.js?file=application.css"]

There's more work left to actually _use_ these in our application. The pet-store application is intended to demonstrate
that the dependencies are brought in correctly and not necessarily an example of best practice use of AngularJS and Animate.css
in a Grails application, but go ahead and take a look at the page source and note that the dependencies are included.

# Run It!
We should now be able to run our application and use the JS/CSS Bower has installed.

```shell
./grails run-app
```

# Conclusion
Dependency management is an important problem to solve and we want to avoid manually downloading and copying JS/CSS and
the like into our repository. Bower is a popular solution and many projects publish to it. There's a bit of work to set up
Gradle to invoke Bower (made *much* easier by the gradle-node-plugin), but once done maintenance will be significantly
easier. Now we have proper dependency management in a Gradle build with one step to an executable. Also, it appears that
most of this work could be added to the gradle-node-plugin and a new task created for installing Bower dependencies.
