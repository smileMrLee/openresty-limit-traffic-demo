-- conf/bar.lua

module("bar", package.seeall)

local rocks = require "luarocks.loader"

local md5 = require "md5"

ngx.say("rocks and md5 loaded!")

function say( a )
	-- body
	ngx.say(md5.sumhexa(a))
end