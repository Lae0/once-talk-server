
local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_ids, "ngx.var.arg_ids");
check_ngx_arg(ngx.var.arg_names, "ngx.var.arg_names");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end

if check_user_code(ngx.var.arg_userid,ngx.var.arg_code)==false then
	ngx.say("groupid:"..ngx.var.arg_userid.." "..ngx.var.arg_code);
	return;
end

local col,conn = getcollection("groups");
if col == nil then
	ngx.say("groups collection is null");
	return;
end

local ids = json.decode(HelperDecodeURI(ngx.var.arg_ids));
if ids == nil then
	ngx.say("group id list format is invalidate");
	return;
end

local userid = tonumber(ngx.var.arg_userid);
local names = json.decode(HelperDecodeURI(ngx.var.arg_names));
if ids == nil then
	ngx.say("group names format is invalidate");
	return;
end

if table.getn(ids)~=table.getn(names) then
	ngx.say("group names size neq ids size");
	return;
end

local last = #ids;
if ids[last] ~= userid then
	ngx.say("no exist master id");
	return;
end

local members = {};
for k,v in ipairs(ids) do
	members[k-1] =  {id=tonumber(v),name=HelperEncodeURI(names[k]),power=1,friend_id=userid,friend_name=HelperEncodeURI(names[last])};
end

math.randomseed(os.time());
local id = get_increment_id("groupid")+10000;
local code = math.random(1000,9999);

local col,conn = getcollection("groups");
local n,r = col:insert({{id=id, ownerid=tonumber(ngx.var.arg_userid),code=code,members=members}});
if n== nil then
	ngx.say("group is null",r);
	return;
end

local _date = os.date("%Y-%m-%d %H:%M:%S", os.time());
local _msg={toid=tonumber(id),fromid=tonumber(userid),isgroup=1,msg=json.encode({code=code}), msg_t='9',stime=_date};
group_broadcast_msg(id,code,_msg);

ngx.say(json.encode({groupid=id}));




