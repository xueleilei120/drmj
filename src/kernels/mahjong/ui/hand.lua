-- hand.lua
-- 1016-02-16
-- KevinYuen
-- 手牌定义

-- 手牌
local tcard = import( ".card" )
local MJHand = class( "MJHand" )

-- 牌堆类型
STACK_LCHI   = "lchi"    -- 左吃
STACK_MCHI   = "mchi"    -- 中吃
STACK_RCHI   = "rchi"    -- 右吃
STACK_GANG   = "gang"    -- 杠
STACK_LPEN   = "lpen"    -- 左碰
STACK_MPEN   = "mpen"    -- 中碰
STACK_RPEN   = "rpen"    -- 右碰

-- 构造
function MJHand:ctor( node, seatNo, args, callback )

    self.node           = node
    self.seat           = seatNo
    self.dir            = args.dir or SCHEME_LEFT2RIGHT
    self.cdim           = args.cdim or cc.size( 48, 72 )
    self.offset         = args.offset or cc.p( 0, 0 )
    self.maxcols        = args.cols or 13
    self.callbk         = callback
    self.mopai          = nil
    self.cards          = {}
    self.stacks         = {}
    self.stack_space    = 10
    self.mopai_space    = 15
    self.stpos          = cc.p( 0, 0 )
    self.cdpos          = cc.p( 0, 0 )
    self.mppos          = cc.p( 0, 0 )
    self.hoverd         = 0
    self.stackY         = -20
    self.touchLock      = 0

    self:calSchemePos()
    
end

