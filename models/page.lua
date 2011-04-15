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
		['id'] 		= 	{},						-- 页面的id
		['name'] 	= 	{},						-- 页面的内部名称
		['rank'] 	= 	{},						-- 页面在整个页面树中的级别，为字符串
		['title'] 	= 	{},						-- 页面标题
		['content'] = 	{},				-- 页面内容
		['cmd_content'] = { newfield=true, }, 			-- 客户端插件配置输入内容
		
		['is_category'] = {},			-- 标明此页面是否是一个类别页面，即是否可接子页面
		['parent'] 		= {},						-- 页面的父页面id，如果为空，则表明本页面为顶级页面
		['children'] 	= {},					-- 此页面的子页面id列表字符串，受is_category控制
		['groups'] 		= {},						-- 此页面可以所属的组，近似就是它们所说的tag

		['comments'] 	= {},					-- 对此页面的评论id列表字符串
		['attachments'] = {},				-- 附着在此页面上的文件

		['created_date'] 	= {},				-- 本页面创建的日期
		['lastmodified_date'] 	= {},		-- 最后一次修改的日期
		['creator'] 		= {},					-- 本页面的创建者
		['owner'] 			= {},					-- 本页面的拥有者
		['lastmodifier'] 	= {},				-- 最后一次本页面的修改者
		
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




