-- limit_frequency_token_bucket_avg.lua
 -- 令牌桶限流，不允许延迟处理，不允许突发流量
 -- rate: 120/min，最大通过请求 max <= 120次 , 请求平均分流到每个500ms时刻执行。
 -- 每个0-500ms时间窗内，只能通过一个请求。对请求流入进行规整。
local limit_req = require "resty.limit.req"
-- 这里设置rate=2/s，漏桶桶容量设置为0，（也就是来多少水就留多少水） 
-- 因为resty.limit.req代码中控制粒度为毫秒级别，所以可以做到毫秒级别的平滑处理
local lim, err = limit_req.new("limit_req_store", 2, 0)
if not lim then
    ngx.log(ngx.ERR, "failed to instantiate a resty.limit.req object: ", err)
    return ngx.exit(500)
end

local _M = {}

function _M.incoming()
    local key = ngx.var.binary_remote_addr
    local delay, err = lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return ngx.exit(503)
        end
        ngx.log(ngx.ERR, "failed to limit req: ", err)
        return ngx.exit(500)
    end

-- 当漏桶容量=0，延迟永远=0
end

return _M