-- limit_frequency_leaky_bucket.lua
 -- 漏桶算法限流
 -- rate: 120/min，最大通过请求 max <= 120次 , 请求分流到每个500ms时刻执行。
 -- 每个0-500ms时间窗内，允许通过 1+60 个请求，但只能执行1个请求，其余将在桶中等待。
 -- 等待时间delay=n*500ms，n等于桶中剩余请求数。
 -- 对请求流出进行规整。
local limit_req = require "resty.limit.req"
-- 这里设置rate=2/s，漏桶桶容量设置为60，允许突发流量，突发流量将进入桶中等待
-- 因为resty.limit.req代码中控制粒度为毫秒级别，所以可以做到毫秒级别的平滑处理
local lim, err = limit_req.new("limit_req_store", 2, 60)
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

    if delay >= 0.001 then
    	-- the 2nd return value holds the number of excess requests
    	-- per second for the specified key. for example, number 31
    	-- means the current request rate is at 231 req/sec for the
    	-- specified key.
    	ngx.log(ngx.INFO, "延迟=" .. delay)
    	local excess = err

    	-- the request exceeding the 200 req/sec but below 300 req/sec,
    	-- so we intentionally delay it here a bit to conform to the
        -- 200 req/sec rate.
    	ngx.sleep(delay)
	end
end

return _M

--[[
测试验证

测试指令：ab -c 70 -n 120 http://10.202.97.23:8080/limitFrequencyLeakyBucket
执行结果：
Concurrency Level:      70
Time taken for tests:   30.008 seconds
Complete requests:      120
success requests:        61
   (Connect: 0, Receive: 0, Length: 61, Exceptions: 0)
Non-2xx responses:      59
Total transferred:      36660 bytes
HTML transferred:       17191 bytes
Requests per second:    4.00 [#/sec] (mean)
Time per request:       17504.432 [ms] (mean)
Time per request:       250.063 [ms] (mean, across all concurrent requests)
Transfer rate:          1.19 [Kbytes/sec] received

成功了61个请求，失败59个。观察nginx access日志，输出顺序如下：
第1-9条日志，返回http-status：503
第10条日志，返回http-status：200
第11-61条，返回http-status：503
第62-120条，返回http-status：200

原理解释：
当ab test第一次发出70并发请求时，第1个请求执行，然后第一个500ms时间片被用掉，后续进来的60个请求都进入桶中等待下一个500ms时间片。
此时70-1-60=9，这9个请求将直接返回503，ab 的并发数是70，此时已经有返回结果的9个并发继续拉取9个任务，继续执行。
但并发时间极短，下一个500ms时间片还没到，漏桶依然没有能力处理请求，所以继续直接拒绝第一批后补9个任务。
继续拉第二批后补9个任务，并发时间极短，下一个500ms时间片还没到，漏桶依然没有能力处理请求，仍然直接拒绝第二批9个任务。
继续拉第三批后补9个任务，并发时间极短，下一个500ms时间片还没到，漏桶依然没有能力处理请求，仍然直接拒绝第三批9个任务。
继续拉第四批后补9个任务，并发时间极短，下一个500ms时间片还没到，漏桶依然没有能力处理请求，仍然直接拒绝第四批9个任务。
继续拉第五批后补9个任务，并发时间极短，下一个500ms时间片还没到，漏桶依然没有能力处理请求，仍然直接拒绝第五批9个任务。
继续拉第六批后补9个任务，但总任务数120-70-5*9=5，只剩下5个请求了，只能拉到5个任务，下一个500ms时间片还没到，漏桶依然没有能力处理请求，仍然直接拒绝第六批5个任务。

所以最终成功的请求数= 1 + 60                        = 61
失败的请求数=（70-1-60）* 5 + 5（最后一批只有5个）    = 59

]]