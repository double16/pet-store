package pet.store

import grails.testing.mixin.integration.Integration
import grails.transaction.*

import geb.spock.*

@Integration
@Rollback
class HomeSpec extends GebSpec {

    def setup() {
    }

    def cleanup() {
    }

    void "test something"() {
        when:"The home page is visited"
            go '/'

        then:"The title is correct"
        	title == "Welcome to Grails"
    }
}
