module(..., package.seeall)

local http = require 'lglib.http'
local posix = require 'posix'

local Form = require 'bamboo.form'
local Upload = require 'bamboo.models.upload'

local Menu = require 'bamboo.models.menu'


function newMenuItem(web, req)
	local params = Form:parse(req)
	local parent = params.parent and Menu:getById(params.parent)
	
	local now = os.time()
    local new_item = Menu {
        name = params.name,
		title = params.title,
        prompt = params.prompt,
		link = params.link,
		parent = parent and parent.id or '',
		
		created_date = now,
        lastmodified_date = now,
    }
    
    if parent then
        new_item.rank = parent.rank + parent.name + '/'
        parent:appendToField('children', new_item.id) 
		-- 更新父页面的信息
		parent:save()
    
    else
        new_item.rank = '/'
    end
    -- 更新数据到数据库
    new_item:save()
	
	return web:json {
        ['success'] = true,
		['id'] = new_item.id,
        ['name'] = new_item.name + ' ' + new_item.title,
		['pId'] = new_item.parent,
    }
end

