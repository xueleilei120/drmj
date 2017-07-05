-- river.lua
-- 2016-02-16
-- KevinYuen
-- 牌河定义

-- 牌河
local tcard = import( ".card" )
local MJRiver = class( "MJRiver" )

-- 构造
function MJRiver:ctor( node, seatNo, args, callback )

    self.node   = node
    self.seat   = seatNo
    self.dir    = args.dir or SCHEME_LEFT2RIGHT
    self.cdim   = args.cdim or cc.size( 48, 72 )
    self.offset = args.offset or cc.p( 0, 0 )
    self.cols   = args.cols or 1 
    self.callbk = callback
    self.cards  = {}
    self.stpos  = cc.p( 0, 0 )
    self.ztrack = 0
    self.zstep  = 0
    self.hoverd = 0

    self:calSchemePos()
    
end

-- 添加
--      id:         麻将编号
--      putHor:     是否横放
--      fromPos:    动态加入偏移量
--      secs:       移动耗时
--      useFade:    是否渐变展示
function MJRiver:push( id, putHor, fromPos, secs, useFade )

    local frameRes = getRiverRes( self.seat, id, putHor )
    local backRes  = getRiverBackRes( self.seat, putHor )
    local card = tcard.new( id, frameRes, backRes )
    if not card then
        g_methods:error( "创建麻将失败! %d  %s", id, frameRes )
        return nil
    end

    local info = { id = id, valid = true, card = card, size = card:getSize() }
    table.insert( self.cards, info ) 

    self.ztrack = self.ztrack + self.zstep
    self.node:addChild( card, self.ztrack )

    local col = math.floor( ( #self.cards - 1 ) % self.cols ) + 1
    local row = math.floor( ( #self.cards - 1 ) / self.cols )
    
    local dir = 1
    if self.dir == SCHEME_RIGHT2LEFT then
        dir = -1
    end
    
    -- 计算横向偏移
    local x = self.stpos.x
    local from = row * self.cols + 1
    if from < #self.cards then
        for i = from, #self.cards - 1 do
            local sz = self.cards[i].size
            x = x + ( self.offset.x + sz.width ) * dir
        end
    end
    
    if self.dir == SCHEME_RIGHT2LEFT then
        x = x - card:getSize().width 
    end    
    
    local newpos = cc.p( x, 0 )
    newpos.y = self.stpos.y + self.delta.y * row    

    if fromPos then

        card:setPosition( fromPos )

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
function MJRiver:pop( id, toPos, secs, useFade  ) 

    local idx, card = self:query( id )
    if idx ~= 0 and card then
        g_methods:error( "删除牌河牌失败,无效的位置:%d", id )
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

        card.card:runAction( cc.Sequence:create( act, cc.RemoveSelf:create() ) )

    else

        card.card:runAction( cc.RemoveSelf:create() )

    end    

    card.card = nil
    return true

end

-- 清空
function MJRiver:clean()

    self.node:removeAllChildren()
    self.cards  = {}
    self.hoverd = 0
    self:calSchemePos()

end

-- 计算起始位相关信息
function MJRiver:calSchemePos()

    if self.dir == SCHEME_RIGHT2LEFT then

        local s = self.node:getContentSize() 
        self.stpos = cc.p( s.width, 0 )
        self.delta = cc.p( -( self.cdim.width + self.offset.x ), ( self.cdim.height + self.offset.y ) )

        self.ztrack = 1000
        self.zstep  = -1
        
    else

        local s = self.node:getContentSize() 
        self.stpos = cc.p( 0, s.height - self.cdim.height ) 
        self.delta = cc.p( ( self.cdim.width + self.offset.x ), -( self.cdim.height + self.offset.y ) )

        self.ztrack = 0
        self.zstep  = 0
        
    end

end

-- 获取麻将信息
-- 参数:  Id麻将唯一编号
-- 返回值:实时位置,麻将数据 
function MJRiver:query( id )

    for idx, cd in pairs( self.cards ) do
        if cd and cd.id == id then
            return idx, cd
        end
    end
    
end

-- 碰撞检测
function MJRiver:isHitted( localPos ) 

    return self.node:hitTest( localPos )
    
end

-- 焦距切换
function MJRiver:setFocus( id )

    if self.hoverd == id then
        return
    end

    if self.callbk and self.hoverd ~= 0 then
        self.callbk( self, "unfocus", self.hoverd )
    end

    self.hoverd = id

    if self.callbk and self.hoverd ~= 0 then
        self.callbk( self, "focus", self.hoverd )
    end
    
end

-- 鼠标按下事件
function MJRiver:onMouseTouchDown( localPos, buttons )
end

-- 鼠标弹起事件
function MJRiver:onMouseTouchUp( localPos, buttons )
end

-- 鼠标移动事件
function MJRiver:onMouseTouchMove( localPos, buttons )
    
    if  self:isHitted( localPos ) == false or 
        #self.cards == 0 then 
        self:setFocus( 0 )
        return
    end
    
    if self.dir == SCHEME_RIGHT2LEFT then  
      
        for i = 1, #self.cards do
            local cd = self.cards[i]
            if cd.card and cd.card:hitTest( localPos, true ) then
                self:setFocus( cd.id )
                return
            end
        end
        
    else

        for i = #self.cards, 1, -1 do
            local cd = self.cards[i]
            if cd.card and cd.card:hitTest( localPos, true ) then
                self:setFocus( cd.id )
                return
            end
        end
        
    end

    self:setFocus( 0 )
    
end


return MJRiver