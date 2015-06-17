import grails.util.Environment

beans = {
    switch(Environment.current) {
        case Environment.DEVELOPMENT:
        case Environment.TEST:
            // We need to have mongodb started before GORM
            def mongodb = new EmbeddedMongoDB()
            mongodb.start()
            embeddedMongodb(EmbeddedMongoDB) {
                port = mongodb.port
                executable = mongodb.executable
            }
            break
    }
}
