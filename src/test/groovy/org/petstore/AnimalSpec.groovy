package org.petstore

import grails.testing.gorm.DomainUnitTest
import spock.lang.Ignore
import spock.lang.Specification

class AnimalSpec extends Specification implements DomainUnitTest<Animal> {

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
