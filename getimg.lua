
local osfilepath =ngx.shared.config:get("img.path.get");--"/home/ouloba/usershare/carserver/conf/mongo/img"
local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_userid, "ngx.var.arg_userid");
check_ngx_arg(ngx.var.arg_file, "ngx.var.arg_file");
check_ngx_arg(ngx.var.arg_code, "ngx.var.arg_code");
if arg_chek_sum ~= 0 then
	return;
end

local col,conn = getcollection("users");
if col == nil then
	ngx.say("getcollection is nil "..ngx.var.arg_code.." ip:"..ip1.." port:"..port1)
	return;
end

local r = col:find_one({userid=tonumber(ngx.var.arg_userid),code=tonumber(ngx.var.arg_code)});
if r == nil then
	ngx.say("error user code.")
	return;
end

local name = ngx.re.match(string.lower(ngx.var.arg_file), '.+\\.(png|jpg|gif)$');
if not name then
	ngx.say("Invalidate File type");
	return
end

local filename = HelperDecodeURI(ngx.var.arg_file);
local file = io.open(osfilepath..filename);
if not file then
	ngx.say("server not exist:"..osfilepath..filename);
	return
end 

--ngx.say("server sendfile:"..osfilepath..ngx.var.arg_file);
io.close(file);
sendfile(osfilepath..filename,-1,-1); 
if string.gsub(filename, 1, 1)=='0' then --not group file.
	os.remove(osfilepath..filename);
end