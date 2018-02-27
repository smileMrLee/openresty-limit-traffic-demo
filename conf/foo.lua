-- conf/foo.lua
module("foo", package.seeall)

local bar = require "bar"
local json = require("cjson")

ngx.say(" bar loaded")

function say(var)
	-- body
	print(json.encode({}))
	print(json.encode({dogs = {}}))
	bar.say(var)
	ngx.say("value --> ", json.encode({dogs={}}))
	ngx.say(json.encode({}))
	ngx.say(json.encode({dogs = {}}))
end
	