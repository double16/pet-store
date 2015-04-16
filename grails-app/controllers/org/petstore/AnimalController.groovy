package org.petstore

import static org.springframework.http.HttpStatus.*
import grails.transaction.Transactional

@Transactional(readOnly = true)
class AnimalController {

    static allowedMethods = [save: "POST", update: "PUT", delete: "DELETE"]

    def index(Integer max) {
        params.max = Math.min(max ?: 10, 100)
        respond Animal.list(params), model:[animalCount: Animal.count()]
    }

    def show(Animal animal) {
        respond animal
    }

    def create() {
        respond new Animal(params)
    }

    @Transactional
    def save(Animal animal) {
        if (animal == null) {
            transactionStatus.setRollbackOnly()
            notFound()
            return
        }

        if (animal.hasErrors()) {
            transactionStatus.setRollbackOnly()
            respond animal.errors, view:'create'
            return
        }

        animal.save flush:true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.created.message', args: [message(code: 'animal.label', default: 'Animal'), animal.id])
                redirect animal
            }
            '*' { respond animal, [status: CREATED] }
        }
    }

    def edit(Animal animal) {
        respond animal
    }

    @Transactional
    def update(Animal animal) {
        if (animal == null) {
            transactionStatus.setRollbackOnly()
            notFound()
            return
        }

        if (animal.hasErrors()) {
            transactionStatus.setRollbackOnly()
            respond animal.errors, view:'edit'
            return
        }

        animal.save flush:true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.updated.message', args: [message(code: 'animal.label', default: 'Animal'), animal.id])
                redirect animal
            }
            '*'{ respond animal, [status: OK] }
        }
    }

    @Transactional
    def delete(Animal animal) {

        if (animal == null) {
            transactionStatus.setRollbackOnly()
            notFound()
            return
        }

        animal.delete flush:true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.deleted.message', args: [message(code: 'animal.label', default: 'Animal'), animal.id])
                redirect action:"index", method:"GET"
            }
            '*'{ render status: NO_CONTENT }
        }
    }

    protected void notFound() {
        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.not.found.message', args: [message(code: 'animal.label', default: 'Animal'), params.id])
                redirect action: "index", method: "GET"
            }
            '*'{ render status: NOT_FOUND }
        }
    }
}
