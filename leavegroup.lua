local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_kickid, "ngx.var.arg_kickid");
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_groupid, "ngx.var.arg_groupid");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end

local groupid = tonumber(ngx.var.arg_groupid);
local userid = tonumber(ngx.var.arg_userid);
local kickid = tonumber(ngx.var.arg_kickid);
local code  = tonumber(ngx.var.arg_code);
if check_user_code(userid,code)==false then
	ngx.say("check_user_code userid.");
	return;
end

local col,conn = getcollection("groups");
if col == nil then
	ngx.say("groups collection is null");
	return;
end

local _date = os.date("%Y-%m-%d %H:%M:%S", os.time());
local remove = {};
remove["$pull"] = {members={id=kickid}};
local selector = {id=tonumber(ngx.var.arg_groupid)};

local group = col:find_one(selector,{members=0});
if group == nil then
	ngx.say("group does't exists:"..ngx.var.arg_groupid);
	return;
end

if group.ownerid~=userid and userid~=kickid then
	ngx.say("user has not power to kick member.");
	return;
end

if group.ownerid==kickid and userid==kickid then	
	local _msg={toid=tonumber(ngx.var.arg_groupid),fromid=tonumber(userid),isgroup=1,msg=json.encode({userid=userid}), msg_t='8',stime=_date};
	group_broadcast_msg(groupid,nil,_msg);
	col:delete(selector);	
	return;
end

local _msg={toid=tonumber(ngx.var.arg_groupid),fromid=tonumber(userid),isgroup=1,msg=json.encode({kickid=kickid,userid=userid}), msg_t='7',stime=_date};
group_broadcast_msg(groupid,nil,_msg);

local n,r = col:update(selector, remove);
if n==nil then
	ngx.say("group does't exists",r);
	return;
end

ngx.say(json.encode({groupid=groupid}));






