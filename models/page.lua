module(..., package.seeall)

local http = require 'lglib.http'
local Node = require 'bamboo.models.node'
local View = require 'bamboo.view'

local Page 
Page = Node:extend {
    __tag = 'Bamboo.Model.Node.Page';
	__name = 'Page';
	__desc = 'Abstract page node definition.';
	__fields = {
		['cmd_content'] = { newfield=true, }, 			-- 客户端插件配置输入内容
		
		['name'] 	= 	{},
		['rank'] 	= 	{},
		['title'] 	= 	{ required=true},
		['content'] = 	{ required=true},

		['is_category'] = {},
		['parent'] 		= { st='ONE', foreign='Page'},
		['children'] 	= { st='MANY', foreign='Page'},
		['groups'] 		= { st='MANY', foreign='Page'},

		['comments'] 	= { st='MANY', foreign='Message'},
		['attachments'] = { st='MANY', foreign='Upload'},

		['created_date'] 	= {},
		['lastmodified_date'] 	= {},
		['creator'] 		= { st='ONE', foreign='User'},
		['owner'] 			= { st='ONE', foreign='User'},
		['lastmodifier'] 	= { st='ONE', foreign='User'},
		
	};
	
	init = function (self, t)
		if not t then return self end
		
		self.cmd_content = t.cmd_content
		
		return self
	end;
	
	-- 实例函数。返回breadcrums渲染文本
	makeBreadLinks = function (self)
		local rank_str = self.rank
		local ranks = rank_str:split('/')
		if ranks[1] == '' then table.remove(ranks, 1) end
		if ranks[#ranks] == '' then table.remove(ranks, #ranks) end
		
		local pagenodes = {}
		for i, v in ipairs(ranks) do
			local p = Page:getByName(v)
			table.insert(pagenodes, p)
		end
		
		return View("breadcrums.html"){ nodes = pagenodes, page = self }
		
	end
	
}

return Page




