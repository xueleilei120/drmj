-- base_comp.lua
-- 2014-11-02
-- KevinYuen
-- 富文本控件

local ChineseSize = 3 -- 修正宽度缺陷(范围:3~4)
local RichLabel = class( "RichLabel", function() return display.newNode() end )

-- 元素部件类型
RichLabel.TextUnit = 1
RichLabel.ImageUnit = 2
RichLabel.AnimUnit = 3

-- 构造函数
function RichLabel:ctor( param )

    self.font = param.font or "gfont.ttf"
    self.fontSize = param.fontSize or 18
    self.rowWidth = param.rowWidth or 280
    self.multline = param.multline or true
    self.unitLines = {} 
    self.height = 0
    self.text = ""
    if param.text ~= nil and param.text ~= "" then
        self:SetText( param.text )
    end
end

-- 设置多行
function RichLabel:SetMultLines( mult )
    self.multline = mult
end

-- 重置宽度
function RichLabel:SetWidth( width )
    self.rowWidth = width
end

-- 获取宽度
function RichLabel:GetWidth()
    return self.rowWidth
end

-- 获取高度
function RichLabel:GetHeight()
    return self.height
end

-- 获取尺寸
function RichLabel:getContentSize()
    return { width = self.rowWidth, height = self.height }
end

-- 文本串设定
function RichLabel:SetText( str )

    -- 参数无效或者重复直接返回
    if str == nil or str == "" or str == self.text then
        return
    end

    -- 文本重置
    self.text = str

    -- 重新进行拆分
    self:Split()

    -- 刷新
    self:Refresh()

end

-- 文本串获取
function RichLabel:GetText()
    return self.text
end

-- 解析16进制颜色RGBA值 
function RichLabel:GetTextColor( color_text )
    if string.len(color_text) == 8 then
        local tmp = {}
        for i = 0, 7 do
            local str =  string.sub( color_text, i + 1, i + 1 )
            if    ( str >= '0' and str <= '9') then tmp[8-i] = str - '0'
            elseif( str == 'A' or str == 'a' ) then tmp[8-i] = 10
            elseif( str == 'B' or str == 'b' ) then tmp[8-i] = 11
            elseif( str == 'C' or str == 'c' ) then tmp[8-i] = 12
            elseif( str == 'D' or str == 'd' ) then tmp[8-i] = 13
            elseif( str == 'E' or str == 'e' ) then tmp[8-i] = 14
            elseif( str == 'F' or str == 'f' ) then tmp[8-i] = 15
            else
                print("Wrong color value.")
                tmp[8-i] = 0
            end
        end
        local a = tmp[8] * 16 + tmp[7]
        local r = tmp[6] * 16 + tmp[5]
        local g = tmp[4] * 16 + tmp[3]
        local b = tmp[2] * 16 + tmp[1]
        return cc.c4b( a, r, g, b )
    end
    return cc.c4b( 255, 255, 255, 255 )
end