-- 添加
function MJHand:push( id, offset, secs, useFade )

    if #self.cards == self.maxcols then
        g_methods:error( "手牌只允许有%d张牌,多牌错误!", self.maxcols ) 
        return
    end

    local frameRes = getHandRes( self.seat, id, false )
    local backRes  = getHandBackRes( self.seat, false )
    local card = tcard.new( id, frameRes, backRes )
    if not card then
        g_methods:error( "创建麻将失败! %d  %s", id, frameRes )
        return
    end

    local info = { id = id, valid = true, card = card, size = card:getSize() }
    table.insert( self.cards, info ) 

    self.node:addChild( card )

    -- 计算横向偏移
    local newpos = cc.p( 0, 0 )
    if self.dir == SCHEME_RIGHT2LEFT then
        newpos.x = self.cdpos.x - ( #self.cards - 1 ) * ( self.cdim.width + self.offset.x ) 
    else
        newpos.x = self.cdpos.x + ( #self.cards - 1 ) * self.cdim.width + ( #self.cards - 2 ) * self.offset.x
    end
         
    if offset then

        card:setPosition( cc.p( newpos.x + offset.x, newpos.y + offset.y ) )

        local act
        secs = secs or 1    
        if useFade and useFade == true then

            local mov = cc.MoveTo:create( secs, newpos )
            local fad = cc.FadeIn:create( secs )
            act = cc.Spawn:create( mov, fad )
            card:setOpacity( 0 )

        else

            act = cc.MoveTo:create( secs, newpos ); 

        end

        card:runAction( act )

    else

        card:setPosition( newpos )

    end

    return card
    
end

-- 删除
function MJHand:pop( id, offset, secs, useFade  ) 

    local idx, card = self:query( id )
    if not idx or not card then
        g_methods:error( "删除手牌牌失败,无效的麻将:%d", id )
        return false
    end

    if offset then

        local x, y = card.card:getPosition()
        
        local act
        secs = secs or 1
        if useFade and useFade == true then

            local mov = cc.MoveTo:create( secs, cc.p( x + offset.x, y + offset.y ) )
            local fad = cc.FadeOut:create( secs )
            act = cc.Spawn:create( mov, fad )

        else

            act = cc.MoveTo:create( secs, cc.p( x + offset.x, y + offset.y ) );

        end    

        card.card:runAction( cc.Sequence:create( act, cc.RemoveSelf:create() ) )

    else

        card.card:runAction( cc.RemoveSelf:create() )

    end    

    if self.mopai and self.mopai.id == id then
        self.mopai = nil
    else
        table.remove( self.cards, idx )
    end
    return true

end

-- 排序刷新
function MJHand:sortBy( func )
    
    table.sort( self.cards, func )
    self:updateHands( false )
    
end

-- 牌背展示
function MJHand:showBackAll( show, incMP, specailBGRes )
    
    if incMP and incMP == true and self.mopai then
        self.mopai:showBack( show, specailBGRes )
    end
    
    if #self.cards > 0 then
        for i = 1, #self.cards do
            self.cards[i].card:showBack( show, specailBGRes )
        end
    end
    
end

-- 手牌锁定操作/解锁操作
function MJHand:lockTouch( lock )
    
    if lock == nil or lock == true then
        self.touchLock = self.touchLock + 1
        g_methods:debug( "手牌[%d]锁定+1次!", self.seat )
    else
        self.touchLock = self.touchLock - 1
        g_methods:debug( "手牌[%d]锁定-1次!", self.seat )
        if self.touchLock < 0 then
            g_methods:warn( "手牌解锁错误,解锁次数过多!" )
            self.touchLock = 0 
        end
    end
    
    self:updateHands( false )
    self:updateMP( false )

end

-- 查找指定牌所在牌组
function MJHand:findStack( cardid )

    for idx, stack in pairs( self.stacks ) do
        for _, id in pairs( stack.cards ) do
            if id == cardid then
                return idx, stack 
            end
        end
    end
    
    g_methods:error( "查找牌组失败! %d  %d", self.seat, cardid )
    return nil

end

-- 获取牌组
function MJHand:getStack( idx )

    local stack = self.stacks[idx]
    if not stack then
        g_methods:error( "获取牌组失败! %d  %d", self.seat, idx )
    end
    return stack
    
end

-- 创建牌堆
function MJHand:pushStack( stackType, stackCards, stackReses, fadeSecs )

    local stack = { stack = cc.Node:create(), width = 0, cards = {} }
    self.node:addChild( stack.stack )
    table.insert( self.stacks, stack )
    return self:resetStack( stack, stackType, stackCards, stackReses, fadeSecs )

end

-- 牌组重置
function MJHand:resetStack( stackInfo, stackType, stackCards, stackReses, fadeSecs )

    if stackType == STACK_GANG then
        if #stackCards ~= 4 or #stackReses ~= 4 then
            g_methods:error( "牌堆创建错误,杠牌需要四张牌!" )
            return false
        end
    else
        if #stackCards ~= 3 or #stackReses ~= 3 then
            g_methods:error( "牌堆创建错误,碰牌需要三张牌!" )
            return false
        end
    end

    stackInfo.stype = stackType
    stackInfo.stack:removeAllChildren()
    local width = 0
    for i = 1, #stackCards do

        local id = stackCards[i]
        local res = stackReses[i]

        local card = tcard.new( id, res )
        if not card then
            g_methods:error( "创建牌堆麻将失败! %d  %s", id, res )
            return false
        end

        if stackType == STACK_GANG and i == 3 then
            card:setPosition( cc.p( width, -self.stackY ) )
        else
            card:setPosition( cc.p( width, 0 ) )
        end

        stackInfo.stack:addChild( card )

        if stackType == STACK_GANG and i == 2 then
        -- 
        else
            width = width + card:getSize().width + self.offset.x 
        end

    end

    stackInfo.width = width
    stackInfo.cards = stackCards
    self:forceUpdate()

    if fadeSecs and fadeSecs > 0 then
    
        stackInfo.stack:setCascadeOpacityEnabled( true )
        stackInfo.stack:setOpacity( 0 )
        local delay = cc.DelayTime:create( 0.3 )
        local fadin = cc.FadeIn:create( fadeSecs )
        stackInfo.stack:runAction( cc.Sequence:create( delay, fadin ) )
        
        local stackEffect = g_library:CreateAnimation( "ani.stackShow" )
        if stackEffect then
            local effc = display.newSprite()
            self.node:addChild( effc )
            local posx, posy = stackInfo.stack:getPosition()
            local size = stackInfo.stack:getCascadeBoundingBox()
            effc:setPosition( cc.p( posx + size.width / 2, posy + size.height / 2 ) )
            effc:playAnimationOnce( stackEffect, false, function(sender, args )
                sender:runAction( cc.RemoveSelf:create() )
            end, 0 )  
        end
    end

    return true
    
end 

-- 获取摸牌
function MJHand:getMP()

    return self.mopai
 
end

-- 设定摸牌
function MJHand:setMP( id, offset, secs, useFade  ) 

    --g_methods:debug( "设置摸牌:%d, %d", self.seat, id ) 
    
    if self.mopai then
        g_methods:error( "当前存在摸牌,重复设定非法!" )
        return false
    end
    
    self:calSchemePos()

    local frameRes = getHandRes( self.seat, id, false )
    local backRes = getHandBackRes( self.seat, flase )
    self.mopai = tcard.new( id, frameRes, backRes )
    if not self.mopai then
        g_methods:error( "创建摸牌失败! %d  %s", id, frameRes )
        return false
    end
    self.node:addChild( self.mopai )
    
    if offset then

        self.mopai:setPosition( cc.p( self.mppos.x + offset.x, self.mppos.y + offset.y ) )

        local act
        secs = secs or 1    
        if useFade and useFade == true then

            local mov = cc.MoveTo:create( secs, self.mppos )
            local fad = cc.FadeIn:create( secs )
            act = cc.Spawn:create( mov, fad )
            self.mopai:setOpacity( 0 )

        else

            act = cc.MoveTo:create( secs, self.mppos );

        end

        self.mopai:runAction( act )

    else

        self.mopai:setPosition( self.mppos )

    end
    
    return true
    
end

-- 删除摸牌
function MJHand:delMP( toPos, secs, useFade  ) 

    if not self.mopai then
        g_methods:error( "删除摸牌失败,当前没有摸牌!" )
        return false
    end
    
    if toPos then

        local act
        secs = secs or 1
        if useFade and useFade == true then

            local mov = cc.MoveTo:create( secs, toPos )
            local fad = cc.FadeOut:create( secs )
            act = cc.Spawn:create( mov, fad )

        else

            act = cc.MoveTo:create( secs, toPos );

        end    

        self.mopai:runAction( cc.Sequence:create( act, cc.RemoveSelf:create() ) )

    else

        self.mopai:runAction( cc.RemoveSelf:create() )

    end    

    self.mopai = nil
    return true

end

-- 清空
function MJHand:clean( justHands )

    if justHands and justHands == true then
        if self.mopai then
            self.mopai:removeFromParent()
        end
    
        for i = 1, #self.cards do
            local cd = self.cards[i]
            if cd and cd.card then
                cd.card:removeFromParent()
            end
        end
        self.cards = {}
         self.mopai = nil
    else    
        self.node:removeAllChildren()
        self.cards  = {}
        self.stacks = {}
        self.mopai = nil
    end
    
    self.hoverd = 0
    self:forceUpdate()
    
end

-- 计算起始位相关信息
function MJHand:calSchemePos()

    -- 计算最小宽度需求
    local min_width = self.maxcols * self.cdim.width + ( self.maxcols - 1 ) * self.offset.x
    min_width = min_width + self.mopai_space + self.cdim.width 

    -- 计算全宽度
    local real_width, stack_width, hand_width = 0, 0, 0
    
    -- 计算牌堆的宽度
    if #self.stacks > 0 then        
        for i = 1, #self.stacks do
            stack_width = stack_width + self.stacks[i].width + self.stack_space
        end
        real_width = real_width + stack_width
    end
    
    -- 计算的手牌宽度
    if #self.cards > 0 then
        hand_width = #self.cards * self.cdim.width + ( #self.cards - 1 ) * self.offset.x
        real_width = real_width + hand_width
    end
    
    -- 计算摸牌宽度
    if true then
        real_width = real_width + self.mopai_space + self.cdim.width 
    end

    local width = min_width
    if  width < real_width then 
        width = real_width
    end

    if self.dir == SCHEME_RIGHT2LEFT then

        local startx = ( self.node:getContentSize().width - width ) / 2 + width
        self.stpos = cc.p( startx , 0 )
        self.cdpos = cc.p( startx - stack_width - self.cdim.width, 0 ) 
        self.mppos = cc.p( startx - stack_width - hand_width - self.mopai_space - self.cdim.width, 0 )

    else

        local startx = ( self.node:getContentSize().width - width ) / 2
        self.stpos = cc.p( startx , 0 )
        self.cdpos = cc.p( startx + stack_width, 0 )
        self.mppos = cc.p( startx + stack_width + hand_width + self.mopai_space, 0 )

    end

end

-- 获取麻将信息
-- 参数:    Id麻将唯一编号
-- 返回值:  实时位置,麻将数据 
-- Note:    如果是摸牌 只有数据 位置为0
function MJHand:query( id, needWarn )
    
    -- 摸牌查询
    if self.mopai and self.mopai.id == id then
        return 0, { card = self.mopai }
    end
    
    -- 手牌查询
    for idx, cd in pairs( self.cards ) do
        if cd and cd.id == id then
            return idx, cd
        end
    end 

    if needWarn == nil or needWarn == true then
        g_methods:warn( "找不到指定的牌:%d", id )
    end
    
end

-- 获取麻将信息
-- 参数:    pos所在索引位置
-- 返回值:  实时位置,麻将数据 
-- Note:    如果是摸牌 只有数据 位置为0
function MJHand:queryByPos( pos )
    
    -- 摸牌返回
    if pos <= 0 then
        return { card = self.mopai }
    end
    
    -- 手牌返回
    if pos >= 1 and pos <= #self.cards then
        return self.cards[pos]
    end

    g_methods:warn( "找不到指定位置的牌:%d", pos )
    
end

-- 强制刷新牌堆区
function MJHand:updateStacks( needCalScheme )

    if #self.stacks == 0 then
        return
    end
    
    if needCalScheme and needCalScheme == true then
        self:calSchemePos()
    end

    if #self.stacks > 0 then

        local startx = self.stpos.x

        for i = 1, #self.stacks do

            local stk = self.stacks[i] 
            if  self.dir == SCHEME_RIGHT2LEFT then
                startx = startx - stk.width
                stk.stack:setPosition( cc.p( startx, 0 ) )
                startx = startx - self.stack_space 
            else
                stk.stack:setPosition( cc.p( startx, 0 ) )
                startx = startx + stk.width + self.stack_space
            end

        end
    end
    
end

-- 强制刷新手牌区
function MJHand:updateHands( needCalScheme )

    if #self.cards == 0 then
        return
    end

    if needCalScheme and needCalScheme == true then
        self:calSchemePos()
    end

    if  self.dir == SCHEME_RIGHT2LEFT then
        for i = 1, #self.cards do
            local cd = self.cards[i]        
            local width = ( i - 1 ) * ( self.cdim.width + self.offset.x )
            cd.card:setPosition( cc.p( self.cdpos.x - width, 0 ) )
        end
    else
        for i = 1, #self.cards do
            local cd = self.cards[i]        
            local width = ( i - 1 ) * self.cdim.width + ( i - 2 ) * self.offset.x
            cd.card:setPosition( cc.p( self.cdpos.x + width, 0 )  )
        end
    end      

end

-- 强制刷新摸牌区
function MJHand:updateMP( needCalScheme )

    if not self.mopai then
        return
    end

    if needCalScheme and needCalScheme == true then
        self:calSchemePos()
    end

    self.mopai:setPosition( cc.p( self.mppos.x, 0 ) )
    
end

-- 强制刷新
function MJHand:forceUpdate()

    -- 位置重计算    
    self:calSchemePos()

    -- 牌堆刷新
    self:updateStacks( false )
        
    -- 手牌刷新
    self:updateHands( false )

    -- 摸牌刷新
    self:updateMP( false )

end

-- 碰撞检测
function MJHand:isHitted( localPos, accurate ) 

    if not self.node then
        return false
    end
    
    local ret = self.node:hitTest( localPos )

    -- 精确检查
    if ret and accurate then

        for _, cd in pairs( self.stacks ) do            
            if cd.stack and cd.stack:hitTest( localPos, true ) then                
                return true
            end
        end

        for _, cd in pairs( self.cards ) do
            if cd.card and cd.card:hitTest( localPos, true ) then                
                return true
            end
        end  

        if self.mopai and self.mopai:hitTest( localPos, true ) then                
            return true
        end
              
        return false
            
    end    

    return ret

end

-- 聚焦刷新
function MJHand:freshFocus()

    self:onMouseTouchMove( self.lastPos )
    
end

-- 焦距切换
function MJHand:setFocus( Id, notify )

    if self.hoverd == Id then
        return
    end

    if self.touchLock == 0 and notify and self.callbk and self.hoverd ~= 0 then
        self.callbk( self, "unfocus", self.hoverd )
    end

    self.hoverd = Id

    if self.touchLock == 0 and notify and self.callbk and self.hoverd ~= 0 then
        self.callbk( self, "focus", self.hoverd )
    end

end

-- 刷新聚焦
function MJHand:_updateHoverd( localPos, notify )

    if not localPos then
        return
    end
    
    self.lastPos = localPos

    if  self:isHitted( localPos ) == false or 
        #self.cards == 0 then 
        self:setFocus( 0, notify )
        return
    end

    -- 摸牌碰撞
    if self.mopai and self.mopai:hitTestHor( localPos, true ) then 
        self:setFocus( self.mopai.id, notify )
        return
    end

    if self.dir == SCHEME_RIGHT2LEFT then  

        for i = 1, #self.cards do
            local cd = self.cards[i]
            if cd.card and cd.card:hitTestHor( localPos, true ) then
                self:setFocus( cd.id, notify )
                return
            end
        end

    else

        for i = #self.cards, 1, -1 do
            local cd = self.cards[i]
            if cd.card and cd.card:hitTestHor( localPos, true ) then
                self:setFocus( cd.id, notify )
                return 
            end
        end

    end

    self:setFocus( 0, notify )
    
end

-- 鼠标按下事件
function MJHand:onMouseTouchDown( localPos, buttons )

    self:_updateHoverd( localPos, false )
    
    if self.touchLock == 0 and self.callbk and self.hoverd ~= 0 then
        self.callbk( self, "press", self.hoverd )
    end
end

-- 鼠标弹起事件
function MJHand:onMouseTouchUp( localPos, buttons )

    self:_updateHoverd( localPos, false )
    
    if self.touchLock == 0 and self.callbk and self.hoverd ~= 0 then
        self.callbk( self, "click", self.hoverd )
    end
    
end

-- 鼠标事件
function MJHand:onMouseTouchMove( localPos, buttons )

    self:_updateHoverd( localPos, true )
    
end


return MJHand