
import de.flapdoodle.embed.mongo.Command
import de.flapdoodle.embed.mongo.MongodExecutable
import de.flapdoodle.embed.mongo.MongodStarter
import de.flapdoodle.embed.mongo.config.MongodConfigBuilder
import de.flapdoodle.embed.mongo.config.Net
import de.flapdoodle.embed.mongo.config.RuntimeConfigBuilder
import de.flapdoodle.embed.mongo.distribution.Version
import de.flapdoodle.embed.process.config.IRuntimeConfig
import de.flapdoodle.embed.process.config.io.ProcessOutput

import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import java.util.logging.Logger

/**
 * Spring component to manage a MongoDB install for development and testing.
 */
class EmbeddedMongoDB {
    int port = 27017
    MongodExecutable executable

    @PostConstruct
    void start() {
        if (!executable) {
            def mongodConfig = new MongodConfigBuilder()
                .version(Version.Main.PRODUCTION)
                .net(new Net(InetAddress.getLoopbackAddress().getHostAddress(), port, InetAddress.getLoopbackAddress().getAddress().length > 4))
                .build()
            Logger logger = Logger.getLogger(getClass().getName());
            //ProcessOutput processOutput = new ProcessOutput(Processors.logTo(logger, Level.FINE), Processors.logTo(logger, Level.FINE), Processors.logTo(logger, Level.FINE))
            //ProcessOutput processOutput = new ProcessOutput(Processors.console(), Processors.console(), Processors.console())
            ProcessOutput processOutput = ProcessOutput.getDefaultInstanceSilent()
            IRuntimeConfig runtimeConfig = new RuntimeConfigBuilder()
                .defaultsWithLogger(Command.MongoD, logger)
                .processOutput(processOutput)
                .build()
            executable = MongodStarter.getInstance(runtimeConfig).prepare(mongodConfig)
            executable.start()            
        }
    }
    
    @PreDestroy
    void stop() {
        if (executable) {
            executable.stop()
            executable = null
        }
    }
}

