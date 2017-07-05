-- seat.lua
-- 2016-03-02
-- KevinYuen
-- 达人麻将座位

local DRSeat = class( "DRSeat" )

-- 构造
function DRSeat:ctor( seatNo )

    self.uid            = 0
    self.seatNo         = seatNo
    
    self:reset() 
    
end

-- 重置
function DRSeat:reset()
    self.hand_cards     = {}            -- 手牌
    self.lstGrabPile    ={}             --结构牌{lstCards, type}
    self.newcard        = nil           -- 新牌
    self.has_newcard    = false         -- 是否有新牌
    self.rivercards     = {}            -- 牌河的牌
    self.blindHands   = true          -- 当前手牌是否不可见 
    
end

-- 添加新手牌
function DRSeat:addHand( cardid, sort )
    table.insert( self.hand_cards, cardid )    
end

-- 排序
function DRSeat:sortHand( inc )

    if inc then
        table.sort( self.hand_cards,  function( a, b ) return a < b  end )
    else
        table.sort( self.hand_cards,  function( a, b ) return a > b  end )
    end
    
end

--删除指定玩家的数据手牌
function DRSeat:delHand( cardid )

    if #self.hand_cards > 0 then    
        for i = 1, #self.hand_cards do        
            if self.hand_cards[i] == cardid then 
                table.remove( self.hand_cards, i )
                return true
            end 
        end
    end

    g_methods:error( "删除指定玩家的数据手牌失败:位置[%d]没有指定的牌%d...", self.seatNo, cardid )
    return false

end

-- 设置玩家的新手牌
function DRSeat:setNewCard( newcardid )

    self.has_newcard = true
    self.newcard = newcardid

end

-- 删除玩家的新牌
function DRSeat:delNewCard()

    self.has_newcard = false
    self.newcard = nil

end

-- 是否有新牌
function DRSeat:hasNewCard()

    return self.has_newcard

end

-- 返回玩家的新牌
function DRSeat:getNewCard()

    return self.newcard

end

-- 是不是牌背
function DRSeat:isBlindHand()
    return self.blindHands
end

return DRSeat