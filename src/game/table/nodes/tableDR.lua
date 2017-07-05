-- tableDR.lua
-- 2016-02-16
-- KevinYuen
-- 麻将牌桌管理

local MJWall  = require( "kernels.mahjong.ui.wall")
local MJRiver = require( "kernels.mahjong.ui.river")
local MJHand  = require( "kernels.mahjong.ui.hand")
local MJTableDR = class(  "MJTableDR" )

-- 构造
function MJTableDR:ctor( node )

    self.node = node
    self.fly_layer = cc.Layer:create()
    self.node:addChild(self.fly_layer)
    -- 座位数据列表
    self.seats = {}
    for i = 0, TABLE_MAX_USER - 1 do
        self.seats[i] = { hand = nil, wall = nil, river = nil }     
    end

    self.node:openMouseTouch( true, self )  
    
end

-- 位置合法确认
function MJTableDR:verifySeatNo( seatNo )

    if seatNo < 0 or seatNo >= TABLE_MAX_USER then
        g_methods:error( "参数位置非法:%d", seatNo )
        return false
    end
    return true
    
end

-- 绑定牌墙
function MJTableDR:bindWall( seatNo, node, cfgs )  
    
    if  not node or false == self:verifySeatNo( seatNo ) then
        g_methods:error( "绑定牌墙失败:%d", seatNo )
        return false
    end
    
    self.seats[seatNo].wall = MJWall.new( node, seatNo, cfgs )
    
    return true
    
end

-- 绑定牌河
function MJTableDR:bindRiver( seatNo, node, args, callback )  
 
    if  not node or false == self:verifySeatNo( seatNo ) then
        g_methods:error( "绑定牌河失败:%d", seatNo )
        return false
    end

    self.seats[seatNo].river = MJRiver.new( node, seatNo, args, callback )
    
    return true
    
end

-- 绑定手牌
function MJTableDR:bindHand( seatNo, node, args, callback ) 

    if  not node or false == self:verifySeatNo( seatNo ) then
        g_methods:error( "绑定手牌失败:%d", seatNo )
        return false
    end
    
    self.seats[seatNo].hand = MJHand.new( node, seatNo, args, callback )
    
    return true
    
end

-- 获取牌墙
function MJTableDR:getWall( seatNo )

    if false == self:verifySeatNo( seatNo ) then 
        return nil
    end
    
    return self.seats[seatNo].wall
    
end

-- 获取牌河
function MJTableDR:getRiver( seatNo )

    if false == self:verifySeatNo( seatNo ) then
        return nil
    end

    return self.seats[seatNo].river
    
end

-- 获取手牌
function MJTableDR:getHand( seatNo )

    if false == self:verifySeatNo( seatNo ) then
        return nil
    end

    return self.seats[seatNo].hand
    
end

-- 全重置
function MJTableDR:resetAll()

    for i = 0, TABLE_MAX_USER - 1 do        
        self.seats[i].river:clean()
        self.seats[i].wall:clean()
        self.seats[i].hand:clean()
        self.seats[i].hand.node:setScale( 1.0 )       
        self.seats[i].river.node:setVisible( true )
        self.seats[i].wall.node:setVisible( true )
        self.fly_layer:removeAllChildren()
    end
    
end

-- 查找某个麻将
function MJTableDR:findCard( cardId )
    
    for i = 0, TABLE_MAX_USER - 1 do
        
        -- 牌河中查找
        local mjRiver = self.seats[i].river
        local idx, card = mjRiver:query( cardId, false )
        if idx and card then
            return card 
        end
        
        -- 手牌中查找
        local mjHand = self.seats[i].hand
        idx, card = mjHand:query( cardId, false )
        if idx and card then
            return card 
        end
        
    end
    
    g_methods:warn( "查找某个麻将失败,找不到:%d", cardId )
    
end

