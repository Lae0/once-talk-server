local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");
local json = require "cjson";


arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_msg, "ngx.var.arg_msg");
check_ngx_arg(ngx.var.arg_fromid, "ngx.var.arg_fromid");
check_ngx_arg(ngx.var.arg_toid, "ngx.var.arg_toid");
check_ngx_arg(ngx.var.arg_msg_t, "ngx.var.arg_msg_t");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end

local isgroup = 0;
if ngx.var.arg_isgroup~=nil then	
	isgroup = tonumber(ngx.var.arg_isgroup);
end

if isgroup==0 then	
	if check_user_code(ngx.var.arg_fromid, tonumber(ngx.var.arg_code)) ==false then
		return;	
	end	
	if ngx.var.arg_msg_t=='0' and check_user_friendcode(ngx.var.arg_toid, ngx.var.arg_friendcode)==false then
		return;
	end	
elseif isgroup==1 and check_group_code(ngx.var.arg_toid, tonumber(ngx.var.arg_code)) ==false then
	return;
end

send_msg(ngx.var.arg_fromid,
                   ngx.var.arg_toid,
				   isgroup,
				   ngx.var.arg_msg,
				   ngx.var.arg_msg_t,
				   nil);










