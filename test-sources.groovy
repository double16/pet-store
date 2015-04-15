#!/usr/bin/env groovy
@GrabResolver(name='local', root='/Users/pdouble/.m2/repository')
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
import org.apache.http.impl.client.DefaultHttpClient
import org.apache.http.client.methods.HttpPut
import org.apache.http.entity.FileEntity

Logger.getLogger("org.apache.http.headers").setLevel(Level.DEBUG)
//Logger.getLogger("org.apache.http.wire").setLevel(Level.DEBUG)

def file = new File("build/distributions/pet-store-0.1.tar")

        RESTClient heroku = new RESTClient("https://api.heroku.com/apps/${System.getenv("HEROKU_APP_NAME")}/")
        heroku.headers['Authorization'] = "Bearer ${System.getenv('HEROKU_AUTH_TOKEN')}"
        heroku.headers['Accept'] = 'application/vnd.heroku+json; version=3'

	// upload sources
	def sources = heroku.post(path: 'sources')
        def put_url = sources.data.source_blob.put_url
        def get_url = sources.data.source_blob.get_url

        // upload sources
	System.err.println "Uploading ${file} to ${put_url}"
        def res = new DefaultHttpClient().execute(new HttpPut(URI: new URI(put_url), entity: new FileEntity(file)))
        if (res.statusLine.statusCode > 399) {
            throw new IOException(res.statusLine.reasonPhrase)
        }

        // start the build
	System.err.println "Building ${get_url}"
	heroku.post(path: 'builds', requestContentType: 'application/json',
            body: ['source_blob': ['url':get_url, 'version': 'test' ]]
        )

