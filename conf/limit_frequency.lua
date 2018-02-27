-- 时间窗内，总流量限流
-- 低版本openresty暂不支持，仅支持1.13.6.1+ 以上
local limit_count = require "resty.limit.count"

print("测试输出成功3------------------")
 -- rate: 120/min 
local lim, err = limit_count.new("limit_count_store", 60, 60)
if not lim then
	ngx.log(ngx.ERR, "failed to instantiate a resty.limit.count object: ", err)
	return ngx.exit(500)
end
ngx.log(ngx.INFO, "limit_count new successfull!")

local _M = {}

function _M.incoming()
    local key = ngx.var.binary_remote_addr
    local delay, err = lim:incoming(key, true)
    -- 如果请求数在限制范围内，则当前请求被处理的延迟（这种场景下始终为0，因为要么被处理要么被拒绝）和将被处理的请求的剩余数
    if not delay then
        if err == "rejected" then
            return ngx.exit(503)
        end

        ngx.log(ngx.ERR, "failed to limit count: ", err)
        return ngx.exit(500)
    end
end

return _M