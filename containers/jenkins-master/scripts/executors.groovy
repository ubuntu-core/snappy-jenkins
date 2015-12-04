import hudson.model.*

Hudson hudson = Hudson.getInstance()
hudson.setNumExecutors(8)
hudson.setNodes(hudson.getNodes())

hudson.save()