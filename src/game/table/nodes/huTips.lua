-- huTips.lua
-- 2016-02-16
-- KevinYuen
-- 胡牌提示面板

local HuTips = class(  "HuTips" )
local MJRiver  = require( "kernels.mahjong.ui.river")

EAT_MAX_STACK = 3   -- 最大组数
EAT_MAX_CARDS = 3   -- 单组牌数

-- 构造
function HuTips:ctor( node )
    
    self.node = node
    self.nodCards = node:getChildByName( "cards" )
    self.tape = MJRiver.new( self.nodCards, 99, TIPHAND_CFG )    
    self.node:setVisible( false )
    
end

-- 显示胡牌提示面板
-- cardInfos:卡数据类表{ { id, count, points }, ... }
function HuTips:show( seatNo, cardInfos )

    g_methods:log("展示待胡牌列表")
    self.cards = cardInfos

    self.tape:clean()

    local setCard = function( card, count, points )
        
        if count== nil then
            return
        end
        
        -- 胡牌点数
        if points then
            local numFont = ccui.TextBMFont:create( tostring( points ), "fnt_hutip_point.fnt" ) 
            --local numFont = ccui.TextAtlas:create( tostring( points ), "bluenum.png", 13, 18, '0' )
            numFont:setAnchorPoint( cc.p( 0, 0 ) )
            numFont:setPosition( cc.p( card:getSize().width - 16, card:getSize().height - 10 ) ) 
            card:addChild( numFont, 3000 )
        end 
                
        -- 剩余张数
        local imgBg = display.newSprite( "#font.bg.png" )
        local cfgs = {
            text    = string.format( "剩%d张", count ),
            font    = "gfont.ttf",
            size    = 19,
            color   = cc.c3b( 255, 189, 0 )            
        }
        local txtFont = display.newTTFLabel( cfgs )
        txtFont:setPosition( imgBg:getContentSize().width / 2, 10 )
        imgBg:addChild( txtFont )
        imgBg:setPosition( card:getSize().width / 2, 10 )
        card:addChild( imgBg, 3000 )
        card:setScale( 1.0 ) 
        if count == 0 then
            card:setColor( cc.c3b( 128, 128, 128 ) )
        else
        end
        
    end
    
    self.tape.maxcols = #cardInfos
    for i = 1, #cardInfos do
        
        local info = cardInfos[i]
        local ncard = self.tape:push( info.id )
        if ncard then
            if seatNo == 0 then
                setCard( ncard, info.count, info.points  )
            else
                setCard( ncard, info.count, info.points )
            end            
        else
            g_methods:error( "显示胡牌提示面板失败!" )
            return false
        end
        
    end

    local width = TIPHAND_CFG.cdim.width * #cardInfos + TIPHAND_CFG.offset.x * ( #cardInfos - 1 )
    local size = self.node:getContentSize()
    size.width = width + 80
    self.node:setContentSize( size )  
    self.node:setPositionX( ( display.width - size.width ) / 2 )
        
    if seatNo == 0 then
        self.node:setPositionY( 130 )
    else
        self.node:setPositionY( display.height - 130 - size.height ) 
    end
        
    self.node:setVisible( true )

end

-- 关闭
function HuTips:close()      
    self.node:setVisible( false )    
end

return HuTips