-- 手牌重置
function MJTableDR:resetHands( seatNo, cardIds, orderInc )

    if false == self:verifySeatNo( seatNo ) then
        return false
    end

    local mjHand = self:getHand( seatNo )
    if #mjHand.cards ~= #cardIds then
        g_methods:log( "手牌重置失败,重置手牌数量不一致!" )
        return false
    end
    
    mjHand:clean( true )
    for i = 1, #cardIds do
        mjHand:push( cardIds[i] )
    end

    -- 排序算法
    local sortFunc = function( cA, cB )
        if orderInc and orderInc == true then
            return cA.id < cB.id
        else
            return cA.id > cB.id
        end 
    end
    mjHand:sortBy( sortFunc )
    
    return true
    
end

-- 手牌排序(附带翻牌延迟效果)
function MJTableDR:sortHands( seatNo, orderInc, needFlip, flipSecs, callback )

    if false == self:verifySeatNo( seatNo ) then
        return false
    end
    
    -- 排序算法
    local sortFunc = function( cA, cB )
        if orderInc and orderInc == true then
            return cA.id < cB.id
        else
            return cA.id > cB.id
        end 
    end
    
    local mjHand = self:getHand( seatNo )
    if  needFlip == nil or needFlip == false then
        mjHand:sortBy( sortFunc )
    else
        g_audio:PlaySound("lipai.mp3")
        -- 如果是自己的牌,那么显示推倒的牌背效果
        local cRes
        if seatNo == 0 then
            cRes = getCardResLarge( TYPE_PAIBEI, PDIR_UP, SHOW_DAO )
        end
        
        mjHand:showBackAll( true, true, cRes )
        mjHand:sortBy( sortFunc )
        local delay = cc.DelayTime:create( flipSecs )
        local cback = cc.CallFunc:create( function( sender, args )
            args.hand:showBackAll( false, true ) 
            if args.callback then
                args.callback()
            end
        end, { hand = mjHand, callback = callback } )
        self.node:runAction( cc.Sequence:create( delay, cback ) )
    end    
    
    return true
    
end

-- 初始化牌墙
function MJTableDR:buildWall( callback, secs, raiseY )
    
    local wallDn = self:getWall( 0 )
    local wallUp = self:getWall( 1 )
    
    wallDn:clean()
    wallUp:clean()    
    
    for i = 1, WALL_COLCOUNT * 2 do
        wallUp:push( TYPE_PAIBEI, PDIR_UP )
        wallDn:push( TYPE_PAIBEI, PDIR_UP )
    end
    
    -- 需要动画
    if secs and secs > 0 then
    
        local dx, dy = wallDn.node:getPosition()
        wallDn.node:setPosition( cc.p( dx, dy - raiseY ) )
        local movet1 = cc.MoveTo:create( secs, cc.p( dx, dy ) )
        local callfu = cc.CallFunc:create( function( wall, args )
            args.slotDn:removeAllChildren()
            args.slotUp:removeAllChildren()
            if self.slotTickHandle then
                local sched = cc.Director:getInstance():getScheduler()
                sched:unscheduleScriptEntry( self.slotTickHandle )
                self.slotTickHandle = nil
            end
            args.callback() 
        end, { callback = callback, slotDn = wallDn.slotUI, slotUp = wallUp.slotUI } )
        wallDn.node:runAction( cc.Sequence:create( cc.DelayTime:create( 0.1 ), movet1, callfu ) )

        local ux, uy = wallUp.node:getPosition()
        wallUp.node:setPosition( cc.p( ux, uy - raiseY ) )
        local movet2 = cc.MoveTo:create( secs, cc.p( ux, uy ) )
        wallUp.node:runAction( cc.Sequence:create( cc.DelayTime:create( 0.1 ), movet2 ) )  
        
        -- 升降槽模拟
        if true then

            self.blackSlotDn = cc.DrawNode:create()
            wallDn.slotUI:addChild( self.blackSlotDn )
            local size = wallDn.slotUI:getContentSize()
            self.blackSlotDn.ld = cc.p( 0, size.height )
            self.blackSlotDn.rt = cc.p( size.width, size.height )
            self.blackSlotDn.step = size.height / 20
            self.blackSlotDn:drawSolidRect( self.blackSlotDn.ld, self.blackSlotDn.rt, cc.c4f( 0, 0, 0, 1) )

            self.blackSlotUp = cc.DrawNode:create()
            wallUp.slotUI:addChild( self.blackSlotUp )
            size = wallUp.slotUI:getContentSize()
            self.blackSlotUp.ld = cc.p( 0, size.height )
            self.blackSlotUp.rt = cc.p( size.width, size.height )
            self.blackSlotUp.step = size.height / 20
            self.blackSlotUp:drawSolidRect( self.blackSlotUp.ld, self.blackSlotUp.rt, cc.c4f( 0, 0, 0, 1) )
            
            local sched = cc.Director:getInstance():getScheduler()
            self.slotTickHandle = sched:scheduleScriptFunc( function() 
                self.blackSlotDn.ld.y = self.blackSlotDn.ld.y - self.blackSlotDn.step
                if self.blackSlotDn.ld.y < 0 then
                    self.blackSlotDn.ld.y = 0
                end
                self.blackSlotDn:drawSolidRect( self.blackSlotDn.ld, self.blackSlotDn.rt, cc.c4f( 0, 0, 0, 1) )
                self.blackSlotUp.ld.y = self.blackSlotUp.ld.y - self.blackSlotUp.step
                if self.blackSlotUp.ld.y < 0 then
                    self.blackSlotUp.ld.y = 0
                end
                self.blackSlotUp:drawSolidRect( self.blackSlotUp.ld, self.blackSlotUp.rt, cc.c4f( 0, 0, 0, 1) )
                if self.blackSlotDn.ld.y == 0 then
                    sched:unscheduleScriptEntry( self.slotTickHandle )
                    self.slotTickHandle = nil
                end
                end, secs / 20, false )
        end
    end  
    
