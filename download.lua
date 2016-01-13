local osfilepath =ngx.shared.config:get("download.path.get");--"/home/ouloba/usershare/carserver/conf/mongo/img"
local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)

if ngx.var.arg_file==ngx.arg_null then
	return;
end

--dofile("enenmsg.lua");
local name = ngx.re.match(string.lower(ngx.var.arg_file), '.+\\.(lua|lxz|exe|zip|cfg|txt)$');
if not name then
	ngx.say("[false, \"Invalidate File type\"]");
	return
end

local filename = ngx.var.arg_file;
local file = io.open(osfilepath..filename);
if not file then
	ngx.say("[false, \"server not exist:"..osfilepath..filename.."\"]");
	return
end 

io.close(file);
sendfile(osfilepath..filename,-1,-1); 

