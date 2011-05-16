import urllib,urllib2,json
from MultipartPostHandler import MultipartPostHandler

# Settings
key = "tuldTHueMYlZOioR7YDD"
secret = "XSM71hYeIcUeUdqG"
image_filename = "sample.jpg"
id = "test1234"

# urllib boilerplate
api_ep_base = "http://api.moodstocks.com"
api_ep = api_ep_base + "/v2"
pass_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
pass_manager.add_password(None,api_ep_base,key,secret)
auth_handler = urllib2.HTTPDigestAuthHandler(pass_manager)
opener = urllib2.build_opener(auth_handler)
multipart_opener = urllib2.build_opener(auth_handler,MultipartPostHandler)

# Results handler
def disp(r):
  print json.loads(r.read())

# Authenticating with your API key (Echo service)
qstring = urllib.urlencode({"foo":"bar","bacon":"chunky"})
disp(opener.open("%s?%s" % (api_ep+"/echo",qstring))) 

# Adding objects to recognize
imgdata = {"image_file":open(image_filename,"rb")}
req = urllib2.Request(api_ep+"/ref/"+id,imgdata)
req.get_method = lambda: "PUT"
disp(multipart_opener.open(req))

# Looking up objects
disp(multipart_opener.open(api_ep+"/search",imgdata))

# Removing reference images
req = urllib2.Request(api_ep+"/ref/"+id,"")
req.get_method = lambda: "DELETE"
disp(opener.open(req))
