Deploying Grails 3 Applications (and other fat jars) to Heroku
==============================================================

[Heroku](https://heroku.com) users that have run into the 15 minute build timeout should not have to change their source or technology choice
to continue using Heroku. This post outlines a method using [Gradle](http://gradle.org) to work-around that limit and still leverage the advantages
of building from source. We are targeting [Grails](http://grails.org) applications, but the procedure can be tailored to other languages.

Heroku is an application hosting provider targeting developers. The primary deployment method is to push source code to
the git repository that Heroku creates for every application. Heroku will detect how to build the source using a set of
build packs, build it, and if successful deploy and run the application.

The build stage has the 15 minute timeout. This includes downloading dependencies, compiling, assembling, etc. As an
application grows larger the 15 minutes can make it impossible to build, even with [dependency caching](https://devcenter.heroku.com/articles/buildpack-api#caching).

All source code for this blog and a working application are available on [GitHub.com/double16/pet-store](https://github.com/double16/pet-store).

# Slug Design
Heroku runs applications on [dynos](https://devcenter.heroku.com/articles/dynos), which are virtual machines with certain specifications. The virtual machines follow
the immutable infrastructure approach. On each application deploy, or adjustment to the number of dynos to run, a new virtual
machine is created. The running machines are never maintained or configured after being created. The filesystem image run
is called a [slug](https://devcenter.heroku.com/articles/slug-compiler).

The slug is a GNU tar file, gzipped, with the application binaries in an `app` folder. Runtime dependencies beyond basic
Linux tools must be included, such as the JDK to use for your Grails application. The slug is tied to a specific architecture
which Heroku identifies with a code name, the current being "cedar-14", an Ubuntu image. The build packs take the source,
build it, and assemble into a slug for deployment.

# What is Needed to Run Grails 3 Applications on Heroku
Few artifacts are needed to run Grails 3 applications (or Grails 2.x using the [build-standalone](https://grails.org/plugin/standalone) plugin), or really any
Java web application that is packaged in a WAR. The most concise way to do this is with a "fat jar". A fat jar contains
all of the applications code, content (GSP, JS, CSS, etc), dependency jars, and a servlet container such as tomcat or
jetty. The fat jar is a Java application that can be run using the `java -jar` command which starts the servlet container
and serves the web app as if the WAR were deployed to the container. Sometimes the fat jar has a .jar extension and sometimes
a .war. The .war is a bit more flexible in that it can be deployed to an application container in addition to being run
standalone. The .jar extension is recognized by operating systems as runnable by the Java platform.

Grails 3 uses Gradle as the build system and provides a `bootRepackage` task to take the application jar and turn it into
a runnable web app. There are other methods, such as using the .tar packaging and associated shell script, but we'll
stick to the fat jar approach to keep to the point - how to get this running on Heroku without hitting the 15 minute
build limit. The fat jar is all we need for a simple web app, it is trivial to include other artifacts such as the
[newrelic](http://newrelic.com) agent, properties files, etc.

# Platform API
Instead of using Heroku's git repo to push the source code we're going to build a different source package containing
our fat jar and push it using [Heroku's Platform API](https://devcenter.heroku.com/articles/build-and-release-using-the-api).
The Platform API provides all of the functionality of Heroku in
a REST interface so it can be used programmatically. The steps we'll take are:

1. Build a source tarball containing the fat jar and other files Heroku needs (explained below)
2. Create an endpoint on Heroku to host the tarball via the ["sources"](https://devcenter.heroku.com/articles/build-and-release-using-the-api#sources-endpoint) REST service
3. [Upload](https://devcenter.heroku.com/articles/build-and-release-using-the-api#use-the-source_blob-put_url-to-upload-data) the tarball
4. Create a [build](https://devcenter.heroku.com/articles/build-and-release-using-the-api#create-a-build-using-source_blob-get_url) from the tarball

# Faking a Java Build
We're going to do a "fake" Java build on Heroku with an already built fat jar. This will make the build time nearly
constant over the lifetime of the application and keep us well within the 15 minute timeout.

We could build a slug and deploy that, the Platform API provides such services. I've tried that and failed, and decided
later I didn't like it even if it worked. First, the slug must be a GNU tar and not POSIX. The Gradle Tar task creates a
POSIX archive. I tried to find a Java library that created a GNU tar but was not successful. It seems fragile to do so.

Second, the JDK must be included in the slug and it must match the target stack, currently `cedar-14`. The distributions of
OpenJDK Heroku uses are available publicly. I don't like this because each project must update the project build for new
versions of the JDK, the slug size is much larger than the source tarball we'll create, and we're duplicating effort with
the Heroku team maintaining the Java build pack.

Faking a Java build will leverage the work the Heroku team is doing with the expense of a small Maven build and jar that
won't ever be used. (See [Heroku Java Support](https://devcenter.heroku.com/articles/java-support) for details).
Heroku's default Java build pack uses Maven. There are others supporting Grails, Gradle and other build
systems. Maven is the most simple and the default. If someone finds a better way, feel free to submit a pull request on
the pet-store repo. Note that the slug will contain all of the files in the source tarball, unless it is excluded with
a `.slugignore` file in the root folder, which is similar to `.gitignore`. Since we're building the source tarball
specifically for the build, we don't need to ignore anything.

In addition to the fat jar, we need to give Heroku some other files to tell the build which version of the JDK we want
and how to run our application. This is well documented on Heroku, so only summary is given here.

The [`Procfile`](https://devcenter.heroku.com/articles/procfile) file tells Heroku how many types of processes the application requires, the only required one being `web`. It
also includes the command to execute.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=Procfile"]

The [`system.properties`](https://devcenter.heroku.com/articles/java-support#specifying-a-java-version) file tells the build pack which version of the JDK to include, such as 1.8 or 1.7.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=system.properties"]

We need a `pom.xml` for the Java build pack to work. This will be generated by the Gradle build.

# Mechanics of using Platform API
I've found the REST interface to be easy to use from Gradle, using the Groovy RESTClient class. However, uploading the source
was troublesome. The upload is directly to AWS and it is picky, not wanting a "Content-Type" header, which other
tools think it should be there and so the upload fails. I found using the `org.apache.http.impl.client.DefaultHttpClient` from
the Apache `httpclient` library to be concise and stable.

First, we need to be able to authenticate to Heroku and tell it which application to work with. We specify these in
environment variables to keep the secret out of source control, and being flexible in the application name allows the
build to be deployed to a staging environment, etc.

```shell
$ heroku auth:token
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
$ export HEROKU_AUTH_TOKEN=$(heroku auth:token)
$ export HEROKU_APP_NAME=arcane-savannah-7223
```

Creating the REST client is simple. We'll re-use this for the two services we need.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=restclient.gradle"]

We need to call the `sources` service to create an endpoint to temporarily host our source code. This endpoint lives for
about an hour, which is plenty for our build.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=heroku-sources.gradle"]

I've found uploading to be very specific and tried several ways of using HTTPBuilder to get it working. Using
DefaultHttpClient directly works and Groovy makes it concise.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=heroku-upload.gradle"]

Finally, we'll trigger Heroku to build the source and if successful, deploy it.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=heroku-build.gradle"]

# Gradle Build
Now we'll put it all together. The pet-store application was created by `grails create-app`. This will create several files,
including the `build.gradle` file we're interested in. This is the only file we need to touch in the Grails application. The
`Procfile` and `system.properties` files are only for Heroku, Grails doesn't need them.

We're going to create Gradle tasks to create a pom.xml, build the source tarball, and deploy it to Heroku. The full source
is at [build.gradle](https://github.com/double16/pet-store/blob/master/build.gradle). Some of the build is generated from Grails 3, we'll
focus on our additions.

[addjs src="https://gist.github.com/double16/b58fca44e009cce82076.js?file=build.gradle"]

The `emptyPom` task creates the `pom.xml` that Heroku will build. This will quickly create an empty jar file. The important
thing is that Heroku will detect this as a Java build and create a slug with Java installed, using the `system.properties`
file to determine the JDK version.

The `herokuSources` task creates the sources tarball that includes the fat jar, `Procfile`, `system.properties`, and `pom.xml`
that will deploy the application. Additional resources needed during runtime can be added using a `from` line in this task. Read
the Gradle user guide on [Creating Archives](http://gradle.org/docs/current/userguide/working_with_files.html) for details on
how archives are built.

The `deployToHeroku` task uses the Platform API to upload the sources and build. It requires the definition of
`HEROKU_AUTH_TOKEN` and `HEROKU_APP_NAME` in the environment.

Once you have these tasks in your `build.gradle` file, execute the task and the application will be built and deployed.
(You'll want to run your tests first, this task won't do that)

```shell
$ ./gradlew deployToHeroku
```

# Conclusion
Heroku is a developer centric application platform. One of the cool features is that the developer can push code and
Heroku will perform the build and deploy. If it is undesirable to use this feature, the Heroku Platform API and Gradle
can concisely deploy the binary application.
