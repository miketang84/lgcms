module(..., package.seeall)


local View = require 'bamboo.view'
-- 接收一个list，返回渲染后的字符串
-- npp 为每页条目数
function paginator(list, npp)

	local length = #list
	local pages = math.ceil(length/npp)
	
	return View('paginator.html'){ npp = npp, pages = pages }

end


