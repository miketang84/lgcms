module(..., package.seeall)

local http = require 'lglib.http'
local posix = require 'posix'

local Form = require 'bamboo.form'
local View = require 'bamboo.view'
local User = require 'bamboo.user'
local Upload = require 'bamboo.upload'

local Page = require 'legecms.models.page'


-- 状态编程
function login(web, req)
    web:page(View("login/login.html"){})
    
    -- 这里等待输入
    params, req = web:input()
    
    --ptable(req.headers)
    -- 这里要检查params的内容，即Form:validate的功能
    local user = User:login (params, req)
    if not user then
        -- 显示登录出错信息
        local data = {
            ['success'] = false,
            ['error_code'] = 102,
            ['error_desc'] = "username or password error."
        }
        return web:json(data)
    end
    
    local page = Page:getByName('index')
    local data = {
        ['success'] = true,
        ['username'] = user.username,
        ['pagename'] = page.name,
        ['htmls'] = View("page.html"){ page = page }
    }
    return web:json(data)
end 

function register (web, req)
    web:page(View("login/register.html"){})
    
    -- 这里等待输入
    params, req = web:input()
    
    --ptable(req.headers)
    -- 这里要检查params的内容，即Form:validate的功能
    local user, error_code, error_desc = User:register  (params, req)
    if not user then
        -- 显示登录出错信息
        local data = {
            ['success'] = false,
            ['error_code'] = error_code,
            ['error_desc'] = error_desc
        }
        return web:json(data)
    end
    

    print('register OK, ready login.')
    local user = User:login (params, req)
    if user then
        print('login OK.')
    end
    
    req.user = user
    
    local page = Page:getByName('index')
    local data = {
        ['success'] = true,
        ['username'] = user.username,
        ['pagename'] = page.name,
        ['htmls'] = View("page.html"){ page = page }
    }
    return web:json(data)
end 

function logout(web, req)
    User:logout(req)
    local page = Page:getByName('index')
    local data = {
        ['success'] = true,
        ['pagename'] = page.name,
        ['htmls'] = View("page.html"){ page = page }
    }
    return web:json(data)
end