end

-- 添加牌堆
function MJTableDR:pushStack( seatNo, stackType, stackIds, putHors, fadeSecs )

    if false == self:verifySeatNo( seatNo ) then
        return false
    end
    
    if #stackIds == 0 or #putHors == 0 or #stackIds ~= #putHors then
        g_methods:error( "牌堆添加失败,参数列表不符合要求!" )
        return false
    end
    
    local stackRes = {}
    for idx = 1, #stackIds do
        local id  = stackIds[idx]
        local res = getHandFallRes( seatNo, id, putHors[idx] )
        table.insert( stackRes, res )
    end
    
    return self:getHand(seatNo):pushStack( stackType, stackIds, stackRes, fadeSecs )
    
end

-- 修改牌堆
function MJTableDR:resetStackByKeyId( seatNo, stackKeyCardId, stackType, stackIds, putHors, fadeSecs )

    local mjHand = self:getHand(seatNo)
    if not mjHand then
        g_methods:error( "牌堆修改失败,无效的座位号! %d", seatNo )
        return false
    end

    if #stackIds == 0 or #putHors == 0 or #stackIds ~= #putHors then
        g_methods:error( "牌堆修改失败,参数列表不符合要求!" )
        return false
    end

    local stackRes = {}
    for idx = 1, #stackIds do
        local id  = stackIds[idx]
        local res = getHandFallRes( seatNo, id, putHors[idx] )
        table.insert( stackRes, res )
    end

    local stackIdx, stackInfo = mjHand:findStack( stackKeyCardId )
    if not stackInfo then
        g_methods:error( "牌堆修改失败,关键卡无效! %d", stackKeyCardId )
        return false
    end

    return mjHand:resetStack( stackInfo, stackType, stackIds, stackRes, fadeSecs )

end

-- 修改牌堆
function MJTableDR:resetStackByIndex( seatNo, stackIdx, stackType, stackIds, putHors, fadeSecs )

    local mjHand = self:getHand(seatNo) 
    if not mjHand then
        g_methods:error( "牌堆修改失败,无效的座位号! %d", seatNo )
        return false
    end

    if #stackIds == 0 or #putHors == 0 or #stackIds ~= #putHors then
        g_methods:error( "牌堆修改失败,参数列表不符合要求!" )
        return false
    end

    local stackRes = {}
    for idx = 1, #stackIds do
        local id  = stackIds[idx]
        local res = getHandFallRes( seatNo, id, putHors[idx] )
        table.insert( stackRes, res )
    end

    local stackInfo = mjHand:getStack( stackIdx )
    if not stackInfo then
        g_methods:error( "牌堆修改失败,牌堆索引无效! %d", stackIdx )
        return false
    end

    return mjHand:resetStack( stackInfo, stackType, stackIds, stackRes, fadeSecs )

