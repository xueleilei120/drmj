-- gangSelect.lua
-- 2016-02-16
-- KevinYuen
-- 杠操作选择面板

local GangSelect = class(  "GangSelect" )

GANG_MAX_STACK = 3   -- 最大组数
GANG_MAX_CARDS = 4   -- 单组牌数

-- 构造
function GangSelect:ctor( node, callback )

    self.node = node
    self.callback = callback
    self.focusIdx = -1
    
    self.ui_stacks = {}    
    for i = 1, GANG_MAX_STACK do        
        local stack = { node = nil, cards = {} }           
        stack.node = self.node:getChildByName( "stack" .. i )
        for k = 1, GANG_MAX_CARDS do
            stack.cards[k] = stack.node:getChildByName( "card".. k )
        end
        self.ui_stacks[i] = stack 
    end
    
    self.node:setVisible( false )
    
end

-- 显示杠牌面板
function GangSelect:show( stacks, defIndex )

    -- 堆数组不能超过GANG_MAX_STACK组
    if not stacks or #stacks > GANG_MAX_STACK then
        g_methods:error( "杠牌提示显示失败,无效的提示信息!" )
        return
    end    
    
    -- 默认聚焦
    if defIndex < 1 or defIndex > #stacks then
        g_methods:error( "杠牌提示显示失败,默认聚焦无效!" )
        return
    end
    
    self.showStacks = stacks

    -- 遍历填充
    local stackWidth = 10
    local stackIdx = #stacks 
    for i = 1, GANG_MAX_STACK do
         
        local nodStack = self.ui_stacks[i] 
        nodStack.node:setVisible( false )
        
        if stackIdx > 0 and stackIdx <= #stacks then 

            local cardlst = stacks[stackIdx]  
            if #cardlst ~= GANG_MAX_CARDS then
                g_methods:error( "杠牌提示显示失败,第%d组提示张数错误:%d!", i, #cardlst )
                return
            end
            
            nodStack.index = stackIdx
            stackIdx = stackIdx - 1

            for idx, id in pairs( cardlst ) do
                local card = nodStack.cards[idx]
                local res = getCardResSmall( id, PDIR_UP, SHOW_LI )
                res = string.sub( res, 2 )
                card:loadTexture( res, ccui.TextureResType.plistType )
            end

            nodStack.node:setVisible( true )
            stackWidth = stackWidth + nodStack.node:getContentSize().width + 15

        end
        
    end

    local size = self.node:getContentSize()
    size.width = stackWidth - 15
    self.node:setContentSize( size )
    self.node:setPositionX( display.width - size.width - 30 )

    self.node:openMouseTouch( true, self )
    self.node:setVisible( true )
    self:changeFocus( defIndex )

end

-- 关闭
function GangSelect:close() 

    self.node:openMouseTouch( false )        
    self.node:setVisible( false )
    
end

-- 改变聚焦
function GangSelect:changeFocus( idx )
    
    if  idx == self.focusIdx or 
        idx < 1 or idx > #self.ui_stacks then
        return
    end
    
    self.focusIdx = idx
    
    -- 手牌明暗设定
    local stack = self.ui_stacks[idx]
    local cardlst = self.showStacks[stack.index]
    g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = cardlst } )

    -- 明暗设定
    for i = 1, GANG_MAX_STACK do
    
        local hoverd = ( idx == i )
        local stack = self.ui_stacks[i]
        for k = 1, GANG_MAX_CARDS do
            local cd = stack.cards[k]
            if hoverd then
                cd:setColor( cc.c3b( 255, 255, 255 ) )
            else
                cd:setColor( cc.c3b( 128, 128, 128 ) )
            end
        end
    end
    
end

-- 聚焦检测
function GangSelect:freshFocus( loca )

    for i = 1, GANG_MAX_STACK do
        local stack = self.ui_stacks[i]
        if  stack.node:isVisible() == true and 
            stack.node:hitTest( loca ) == true then
            self:changeFocus( i )
            return stack
        end
    end
    
end

-- 鼠标按下
function GangSelect:onMouseTouchDown( location, args )

    self:freshFocus( location )
    
end

-- 鼠标弹起
function GangSelect:onMouseTouchUp( location, args )

    local stack = self:freshFocus( location )
    if stack and self.callback then
        self.callback( stack.index )
    end 

end

-- 鼠标滚动
function GangSelect:onMouseTouchMove( location, args )
    
    self:freshFocus( location )

end

return GangSelect
