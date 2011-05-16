require "luacurl"
require "cgilua"
require "pl.pretty"
require "json"

-- Settings
key = "tuldTHueMYlZOioR7YDD"
secret = "XSM71hYeIcUeUdqG"
image_filename = "sample.jpg"
id = "test1234"
api_ep = "http://api.moodstocks.com/v2"

-- cURL
result_data = ""
data = function(stream,buf)
  result_data = result_data .. buf
  return string.len(buf)
end

new_curl = function(url)
  c = curl.new()
  c:setopt(curl.OPT_URL,api_ep .. url)
  c:setopt(curl.OPT_WRITEFUNCTION,data)
  c:setopt(curl.OPT_HTTPAUTH,curl.AUTH_DIGEST)
  c:setopt(curl.OPT_USERPWD,key .. ":" .. secret)
  return c
end

disp = function(c)
  pl.pretty.dump(json.decode(result_data))
  c:close()
  result_data = ""
end

-- Authenticating with your API key (Echo service)
c = new_curl("/echo?" .. cgilua.urlcode.encodetable{foo="bar",bacon="chunky"})
c:perform()
disp(c)
