require = require"require".require
local cjson = require "cjson";
local config = ngx.shared.config;
local file = io.open("/home/ouloba/usershare/carserver/conf/mongo/config.json","r");
if file then
	local content = cjson.decode(file:read("*all"));
	file:close();
	for name,value in pairs(content) do
	   config:set(name,value);
	end
end

--
config:set("mongo.ip", "192.168.80.130");
config:set("mongo.port", "27017");

config:set("memcached.ip", "192.168.80.130");
config:set("memcached.port", "5120");

--
config:set("img.path.upload", "/home/ouloba/usershare/carserver/conf/mongo/img/");
config:set("img.path.get", "/home/ouloba/usershare/carserver/conf/mongo/img/");
config:set("download.path.get", "/home/ouloba/usershare/carserver/conf/mongo/download/");
config:set("package.path",  "/home/ouloba/usershare/carserver/conf/mongo/");

