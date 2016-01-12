import hudson.model.*

Hudson hudson = Hudson.getInstance()
hudson.setNumExecutors(0)
hudson.setNodes(hudson.getNodes())

hudson.save()