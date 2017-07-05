-- card.lua
-- 2016-02-16
-- KevinYuen
-- 麻将牌定义

-- 麻将单牌
local MJCard = class( "MJCard", function() return display.newNode() end )

-- 构造
function MJCard:ctor( id, frameRes, backRes )

    self.id             = id
    self.frameRes       = frameRes 
    self.isBackShow     = false
    self.beCPG          = false 
    self.isBlink        = false
    self.bgSpt          = display.newSprite( frameRes )     -- 牌面精灵
    self.bgSpt:setAnchorPoint( cc.p( 0, 0 ) )
    self.bgSpt:getTexture():setAntiAliasTexParameters()
    self:addChild( self.bgSpt, 10 ) 
    self.rtSpt          = nil                               -- 右上数字
    self.rdSpt          = nil                               -- 右下数字
    self.fgSpt          = nil                               -- 关注标记
    self.mkSpt          = nil                               -- 模板标记
    self:setCascadeColorEnabled( true )
    self:setCascadeOpacityEnabled( true )
    
    -- 组件层次定义
    self.ZORDER_BG      = 10
    self.ZORDER_MASK    = 20
    self.ZORDER_NUM     = 30
    self.ZORDER_STONE   = 40
    
end

-- 获取编号
function MJCard:getID()
    
    return self.id
    
end

-- 获取尺寸
function MJCard:getSize()
    
    local sze = self.bgSpt:getContentSize()
    return sze;
    
end

-- 设置吃碰杠标记
-- 牌透明化处理
function MJCard:setBeCPG( enable )

    self.beCPG = enable
    if enable == true then
        self:setOpacity( 100 )
    else
        self:setOpacity( 255 )
    end

end

-- 是否具备吃碰杠标记
function MJCard:isBeCPG()
    
    return self.beCPG
    
end

-- 设置牌面
function MJCard:setFrame( frmRes )
    
    self.frameRes = frmRes
    if self.isBackShow == false then

        -- first char is #
        if string.byte(frmRes) == 35 then
            frmRes = string.sub( frmRes, 2 )
        end
        
        local sptFrame = display.newSpriteFrame( frmRes )
        if not sptFrame then
            g_methods:error( "牌背切换显示失败,获取资源失败! %s", frmRes )
            return false
        end

        self.bgSpt:setSpriteFrame( sptFrame ) 
        
    end
    
    return true
    
end

-- 是否显示牌背中
function MJCard:isShowBack()
    return self.isBackShow
end

-- 显示牌背
function MJCard:showBack( show, specailBGRes )
    
    if  self.isBackShow == show then
        return true
    end
    
    local frmRes = self.frameRes
    if show == true then
        frmRes = specailBGRes or self.backRes
    end
    
    if frmRes == nil or frmRes == "" then
        g_methods:error( "牌背切换显示失败,参数不足!" )
        return false
    end
    
    -- first char is #
    if string.byte(frmRes) == 35 then
        frmRes = string.sub( frmRes, 2 )
    end
    
    local sptFrame = display.newSpriteFrame( frmRes )
    if not sptFrame then
        g_methods:error( "牌背切换显示失败,获取资源失败! %s", frmRes )
        return false
    end
    
    self.isBackShow = show
    self.bgSpt:setSpriteFrame( sptFrame ) 
 
    return true
    
end

-- 设置闪烁
function MJCard:setBlink( enable )

    if self.isBlink ~= enable then
        
        self.isBlink = enable
        if enable == true then 
            local fadout = cc.FadeOut:create( 0.5 )
            local fadein = cc.FadeIn:create( 0.4 )
            local sequce = cc.Sequence:create( fadout, fadein )
            self.actBlink = self:runAction( cc.RepeatForever:create( sequce ) )
        else
            self:stopAction( self.actBlink )
            self.actBlink = nil             
            self:setBeCPG( self.beCPG )
        end
        
    end
    
end

-- 是否正在闪烁
function MJCard:isBlink()
    
    return self.isBlink
    
end

