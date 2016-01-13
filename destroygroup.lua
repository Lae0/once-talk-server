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
local group = col:find_one(selector, {});
if group == nil then
	ngx.say("group does't exists");
	return;
end

local userid    = tonumber(ngx.var.arg_userid);
local groupid = tonumber(ngx.var.arg_groupid);

local _date = os.date("%Y-%m-%d %H:%M:%S", os.time());
local _msg={toid=tonumber(ngx.var.arg_groupid),fromid=tonumber(userid),isgroup=1,msg=json.encode({userid=userid}), msg_t='8',stime=_date};
group_broadcast_msg(groupid,code,_msg);

ngx.say(json.encode(group));






