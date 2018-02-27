-- access_limit_frequency_token_bucket.lua
local limit_frequency_token_bucket = require "limit_frequency_token_bucket"

-- 对于内部重定向或子请求，不进行限制。因为这些并不是真正对外的请求。
if ngx.req.is_internal() then
    return
end
limit_frequency_token_bucket.incoming()
