import jenkins.model.*
import groovy.io.FileType

def dir = new File("/usr/share/jenkins/ref/jobs")
def jobName = ""
def xmlConfig = ""

def jobNames = Jenkins.instance.getJobNames()

dir.eachFileRecurse (FileType.FILES) { file ->
    jobName = file.name.lastIndexOf('.').with {it != -1 ? file.name[0..<it] : file.name}

    if (! jobNames.contains(jobName)) {
        xmlConfig = file.text
        def xmlStream = new ByteArrayInputStream( xmlConfig.getBytes() )

        println "Creating job $jobName..."
        Jenkins.instance.createProjectFromXML(jobName, xmlStream)
    }
}
