-- ui_marquees.lua
-- 2015-01-08
-- KevinYuen
-- 跑马灯

local UIMarquees = class( "UIMarquees", function()
    return display.newNode()
end )

-- 构造初始化
function UIMarquees:ctor( params )
    
    -- 基本变量初始化
    self.name           = params.name or "" 
    self.items          = {}
    self.move_seconds   = params.move_seconds or 4
    self.move_toleft    = params.move_toleft
    self.view_rect      = params.view_rect or cc.rect( 0, 0, 500, 40 )
    self.item_space     = params.item_space or 50
    self.params         = params   
    
--    cc.LayerColor:create( cc.c4b( 255,0,0,100 ) ) 
--        :size(self.view_rect.width, self.view_rect.height)
--        :pos(self.view_rect.x,self.view_rect.y)
--        :addTo(self)
--        :setTouchEnabled(false)
end

-- 重置课件区域
function UIMarquees:SetViewRect( view_rect )
    self.view_rect = view_rect or self.view_rect
end

-- 压入新条目
function UIMarquees:AddItem( item )
    
    if item == nil then
        return nil
    end

    local end_posx
    local start_posx
    if self.move_toleft == true then                -- 从右到左
        end_posx = -item:getContentSize().width
        start_posx = self.view_rect.width
        if #(self.items) > 0 then
            -- 加入到最后一位的右边
            local count = #(self.items) 
            local last = self.items[count]  
            local last_posx = last:getPositionX() + last:getContentSize().width
            if last_posx > self.view_rect.width then
                start_posx = last_posx + self.item_space
            end
        end
    else                                            -- 从左到右
        end_posx = self.view_rect.width
        start_posx = -item:getContentSize().width
        if #(self.items) > 0 then
            -- 加入到最后一位的左边
            local count = #(self.items) 
            local last = self.items[count] 
            local last_posx = last:getPositionX()
            if last_posx < 0 then
                start_posx = last_posx - self.item_space - item:getContentSize().width
            end
        end
    end
    
    self:addChild( item )    
    item:setPosition( start_posx, 0 )
    local speed = self.view_rect.width / self.move_seconds
    local seconds = ( end_posx - start_posx ) / speed
    local moveto = cc.MoveTo:create( math.abs(seconds), cc.p( end_posx, 0 ) )
    local moveover = function( sender, back_data )
        if #(self.items) > 0 then
            for idx = 1, #(self.items) do
                if self.items[idx] == sender then
                    sender:removeFromParent()
                    table.remove( self.items, idx )
                    break
                end
            end
        end
    end
    local callback = cc.CallFunc:create( moveover, { binder = item } )
    local seq = cc.Sequence:create( moveto, callback )
    item:runAction( seq )
    table.insert( self.items, item )
    
    return item
    
end

-- 压入纯文本条目
function UIMarquees:AddTextItem( text_args )

    local content = cc.ui.UILabel.new( {
        text = text_args.text or "...",
        font = text_args.font or display.DEFAULT_TTF_FONT,
        size = text_args.font_size or 30, 
        color = text_args.font_color or display.COLOR_BLACK } )
    content:setAnchorPoint( 0.0, 0.0 )
    content:enableOutline( cc.c4b(0, 0, 0, 255), 1 )
    content:setColor( cc.c3b( 255, 255, 0 ) ) 
    return self:AddItem( content )

end

-- 压入富文本条目
local RichLabel = require("kernels.node.nodeRichLabel" )
function UIMarquees:AddRichText( text_args )

    local content = cc.ui.UILabel.new( {
        text = text_args.text or "...",
        font = text_args.font or display.DEFAULT_TTF_FONT,
        size = text_args.fontSize or 30, 
        color = text_args.font_color or display.COLOR_BLACK } )
        text_args.rowWidth = content:getContentSize().width * 1.1
        text_args.multline = false
        
    local ricLab = RichLabel.new( text_args )
    return self:AddItem( ricLab )
    
end

-- 清空所有条目
function UIMarquees:Clear()
    
    if #(self.items) > 0 then
        for index = 1, #(self.items) do
            self.items[index]:removeFromParent()
        end
    end
    self.items = {}
    
end
                         
return UIMarquees
