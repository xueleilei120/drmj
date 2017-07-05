-- nodeTestUnit.lua
-- 2016-03-07
-- KevinYuen
-- 测试单元列表

local UITestUnits = class( "UITestUnits" )

-- 构造初始化
function UITestUnits:ctor()
        
    local rwidth    = display.width * 0.3
    local rheight   = display.height * 0.9    
    self.vlist      = cc.ui.UIListView.new( {
        bgColor     = cc.c4b( 0, 0, 0, 180 ),
        viewRect    = cc.rect( 0, 0, rwidth, rheight ),
        alignment   = cc.ui.UIListView.ALIGNMENT_LEFT,
        direction   = cc.ui.UIScrollView.DIRECTION_VERTICAL
    } )

    self.vlist:onTouch( handler( self, self.OnTouchMenu ) )
    local scene = cc.Director:getInstance():getRunningScene()
    scene:addChild( self.vlist, 400000 )
    self.vlist:setPosition( cc.p( ( display.width - rwidth ), (display.height - rheight ) / 2 ) )
        
    self.vlist:setVisible( false )
    
end
       
-- 重组单元类表
function UITestUnits:ResetUnits( unitmaps )

    self.vlist:removeAllItems()

    self.units = unitmaps
    for idx, unit in pairs( unitmaps ) do

        local item = self.vlist:newItem()
        local content = cc.ui.UILabel.new( {
            text = string.format( " %03d \t%s", idx, unit[1] ),
            font = "gfont.ttf",
            size = 20,
            align = cc.ui.TEXT_ALIGN_LEFT,
            color = display.COLOR_GREEN } ) 
        --content:enableOutline( cc.c4b(0, 0, 0, 255), 1 )
        content:setColor( cc.c3b( 0, 255, 0 ) )
        item:addContent( content )
        item:setItemSize( 250, 30 )
        self.vlist:addItem(item)
        
    end

    self.vlist:reload()
    
end

-- 测试单元列表点击
function UITestUnits:OnTouchMenu( event )

    -- 点击处理
    if event.itemPos and "clicked" == event.name then
        local func = self.units[event.itemPos][2]
        if func then
            func()
        end
    end
end

-- 显示隐藏
function UITestUnits:togShow()
    local show = self.vlist:isVisible()
    self.vlist:setVisible( not show )
end
   
return UITestUnits
