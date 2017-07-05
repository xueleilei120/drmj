-- tape.lua
-- 2015-10-13
-- KevinYuen,gaoxe
-- 卡带(必须放在一个有尺寸属性的层容器上)

local HuTypeGrid = class( "HuTypeGrid", function()
    return display.newNode()
end )

-- 排列方式
HuTypeGrid.SCHEME_L2R     = "SCHEME_L2R"      -- 从左到右(右压左)
HuTypeGrid.SCHEME_U2D     = "SCHEME_U2D"      -- 从上到下(下压上)


-- 对齐方式
HuTypeGrid.ALIGN_CENTER   = "CENTER"          -- 居中
HuTypeGrid.ALIGN_LEFT     = "LEFT"            -- 左(上)对齐
HuTypeGrid.ALIGN_TOP      = "TOP"            -- 左(上)对齐
HuTypeGrid.ALIGN_RIGHT    = "RIGHT"           -- 右(下)对齐 
HuTypeGrid.ALIGN_DOWN     = "DOWN"           -- 右(下)对齐

-- 构造初始化
function HuTypeGrid:ctor( HuTypeGrid )

    -- 基本变量初始化
    self.HuTypeGrid      = HuTypeGrid
    self.gridSuit     = ""
    self.gridPerLine  = 4
    self.gridDim       = { 200, 30 }                                                -- 卡带节点的长和宽
    self.offset         = { 15, 10 }                                                -- 卡带节点之间的距离
    self.move_seconds   = 0.1                                                       -- 卡带节点的时间
    self.gridList      = {}                                                         -- 卡带列表
    self.scheme_type    = HuTypeGrid.SCHEME_U2D                                     --卡带排布方式
    self.align_type     = {  HuTypeGrid.ALIGN_LEFT, HuTypeGrid.ALIGN_TOP  }      -- 卡带节点的对齐方式
    self.hover_card     = 0                                                         -- 弃用
    self.dragging_now   = false                                                     -- 弃用

end

--设置排列方式
function HuTypeGrid:SetSchemeType( type )

    self.scheme_type = type
end

--设置排列方式
function HuTypeGrid:SeAlignType( type )

    self.align_type = type
end

--设置行/列 数

function HuTypeGrid:SetLineNum( num )
    self.gridPerLine = num
end


-- 批量添加子卡
-- 批量添加子项：批量字典batmap = { id,node,tag },ime_move是否需要移动
function HuTypeGrid:AddBatNode( batmap, ime_move )
    local flag = true
    if #batmap <= 0 then
        flag = false
        return flag
    end

    -- 参数补全
    ime_move = ime_move or false

    for _,items in pairs(batmap) do

        self:AddNode(items)   --将新添加的chip节点添加到self.gridList中去

    end

    self:UpdateScheme(ime_move)               -- 更新精灵框列表

    return flag
end

-- 添加新卡
function HuTypeGrid:AddNode( items )

    -- 创建新卡
    local new_chip = 
        {
            chipid = items['chipid'],
            node = items["node"],
            tag  = items["tag"] or ""
        }

    -- 加入子节点和管理列表
    self:addChild( new_chip.node, 0, 0 )

    table.insert( self.gridList, new_chip )

end

-- 根据tag得到该节点的x,y坐标
-- cx,cy表示该节点的x,y坐标，falg表示是否找到该节点，node返回该节点，可以用来修改该节点信息
function HuTypeGrid:FindByTag(tag)
    local node= {flag = false,cx = 0,cy = 0, node = nil}
    for _, item in pairs( self.gridList ) do
        if item.tag == tag then
            if item.node:isVisible() == true then
                local cx,cy = item.node:getPosition()
                node = { falg = true, cx = cx, cy = cy, node = item.node}
                break 
            end
        end
    end

    return node      
end

-- 根据tag得到该节点的x,y坐标
-- cx,cy表示该节点的x,y坐标，falg表示是否找到该节点，node返回该节点，可以用来修改该节点信息
function HuTypeGrid:FindByNodeId(chipid)
    local chipnode= {flag = false,cx = 0,cy = 0, node = nil}
    for _, item in pairs( self.gridList ) do
        if item.chipid == chipid then
            if item.node:isVisible() == true then
                local cx,cy = item.node:getPosition()
                chipnode = { falg = true, cx = cx, cy = cy, node = item.node}
                break 
            end
        end
    end

    return chipnode      
end

-- 通过tag删除该节点
function HuTypeGrid:DeleteByTag(tag)
    if #(self.gridList) == 0 then
        return
    end
    local falg = false

    for index = 1, #(self.gridList) do
        local chip = self.gridList[index]
        if chip.tag == tag then
            chip.node:removeFromParent()          --暂定，筹码节点
            table.remove(self.gridList,index)
            flag = true
            break
        end
    end

    return flag
