#!/usr/bin/env groovy
@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.7.2')
// This brings in slf4j, log4j12 (as dependancies) and the bridge to log4j
@Grab(group='org.slf4j', module='slf4j-log4j12', version='1.7.7')
// This brings in the bridge to commons-logging
@Grab(group='org.slf4j', module='jcl-over-slf4j', version='1.7.7')

import groovyx.net.http.RESTClient
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import groovyx.net.http.ContentType
import groovy.util.slurpersupport.GPathResult
import org.apache.log4j.Logger
import org.apache.log4j.Level
import static groovyx.net.http.ContentType.URLENC

Logger.getLogger("org.apache.http.headers").setLevel(Level.DEBUG)
Logger.getLogger("org.apache.http.wire").setLevel(Level.DEBUG)

def file = new File("build/distributions/pet-store-slug-0.1.tgz")

        RESTClient heroku = new RESTClient("https://api.heroku.com/apps/${System.getenv("HEROKU_APP_NAME")}/")
        heroku.headers['Authorization'] = "Bearer ${System.getenv('HEROKU_AUTH_TOKEN')}"
        heroku.headers['Accept'] = 'application/vnd.heroku+json; version=3'

        // create the slug
        def slug = heroku.post(path: 'slugs', requestContentType: "application/json",
                body: ["process_types": [ "web": "java -jar \$JAVA_OPTS pet-store-0.1.jar"]])

        // upload the slug
        new HTTPBuilder().request(slug.data.blob.url, Method.PUT, ContentType.ANY) {
            requestContentType = 'application/octet-stream'
            body = file.newInputStream()
            headers.'Content-Type' = ''
        }

        // release the slug
        heroku.post(path: 'releases', requestContentType: 'application/json',
            body:[ 'slug': slug.data.id ])

