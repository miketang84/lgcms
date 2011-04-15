module(..., package.seeall)

local http = require 'lglib.http'
local posix = require 'posix'

local Form = require 'bamboo.form'
local View = require 'bamboo.view'
local User = require 'bamboo.models.user'
local Upload = require 'bamboo.models.upload'
local Node = require 'bamboo.models.node'

function newNode(web, req, params, is_category)
	local parent = nil
	if params.parent then parent = Node:getById(params.parent) end
	
	local now = os.time()
    local new_node = Node {
        title = params.title,
        content = params.content,
        created_date = now,
        lastmodified_date = now,
        
        is_category = is_category,
    }
    
	-- Page的config可以展开成平级的存在数据库中，可能操作上更方便一点
    -- 如果当前页面is_category为true，表明当前页面下可以建立子页面
    -- 注，从数据库中获取出来的值都是字符串
    if parent and parent.is_category == 'true' then
        new_node.rank = parent.rank + parent.name + '/'
        -- 记录新的子页面外链
        new_node.parent = parent.id
        parent:recordMany('children', new_node.id) 
		-- 更新父页面的信息
		parent:save()
    
    -- 如果当前页面下不允许建立子页面，就将页面建在最顶级
    else
        new_node.rank = '/'
        new_node.parent = ''
    end
    
    -- 更新数据到数据库
    new_node:save()
    
    return true, new_node
end


-- 状态编程
function newLeaf(web, req)
    local params = Form:parse(req)
    local success, new_leaf = newNode(web, req, params, false)
    
    data = {
        ['success'] = success,
		['id'] = new_leaf.id,
        ['name'] = new_leaf.name + ' ' + new_leaf.title,
		['pId'] = new_leaf.parent,
		['isParent'] = false
    }
    web:json(data)
end


-- 状态编程
function newCate(web, req)
    local params = Form:parse(req)
    local success, new_cate = newNode(web, req, params, true)
    
    data = {
        ['success'] = success,
		['id'] = new_cate.id,
        ['name'] = new_cate.name + ' ' + new_cate.title,
		['pId'] = new_cate.parent,
		['isParent'] = true
    }
    web:json(data)
end


