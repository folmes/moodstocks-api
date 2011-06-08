require "as-extensions"
ASE::need %w{map must_be twitter twitterstream httparty rest-client}

# HTTParty HTTP Digest Auth patch
HTTParty::Request.class_eval do
  alias :orig_setup_digest_auth :setup_digest_auth
  def setup_digest_auth
    options.delete(:headers)
    orig_setup_digest_auth
  end
end

module MsTwitter

  CFG = {
    msapi: {
      key: ENV["MS_API_KEY"],
      secret: ENV["MS_API_SECRET"],
    },
    twitter: {
      cons_key: ENV["TWITTER_CONSUMER_KEY"],
      cons_secret: ENV["TWITTER_CONSUMER_SECRET"],
      oauth_token: ENV["TWITTER_OAUTH_TOKEN"],
      oauth_secret: ENV["TWITTER_OAUTH_SECRET"],
    },
  }

end

module MsTwitter module MsApi

  class Ep
    include HTTParty
    base_uri("http://api.moodstocks.com")
    digest_auth(CFG[:msapi][:key],CFG[:msapi][:secret])
  end

  class << self

    def search(image_url)
      r = Ep::post("/v2/search",{body:"",query:{image_url:image_url}})
      r = JSON.parse(r.body)
      r["found"] ? Base64.urlsafe_decode64(r["id"],true) : nil
    end

    def add(image_fname,text)
      text.length.must_be <= 118
      enc = Base64.urlsafe_encode64(text,true)
      body,headers = File.open(image_fname,'rb') do |f|
        mp = RestClient::Payload::Multipart.new(image_file:f)
        [mp.read,mp.headers]
      end
      JSON.parse(Ep::put("/v2/ref/#{enc}",{body:body,headers:headers}).body)
    end

  end # class << self

end end

module MsTwitter class Worker

  def image_url_for(url)
    return nil unless url.is_a?(String)
    url.strip!
    uri = URI.parse(url)
    if url.match(/\.jpg$/)
      url
    elsif url.match(/^http\:\/\/yfrog\./)
      "#{url}:iphone"
    elsif url.match(/^http\:\/\/twitpic\./)
      "http://twitpic.com/show/iphone#{uri.path}.jpg"
    else nil end
  end

  def initialize
    nil.must_not_be_in(CFG[:twitter].values)
    nil.must_not_be_in(CFG[:msapi].values)
    Twitter.configure do |config|
      config.consumer_key = CFG[:twitter][:cons_key]
      config.consumer_secret = CFG[:twitter][:cons_secret]
      config.oauth_token = CFG[:twitter][:oauth_token]
      config.oauth_token_secret = CFG[:twitter][:oauth_secret]
    end
    @twitter = Twitter::Client.new
    @stream = TwitterStream.new({
      consumer_token: CFG[:twitter][:cons_key],
      consumer_secret: CFG[:twitter][:cons_secret],
      access_token: CFG[:twitter][:oauth_token],
      access_secret: CFG[:twitter][:oauth_secret],
    })
    @my_screen_name = @twitter.user.screen_name
  end

  def run
    puts "Running with user @#{@my_screen_name}"
    @stream.userstreams do |status|
      begin
        status = Map(status)
        next if status[:user].nil?
        (user = status[:user][:screen_name]).must_be_a(String)
        next if user == @my_screen_name
        puts "From @#{user}: #{status[:text]}"
        status[:entities][:urls].each do |x|
          image_url = image_url_for(orig_url = x[:expanded_url] || x[:url])
          puts "url: #{orig_url} -> #{image_url}"
          if (image_url = image_url_for(x[:expanded_url]||x[:url])).nil?
            puts "Invalid URL"; next
          end
          unless (text = MsApi.search(image_url))
            puts "Not found"; next
          end
          puts "Sending @#{user}: #{text}"
          (to_send = "@#{user} #{text}").length.must_be <= 140
          @twitter.update(to_send)
        end
      rescue => e
        ASE::log(e.inspect,:error)
      end
    end
  end

end end

module MsTwitter module Cli; class << self

  def add(*args)
    usage unless args.size == 2
    puts MsApi.add(args.shift,args.shift).inspect
  end

  def run(*args)
    m = (args.head || "nomethodpassed").underscore.to_sym
    respond_to?(m) ? send(m,*args.tail) : usage
  end

  def work(*args)
    usage unless args.size == 0
    MsTwitter::Worker.new.run
  end

  def usage
    puts <<-end
USAGE EXAMPLES:
  ruby mstwitter.rb work
  ruby mstwitter.rb add my_image.jpg "text for my tweet"
    end
    exit!
  end

end end end

if __FILE__ == $0
  MsTwitter::Cli::run(*ARGV)
end
