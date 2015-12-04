import jenkins.model.*
import hudson.security.*
import hudson.security.captcha.CaptchaSupport
import org.jenkinsci.plugins.*

def instance = Jenkins.getInstance()

def securityRealm = new HudsonPrivateSecurityRealm(false, false, (CaptchaSupport) null)

//def env = System.getenv()
//def username = env['OS_USERNAME']
//def password = env['OS_PASSWORD']
def username = (java.lang.String) "admin"
def password = (java.lang.String) "snappy"
securityRealm.createAccount(username, password)

instance.setSecurityRealm(securityRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)

instance.save()