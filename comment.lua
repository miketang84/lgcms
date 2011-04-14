module(..., package.seeall)

local Form = require 'bamboo.form'
local View = require 'bamboo.view'

local Page = require 'legecms.models.page'
local Message = require 'bamboo.message'

function comment(web, req)
    -- 这里等待输入
    local pagename = req.path:match('/([%w%-_]+)/comment/$')
    local page = Page:getByName(pagename)

    local params = Form:parse(req)
    local new_comment = Message {
		from = '',
		to = '',
		subject = page.id,
		type = '',
		uuid = '',
		author = '',
		content = params.content,
		timestamp = os.time()
	}
	-- 保存评论
	new_comment:save()
	-- 将新评论的id追加到评论索引的后面
	--ptable(page)
	--page.comments = ('%s %s'):format((page.comments or ''), new_comment.id)
	page:recordMany('comments', new_comment.id)
	--ptable(page)
	-- 保存一次page（后面可以考虑更新模型部分字段，以提升效率）
	page:save()
	
	local data = {
        ['success'] = true,
        ['pagename'] = page.name,
        ['htmls'] = View("comment/new.html"){ comment = new_comment }
    }
    web:json(data)
end