end

-- 手牌盲打入牌河
-- handPos( 1 ~ hand.maxcols )
function MJTableDR:pushToRiverBlind( seatNo, handPos, id, putHor, callback )

    if false == self:verifySeatNo( seatNo ) then
        return false
    end

    local mjHand, mjRiver = self:getHand( seatNo ), self:getRiver( seatNo )
    if not mjHand or not mjRiver then
        g_methods:error( "指定位置不具备条件: %d", seatNo )
        return false
    end
    
    -- 根据索引获取要打出的牌
    local hand_card = mjHand:queryByPos( handPos )
    if  not hand_card then
        g_methods:error( "手牌指定牌无效: %d %d", seatNo, handPos )
        return false
    end 

    -- 先给牌河中加牌
    local river_card = mjRiver:push( id, putHor )
    river_card:setVisible( false )

    -- 计算飞行位置
    local card = hand_card.card    
    local sx, sy = card:getPosition()
    local srcPos = mjHand.node:convertToWorldSpace( cc.p( sx, sy ) )
    srcPos = self.node:convertToNodeSpace( srcPos )

    local tx, ty = river_card:getPosition()     
    local tarPos = mjRiver.node:convertToWorldSpace( cc.p( tx, ty ) )
    tarPos = self.node:convertToNodeSpace( tarPos )

    card:retain()
    card:removeFromParent( false )
    if card == mjHand:getMP() then
        mjHand.mopai = nil
    else
        table.remove( mjHand.cards, handPos )
    end

    local res = getHandRes( seatNo, id, putHor )
    card:setFrame( res )
    self.fly_layer:addChild( card )
    card:release()
    card:setPosition( srcPos )
    card:setOpacity( 180 )
    card:setLocalZOrder( 10000 )

    local scale1 = cc.ScaleTo:create( 0.1, 1.2 )
    local scale2 = cc.ScaleTo:create( 0.4, 0.8 )
    local moveTo = cc.MoveTo:create( 0.08, tarPos )
    local expon = cc.EaseExponentialIn:create( moveTo )
    local callfn = cc.CallFunc:create( function( card, args )
        local id = card.id
        card:removeFromParent()
        args.rivCard:setVisible( true ) 
        self:lockHandCardTouch(args.seatNo ,false)
        args.callback( args.seatNo, args.rivCard )
    end, { seatNo = seatNo, rivCard = river_card, hand = mjHand, callback = callback } )
    local spawn  = cc.Spawn:create( scale2, expon )
    local sequnc = cc.Sequence:create( scale1, spawn, callfn )
    
    self:lockHandCardTouch( seatNo, true )
    card:runAction( sequnc )

    return true
    
end

-- 手牌打入牌河
function MJTableDR:pushToRiver( seatNo, id, putHor, callback ) 

    if false == self:verifySeatNo( seatNo ) then
        return false
    end
    
    local mjHand, mjRiver = self:getHand( seatNo ), self:getRiver( seatNo )
    if not mjHand or not mjRiver then
        g_methods:error( "指定位置不具备条件: %d", seatNo )
        return false
    end
    
    local idx, hand_card = mjHand:query( id )
    if not idx or not hand_card then
        g_methods:error( "手牌指定牌无效: %d %d", seatNo, id )
        return false
    end 
    
    -- 先给牌河中加牌
    local river_card = mjRiver:push( id, putHor )
    river_card:setVisible( false )
         
    -- 计算飞行位置
    local card = hand_card.card    
    local sx, sy = card:getPosition()
    local srcPos = mjHand.node:convertToWorldSpace( cc.p( sx, sy ) )
    srcPos = self.node:convertToNodeSpace( srcPos )

    local tx, ty = river_card:getPosition()     
    local tarPos = mjRiver.node:convertToWorldSpace( cc.p( tx, ty ) )
    tarPos = self.node:convertToNodeSpace( tarPos )

    card:retain()
    card:removeFromParent( false )
    if card == mjHand:getMP() then
        mjHand.mopai = nil
    else
        table.remove( mjHand.cards, idx )
    end

    self.fly_layer:addChild( card )
    card:release()
    card:setPosition( srcPos )
    card:setOpacity( 180 )
    card:setLocalZOrder( 10000 )
    
    local scale1 = cc.ScaleTo:create( 0.1, 1.2 )
    local scale2 = cc.ScaleTo:create( 0.4, 0.8 )
    local moveTo = cc.MoveTo:create( 0.1, tarPos )
    local expon = cc.EaseExponentialIn:create( moveTo )
    local callfn = cc.CallFunc:create( function( card, args )
        local id = card.id
        card:removeFromParent()
        args.rivCard:setVisible( true )
        self:lockHandCardTouch(args.seatNo ,false)
        args.callback( args.seatNo, args.rivCard, args.putHor ) 
    end, { seatNo = seatNo, rivCard = river_card, hand = mjHand, putHor = putHor, callback = callback } )
    local spawn  = cc.Spawn:create( scale2, expon )
    local sequnc = cc.Sequence:create( scale1, spawn, callfn )
    self:lockHandCardTouch( seatNo, true )
    card:runAction( sequnc )
        
    return true
    
