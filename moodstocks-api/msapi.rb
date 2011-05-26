%w{rubygems httparty rest-client uri json}.each{|x| require x}

# Settings
@@key = "YourApiKey"
@@secret = "YourApiSecret"
image_filename = "sample.jpg"
image_url = "http://api.moodstocks.com/static/sample-book.jpg"
id = "test1234"

# HTTParty HTTP Digest Auth patch
HTTParty::Request.class_eval do
  alias :orig_setup_digest_auth :setup_digest_auth
  def setup_digest_auth
    options.delete(:headers)
    orig_setup_digest_auth
  end
end

class MSApi
  include HTTParty
  base_uri("http://api.moodstocks.com")
  digest_auth(@@key,@@secret)
end
ep = "/v2"

# Results handler
def disp(r)
  puts JSON.parse(r.body)
end

# Authenticating with your API key (Echo service)
disp(MSApi::get("#{ep}/echo",{query:{foo:"bar",bacon:"chunky"}}))

# Adding objects to recognize
body,headers = File.open(image_filename,'rb') do |f|
  mp = RestClient::Payload::Multipart.new(image_file:f)
  [mp.read,mp.headers]
end
imgdata = {body:body,headers:headers}
disp(MSApi::put("#{ep}/ref/#{id}",imgdata))

# Looking up objects
disp(MSApi::post("#{ep}/search",imgdata))

# Updating a reference & using a hosted image
disp(MSApi::put("#{ep}/ref/#{id}",{body:"",query:{image_url:image_url}}))

# Removing reference images
disp(MSApi::delete("#{ep}/ref/#{id}"))
