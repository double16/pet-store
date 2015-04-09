package org.petstore

import grails.test.mixin.TestFor
import spock.lang.Ignore
import spock.lang.Specification

/**
 * See the API for {@link grails.test.mixin.domain.DomainClassUnitTestMixin} for usage instructions
 */
@TestFor(Animal)
class AnimalSpec extends Specification {

    def setup() {
    }

    def cleanup() {
    }

    @Ignore
    void "test something"() {
        expect:"fix me"
            true == false
    }
}
