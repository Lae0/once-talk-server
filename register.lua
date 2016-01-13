

local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_mail, "ngx.var.arg_mail");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
check_ngx_arg(ngx.var.arg_mac, "ngx.var.arg_mac");
if arg_chek_sum ~= 0 then
	return;
end

local mail = HelperDecodeURI(ngx.var.arg_mail);
local mac = HelperDecodeURI(ngx.var.arg_mac);

local col,conn = getcollection("lae");
local r = col:find_one({userid=mail});
if r == nil then
	ngx.say("[false,\"用户不存在.\"]");
	return;
end

if tostring(r.code) ~= ngx.var.arg_code then
	ngx.say("[false,\"邀请码不正确.\"]");	
	return;
end

local update = {};
local selector = {userid=mail};
update["$set"]  = {valid=true,mac=mac};
local n,r = col:update(selector, update);
if n==nil then
	ngx.say("[false,\"update error.\"]"..mail);	
	return;
end

ngx.say("[true,\"注册成功.\"]");	