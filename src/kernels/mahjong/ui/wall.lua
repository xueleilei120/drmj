-- wall.lua
-- 2016-02-16
-- KevinYuen
-- 牌墙定义

-- 牌墙
local tcard = import( ".card" )
local MJWall = class( "MJWall" )

-- 构造
function MJWall:ctor( node, seatNo, args )

    self.node   = node
    self.seat   = seatNo
    self.dir    = args.dir or SCHEME_LEFT2RIGHT
    self.cdim   = args.cdim or cc.size( 48, 72 )
    self.offset = args.offset or cc.p( 0, 0 )
    self.cols   = args.cols or 1 
    self.cards  = {}
    self.stpos  = cc.p( 0, 0 )

    self:calSchemePos()
    
end

-- 添加
--      id:         麻将编号
--      cardDir:    麻将朝向
--      offset:     动态加入偏移量
--      secs:       移动耗时
--      useFade:    是否渐变展示
function MJWall:push( id, cardDir, offset, secs, useFade )
	
    if #self.cards >= self.cols * 2 then
	   g_methods:error( "添加麻将失败,牌墙已经满了!" )
	   return -1
	end
	
	local frameRes = getCardResSmall( TYPE_PAIBEI, cardDir, SHOW_DAO )
	local card = tcard.new( id, frameRes )
	if not card then
	   g_methods:error( "创建麻将失败! %d  %s", id, frameRes )
	   return -1
	end
	
	table.insert( self.cards, { valid = true, card = card } )
		
	self.node:addChild( card )
	
	local col = math.floor( ( #self.cards - 1 ) / 2 )
    local idn = ( #self.cards % 2 ) == 1
    
	local newpos = cc.p( 0, 0 )
    newpos.x = self.stpos.x + self.delta.x * col
    newpos.y = self.stpos.y
	if idn == false then
        newpos.y = self.stpos.y + self.delta.y 
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
    
end

-- 删除
function MJWall:pop( pos, offset, secs, useFade  ) 

    local info = self.cards[pos]
    if not info then
        g_methods:error( "删除牌墙牌失败,无效的位置:%d", pos )
        return false
    end
    
    if info.valid == false or  not info.card then
        g_methods:error( "删除牌墙牌失败,该位置是空的:%d", pos )
        return false
    end 

    info.valid = false
    if offset then
    
        local nowPosx, nowPosy = info.card:getPosition()
     
        local act
        secs = secs or 1
        if useFade and useFade == true then

            local mov = cc.MoveTo:create( secs, cc.p( nowPosx + offset.x, nowPosy + offset.y ) )
            local fad = cc.FadeOut:create( secs )
            act = cc.Spawn:create( mov, fad )
        
        else
            
            act = cc.MoveTo:create( secs, cc.p( nowPosx + offset.x, nowPosy + offset.y ) );
            
        end    

        info.card:setLocalZOrder( 1000 )
        info.card:runAction( cc.Sequence:create( act, cc.RemoveSelf:create() ) )
        
    else

        info.card:runAction( cc.RemoveSelf:create() )
        
    end    
    
    info.card = nil
    return true
    
end

-- 删除最前一个有效牌
function MJWall:popFront( offset, sec, useFade ) 

    for i = 1, #self.cards do
        local cd = self.cards[i]
        if cd and cd.card then
            return self:pop( i, offset, sec, useFade )
        end
    end

    return false

end

-- 删除最后一个有效牌
function MJWall:popBack( offset, sec, useFade )

    for i = #self.cards, 1, -1 do
        local cd = self.cards[i]
        if cd and cd.card then
            return self:pop( i, offset, sec, useFade )
        end
    end
    
    return false
    
end

-- 清空
function MJWall:clean()

    self.node:removeAllChildren()
    self.cards  = {}

end

-- 计算起始位相关信息
function MJWall:calSchemePos()
    
    if self.dir == SCHEME_RIGHT2LEFT then

        local s = self.node:getContentSize() 
        self.stpos = cc.p( s.width - self.cdim.width, 0 )
        self.delta = cc.p( -( self.cdim.width + self.offset.x ), self.offset.y )
         
    else
    
        self.stpos = cc.p( 0, 0 )
        self.delta = cc.p( ( self.cdim.width + self.offset.x ), self.offset.y )
    end

end

return MJWall