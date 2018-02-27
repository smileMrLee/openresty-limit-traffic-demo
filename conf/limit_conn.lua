-- 限制单IP连接并发数
-- utils/limit_conn.lua
local limit_conn = require "resty.limit.conn"

print("测试输出成功2------------------")
-- new 的第四个参数用于估算每个请求会维持多长时间，以便于应用漏桶算法
local limit, limit_err = limit_conn.new("limit_conn_store", 3, 2, 2)
if not limit then
   	print(limit_err)
	error("failed to instantiate a resty.limit.conn object: ", limit_err)
end

local _M = {}

function _M.incoming()
    local key = ngx.var.binary_remote_addr
    print("客户端IP=" .. key .. "请查看IP是否存在")
    local delay, err = limit:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return ngx.exit(503)
        end
        ngx.log(ngx.ERR, "failed to limit req: ", err)
        return ngx.exit(500)
    end
    ngx.log(ngx.INFO, "delay = ", delay)
    if limit:is_committed() then
        local ctx = ngx.ctx
        ctx.limit_conn_key = key
        ctx.limit_conn_delay = delay
    end

    if delay >= 2 then
        ngx.log(ngx.WARN, "delaying conn, excess ", delay,
                "s per binary_remote_addr by limit_conn_store")
        ngx.sleep(delay)
    end
end

function _M.leaving()
    local ctx = ngx.ctx
    local key = ctx.limit_conn_key
    if key then
        local latency = tonumber(ngx.var.request_time) - ctx.limit_conn_delay
        local conn, err = limit:leaving(key, latency)
        if not conn then
            ngx.log(ngx.ERR,
            "failed to record the connection leaving ",
            "request: ", err)
        end
    end
end

return _M
