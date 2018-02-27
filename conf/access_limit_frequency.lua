-- src/access_limit_frequency.lua
local limit_frequency = require "limit_frequency"

-- 对于内部重定向或子请求，不进行限制。因为这些并不是真正对外的请求。
if ngx.req.is_internal() then
    return
end
limit_frequency.incoming()
