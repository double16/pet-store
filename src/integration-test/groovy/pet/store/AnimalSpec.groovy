package pet.store

import grails.testing.mixin.integration.Integration
import grails.transaction.*

import geb.spock.*

@Integration
@Rollback
class AnimalSpec extends GebSpec {

    def setup() {
    }

    def cleanup() {
    }

    void "test something"() {
        when:"The home page is visited"
            go '/animal'

        then:"The title is correct"
        	title == "Animal List"
    }
}