end

-- 摸牌
function MJTableDR:mpFromWall( seatNo, cId, wallNo, wallPos, callback )

    
    if  false == self:verifySeatNo( seatNo ) or 
        false == self:verifySeatNo( wallNo ) then
        g_methods:error( "摸牌失败:%d", seatNo )
        return false
    end

    local mjHand, mjWall = self:getHand( seatNo ), self:getWall( wallNo )
    if not mjHand or not mjWall then
        g_methods:error( "指定位置不具备条件: %d %d", seatNo, wallNo )
        return false
    end
    
    local cRes = getCardResSmall( TYPE_PAIBEI, PDIR_UP, SHOW_DAO )
    if seatNo == 0 then
        cRes = getCardResLarge( cId, PDIR_UP, SHOW_LI )
    end
    
    -- 从牌墙中取牌
    local rivCard = mjWall.cards[wallPos]
    if not rivCard or rivCard.valid == false or not rivCard.card then
        g_methods:error( "摸牌失败,找不到牌墙位置: %d, %d", wallNo, wallPos )
        return false
    else
        rivCard.valid = false        
    end
    
    if false == mjHand:setMP( cId ) then
        return false
    else
        mjHand:getMP():setVisible( false )
    end
        
    local card = rivCard.card    
    local sx, sy = card:getPosition()
    local srcPos = mjWall.node:convertToWorldSpace( cc.p( sx, sy ) )
    srcPos = self.node:convertToNodeSpace( srcPos )

    local tx, ty = mjHand:getMP():getPosition()     
    local tarPos = mjHand.node:convertToWorldSpace( cc.p( tx, ty ) )
    tarPos = self.node:convertToNodeSpace( tarPos )
    
    rivCard.card:retain()
    rivCard.card:removeFromParent( false )
    rivCard.card = nil
    
    self.fly_layer:addChild( card )
    card:release()
    card:setPosition( srcPos )
    card:setOpacity( 100 )
    card:setLocalZOrder( 10000 )
    
    local move1 = cc.MoveTo:create( 0.2, tarPos )
    local expon = cc.EaseExponentialIn:create( move1 )
    local calbk = cc.CallFunc:create( function( card, args )
        card:removeFromParent()
        if args.seatNo == 0 then
            self:lockHandCardTouch(args.seatNo ,false)
            args.hand:freshFocus()
        end
        local mp = args.hand:getMP()
        if mp then
            g_methods:log( "mp fly show~" )
            mp:setVisible( true ) 
        end
        args.callback( args.seatNo )
    end, { seatNo = seatNo, hand = mjHand, callback = callback } )
    
    self:lockHandCardTouch( seatNo, true )
    card:runAction( cc.Sequence:create( expon, calbk ) )
    
    return true
    
end

-- 手牌置灰
function MJTableDR:showHandGray( seatNo, enable )

    local mjHand = self:getHand(seatNo) 
    -- 手牌处理
    for i = 1, #mjHand.cards do
        local card = mjHand.cards[i]
        if enable == false then
            card.card:setColor( COLOR_NORMAL )
        else
            card.card:setColor( COLOR_DISABLED )
        end
    end
    
