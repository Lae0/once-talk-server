
--require = require"require".require
local json = require "cjson";
local p = ngx.shared.config:get("package.path"); --"/home/ouloba/usershare/carserver/conf/mongo/";
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s", p, p, m_package_path)
dofile("enenmsg.lua");

function HelperDecodeURI(s)
--	s=mime.unb64(s);	
--	s=string.gsub(s,"([+/=])", function(h) if h=='+' then  return '-'	 elseif h=='/'  then  return '_'  elseif h=='=' then  return '.'  end  end);
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

arg_chek_sum = 0;
check_ngx_arg(ngx.var.arg_mail, "ngx.var.arg_mail");
if arg_chek_sum ~= 0 then
	return;
end

local mail = HelperDecodeURI(ngx.var.arg_mail);

-- Michal Kottman, 2011, public domain
local socket = require("socket")
--local smtp = require 'socket.smtp'
local smtp = require("resty.smtp")
local ssl = require 'ssl'
local https = require 'ssl.https'
local ltn12 = require 'ltn12'
local mime = require("resty.smtp.mime")


function sslCreate()
    local sock = socket.tcp()
    return setmetatable({
        connect = function(_, host, port)
            local r, e = sock:connect(host, port)
            if not r then return r, e end
            sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            return sock:dohandshake()
        end
    }, {
        __index = function(t,n)
            return function(_, ...)
                return sock[n](sock, ...)
            end
        end
    })
end


function sendMessage(subject, body)
	local msg = {
		headers= {
			subject= mime.ew(subject, nil,
							 { charset= "gbk" }),
			["content-transfer-encoding"]= "BASE64",
			["content-type"]= "text/plain; charset='gbk'",
		},

		body= mime.b64(body)
	}

    local ok, err = smtp.send {
        from           = '<admin@laework.com>',
        rcpt             = {"<"..mail..">"},
        source       = smtp.message(msg),
        user           = 'admin@laework.com',
        password = '19781103Cnm',
		--password = '19781103Cnm',
        server       = 'smtp.ym.163.com',
		port = 994,
		create=sslCreate
    }
    if not ok then
        --print("Mail send failed", err) -- better error handling required
		ngx.say("[false,\" 邮件发送错误,注册失败.\"]");
		return;
    end
	
	ngx.say("[true,\"邀请码发送成功,请查收邮件.\"]");
	return true
end


--[[
local smtp = require("resty.smtp")
local mime = require("resty.smtp.mime")
local ltn12 = require("resty.smtp.ltn12")
local socket = require("socket")

function sendMessage(subject,body)
	local mesgt = {
		headers= {
			subject= mime.ew(subject, nil,
							 { charset= "utf-8" }),
			["content-transfer-encoding"]= "BASE64",
			["content-type"]= "text/plain; charset='utf-8'",
		},

		body= mime.b64(body)
	}

	local ok, err = smtp.send {
		from= '215271461@qq.com',
		rcpt= {mail,'215271461@qq.com'},
		user= '215271461@qq.com',
		password= '19781103q' ,
		server= "smtp.exmail.qq.com",
		source= smtp.message(mesgt),
		create=socket.tcp()
	}
	
   if not ok then
        --print("Mail send failed", err) -- better error handling required
		ngx.say("{false,\" 邮件发送错误,注册失败.\""..err.."  "..mail.."}");
		return;
    end
	
	ngx.say("{true,\"邀请码发送成功,请查收邮件.\"}");
	return true
end
--]]

math.randomseed(os.time());
local code = math.random(1000,9999);
local col,conn = getcollection("lae");
local rr = col:find_one({userid=mail});

local ret = sendMessage("Lae邀请码", "亲爱的用户：\r\t您的Lae邀请码是:"..code..",欢迎使用Lae引擎");
if(ret == nil) then
	if(rr) then
		ngx.say(rr.code);
	end
	return;
end

if(rr==nil) then
	local user = {{userid=mail, code=code}};
	local n,r = col:insert(user);
	if n== nil then	
		ngx.say("[false,\"用户注册失败.\"]");
		return;
	end
else
	local update = {};
	local selector = {userid=mail};
	update["$set"] = {code=code};
	local n,r = col:update(selector, update);
	if n==nil then
		ngx.say("[false,\"update error.\"]"..n);	
		return;
	end
end