-- 拆分文本串
function RichLabel:Split()

    -- 拆分集合清空
    g_methods:CleanTable( self.unitLines )

    -- 拆分规则
    -- <c=#>]颜色,设定对随后的所有文本均有效,直到结束或者另外一个color出现
    -- <i=#framename或者filename>图片
    -- <a=plistfile>动画
    -- <bl]主动断行
    local label = display.newTTFLabel( {text = "", size = self.fontSize } )
    local now_width = 0
    local line_index = 1

    -- 规则对解析
    -- 基本思路：
    -- 1.找到需要匹配的所有表示（颜色，图片）
    -- 2.根据匹配的初始位置，对字典中的值排序
    -- 3.根据替换规则替换为需要的数据形式
    local split_text = self.text   
    local teststr = self.text
    local ruleTbl = {}


    -- 基本思路如下：
    -- 先找到#位置，然后向后取8位
    -- 根据优先级来判断是否是怎么的取值（先是16定制，再是颜色，再是数字）
    local fidx = 0
    local lidx = 0
    local xflag = false  -- 已经匹配了十六定制的值
    local zflag = false  -- 已经匹配了字母的值

    -- 目前图片支持0-999,1000个动画或者静态图片的配置
    local query_res = function( num )
        
        -- 先从表情库中查找
        local temp = string.format( "faces.sf_%03d", num )
        local config = g_library:QueryConfig( temp )
        if config then
            return temp, "ani"
        end
        
        -- 再从静态图库(暂时用文本库替代)查找
        temp = string.format( "image.%03d", num )
        local cfg = g_library:QueryConfig( temp )
        if cfg ~= nil then
            return cfg, "image"
        end
        
        return nil
        
    end

    for ss in string.gfind(teststr,"#") do
        xflag = false
        zflag = false

        fidx,lidx = string.find(teststr,ss,lidx+1)
        local temp_str = string.sub(teststr,fidx,fidx+10)
        --  print(temp_str)

        for ss in string.gfind(temp_str,"#0x%x%x%x%x%x%x%x%x") do
            xflag = true
            local c_value = self:GetTextColor( string.sub(tostring(ss),4 ))
            table.insert(ruleTbl,{value=c_value,fidx = fidx, lidx = fidx+10, type= "color" })
        end
        if xflag then

        else      -- 匹配单字母的颜色定义
            local temp_str = string.sub(teststr,fidx,fidx+1)
            for ss in string.gfind(temp_str,"#%a") do

                -- 设置一个颜色筛选器，对不是颜色的匹配不处理
                local push_color = function( rule_value ) 
                    rule_value = string.lower(rule_value)         -- 将所有字母全部转换为小写形式
                    if    rule_value == "r"   then      return cc.c4b( 231, 83, 83, 255 )       -- 红色-- 颜色（RGBA）
                    elseif rule_value == "g"  then      return cc.c4b( 119, 214, 97, 255 )      -- 绿色
                    elseif rule_value == "b"  then      return cc.c4b( 0, 0, 255, 255 )         -- 蓝色
                    elseif rule_value == "y"  then      return cc.c4b( 255, 255, 0, 255 )       -- 黄色
                    elseif rule_value == "k"  then      return cc.c4b( 237, 173, 0, 255 )       -- 土黄色 
                    elseif rule_value == "p"  then      return cc.c4b( 255, 0, 255, 255 )       -- 紫色
                    elseif rule_value == "w"  then      return cc.c4b( 255, 255, 255, 255 )     -- 白色
                    elseif rule_value == "h"  then      return cc.c4b( 0, 0, 0, 255 )           -- 黑色
                    elseif rule_value == "G"  then      return cc.c4b( 131, 131, 131, 255 )      -- 灰色
                    else  return nil
                    end
                end

                local c_value = push_color(string.sub(ss,2))
                if c_value == nil then     -- 不存在该字母的颜色设置，固排除
                else
                    table.insert(ruleTbl,{value = c_value, fidx = fidx, lidx = fidx+1,type = "color",realvalue = ss})
                end
            end

            if zflag then 
            --          print("匹配到了字母颜色了")

            else  -- 匹配图片包括一位，两位，三位
                --          print("开始匹配数字情况")
                local numcount = 3

                while (numcount >0) do

                    local threeflag = false
                    local twoflag   = false
                    local oneflag   = false
                    local temp_str = string.sub(teststr,fidx,fidx+numcount)
                    for ss in string.gfind(temp_str,"#%d+") do
                        local tmp = string.sub( tostring(ss),2 )
                        local res, type = query_res( tonumber( tmp ) )
                        if res then
                                threeflag = true
                                table.insert(ruleTbl,{value = res, fidx = fidx, lidx = fidx+3,type = type })
                            end
                        end 
                        if threeflag then
                            break
                    end
                
                    numcount = numcount - 1
                end
            end 
        end 
    end
    
    
    local fidx = 0
    local lidx = 0 
    
    -- 匹配分行（#bl）
    for ss in string.gfind(split_text,"<bl>") do
        fidx,lidx = string.find(split_text,ss,lidx+1)
        -- 此处需要一个map表，对相应的图片编号找到对应的图片
        table.insert(ruleTbl,{value = ss, fidx = fidx, lidx = lidx,type = "breakline"})
    end
    

    -- 对匹配的所有特殊字符定义按所在字符串中的位置进行排序
    table.sort(ruleTbl,function(a,b)
        return a.fidx < b.fidx
        end
    )
    
    -- 将特殊字符之间的文本数据拆分出来，压入到dealorder字典中
    local dealOrders = {}          -- 保存拆分后的所有片段（按所在位置的索引大小）
    local i =0                     -- 暂时保存当前拆分的位置
    for j = 1,(#ruleTbl) do 
        if i == (ruleTbl[j].fidx-1) and i == 0 then      -- 特殊处理特殊字符在最前面的情况
            table.insert(dealOrders,ruleTbl[j])
            i = ruleTbl[j].lidx + 1
        else
            local text_str = string.sub(split_text,i,ruleTbl[j].fidx-1)
            table.insert(dealOrders,{value = text_str,type = "text"})
            table.insert(dealOrders,ruleTbl[j])
            i = ruleTbl[j].lidx + 1
        end
        
        -- 特殊处理特殊字符在最后面的情况
        if j == #ruleTbl and ruleTbl[j].lidx ~= #split_text then
            local text_str = string.sub(split_text,i,#split_text)
            table.insert(dealOrders,{value = text_str,type = "text"})
        end
    end
  
  if #ruleTbl == 0 then
        table.insert(dealOrders,{value = split_text,type = "text"})
  end

    -- 循环执行序列
    local line_width = 0
    local line_index = 1
    local now_color = cc.c4b( 255, 255, 255, 255 )
    for k, cmd in pairs( dealOrders ) do

        if cmd.type == "color" then

            now_color = cmd.value

        elseif cmd.type == "image" then

            local spt = display.newSprite( cmd.value )
            if spt then

                spt:addTo( self )

                -- 超出宽度需要换行
                local spt_width = spt:getContentSize().width
                if self.multline == true and spt_width + line_width > self.rowWidth then
                    line_index = line_index + 1
                    line_width = 0
                end

                -- 加一行记录
                if not self.unitLines[line_index] then
                    self.unitLines[line_index] = {}
                end

                table.insert( self.unitLines[line_index], 
                    { type = RichLabel.ImageUnit, 
                        sprite = spt, 
                        width = spt_width, 
                        height = spt:getContentSize().height } )
                line_width = line_width + spt_width
            end

        elseif cmd.type == "ani" then
        
            local spt = display.newSprite()
            local spt_ani, max_size = g_library:CreateAnimation( cmd.value )
            if spt then
            
                spt:playAnimationForever( spt_ani )

                spt:addTo( self )
                spt:setContentSize( max_size )

                -- 超出宽度需要换行
                local spt_width = max_size.width
                if self.multline == true and spt_width + line_width > self.rowWidth then
                    line_index = line_index + 1
                    line_width = 0
                end

                -- 加一行记录
                if not self.unitLines[line_index] then
                    self.unitLines[line_index] = {}
                end

                table.insert( self.unitLines[line_index], 
                    { type = RichLabel.ImageUnit, 
                        sprite = spt, 
                        width = spt_width, 
                        height = max_size.height } )
                line_width = line_width + spt_width
            end
            
        elseif cmd.type == "breakline" then

            if self.multline == true and line_width > 0 then
                line_index = line_index + 1
                line_width = 0
            end

        elseif cmd.type == "text" then

            function split_line( width, text )

                local real_width = 0
                local real_text = ""
                local len = string.len(text)
                local list = self:CutText( text )
                for index = 1, #list do

                    label:setString( list[index] )
                    local len = string.len( list[index] )

                    local txt_width = label:getContentSize().width
                    if txt_width < self.fontSize / 2 then
                        txt_width = math.ceil( self.fontSize / 2 )
                    end

                    if self.multline == true then
                        if real_width + txt_width < width then
                            real_width = real_width + txt_width
                            real_text = real_text .. list[index]
                        else
                            local tmp_text = ""
                            for loop = index, #list do
                                tmp_text = tmp_text .. list[loop]
                            end

                            return real_text, real_width, tmp_text
                        end
                    else
                        real_width = real_width + txt_width
                        real_text = real_text .. list[index]
                    end
                end

                return text, real_width, ""
            end

            -- 文本多行拆分
            while true do
                local line_text, text_width, remain_text = split_line( self.rowWidth - line_width , cmd.value )
                if line_text ~= "" then
                    if not self.unitLines[line_index] then
                        self.unitLines[line_index] = {}
                    end
                    line_width = line_width + text_width
                    table.insert( self.unitLines[line_index],
                        { type = RichLabel.TextUnit,
                            text = line_text,
                            color = now_color,
                            width = text_width,
                            height = 0 } )
                end
                if remain_text ~= "" then
                    line_index = line_index + 1
                    line_width = 0
                    cmd.value = remain_text
                else
                    break
                end
            end

        else
            g_methods:error( "无法解析的规则关键字:%s.", cmd.type )
        end

    end

end

-- 更新
function RichLabel:Refresh()

    self.height = 0
    local nWidth, nHeight, maxHeight = 0, 0, 0;
    for index = #self.unitLines, 1, -1 do
        local line = self.unitLines[index]
        for order = 1, #line do
            if line[order].type == RichLabel.TextUnit then
                local lbl = display.newTTFLabel( 
                    { text = line[order].text, 
                        size = self.fontSize, 
                        color = line[order].color, 
                        font  = self.font } )
                lbl:align(display.LEFT_BOTTOM, nWidth, nHeight )
                lbl:addTo( self )

                nWidth = nWidth + lbl:getContentSize().width
                local height = lbl:getContentSize().height
                if height > maxHeight then 
                    maxHeight = height
                end

            elseif line[order].type == RichLabel.ImageUnit then

                line[order].sprite:align( display.LEFT_BOTTOM, nWidth, nHeight )
                nWidth = nWidth + line[order].sprite:getContentSize().width
                local height = line[order].sprite:getContentSize().height
                if height > maxHeight then
                    maxHeight = height
                end

            elseif line[order].type == RichLabel.AnimUnit then
            else
            end
        end
        nHeight = nHeight + maxHeight
        self.height = self.height + maxHeight        
        nWidth, maxHeight = 0, 0
    end
end

-- 拆分出单个字符
function RichLabel:CutText(str)
    local list = {}
    local len = string.len(str)
    local i = 1 
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i+shift-1)
        i = i + shift
        table.insert(list, char)
    end
    return list, len
end

return RichLabel 