end

-- 手牌推倒
function MJTableDR:fallDownHand( seatNo, fall, scale )
    
    local mjHand = self:getHand( seatNo )
    if not mjHand then
        g_methods:error( "手牌推倒失败:座位无效%d", seatNo )
        return false
    end
    
    for _, card in pairs( mjHand.cards ) do
        if card and card.card then
            local res = getHandFallRes( seatNo, card.id, false )
            card.card:setFrame( res )
        end
    end
    
    if mjHand.mopai then
        local res = getHandFallRes( seatNo, mjHand.mopai.id, false )
        mjHand.mopai:setFrame( res )
    end
    
    if scale then
        mjHand.node:setScale( 1.1 )
    else
        mjHand.node:setScale( 1.0 )
    end
    
    return true
    
end

--锁定首牌
function MJTableDR:lockHandCardTouch( seatNo, enable )
	if jav_iswatcher( jav_self_uid ) then
	       self:getHand(seatNo):lockTouch( true )
	       return
	end
	local en = "false"
	
	if enable then
        en = "true"
	end
    g_methods:log(string.format("MJTableDR:lockHandCardTouch 座位：%d, 首牌是否锁定：%s",seatNo, en))
    self:getHand(seatNo):lockTouch( enable )
	
end


-- 手牌聚焦刷新
function MJTableDR:freshHandFocus( loca )

    local hand = nil
    for i = 0, TABLE_MAX_USER - 1 do
    
        local mjHand = self.seats[i].hand
        if  mjHand:isHitted( loca, true ) == true and 
            mjHand.cards and #mjHand.cards > 0 then
            hand = mjHand
            break
        end
        
    end
    
    if hand ~= self.focusHand then
    
        if self.focusHand then
            g_event:SendEvent( CTC_HAND_FOCUSCHANGED, { seatNo = self.focusHand.seat, focus = false })
        end
                
        self.focusHand = hand
        
        if self.focusHand then
            g_event:SendEvent( CTC_HAND_FOCUSCHANGED, { seatNo = self.focusHand.seat, focus = true })
        end
        
    end

end

-- 鼠标按下
function MJTableDR:onMouseTouchDown( location, args )
    
    for i = 0, TABLE_MAX_USER - 1 do        
        self.seats[i].river:onMouseTouchDown( location, args )
        self.seats[i].hand:onMouseTouchDown( location, args )        
    end
    
end

-- 鼠标弹起
function MJTableDR:onMouseTouchUp( location, args )

    for i = 0, TABLE_MAX_USER - 1 do  
        self.seats[i].river:onMouseTouchUp( location, args )
        self.seats[i].hand:onMouseTouchUp( location, args )   
    end

end

-- 鼠标滚动
function MJTableDR:onMouseTouchMove( location, args )

    -- 刷新手牌聚焦
    self:freshHandFocus( location )
    
    -- 遍历通告
    for i = 0, TABLE_MAX_USER - 1 do  
        self.seats[i].river:onMouseTouchMove( location, args )
        self.seats[i].hand:onMouseTouchMove( location, args )  
    end
    
end

-- 调试使用
function MJTableDR:getTempCard()
    
    if not self.tempCards or #self.tempCards == 0 then
        self.tempCards = {}
        for i = 1, 9 do
            local t = TYPE_WAN * 100 + i * 10
            table.insert( self.tempCards, t + 1 )
            table.insert( self.tempCards, t + 2 )
            table.insert( self.tempCards, t + 3 )
            table.insert( self.tempCards, t + 4 ) 
        end
        for i = 1, 7 do
            local t = TYPE_FENG * 100 + i * 10
            table.insert( self.tempCards, t + 1 )
            table.insert( self.tempCards, t + 2 )
            table.insert( self.tempCards, t + 3 )
            table.insert( self.tempCards, t + 4 ) 
        end
        
        self.tempCards = g_methods:RandArray( self.tempCards )
        
    end
    
    if #self.tempCards > 0 then
        local cId = self.tempCards[1]
        table.remove( self.tempCards, 1 )
        return cId
    end
    
    return nil
end


return MJTableDR
