	
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

local json = require "cjson";
	
local ip    = ngx.shared.config:get("memcached.ip")
local port = tonumber(ngx.shared.config:get("memcached.port"));
		
local function getmemcached()
		local memcached = require "resty.memcached";
		local  c, err = memcached:new();
		if not c then
			ngx.say("failed to instantiate memc: ", err);
			return;
		end

		c:set_timeout(500); -- 1 sec	
		c:set_keepalive(60000, 512);
		local ok, err = c:connect(ip, port);
		if not ok then
			ngx.say("ip:"..ip.." port:"..port.." failed to connect: ", err);
			return;
		end
		return c;
end

local function getdbcollection(capture, sql)
	local resp = ngx.location.capture(capture, {  method = ngx.HTTP_GET, body = sql})
	if resp.status ~= ngx.HTTP_OK or not resp.body then
	   error("failed to query mysql,"..capture..", "..sql);
	end

	local parser = require "rds.parser"
	local res, err = parser.parse(resp.body)
	if res == nil then
	   error("failed to parse RDS: " .. err)
	end
	
	local rows = res.resultset
	if not rows or #rows == 0 then
	   ngx.say("all ids have been distributed");
	   return;
	end
	return rows;
end

local function dbexecute(capture,sql)
	local resp = ngx.location.capture(capture, {method = ngx.HTTP_POST, body = sql})
	if resp.status ~= ngx.HTTP_OK or not resp.body then
	   error("failed to query mysql,"..capture..","..sql);
	end
end

local c = getmemcached();
if c == nil then
	return;
end

local capture = "/mysql";
local idx = c:incr("index", 1) or 1;
local id   = c:get(idx);
if not id then
	local sql = "select accountid from accounts where used=0 limit 1000";		
	local rows = getdbcollection(capture, sql);
	if rows == nil then
		return;
	end
	
	for i=0,#rows-1,1 do
		local index = idx+i;
		c:set(index, rows[i+1].accountid);
	end
	c:set("index", idx);
	
	id = c:get(idx);
	c:delete(idx);
	idx = c:incr("index", 1) or 1;
else
	c:delete(idx);
end

math.randomseed(os.time());
local code = math.random(1000,9999);
local friendcode = math.random(1000,9999);
local sql = "update accounts set used=1 where accountid="..id;
dbexecute(capture, sql);

local col,conn = getcollection("users");
if col == nil then
	ngx.say("getcollection failed users")
	return;
end

local user = {{userid=tonumber(id), code=code,pwd="",friendcode=friendcode}};
local n,r = col:insert(user);
if n== nil then
	ngx.say("fail to insert users collection db");
end

--conn:shutdown()
local ok, err = conn:set_keepalive(1000,1000)
if not ok then
	ngx.say("failed to set keepalive: ", err)
	return
end--]]

ngx.say(json.encode({id=tonumber(id),code=code,friendcode=friendcode}));
	
	