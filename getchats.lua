
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");
local json = require "cjson";

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end

local col,conn = getcollection("users");
if col == nil then
	ngx.say("getcollection failed users")
	return;
end

local selector = {userid=tonumber(ngx.var.arg_userid),code=tonumber(ngx.var.arg_code)};
local user = col:find_one(selector,{});
if user==nil then
	ngx.say("find_one target no exist");
	return;
end

local _update = {};
_update["$unset"] = {msgs=""};
local n,r = col:update({_id=user._id}, _update);
if n==nil then
	ngx.say("update:",err);
	return;
end

local ok, err = conn:set_keepalive(1000,1000)
if not ok then
	ngx.say("failed to set keepalive: ", err)
	return
end--]]

ngx.say(json.encode(user.msgs));
