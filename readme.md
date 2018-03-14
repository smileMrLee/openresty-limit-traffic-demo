### openresty 限流场景实战指南
+ 本文内容包含：
	- * 1.限制单IP并发数
	- * 2.限制单IP时间段内调用频次-允许一次性通过时间段内最大请求数
	- * 3.平滑限制单IP时间段内调用频次-允许突发，但请求依然是平均分配请求到每个时间点	
	- * 4.平滑限制单IP时间段内调用频次-允许突发，每秒最大通过数=？
	- * 5.平滑限制单IP时间段内调用频次-不允许突发，每秒最大通过数=速率*1秒。

#### 1.限制单IP并发数
``` 
1.同一时刻，单IP连接数不能超过指定值。
2.可以设置单个接口并发数，也可以设置多个接口并发数。
3.限制多个接口并发数，可以通过共享lua_shared_dict 100M 缓存区实现。 
```
**实现参考 conf/access_limit_conn.lua 和 limit_conn.lua**

#### 2.限制单IP时间段内调用频次
``` 
1.限制单IP在指定时间内，调用频次，允许一次性通过时间段内最大请求数。
2.仅 openresty 1.13.6.1+ 以上版本支持，低版本不支持。
3.按照指定时间内通过请求总数进行统计实现。 
4.支持单接口或多接口统计，多接口通过共享 lua_shared_dict 缓存区实现。 
```
**实现参考 conf/access_limit_frequency.lua 和 limit_frequency.lua**

#### 3.平滑限制单IP时间段内调用频次-允许突发
```
1.按照速率进行平滑限制，允许突发，但突发请求将进入队列排队。
2.进入队列排队的请求，按照速率时间周期进行调度执行。
3.采用漏桶算法原理限流。

```
**实现参考 conf/access_limit_frequency_leaky_bucket.lua 和 limit_frequency_leaky_bucket.lua**

#### 4.平滑限制单IP时间段内调用频次-允许突发，突发请求直接放行
```
1.按照速率进行平滑限制，允许突发，突发请求将直接放行。
2.采用令牌桶算法原理限流
```
**实现参考 conf/access_limit_frequency_token_bucket.lua 和 limit_frequency_token_bucket.lua**

#### 5.平滑限制单IP时间段内调用频次-不允许突发，每秒最大通过数=速率*1秒
```
1.按照速率进行平滑限制，不允许突发。
2.采用令牌桶算法原理限流
```
**实现参考 conf/access_limit_frequency_token_bucket_avg.lua 和 limit_frequency_token_bucket_avg.lua**
