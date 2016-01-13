local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_newkey, "ngx.var.arg_newkey");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end

if ngx.var.arg_oldkey == nil then
	 ngx.var.arg_oldkey="";
end

local col = getcollection("users");
if col == nil then
	return;
end

local selector = {accountid=tonumber(ngx.var.arg_userid),pwd=ngx.var.arg_oldkey,code=ngx.var.arg_code};
local update = {pwd=ngx.var.arg_newkey};
local n,r = col:update(selector, update);
if n==nil then
	ngx.say("old password error");
	return;
end

local ok, err = conn:set_keepalive(0,1000)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