end

-- 通过tag删除该节点
-- 返回 true表示删除成功，为false表示删除失败
function HuTypeGrid:DeleteByNodeID(chipid)
    if #(self.gridList) == 0 then
        return
    end
    local falg = false

    for index = 1, #(self.gridList) do
        local chip = self.gridList[index]
        if chip.chipid == chipid then
            chip.node:removeFromParent()          --暂定，筹码节点
            table.remove(self.gridList,index)
            flag = true
            break
        end
    end

    return flag
end

-- 卡列表清空
function HuTypeGrid:ClearGridList()

    if #(self.gridList) == 0 then
        return
    end

    for index = 1, #(self.gridList) do
        local chip = self.gridList[index]
        chip.node:removeFromParent()          --暂定，筹码节点
    end
    self.gridList = {}
    self:UpdateScheme()
end

-- 更新布局
-- ime_move 表示是否移动
function HuTypeGrid:UpdateScheme( ime_move )

    -- 布局取决于父节点的位置
    local pan_parent = self:getParent()
    if not pan_parent then
        return false
    end

    -- 参数补全
    ime_move = ime_move or false

    -- 计算卡带排列维度 
    local nGridListNum = table.getn( self.gridList )
    local nColCount  = 1
    local nRowCount  = 1
    if self.scheme_type == HuTypeGrid.SCHEME_L2R then
        nColCount = self.gridPerLine 
        nRowCount = math.floor( nGridListNum / self.gridPerLine ) + 1
    elseif self.scheme_type == HuTypeGrid.SCHEME_U2D then
        nRowCount = self.gridPerLine 
        nColCount = math.floor( nGridListNum / self.gridPerLine ) + 1
    end

    --计算卡带区域的宽度
    local gridWidth =  (nColCount-1) * self.offset[1] + nColCount * self.gridDim[1]
    local gridHeight = (nRowCount -1) * self.offset[2] + nRowCount * self.gridDim[2]


    -- 计算起始位置  
    local parent_area = pan_parent:getContentSize()
    local start_pos = { 0, 0 } 
    local offset_step = {0,0}

    if self.align_type[1] == HuTypeGrid.ALIGN_CENTER then

    elseif self.align_type[1] == HuTypeGrid.ALIGN_LEFT then
        start_pos[1] =  self.offset[1] 
        offset_step[1] = self.gridDim[1] + self.offset[1]
    elseif self.align_type[1] == HuTypeGrid.ALIGN_RIGHT then
        start_pos[1] = parent_area.width  -self.offset[1]
        offset_step[1] = -(self.gridDim[1] + self.offset[1])
    end

    if self.align_type[2] == HuTypeGrid.ALIGN_CENTER then

    elseif self.align_type[2] == HuTypeGrid.ALIGN_TOP then
        start_pos[2] = parent_area.height - self.gridDim[2] -self.offset[2]
        offset_step[2] = -(self.gridDim[2] + self.offset[2])
    elseif self.align_type[2] == HuTypeGrid.ALIGN_DOWN then
        start_pos[2] =  self.gridDim[2]  + self.offset[2]
        offset_step[2] =  self.gridDim[2] + self.offset[2]
    end

    --设置当前的起始位置，即父节点的位置，其他控件根据该坐标调整位置
    self:setPosition( 0,0)

    -- 位置更新
    local index = 0
    local start_x = start_pos[1]
    local start_y = start_pos[2]


    table.foreach( self.gridList, function( i, v )     
        --            -- 移动
        v.node:stop()

        if not ime_move then
            v.node:setPosition( cc.p( start_x, start_y ) )
            --v.sprite:moveTo( 0, start_x, start_y )
        else 
            v.node:moveTo( self.move_seconds, start_x, start_y )
            --                local mov = cc.MoveTo:create( self.move_seconds,cc.p(start_x, start_y))
            --                v.node:runAction(mov)
        end

        index = index + 1
        local colNum = 1
        local rowNum = 1
        if self.scheme_type == HuTypeGrid.SCHEME_L2R then
            colNum = index%self.gridPerLine
            rowNum = math.floor(index/self.gridPerLine)
        elseif self.scheme_type == HuTypeGrid.SCHEME_U2D then
            rowNum = index%self.gridPerLine
            colNum = math.floor(index/self.gridPerLine)
        end

        start_x = start_pos[1]  + offset_step[1]*colNum
        start_y = start_pos[2]  + offset_step[2]*rowNum

    end )

    return true

end

return HuTypeGrid