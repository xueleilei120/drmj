-- tape.lua
-- 2014-10-20
-- KevinYuen
-- 卡带(必须放在一个有尺寸属性的层容器上)

local SpriteGrid = class( "SpriteGrid", function()
    return display.newNode()
end )

-- 排列方式
SpriteGrid.SCHEME_L2R     = "SCHEME_L2R"      -- 从左到右(右压左)
SpriteGrid.SCHEME_R2L     = "SCHEME_R2L"      -- 从右到左(左压右)

-- 对齐方式
SpriteGrid.ALIGN_CENTER   = "CENTER"          -- 居中
SpriteGrid.ALIGN_LEFT     = "LEFT"            -- 左(上)对齐
SpriteGrid.ALIGN_TOP      = "LEFT"            -- 左(上)对齐
SpriteGrid.ALIGN_RIGHT    = "RIGHT"           -- 右(下)对齐 
SpriteGrid.ALIGN_DOWN     = "RIGHT"           -- 右(下)对齐

-- 构造初始化
function SpriteGrid:ctor( tape_name )

    -- 基本变量初始化
    self.tape_name      = tape_name
    self.poker_suit     = ""
    self.item_perline  = 100                 -- 每行显示的图标数量
    self.Item_dim       = { 94, 130 }        -- 单个图标的尺寸（长，宽）
    self.offset         = { 30, 45 }         -- 单个图标的偏移量
    self.item_list      = {}                 -- 保存每个图标的字典
    self.maxrow         = 1000               -- 设置最大行
    self.maxcol         = 1000               -- 设置最大列
    self.hasrow         = 1000               -- 剩余的列
    self.hascol         = 1000               -- 剩余的行
    self.scheme_type    = SpriteGrid.SCHEME_L2R    
    self.align_type     = { SpriteGrid.ALIGN_CENTER, SpriteGrid.ALIGN_CENTER }
    self.callback       = nil
end

function SpriteGrid:SetMouseEnabled( enable )
    local scene = cc.Director:getInstance():getRunningScene()    -- 得到场景根节点
    if not scene then
        return
    end
    
    if enable  then
        if not self.mouse_listener_handle then
            -- 鼠标监听
            self.mouse_listener_handle = cc.EventListenerMouse:create()
            local eventDispatcher = scene:getEventDispatcher()
            self.mouse_listener_handle:registerScriptHandler( handler( self, self.OnMousePressDn ), cc.Handler.EVENT_MOUSE_DOWN )
            self.mouse_listener_handle:registerScriptHandler( handler( self, self.onMouseTouchUp ), cc.Handler.EVENT_MOUSE_UP )
            self.mouse_listener_handle:registerScriptHandler( handler( self, self.OnMouseMove ), cc.Handler.EVENT_MOUSE_MOVE )

            eventDispatcher:addEventListenerWithSceneGraphPriority( self.mouse_listener_handle, scene )            
        end        
    else
        if self.mouse_listener_handle then
            -- 鼠标监听移除    
            local eventDispatcher = scene:getEventDispatcher()
            eventDispatcher:removeEventListener( self.mouse_listener_handle )
            self.mouse_listener_handle = nil
        end        
    end    
end

-- 设置回调函数
function SpriteGrid:SetCallback( func )
    self.callback = func
end

-- 批量添加子项：批量字典batmap = { sprite,tag }
function SpriteGrid:AddBatItems( batmap )  
    for _,items in pairs(batmap) do
        -- 创建新卡
        local newitem = 
            {
                selected = false,   -- 选中状态选择
                sprite = items["sprite"],
                tag = items["tag"],
                hasnum = 1          -- 该装备的数量
            }
        self:addChild( newitem.sprite, 0, 0 )
            
        table.insert( self.item_list, newitem )
    end
    self:SortByTag(false)
    
    self:UpdateScheme(false)               -- 更新精灵框列表
           
end

--增加一项子项
function SpriteGrid:AddOneItems(sprite,tag)
    -- 如果tag已存在，则只需添将该装备的数量+1，如果没有，则添加为新的装备
    for index = 1,#self.item_list do 
        if self.item_list[index].tag == tag then
            self.item_list[index].hasnum = self.item_list[index].hasnum + 1
            return
        end
    end

    local newitem = 
        {
            selected = false,
            sprite = sprite,
            tag = tag,
            hasnum = 1
        }
    self:addChild( newitem.sprite, 0, 0 )
    table.insert( self.item_list, newitem )
    
    self:SortByTag(false)
    
    self:UpdateScheme(false)
end



--删除子项，根据每种装备特有的tag属性
function SpriteGrid:DeleteOneItems(tag)
    -- 如果该转装备的数量大于1一个，则只需要将该装备的数量减1，如果该装备数量小于1，则删除该装备显示
    for index = 1,#self.item_list do 
        if self.item_list[index].tag == tag then
            self.item_list[index].hasnum = self.item_list[index].hasnum - 1
            if self.item_list[index].hasnum == 0 then
                self:removeChild(self.item_list[index].sprite)
                table.remove(self.item_list,index)
                
                self:SortByTag(false)

                self:UpdateScheme(false)
            end
        end
    end  
