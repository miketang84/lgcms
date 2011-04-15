module(..., package.seeall)

local http = require 'lglib.http'
local posix = require 'posix'

local Form = require 'bamboo.form'
local View = require 'bamboo.view'
local User = require 'bamboo.models.user'
local Upload = require 'bamboo.models.upload'

local Page = require 'legecms.models.page'


function showPage(web, req)
    local pagename = req.path:match('/([%w%-_]+)/$')
    local page = Page:getByName(pagename)
    web:page(View("full_page.html"){ page = page, req = req })
end


function showPageFrame(web, req)
    local page = Page:getByName('index')
    web:page(View("pageframe.html"){page = page, req = req})
end

function getPage(web, req)
    -- 这里等待输入
    local params = Form:parse(req)
    local pagename = params.pagename:match('([%w%-_]+)/?$')
    local page = Page:getByName(pagename)

    web:page(View("page.html"){page = page, req = req})
end

---- 无状态编程，整个编辑过程，要两个函数来实现
--function editPageView(web, req)
    --local page = Page:getByName('index')
    --web:page(View("editpage.html"){ page = page })
--end

--function editPageHandler(web, req)
    --ptable(req.headers)
    --local params = Form:parse(req)
    --ptable(params)
    ---- 这里要检查params的内容，即Form:validate的功能
    --local page = Page:getByName('index')
    --page.title = params.title 
    --page.content = params.content
    --page.lastmodified_date = os.time()
    
    ---- 更新数据到数据库
    --page:save()
    ---- 只返回page的主要内容区，不返回整个页面
    --web:page(View("page.html"){ page = page })
--end


-- 状态编程
function editPage(web, req)
    local cur_pagename = req.path:match('/([%w%-_]+)/edit/$')
    local page = Page:getByName(cur_pagename)
    web:page(View("editpage.html"){ page = page })
    
    -- 这里等待输入
    params, req = web:input()
    
    --ptable(req.headers)
    -- 这里要检查params的内容，即Form:validate的功能
    page.title = params.title 
    page.content = params.content
    page.lastmodified_date = os.time()
    
    -- 更新数据到数据库
    page:save()
    -- 只返回page的主要内容区，不返回整个页面
    web:page(View("page.html"){ page = page })
end 

function newPageNode(web, req, cur_page, params, is_category)
    -- 这里要检查params的内容，即Form:validate的功能
    
    local now = os.time()
    local page = Page {
        -- 此时这个name有可能为nil
        name = params.name,
        title = params.title,
        content = params.content,
        created_date = now,
        lastmodified_date = now,
        
        is_category = is_category,
    }
    -- 对象一旦产生，这时id已经生成了
    if isFalse(page.name) then page.name = page.id end
    
    -- Page的config可以展开成平级的存在数据库中，可能操作上更方便一点
    -- 如果当前页面is_category为true，表明当前页面下可以建立子页面
    -- 注，从数据库中获取出来的值都是字符串
    if cur_page.is_category == 'true' then
        page.rank = cur_page.rank + cur_page.name + '/'
        -- 记录新的子页面外链
        page.parent = cur_page.id
        cur_page:recordMany('children', page.id) 
    -- 如果当前页面下不允许建立子页面，就将页面建在最顶级
    else
        page.rank = '/'
        page.parent = ''
    end
    
    -- 更新数据到数据库
    page:save()
    -- 更新父页面的信息
    cur_page:save()
    
    return true, page
end


-- 状态编程
function newPage(web, req)
    local cur_pagename = req.path:match('/([%w%-_]+)/newpage/$')
    -- 在此，应该要判断cur_pagename的合法性，或者在外面判断也行
    local cur_page = Page:getByName(cur_pagename)
    -- 此时，这个cur_page肯定是有值的，因为当前页面已经显示出来了嘛
    -- 显示新建页面输入框
    web:page(View("newpage.html"){page = cur_page})
    -- 这里等待输入
    local params, req = web:input()
    
    local success, page = newPageNode(web, req, cur_page, params, false)
    
    -- 只返回page的主要内容区，不返回整个页面
    data = {
        ['success'] = success,
        ['pagename'] = page.name,
        ['htmls'] = View("page.html"){ page = page }
    }
    web:json(data)
end
-- 状态编程
function newCate(web, req)
    local cur_pagename = req.path:match('/([%w%-_]+)/newcate/$')
    -- 在此，应该要判断cur_pagename的合法性，或者在外面判断也行
    local cur_page = Page:getByName(cur_pagename)
    -- 此时，这个cur_page肯定是有值的，因为当前页面已经显示出来了嘛
    -- 显示新建页面输入框
    web:page(View("newpage.html"){page = cur_page})
    -- 这里等待输入
    local params, req = web:input()
    local success, page = newPageNode(web, req, cur_page, params, true)
    
    -- 只返回page的主要内容区，不返回整个页面
    data = {
        ['success'] = success,
        ['pagename'] = page.name,
        ['htmls'] = View("page.html"){ page = page }
    }
    web:json(data)
end

function properties(web, req)
    local cur_pagename = req.path:match('/([%w%-_]+)/properties/$')
    local page = Page:getByName(cur_pagename)
    web:page(View("properties.html"){ page = page })
    
    -- 这里等待输入
    params, req = web:input()
    
    --ptable(req.headers)
    -- 这里要检查params的内容，即Form:validate的功能
    page.show_breadcums = params.show_breadcums or ""
    page.show_title = params.show_title or ""
    page.show_children = params.show_children or ""
    page.show_comments = params.show_comments or ""
    page.allow_comment = params.allow_comment or ""
    page.show_uploads = params.show_uploads or ""
    page.allow_upload = params.allow_upload or ""
    page.show_extra_1 = params.show_extra_1 or ""
    page.show_extra_2 = params.show_extra_2 or ""

    page.lastmodified_date = os.time()
    
    -- 更新数据到数据库
    page:save()
    -- 只返回page的主要内容区，不返回整个页面
    local data = {
        ['success'] = true,
        ['pagename'] = page.name,
        ['htmls'] = View("page.html"){ page = page }
    }
    web:json(data)

end


function showPageList(web, req)

    return true
end
