# NOTE: get rufus-verbs at https://github.com/catwell/rufus-verbs

%w{rubygems rufus-verbs rest-client uri json}.each{|x| require x}

# Settings
@@key = "YourApiKey"
@@secret = "YourApiSecret"
image_filename = "sample.jpg"
image_url = "http://api.moodstocks.com/static/sample-book.jpg"
id = "test1234"

class MSApi; include Rufus::Verbs

  attr_reader :ep

  def initialize
    @ep = EndPoint.new({
      host: "api.moodstocks.com",
      port: 80,
      resource: "v2",
      digest_authentication: [@@key,@@secret],
    })
  end

  def disp(r)
    if r.code.to_i == 200
      puts "[OK]\t#{JSON.parse(r.body)}"
    else
      puts "[ERROR]\t#{r.code} #{r.body}"
    end
  end

  def do(verb,resource,pp={})
    disp ep.send(verb,pp.merge(id: resource))
  end

end

MS = MSApi.new

# Authenticating with your API key (Echo service)
MS.do(:get,"echo",{params:{query:{foo:"bar",bacon:"chunky"}}})

# Adding a reference image
body,headers = File.open(image_filename,'rb') do |f|
  mp = RestClient::Payload::Multipart.new(image_file:f)
  [mp.read,mp.headers]
end
imgdata = {data:body,headers:headers}
MS.do(:put,"ref/#{id}",imgdata)

# Making an image available offline
MS.do(:post,"ref/#{id}/offline",{data:""})

# Using online search
MS.do(:post,"search",imgdata)

# Updating a reference & using a hosted image
MS.do(:put,"ref/#{id}",{data:"",query:{image_url:image_url}})

# Removing reference images
MS.do(:delete,"ref/#{id}")