-- 重建右上标记
function MJCard:buildRTFlag( numPngRes, numSize, offset )

    -- 存在先删除
    if  self.rtSpt ~= nil then
        self.rtSpt:removeFromParent()
        self.rtSpt = nil
    end

    -- 重建
    self.rtSpt = ccui.TextAtlas:create( "0", numPngRes, numSize.width, numSize.height, '0' )
    self.rtSpt:setAnchorPoint( cc.p( 0, 0 ) )
    self:addChild( self.rtSpt, self.ZORDER_NUM ) 

    local size = self:getSize()
    self.rtSpt:setPosition( cc.p( size.width - offset.x, size.height - offset.y ) ) 

end

-- 设置右上数字
function MJCard:setRTNum( num, showZero )

    if  self.rtSpt == nil then
        g_methods:error( "要设置右上数字,需要先重建标记!" )
        return
    end
    
    -- 为0不显示
    if  num == 0 and ( showZero or showZero == false ) then
        self.rtSpt:setVisible( false )
    else
        self.rtSpt:setString( num )
        self.rtSpt:setVisible( true )
    end
        
end

-- 重建右下标记
function MJCard:buildRDFlag( numPngRes, numSize, offset )

    -- 存在先删除
    if  self.rdSpt ~= nil then
        self.rdSpt:removeFromParent()
        self.rdSpt = nil
    end
    
    -- 重建
    self.rdSpt = ccui.TextAtlas:create( "0", numPngRes, numSize.width, numSize.height, '0' )
    self.rdSpt:setAnchorPoint( cc.p( 1, 1 ) )
    self:addChild( self.rdSpt, self.ZORDER_NUM )

    local size = self:getSize()
    self.rdSpt:setPosition( cc.p( size.width - offset.x, size.height - offset.y ) ) 
    
end

-- 设置右下数字
function MJCard:setRDNum( num, showZero )

    if  self.rdSpt == nil then
        g_methods:error( "要设置右下数字,需要先重建标记!" )
        return
    end

    -- 为0不显示
    if  num == 0 and ( showZero or showZero == false ) then
        self.rdSpt:setVisible( false )
    else
        self.rdSpt:setString( num )
        self.rdSpt:setVisible( true )
    end
    
end

-- 设置当前关注标记
function MJCard:setFingerMark( show, aniRes, offset )
    
    if self.fgSpt ~= nil then
        self.fgSpt:removeFromParent()
        self.fgSpt = nil
    end
    
    if show == true and aniRes ~= nil and aniRes ~= "" then
        local ani = g_library:CreateAnimation( aniRes )
        if not ani then
            g_methods:error( "设置麻将标记动画失败,资源无效:%s", aniRes )
            return false
        else 
            self.fgSpt = display.newSprite()
            self:addChild( self.fgSpt, self.ZORDER_STONE )
            self.fgSpt:playAnimationForever( ani )
            self.fgSpt:setPosition( offset )
            self.fgSpt:getTexture():setAntiAliasTexParameters()
        end
    end
    
    return true
    
end

-- 设置模板
function MJCard:showMask( show, maskRes, needFade )

    -- 存在先删除
    if  self.mkSpt ~= nil then
        self.mkSpt:removeFromParent()
        self.mkSpt = nil
    end
    
    if show == true then
    
        self.mkSpt = display.newSprite( maskRes )
        self.mkSpt:setAnchorPoint( cc.p( 0, 0 ) )
        self.mkSpt:getTexture():setAntiAliasTexParameters()
        self:addChild( self.mkSpt, self.ZORDER_MASK )
        
        if needFade and needFade == true then
            local fadout = cc.FadeOut:create( 0.5 )
            local fadein = cc.FadeIn:create( 0.4 )
            local sequce = cc.Sequence:create( fadout, fadein )
            self.mkSpt:runAction( cc.RepeatForever:create( sequce ) )
        end
    end
    
end

-- 碰撞检测
function MJCard:isHitted( x, y )
    
    local bbox = self.bgSpt:getBoundingBox()
    return cc.rectContainsPoint( bbox, cc.p( x, y ) )
    
end

return MJCard