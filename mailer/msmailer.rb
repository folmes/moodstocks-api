require "as-extensions"
ASE::need %w{mms2r httparty restclient mail}

module MMS2R class MMS2R::Media
  def default_image; attachment(['image']) end
end end

# HTTParty HTTP Digest Auth patch
HTTParty::Request.class_eval do
  alias :orig_setup_digest_auth :setup_digest_auth
  def setup_digest_auth
    options.delete(:headers)
    orig_setup_digest_auth
  end
end

module MS class Api
  include HTTParty
  base_uri "api.moodstocks.com"
  digest_auth ENV["MS_API_KEY"], ENV["MS_API_SECRET"]
  
  class << self
    SEARCH = '/v2/search'
    REF    = '/v2/ref/%s'
    
    def search(image_fname)
      File.open(image_fname,'rb') do |f|
        mp = RestClient::Payload::Multipart.new(image_file:f)
        r = JSON.parse(post(SEARCH, {body:mp.read, headers:mp.headers}).body)
        r["found"] ? Base64.urlsafe_decode64(r["id"], true) : nil
      end
    end

    def add(url, image_fname)
      File.open(image_fname,'rb') do |f|
        mp = RestClient::Payload::Multipart.new(image_file:f)
        uid = Base64.urlsafe_encode64(url, true)
        JSON.parse(put(REF % uid, {body:mp.read, headers:mp.headers}).body)
      end
    end
  
  end

end end

module MS class Gmail
  class << self
  
    def reply(mail, resp)
      r = mail.reply do
        text_part do
          body "Hello,\n\nWe've found this: #{resp}.\n\nCheers,\n\nMoodstocks Mailer."
        end
        delivery_method(:smtp, {address:'smtp.gmail.com',
                                port:'587',
                                enable_starttls_auto:true,
                                user_name:ENV["GMAIL_USERNAME"],
                                password:ENV["GMAIL_PASSWORD"],
                                authentication: :plain,
                                domain:"HELO"})
      end
      r.deliver!
    end

  end
end end

module MS class Mailer
  def self.process(raw_mail)
    Mailer.new(raw_mail).run
  end
  
  def run
    begin
      img, url = @media.default_image, @media.subject.slice(URI.regexp)
      unless img.blank?
        if url.blank?
          search(img.path)
        else
          add(url, img.path)
        end
      end
    rescue => e
      ASE::log(e.inspect, :error)
    end
  end
  
  def add(url, img)
    MS::Api.add(url, img)
  end
  
  def search(img)
    url = MS::Api.search(img)
    MS::Gmail.reply(@media.mail, url) unless url.blank?
  end
    
  def initialize(raw_mail)
    @media = MMS2R::parse(raw_mail)
  end
    
end end

if __FILE__ == $0
  MS::Mailer.process(STDIN.read)
end
