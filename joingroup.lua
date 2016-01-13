local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

--userid invite fuserid join groupid.
arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_fids"); 
check_ngx_arg(ngx.var.arg_name, "ngx.var.arg_fnames");
check_ngx_arg(ngx.var.arg_groupid, "ngx.var.arg_groupid");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_name, "ngx.var.arg_name");
if arg_chek_sum ~= 0 then
	return;
end

local col,conn = getcollection("groups");
if col == nil then
	ngx.say("groups collection is null");
	return;
end

local ids = json.decode(HelperDecodeURI(ngx.var.arg_fids));
if ids == nil then
	ngx.say("group id list format is invalidate");
	return;
end

local userid = tonumber(ngx.var.arg_userid);
local names = json.decode(HelperDecodeURI(ngx.var.arg_fnames));
if ids == nil then
	ngx.say("group names format is invalidate");
	return;
end

if table.getn(ids)~=table.getn(names) then
	ngx.say("group names size neq ids size");
	return;
end

local code = tonumber(ngx.var.arg_code);
local selector = {id=tonumber(ngx.var.arg_groupid),code=code};
local members = {};
for k,v in ipairs(ids) do
	local m = {id=tonumber(v),name=HelperEncodeURI(names[k]),power=1,friend_id=userid,friend_name=ngx.var.arg_name};
	members[k] =  m;

	local update = {};
	update["$push"] = {members=m};
	local n,r = col:update(selector, update);
	if n==nil then
		ngx.say("group does't exists",r);
		return;
	end
end

local group = col:find_one(selector, {});
if group == nil then
	ngx.say("group does't exists");
	return;
end

local groupid = tonumber(ngx.var.arg_groupid);
local _date = os.date("%Y-%m-%d %H:%M:%S", os.time());
local _msg={toid=tonumber(ngx.var.arg_groupid),fromid=tonumber(userid),isgroup=1,msg=json.encode({code=code,members=members}), msg_t='6',stime=_date};
group_broadcast_msg(groupid,code,_msg);

ngx.say("ok");
	






