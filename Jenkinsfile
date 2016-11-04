
// based on https://github.com/lordofthejars/starwars/blob/master/Jenkinsfile
void gradle(Collection<String> tasks, Collection<String> switches = null) {
  String gradleCommand = "";
  gradleCommand += './gradlew '
  gradleCommand += tasks.join(' ')

  if(switches) {
      gradleCommand += ' '
      gradleCommand += switches.join(' ')
  }

  if (System.properties['os.name'].toLowerCase().contains('windows')) {
    bat gradleCommand.toString()
  } else {
    sh gradleCommand.toString()
  }
}


stage 'Compile and Test'
node {

  // get source code
  checkout scm

  gradle(['clean','classes'], ['-i'])

  // save source code so we don't need to get it every time and also avoids conflicts
  stash excludes: 'build/', includes: '**', name: 'source'

  gradle(['test'], ['-i'])
  stash includes: 'build/test-results/**', name: 'unitTests'

}

stage 'Integration Test'
node {
  unstash 'source'
  unstash 'unitTests'
  gradle(['integrationTest'], ['-i'])
  stash includes: 'build/test-results/**', name: 'allTests'
}

stage 'Code Quality'
node {
  unstash 'allTests'
  // publish JUnit results to Jenkins
  step([$class: 'JUnitResultArchiver', testResults: '**/build/test-results/*.xml'])
}

