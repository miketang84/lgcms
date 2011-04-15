module(..., package.seeall)

local Form = require 'bamboo.form'
local View = require 'bamboo.view'

local Page = require 'legecms.models.page'
local Upload = require 'bamboo.models.upload'

local http = require 'lglib.http'

function upload(web, req)
	-- ptable(req.headers)
    -- 这里等待输入
    local pagename = req.path:match('/([%w%-_]+)/upload/$')
    local page = Page:getByName(pagename)
	if not page.id then
		-- 说明没取到一个正确的page对象
		error(('Page name %s does not exist.'):format(pagename))
	end
	
    local newfile, result_type = Upload:process(web, req)
	-- t0用于包装文件对象到一个table中
	local t0 = nil
	-- 将新上传文件的id追加到文件索引的后面
	-- 如果是单文件上传。html4单文件，或html5上传
	if result_type == 'single' then
		page:appendToField ('uploads', newfile.id)
		t0 = { newfile }
	-- 如果是多文件上传。html4多文件上传
	elseif result_type == 'multiple' then
		for i, v in ipairs(newfile) do
			page:appendToField('uploads', v.id)
		end
		t0 = newfile
	end
	
	-- 这里的错误处理还需完善.....
	if not newfile then 
		-- 如果newfile为nil，则说明在上传处理函数中，已经中断了连接，再返回任何值都是无效的了
		-- 所以这里直接返回false
		return false
	 end
	
	-- 保存一次page（后面可以考虑更新模型部分字段，以提升效率）
	page:save()
	
	-- 生成返回的页面片断
	local htmls = ''
	for i, uploadfile in ipairs(t0) do
		-- 将文件路径编码码成URL形式
		uploadfile.name = http.decodeURL(uploadfile.name)
		htmls = htmls + View("upload/new.html"){ uploadfile = uploadfile }
	end

	local data = {
		['success'] = true,
		['pagename'] = page.name,
		['htmls'] = htmls
	}	
	if req.ajax then
        web:json (data)
    else
        web:page(([[{"success": true, "pagename": "%s", "htmls": %q }]]):format(page.name, htmls))
    end
end



require 'gd'
-- 在用户头像上传这个应用中，每次只允许上传一个文件，不允许多文件选择
function userlogoUpload(web, req)

    local newfile, result_type = Upload:process(web, req)
	print(newfile, result_type)
	-- html4文件上传，单文件
	if result_type == 'multiple' then newfile = newfile[1] end
	-- 如果文件出错，直接返回
	if not newfile then return false end
	
	print('file stored to disk, now scale it.')
	
	im_src = gd.createFromJpeg(newfile.path)
	if not im_src then
		print('png')
		local im_src = gd.createFromPng(newfile.path)
	end
	if not im_src then
		print('gif')
		im_src = gd.createFromGif(newfile.path)
	end
	
	local x, y = im_src:sizeXY()
	local ny = 150
	local nx = ny * x / y
	local im_des = gd.createTrueColor(nx, ny)

	im_des:copyResampled(im_src, 0, 0, 0, 0, nx, ny, x, y)
	--local newname = Upload:computeNewFilename(newfile.path)
	-- 分离文件的文件名和扩展名
	local newpath = newfile.path
	local main, ext = newpath:match('^(.+)(%.%w+)$')
	main = main + '_middle'
	newpath = main + '.png'
	local mainname = main:match('/([^:%(%)/]+)$')
	print('save scaled file.')
	-- 存储文件到磁盘上
	im_des:png(newpath)
	
	print('record it to db')
	-- 记录到数据库中
	local newfile = Upload {
		name = mainname + '.png',
		path = newpath
	}
	newfile:save()
	print('save scaled file ok.', main + '.png')

	if req.ajax then
		return web:json { 
			['success'] = true,
			['filename'] = newfile.path,
			['nx'] = nx,
			['ny'] = ny
		}
	else
		return web:page(([[{"success": true, "filename": "%s"}]]):format(newfile.path))
	end
	
end


function userlogoCropdata(web, req) 

    local params = Form:parse(req)
    ptable(params)
    
    local middle_filename = params.middle_filename
	-- 肯定是png图像
	local im_src = gd.createFromPng(middle_filename)
	local x, y = im_src:sizeXY()
	print(x, y)
	local ny = 60
	local nx = 60
	local im_des = gd.createTrueColor(nx, ny)

	print(params.new_x, params.new_y, nx, ny, params.new_w, params.new_h)
	im_des:copyResampled(im_src, 0, 0, params.new_x, params.new_y, nx, ny, params.new_w, params.new_h)
	-- 分离文件的文件名和扩展名
	local newpath = middle_filename
	local main, ext = newpath:match('^(.+)(%.%w+)$')
	main = main:sub(1, -7) + 'small'
	newpath = main + '.png'
	local mainname = main:match('/([^:%(%)/]+)$')
	print('save scaled file.')
	-- 存储文件到磁盘上
	im_des:png(newpath)
	
	print('record it to db')
	-- 记录到数据库中
	local newfile = Upload {
		name = mainname + '.png',
		path = newpath
	}
	newfile:save()
	
	print('save scaled file ok.', main + '.png')

	if req.ajax then
		return web:json { 
			['success'] = true,
			['filename'] = newfile.path,
		}
	else
		return web:page(([[{"success": true, "filename": "%s"}]]):format(newfile.path))
	end

end

