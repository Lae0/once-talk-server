local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_groupid, "ngx.var.arg_groupid");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end


local col,conn = getcollection("groups");
if col == nil then
	ngx.say("groups collection is null");
	return;
end

local selector = {id=tonumber(ngx.var.arg_groupid),code=tonumber(ngx.var.arg_code)};
local group = col:find_one(selector, {msgs=0,_id=0});
if group == nil then
	ngx.say("group does't exists");
	return;
end

local update = {};
local userid = tonumber(ngx.var.arg_userid);

if ngx.var.arg_gname ~= nil then	
	check_ngx_arg(ngx.var.arg_gname, "ngx.var.arg_gname");
	if arg_chek_sum ~= 0 then
		return;
	end
	
	update["name"] = ngx.var.arg_gname;
elseif ngx.var.arg_mname ~= nil then
	check_ngx_arg(ngx.var.arg_mid, "ngx.var.arg_mid");
	check_ngx_arg(ngx.var.arg_mname, "ngx.var.arg_mname");
	if arg_chek_sum ~= 0 then
		return;
	end
	
	update["members.name"] = ngx.var.arg_mname;
	selector["members.id"] = tonumber(ngx.var.arg_mid);
else
	return;
end

local set = {};
set["$set"] = update;
local n,r = col:update(selector, set);
if n==nil then
	ngx.say("group does't exists",r);
	return;
end

local _date = os.date("%Y-%m-%d %H:%M:%S", os.time());
local _msg={toid=tonumber(ngx.var.arg_groupid),fromid=tonumber(userid),isgroup=1,msg=json.encode({s=selector,u=update}), msg_t='10',stime=_date};
group_broadcast_msg(tonumber(ngx.var.arg_groupid),code,_msg);

ngx.say(json.encode({s=selector,u=update}));






