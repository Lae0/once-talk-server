local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local osfilepath =ngx.shared.config:get("img.path.upload");-- "/home/ouloba/usershare/carserver/conf/mongo/img"
local json = require "cjson";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
 dofile("enenmsg.lua");
 
local upload = require "resty.upload"
local json = require "cjson";
local md5 = require "resty.md5"
local _md5 = md5:new();
local chunk_size = 4096
local form = upload:new(chunk_size)
local file
local err
local filelen=0
form:set_timeout(0) -- 1 sec
local filename
local filenames
 local strname
 local fromid =  ngx.var.arg_fromid;
 local toid = ngx.var.arg_toid;
 local code = ngx.var.arg_code;
 local friendcode = ngx.var.arg_friendcode;

 
 arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_fromid, "ngx.var.arg_fromid");
check_ngx_arg(ngx.var.arg_toid, "ngx.var.arg_toid");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end
 
 local isgroup = 0;
if ngx.var.arg_isgroup~=nil then	
	isgroup = tonumber(ngx.var.arg_isgroup);
end

if isgroup==0 then		
	if check_user_code(fromid, tonumber(code)) ==false then
		return;
	end
	
	if check_user_friendcode(toid, friendcode)==false then
		return;
	end
elseif isgroup==1 and check_group_code(toid, tonumber(code)) ==false then
	return;
end
 
 local function get_filename(res)
    filenames = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
    if filenames then 
        return filenames[2]
    end
end

local function HelperBin2Str(data)
	if(data==nil or type(data)~='string') then
		return "";
	end

	local len = string.len(data);
	local str = "";
	for i = 1, len,1 do
		str = str..string.format("%02x", string.byte(data, i));
	end
	return str;
end


local i=0
while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end
    if typ == "header" then
		--ngx.say("filename is null, res:".. json.encode(res));
        if res[1] ~= "Content-Type" then
			filename = get_filename(res[2])				
            if filename then
				 local ext_name = ngx.re.match(filename, '.+\\.(\\w+)$');
				 local _time = os.time();
				 _md5:update(_time..filename);
				 strname = isgroup.."_"..fromid.."_"..toid.."_"..HelperBin2Str(string.sub(_md5:final(), 1, 5)).."."..ext_name[1];
				-- ngx.say(strname);
                i=i+1
                filepath = osfilepath..strname;
                file,err = io.open(filepath,"w+")
                if not file then
                    ngx.say("failed to open file aaaa:".. type(res)..strname.."  "..filename.." err:"..err);
                    return 
                end
				 --ngx.log(ngx.ERROR, "saveimg.lua filepath: " .. filepath);
				 --return;
            else
				--ngx.say("filename is null, res:".. json.encode(res));
            end
        end
    elseif typ == "body" then
        if file then
            filelen= filelen + tonumber(string.len(res))    
            file:write(res)
        else
        end
    elseif typ == "part_end" then
        if file then
			file:flush();
            file:close()
            file = nil
			
			if isgroup == 0 then
				code = nil;
			end
			
			send_msg(fromid,
                   toid,
				   isgroup,
				   HelperEncodeURI(strname),
				   "5",
				   code);		
				   
			return;		
        end
    elseif typ == "eof" then
        break
    else
    end
end
if i==0 then
    ngx.say("please upload at least one file!")
    return
end
