-- nodeCmdList.lua
-- 2016-03-07
-- KevinYuen
-- 命令列表

local UICmdList = class( "UICmdList" )

-- 构造初始化
function UICmdList:ctor( file )
    
    -- 基本变量初始化
    local infos     = g_methods:ImportJson( file )
    self.items      = infos.list
    
    local rwidth    = display.width * 0.5
    local rheight   = display.height * 0.9
    
    self.vlist      = cc.ui.UIListView.new( {
        bgColor     = cc.c4b( 0, 0, 0, 200 ),
        viewRect    = cc.rect( 0, 0, rwidth, rheight ),
        alignment   = cc.ui.UIListView.ALIGNMENT_LEFT,
        direction   = cc.ui.UIScrollView.DIRECTION_VERTICAL
    } )

    self.vlist:onTouch( handler( self, self.OnTouchMenu ) )
    local scene = cc.Director:getInstance():getRunningScene()
    scene:addChild( self.vlist, 400000 )
    self.vlist:setPosition( cc.p( display.width - rwidth, (display.height - rheight ) / 2 ) )
    
    if #self.items > 0 then
    
        for i = 1, #self.items do
        
            local item = self.vlist:newItem()
            local content = cc.ui.UILabel.new( {
                text = string.format( "%02d) %15s:%s", i, self.items[i][1], self.items[i][2] ),
                font = "gfont.ttf",
                size = 20,
                align = cc.ui.TEXT_ALIGN_LEFT,
                color = display.COLOR_YELLOW } )
            --content:enableOutline( cc.c4b(0, 0, 0, 255), 1 )
            content:setColor( cc.c3b( 0, 255, 0 ) )
            item:addContent( content )
            item:setItemSize( 700, 30 )
            self.vlist:addItem(item)
            
        end
        
    end
    
    self.vlist:setVisible( false )
    self.vlist:reload()
    
end
       
-- 测试单元列表点击
function UICmdList:OnTouchMenu( event )

    -- 点击处理
    if event.itemPos and "clicked" == event.name then
        local cmd = self.items[event.itemPos][2]
        g_event:PostEvent( E_CLIENT_SETCHATEDIT, { text = cmd } )
        self:togShow()
    end
end

-- 显示隐藏
function UICmdList:togShow()
    local show = self.vlist:isVisible()
    self.vlist:setVisible( not show )
end
   
return UICmdList
