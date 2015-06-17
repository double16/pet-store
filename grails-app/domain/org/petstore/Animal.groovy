package org.petstore

import grails.rest.Resource

@Resource(uri="/animals", formats = ['json','xml'])
class Animal {
    String name
    boolean specialOrder

    static constraints = {
    }
}