end

-- 根据各子项的tag进行排序
function SpriteGrid:SortByTag( reverse_sort  )

    reverse_sort = reverse_sort or false
 
    if reverse_sort then 
        table.sort(self.item_list,function(a,b)
            return a.tag > b.tag
        end
        )
    else
        table.sort(self.item_list,function(a,b)
            return a.tag < b.tag
        end
        ) 
    end
end

-- 更新布局
function SpriteGrid:UpdateScheme( ime_move )

    -- 布局取决于父节点的位置
    -- 得到父节点的控件的大小
    local pan_parent = self:getParent()
    if not pan_parent then
        return false
    end

    -- 计算卡带排列维度 
    local row_Items = table.getn( self.item_list )
    local col_count = 1
    
    if row_Items > self.item_perline then
        col_count = math.floor( row_Items / self.item_perline ) + 1
        row_Items = self.item_perline
    end

    -- 计算起始位置以及偏移步长
    local parent_area = pan_parent:getContentSize()
    g_methods:debug("parent_area.width = %s, parent_area.height = %s",tostring(parent_area.width),tostring(parent_area.height))

    local start_pos = { 0, 0 } 
    local self_position = { 0, 0 }
    local offset_step = self.offset
    if self.align_type[1] == SpriteGrid.ALIGN_LEFT then
        self_position[1] = 0
        start_pos[1] = self.Item_dim[1] + 2   
    end

    if self.align_type[2] == SpriteGrid.ALIGN_TOP then
        self_position[2] = parent_area.height
        start_pos[2] = -self.Item_dim[2] + 2
    end
    -- 定位节点的初始坐标
    self:setPosition( self_position[1], self_position[2] )

    -- 位置更新
    local index = 1
    local start_x = start_pos[1] 
    local start_y = start_pos[2] 
    table.foreach( self.item_list, function( i, v )
            v        .sprite:setPosition( cc.p( start_x, start_y ) )
            index = index + 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
            if index <= row_Items then
                start_x = start_x + offset_step[1]
            else
                start_x = start_pos[1]
                start_y = start_y - offset_step[2]
                index = 1
            end
    end )
end

-- 获取指定位置的子卡
function SpriteGrid:FindItem( index )
    if index < 1 or index > #(self.item_list) then
        g_methods:error( "获取子卡精灵失败,参数位置无效:%d...", index )
        return  nil
    else
        return self.item_list[index]
    end
end

-- 获取指定位置的子卡精灵
function SpriteGrid:FindItemSprite( index )

    if index < 1 or index > #(self.item_list) then
        g_methods:error( "获取子卡精灵失败,参数位置无效:%d...", index )
        return  nil
    else
        local Item = self.item_list[index]
        return Item.sprite
    end
end

-- 卡列表清空
function SpriteGrid:ClearItemList()
    if #(self.item_list) == 0 then
        return
    end

    for index = 1, #(self.item_list) do
        local item = self.item_list[index]
        item.sprite:removeFromParent()
    end
    self.item_list = {}

end

-- 鼠标按下
function SpriteGrid:OnMousePressDn( mouseEvent )
    self.callback( self, { type = "mousedown" } )
end

-- 鼠标弹起
function SpriteGrid:onMouseTouchUp( mouseEvent )

    local scrx = mouseEvent:getCursorX()
    local scry = mouseEvent:getCursorY()

    -- 判断点击
    for _, item in pairs( self.item_list ) do
        if item.sprite:isVisible() == true and 
            item.sprite:hitTest( cc.p( scrx, scry ) ) then
            if item.tag and self.callback then
                g_methods:debug( "点击了表情[%s]", tostring(item.tag) )           -- 此处添加一个事件处理机制，让其可以添加到输入框中
                self.callback( self, { type = "clicked", posx = scrx , posy = scry, spt = item } )
            end
        else
        end
    end
end

-- 鼠标移动
function SpriteGrid:OnMouseMove( mouseEvent )  
    -- 如果移动在在表情动画面板
    if  self:getParent() then
        local scrx = mouseEvent:getCursorX()
        local scry = mouseEvent:getCursorY()  
        local getface = nil
        local items = self:getChildren()
        for _, item in pairs( items ) do
            if item:isVisible() == true and 
                item:hitTest( cc.p( scrx, scry ) ) then
                local posx, posy = item:getPosition()
                self.callback( self, { type = "mousemove", posx = posx, posy = posy, isget = true} )  -- 返回鼠标移动的位置
                return
            else              
            end
        end  
        if self.callback then
            self.callback( self, { type = "mousemove", posx = scrx , posy = scry, isget = false } )  -- 返回鼠标移动的位置
        end
    end
end
    
    
return SpriteGrid