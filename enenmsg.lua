local json = require "cjson";
local ip1    = ngx.shared.config:get("mongo.ip")
local port1 = tonumber(ngx.shared.config:get("mongo.port"));

function getcollection(name)
		local mongo = require "resty.mongol"
		conn = mongo:new()
		conn:set_timeout(1000)
		local ok, err = conn:connect(ip1, port1)
		if not ok then
			ngx.say("ip:"..ip1.." port:"..port1.."connect failed: " .. err)
			return nil,nil;
		end

		local db = conn:new_db_handle ( "enen" )
		local col = db:get_col(name)
		if col == nil then
			ngx.say("db:"..name.." is null");
			conn:close();
			return  nil,nil;
		end
		
		return col,conn;
end

function check_user_friendcode(userid,code)
	if code == nil then
		ngx.say("check_user_friendcode code is null. userid:"..userid);
		return false;
	end

	local col,conn = getcollection("users");
	if col == nil then
		ngx.say("check_user_friendcode get collection col is null. userid:"..userid.." code:"..code);
		return false;
	end
	
	local selector = {userid=tonumber(userid),friendcode=tonumber(code)};
	local r = col:find_one(selector, {_id=1});
	if r==nil then
		ngx.say("check_user_friendcode  target no exist. userid:"..userid.." code:"..code);
		return false;
	end
	
	return true;
end

function check_user_code(userid,code)
	local col,conn = getcollection("users");
	if col == nil then
		if code == nil then
			code = "nil";
		end
		ngx.say("check_user_code get collection col is null. userid:"..userid.." code:"..code);
		return false;
	end
	
	local selector = {userid=tonumber(userid),code=tonumber(code)};
	local r = col:find_one(selector, {_id=1});
	if r==nil then
		if code == nil then
			code = "nil";
		end
		ngx.say("check_user_code  target no exist. userid:"..userid.." code:"..code);
		return false;
	end
	
	return true;
end

function get_increment_id(name)
	local col,conn = getcollection("counters");
	local r = col:find_one({_id=name},{seq=1});
	if r == nil then
		col:update({_id=name},{_id=name,seq=1},1,nil, true);
		return 1;
	end
	
	local u = {};
	u["$set"] = {seq=r.seq+1};
	col:update({_id=name},u);
	return (r.seq+1);
end

function check_group_code(groupid,code)
	local col,conn = getcollection("groups");
	if col == nil then
		ngx.say("check_group_code get collection col is null. groupid:"..groupid.." code:"..code);
		return false;
	end
	
	local selector = {id=tonumber(groupid),code=tonumber(code)};
	local r = col:find_one(selector, {_id=1});
	if r==nil then
		ngx.say("check_group_code target no exist groupid:"..groupid.." code:"..code);
		return false;
	end
	
	return true;
end

function get_group(groupid,code,returnfield)
	local groups,groups_conn = getcollection("groups");
	if groups == nil then
		return;
	end
	
	if code then
		local group = groups:find_one({id=tonumber(groupid),code=tonumber(code)},returnfield);
		return group;	
	end
	
	local group = groups:find_one({id=tonumber(groupid)},returnfield);
	return group;		
end

arg_chek_sum = 0;
function check_ngx_arg(arg, ret)
	if arg == nil then
		ngx.say(ret.." is null.");
		arg_chek_sum=arg_chek_sum+1;
	end	
end

function HelperDecodeURI(s)
--	s=mime.unb64(s);	
--	s=string.gsub(s,"([+/=])", function(h) if h=='+' then  return '-'	 elseif h=='/'  then  return '_'  elseif h=='=' then  return '.'  end  end);
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function HelperEncodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

function group_broadcast_msg(groupid,code,_msg,excludeid)
	groupid = tonumber(groupid);
	code = tonumber(code);
	excludeid = tonumber(excludeid);
	
	group = get_group(groupid, code,{members=1});
	if group == nil then
		return;
	end
	
	local users,users_conn = getcollection("users");
	if users ~= nil then		
		local update  = {};
		update["$push"]={msgs=_msg};			
		for k,v in pairs(group.members) do				
			local selector = {userid=tonumber(v.id)};			
			if excludeid==nil or v.id~= excludeid then
				local n,r = users:update(selector, update);
			end	
		end		
	end	
end

function send_msg_to_user(userid, code,up)
	local col,conn = getcollection("users");
	if col == nil then
		ngx.say("get collection col is null");
		return;
	end

	local selector = {userid=tonumber(userid)};	
	if code then
		selector["code"] = code;
	end
	
	local update = {};
	update["$push"]={msgs=up};
	local n,r = col:update(selector, update);
	if n==nil then
		ngx.say("target no exist");
		return;
	end
end

function send_msg(fromid, toid, isgroup,msg_,msg_t,code)
	local _date = os.date("%Y-%m-%d %H:%M:%S", os.time());
	local _update={toid=tonumber(toid),fromid=tonumber(fromid),isgroup=isgroup,msg=msg_, msg_t=msg_t,stime=_date};
	if isgroup == 0 then
		send_msg_to_user(toid,code,_update);
	else
		group_broadcast_msg(toid,code,_update,fromid);		
	end
	ngx.say(json.encode(_update));
end
