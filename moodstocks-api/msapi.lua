-- Requirements:
-- - a JSON parser (eg. luajson)
-- - Penlight (to display results)
-- - https://github.com/catwell/lua-http-digest
-- - https://github.com/catwell/lua-multipart-post

local pretty = require "pl.pretty"
local ltn12 = require "ltn12"
local J = (require "json").decode
local MP = (require "multipart-post").gen_request
local H = (require "http-digest").request

--- Settings
local key = "YourApiKey"
local secret = "YourApiSecret"
local image_filename = "sample.jpg"
local image_url = "http://api.moodstocks.com/static/sample-book.jpg"
local sample_id = "test1234"

--- Boilerplate

local api = string.format("http://%s:%s@api.moodstocks.com/v2",key,secret)
local join = function(...) return table.concat({...},"/") end

local disp = function(method,ep,rq)
  rq = rq or {}
  local t = {}
  rq.method = method
  rq.url = join(api,ep)
  rq.sink = ltn12.sink.table(t)
  local _,c,_ = H(rq)
  if c == 200 then
    pretty.dump(J(table.concat(t)))
  else print("ERROR",c,table.concat(t)) end
end

local readfile = function(fn)
  local f = io.open(fn,"rb")
  if not f then return nil end
  local data = f:read("*all")
  f:close()
  return data
end

local imgdata = { image_file = {name="foo.jpg",data=readfile(image_filename)} }

--- Authenticating with your API key (Echo service)
disp("GET","/echo?foo=bar")

--- Adding a reference image
disp("PUT",join("ref",sample_id),MP(imgdata))

--- Making an image available offline
disp("POST",join("ref",sample_id,"offline"))

--- Using online search
disp("POST","search",MP(imgdata))

--- Updating a reference & using a hosted image
disp("PUT",join("ref",sample_id),MP{image_url = image_url})

--- # Removing reference images
disp("DELETE",join("ref",sample_id))
