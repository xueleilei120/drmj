-- table.lua
-- 2015-01-11
-- KevinYuen
-- 达人麻将游戏桌

local BaseTable = require( "game.hall.table" )
local DRTable = class( "DRTable", BaseTable )
local DRSeat = require( "game.table.seat" )
local HuManager = require("kernels.mahjong.logic.huManager")

-- 初始化
function DRTable:OnCreate( args )

    DRTable.super.OnCreate( self, args )
    
    -- 逻辑体创建
    self.logic = g_factory:Create( "MJLogic" )

    -- 游戏桌变量定义
    self.gamestage     = STATE_WAITBEGIN       -- 当前游戏状态
    self.bankerseat = -1               -- 当前庄家位置
    self.basescore = 0                 -- 基础分
    self.settle = nil                  -- 结算信息
    self.waittime = 0                  -- 游戏等待时间
    self.nWalloffset = 10              -- 切排墙位置
    self.bTingPai = false              -- 是否停牌
    self.nMinFan  = 0                  --起胡番数
    self.isCanTing = false
    self.huManager = HuManager.new() 
    
    -- 消息监听列表
    self.msg_hookers = {         
        { E_HALL_GAMEBEGIN,     handler( self, self.OnRecGameBegin ) },
        { E_HALL_GAMEEND,       handler( self, self.OnRecGameEnd ) },
        -- Svr To Client
        { STC_MSG_BASECORE,     handler( self, self.onSetBaseScore )},
        { STC_MSG_CONFIG,       handler( self, self.onGameConfig) },
        { STC_ASSIGNBANKER,     handler( self, self.OnResetBanker)},       --记录庄位置  
        { STC_MSG_DEALCARD,     handler( self, self.OnDealCards )},        
        { STC_MSG_UPDATESTATE,  handler( self, self.UpdateGameState)},
        { STC_MSG_OPER,         handler( self, self.onRecvOper)},

        -- playstate
        { STC_MSG_OPERRESULT,   handler( self, self.onRecOperResult)},
        { STC_MSG_FIRSTPLAY,    handler( self, self.onFirstOper)},           -- 第一次操作
        { STC_MSG_PLAYCARD,     handler( self, self.onPlayCard )},
        { STC_MSG_GETNEWCARD,   handler( self, self.getNewCard )},
        { STC_MSG_SETHAND,      handler( self, self.setHandCard)},
        { STC_MSG_CARDINFO,     handler( self, self.optInfo)},
        { STC_MSG_CUTRETURN,    handler( self, self.onCuttReturn)},     -- 处理掉线重入消息
        { STC_MSG_TING,         handler(self,self.onTingOper)},
        { STC_MSG_CHATING,      handler(self,self.onRecvChaTing)},        -- 处理听牌
        { STC_MSG_CANCELTING,   handler( self, self.onCancelTing)},      -- 取消听牌信息
        
                    
    }
    
    -- 消息监听
    g_event:AddListeners( self.msg_hookers, "mj_table_events" )
    
    -- 分配座位,初始化座位信息列表
    for index = 0, TABLE_MAX_USER - 1 do
        self.seatList[index] = DRSeat.new( index )
    end
     
    return true 
    
end

-- 销毁
function DRTable:OnDestroy()

    -- 事件监听注销
    g_event:DelListenersByTag( "mj_table_events" )
   
    -- 游戏玩法服务销毁
    g_factory:Delete( self.logic )
    
    -- 全局变量销毁
    jav_table = nil
    
    DRTable.super.OnDestroy( self )
    
end

--操作行为
function DRTable:onRecvOper( event_id,event_args )
      local lstOper = { }
              
        --杠
        if operCanGang(  event_args.nOper ) then
            table.insert(lstOper, "gang")
        end
    
        --碰
        if operCanPeng(  event_args.nOper ) then
             table.insert(lstOper, "peng")
        end
        --吃
        if operCanChi(  event_args.nOper ) then
           table.insert(lstOper, "chi")
        end
    
        --听
        if operCanTing(  event_args.nOper ) then
            table.insert(lstOper, "ting")
        end
      local isExistTing = false
	  if self.isCanTing == false then
    	   if event_args.nOperSeat == jav_get_mychairid() then
                if g_methods:IsInTable(lstOper, "ting") then
                    isExistTing = true
                end
           end
      end
      
      if isExistTing == true then
        event_args.nOper = bit.band(event_args.nOper, 0xfffff7ff)
        if #lstOper > 1 then 
            g_event:SendEvent( CTC_MSG_OPER, event_args)
        
        end
      
      else
        g_event:SendEvent( CTC_MSG_OPER, event_args)
      end

end


-- 收到玩家的听牌操作
function DRTable:onRecvChaTing(event_id,event_args)

    --当前玩家旁观
    if jav_iswatcher( jav_self_uid ) then
        return  
    end
    
    local seatInfo = jav_table:getSeat(event_args.nSeat)
    local _lstCanPlay  = {}
    local _lstCanHu  = {}
    local _lstZMFan  = {}
    local _lstFPFan  = {}
    local _lstCount  = {}
    local lstFan     = {}
    
    for idx =1 ,  #event_args.lstCanHu  do 
        local lstZMFan = {}          --自摸
        local lstFPFan    = {}          --放炮
        --计算自摸
        for i = 1, #event_args.lstCanHu[idx] do
            local handCards = clone(seatInfo.hand_cards)
            local newCard = seatInfo:getNewCard()
            table.insert( handCards, newCard )
            for k = 1, #handCards do
                if handCards[k] == event_args.lstCanPlay[idx][1] then
                    table.remove( handCards, k )  
                    break
                end
            
            end
              local  nZMFan = self.huManager:totalizeHuFan(
                    {
                        [1]  = seatInfo.lstGrabPile,
                        [2] = handCards, 
                        [3]      = event_args.lstCanHu[idx][i],
                        [4]   = event_args.nQuanFengCard, 
                        [5]   = event_args.nMenFengCard ,
                        [6]        = true,
                        [7]        = event_args.bTing,
                        [8] = event_args.nLeftWallNum ,
                        [9]  = event_args.lstSpecialHuZM[idx][i] 
                    },
                    true
                )
            g_methods:log(string.format("自摸  %d",nZMFan))
              table.insert(lstZMFan,nZMFan)
              local  nFPFan = self.huManager:totalizeHuFan(
                    {
                    [1] = seatInfo.lstGrabPile,
                    [2] = handCards, 
                    [3]      = event_args.lstCanHu[idx][i],
                    [4]   = event_args.nQuanFengCard,
                    [5]   = event_args.nMenFengCard ,
                    [6]        = false,
                    [7]        = event_args.bTing,
                    [8] = event_args.nLeftWallNum, 
                    [9]  = event_args.lstSpecialHuFP [idx][i] 
                    },
                true
                )
            g_methods:log(string.format("点炮  %d",nFPFan))
            
            table.insert(lstFPFan,nFPFan)
            table.insert(lstFan,nZMFan)
            table.insert(lstFan,nFPFan)

        end
        
        table.sort(lstFan,function(A, B) return A < B end)
        self.isCanTing = false
        g_methods:log(string.format("查听  %d, %d, %d",lstFan[1],event_args.nTaskFan,event_args.nMinFan ))
        if lstFan[1]*event_args.nTaskFan*event_args.nHuMulti  >= event_args.nMinFan  then
            self.isCanTing = true
        end
    
        for _idx = 1, #event_args.lstCanPlay[idx]  do 
            
            local data = clone(event_args.lstCanHu[idx])
            table.insert(_lstCanHu,data)
            
            data = clone(lstZMFan)
            table.insert(_lstZMFan,data)
            
            data = clone(lstFPFan)
            table.insert(_lstFPFan,data)
            
            data = clone(event_args.lstCount[idx])
            table.insert(_lstCount,data)
            
            table.insert(_lstCanPlay,event_args.lstCanPlay[idx][_idx])
        end  
    end

    event_args.lstCanPlay = _lstCanPlay
    event_args.lstCanHu = _lstCanHu
    event_args.lstZMFan = _lstZMFan
    event_args.lstFPFan = _lstFPFan
    event_args.lstCount = _lstCount


    g_event:SendEvent( CTC_MSG_CHATING, event_args)
end

function DRTable:onCancelTing(event_id,event_args)

    self.tingSrvData = nill 
end
-- 收到玩家的听牌操作
function DRTable:onTingOper(event_id,event_args)
   -- self.tingDat
    local _lstCanPlay  = {}
    for idx = 1, #event_args.lstCanPlay   do 
        for _idx = 1, #event_args.lstCanPlay[idx]  do 
    
            table.insert(_lstCanPlay,event_args.lstCanPlay[idx][_idx])
        end  
    end
    event_args.lstCanPlay = _lstCanPlay
    self.tingSrvData = clone(event_args)

    g_event:SendEvent( CTC_TING_OPER, event_args)
    if jav_iswatcher( jav_self_uid ) == false then
        g_event:SendEvent( CTC_MSG_OPER, {nOperSeat = event_args.nTingSeat, nOper = OPER_CANCEL})

    end
    
end


function DRTable:onCuttReturn( event_id,event_args)
	
    -- 记录庄位置
    if event_args.nBanker ~= -1 then
        self:OnResetBanker(event_id,event_args)
    end
    
    self.basescore = event_args.nBaseScore
    
    -- 设置是否支持做牌
    self.canMakeCard = ( event_args.bCanMakeCard == 1 )

    -- 先将自己的手牌处理了
    if #event_args.lstHandCards1 == 0 then   -- 还没有到发牌阶段
        return
    else       
        self:onCutterPlayerCards(0,event_args.lstHandCards1,event_args.nNewCard1,event_args.lstGrabPile1,event_args.lstGrabPileType1 )
        self:onCutterPlayerCards(1,event_args.lstHandCards2,event_args.nNewCard2,event_args.lstGrabPile2,event_args.lstGrabPileType2 )
    end
    
    -- 重置游戏状态
    event_args.state = event_args.nGameState
    self:UpdateGameState(event_id,event_args)
    g_event:SendEvent( CTC_MSG_CUTRETURN,  event_args )
    
end

-- 重新掉线回来后玩家打的牌的相关性信息
-- chairid:玩家的id,lsthandcards:玩家手牌，newcard:玩家新牌
function DRTable:onCutterPlayerCards( chairid, lsthandcards, newcard,lstGrabPile, lstGrabPileType)

    local handcards = clone(lsthandcards) 
    local seatInfo = jav_table:getSeat( chairid )
    local _lstGrabPileType = clone( lstGrabPileType )
    local _lstGrabPile = clone( lstGrabPile )
    
    --处理结构牌
    for idx = 1, #lstGrabPile do 
        local tbl = {type = _lstGrabPileType[idx], lstCards=_lstGrabPile[idx] }
        table.insert(seatInfo.lstGrabPile, tbl)
    end
    
    seatInfo.blindHands = false
    if g_methods:IsInTable(handcards,99) then
        seatInfo.blindHands = true
        handcards = {}
        for i=1,#lsthandcards do
           local card = getBlindId()
           table.insert(handcards,card)
        end
    end
    seatInfo.hand_cards = clone(handcards)
    seatInfo:sortHand(true)
    
    local hasNewCard = false
    
    if newcard ~= -1 then
        hasNewCard = true
        seatInfo:setNewCard(newcard)
    end
    
    local cutterHandcard = {}
    cutterHandcard.hand_cards = handcards
    cutterHandcard.hasNewCard = hasNewCard
    cutterHandcard.newCard = newcard
    cutterHandcard.seatNo = jav_get_localseat(chairid)
    cutterHandcard.chairid = chairid
    cutterHandcard.lstGrabPile = lstGrabPile
    cutterHandcard.lstGrabPileType = lstGrabPileType
    
    g_event:SendEvent( CTC_CUTTER_HANDCARDINFO, cutterHandcard)
    
end

-- 更新游戏状态
function DRTable:UpdateGameState(event_id,event_args)

    self.gamestage = event_args.state
	
end

-- 游戏数据重置
function DRTable:ResetData()

    DRTable.super.ResetData( self )
    
    -- 结算数据清理
    self.settle = nil
    self.bankerseat = -1     -- 庄重置

end

-- 重置对家手牌信息
function DRTable:optInfo( event_id,event_args)
    
    local chairid = event_args.nFrom
    local seatInfo = jav_table:getSeat( chairid )
    seatInfo.hand_cards = {}
    for idx =1, #event_args.lstHandCards do
        table.insert( seatInfo.hand_cards, getBlindId() )
    end
    
    if event_args.lstHandCards[1] ~= 99 then
        seatInfo.hand_cards = event_args.lstHandCards
        seatInfo.blindHands = false
    else
        seatInfo.blindHands = true
    end
    
    event_args.lstHandCards =  seatInfo.hand_cards 
--    seatInfo.hand_cards = event_args.lstHandCards
--    seatInfo.blindHands = false
    seatInfo:sortHand(true)
    if event_args.nNewCard == 99 then
        event_args.nNewCard = getBlindId()
   end 
   
    if event_args.nNewCard ~= -1 then
        seatInfo:delNewCard()
        seatInfo:setNewCard(event_args.nNewCard)
    end
 
  
    g_event:SendEvent(CTC_HANDCARDS_OPTUPDATE, event_args)
    
end

-- 庄更新
function DRTable:OnResetBanker( event_id, event_args )
    
    -- 当前庄家位置重置
    self.bankerseat = event_args.nBanker
    
end

-- 重新设置玩家的手牌信息
function DRTable:setHandCard( event_id,event_args)

    local handcards = event_args.lstHandCards
    local chairid   = event_args.nchair
    local seatNo = jav_get_localseat(chairid)
    
    local seatInfo = jav_table:getSeat( chairid )
    seatInfo:reset()
    seatInfo.hand_cards = {}
    seatInfo.hand_cards = event_args.lstHandCards
    seatInfo.blindHands = false
    
    local newCard = event_args.nNewCard 
    if newCard >1 then
        seatInfo:delNewCard()
        seatInfo:setNewCard(newCard)
    end
    
    seatInfo.nNewCard  = event_args.nNewCard 
    
    local setHandArgs = {}
    setHandArgs.handcards = handcards
    setHandArgs.chairid = chairid
    setHandArgs.seatNo = seatNo
    setHandArgs.nNewCard = event_args.nNewCard 
    
    g_event:SendEvent( CTC_SETHANDCARDS, setHandArgs )
    
end


-- 第一次操作
function DRTable:onFirstOper( event_id, event_args)


    g_event:SendEvent( CTC_FIRSTOPER, event_args )
    
end

function DRTable:onPlayCard( event_id, event_args)
 
    local chairId = event_args.nPlaySeat    
    local seatNo = jav_get_localseat(chairId)   
    local seatInfo = jav_table:getSeat( chairId )
    local newCard = event_args.nNewCard    
    local playcard = event_args.nPlayedCard
    self.tingSrvData = nill 
    -- 停牌更新
    if seatNo == 0 then
        self.bTingPai = event_args.bTingPlay
        g_methods:debug( "停牌更新!" )
    end
    
    -- 增加打牌音效
    local sex = jav_get_chairsex(chairId)
    local cardAudio = string.format(CARD_AUDIO,sex,playcard/10)
    g_audio:PlaySound(cardAudio)
    
    local cardidx = event_args.nCardIdxUI 
    
    local isMoPai = false
    
    if seatInfo:hasNewCard() then
    
        if seatInfo:isBlindHand() then
            
            if event_args.nCardIdxUI == -1 then
                isMoPai = true
            else
                playcard = seatInfo.hand_cards[cardidx]
                newCard = getBlindId()
            end
        else
            if seatInfo:getNewCard() == event_args.nPlayedCard then
                isMoPai = true
            else         
            end
        end
        
        if isMoPai == false then
            seatInfo:addHand( newCard )
            seatInfo:delHand( playcard )
            seatInfo:sortHand( true )
        end 

        seatInfo:delNewCard()

        local playArgs = {}
        playArgs.turnChairid = event_args.nNextTurn
        playArgs.chairid =  chairId    
        playArgs.seatNo = jav_get_localseat(event_args.nPlaySeat)
        playArgs.isBlindHand = seatInfo:isBlindHand()
        -- 对家背牌牌河需要真实牌
        playArgs.playCardid  = event_args.nPlayedCard
        playArgs.playCardidx  = event_args.nCardIdxUI
        playArgs.newCard = newCard
        playArgs.isMoPai = isMoPai
        playArgs.bTingPlay = event_args.bTingPlay

        g_event:SendEvent(CTC_PLAYCARD,playArgs)
        
    else
        g_methods:error( "座位号为 %d 玩家没有新牌，服务器确认打牌位置错误!", chairId)
    end
    
end

-- 获得一张新牌
function DRTable:getNewCard( event_id,event_args)
    
    local chairid = event_args.nSeat
    local seatNo = jav_get_localseat( chairid )
    local seatInfo = jav_table:getSeat( chairid )

    -- 设置新玩家的超时
    
    if seatInfo:isBlindHand() then
        seatInfo:setNewCard( getBlindId() )
    else
        seatInfo:setNewCard( event_args.nNewCard )
    end
    
    local nCardArgs = {}
    nCardArgs.chairid = chairid
    nCardArgs.seatNo = seatNo
    nCardArgs.newCard = event_args.nNewCard
    nCardArgs.bReverse = event_args.bReverse
    nCardArgs.iTime = event_args.nTime
    nCardArgs.totalTime = event_args.nTime
    
    g_event:SendEvent(CTC_SHOWNEWCARD, nCardArgs)
    
end


function DRTable:dealPengAndChi( args )

    local byoperseat = args.nOperSeatBy
    local operseat = args.nOperSeat
    local operCards = args.lstOperCards
    local opercard = args.nOperCard
    local newcard = args.nNewCard

    -- 设置手牌的结构牌
    local seatNo = jav_get_localseat(operseat)    
    local seatInfo = jav_table:getSeat(operseat)

    local delCards = clone(operCards)
    for i=1, #operCards do
        if operCards[i] == opercard then
            table.remove( delCards, i )
            break
        end
    end

    -- 盲删判断
    if  seatInfo:isBlindHand() then
        delCards[1] = seatInfo.hand_cards[1] 
        delCards[2] = seatInfo.hand_cards[2]
    end

    -- 碰删除2牌操作    
    for i = 1, #delCards do          
        seatInfo:delHand( delCards[i] )
    end

    -- 加摸牌
    if seatInfo:isBlindHand() == true then
        local cards = seatInfo.hand_cards
        newcard = cards[#cards]
    end

    seatInfo:delHand( newcard )   
    seatInfo:setNewCard( newcard ) 

    local operArgs = {}
    operArgs.stackCards = args.lstOperCards
    operArgs.tChairId = args.nOperSeatBy
    operArgs.tRiverCard = args.nOperCard
    operArgs.mChairId = args.nOperSeat
    operArgs.mDelCards = delCards
    operArgs.mNewCard = newcard
    operArgs.operFlag = args.nOper
    operArgs.seatNo = seatNo

    return operArgs
end

-- 碰操作
function DRTable:doPeng( args )

    local operArgs = self:dealPengAndChi(args)
    operArgs.operFlag = args.nOper
    operArgs.china = "碰"
    g_event:SendEvent( CTC_STACKOPER_PENGCHI, operArgs )

end

--吃操作
function DRTable:doChiOper( args )

    local operArgs = self:dealPengAndChi(args)
    operArgs.operFlag = args.nOper
    operArgs.china = "吃"
    g_event:SendEvent( CTC_STACKOPER_PENGCHI, operArgs )
    
end

--直杠
function DRTable:doZhiGang( args ) 

    local byoperseat = args.nOperSeatBy
    local operseat = args.nOperSeat
    local operCards = args.lstOperCards
    local opercard = args.nOperCard
    local newcard = args.nNewCard

    -- 设置手牌的结构牌
    local seatNo = jav_get_localseat(operseat)    
    local seatInfo = jav_table:getSeat(operseat)

    local delCards = clone(operCards)
    for i=1, #operCards do
        if operCards[i] == opercard then
            table.remove(delCards,i)
            break 
        end
    end
    

    -- 盲删判断
    if  seatInfo:isBlindHand() then
        delCards[1] = seatInfo.hand_cards[1] 
        delCards[2] = seatInfo.hand_cards[2]
        delCards[3] = seatInfo.hand_cards[3]
    end

    -- 删除牌操作    
    for i = 1, #delCards do          
        seatInfo:delHand( delCards[i] )
    end

    local operArgs = {}
    operArgs.stackCards = args.lstOperCards
    operArgs.tChairId = args.nOperSeatBy
    operArgs.tRiverCard = args.nOperCard
    operArgs.mChairId = args.nOperSeat
    operArgs.mDelCards = delCards
    operArgs.operFlag = args.nOper
    operArgs.seatNo = seatNo
    g_event:SendEvent( CTC_STACKOPER_ZHIGANG, operArgs )
    
end

-- 碰杠操作
function DRTable:doPengGang(args)

    local byoperseat = args.nOperSeatBy
    local operseat = args.nOperSeat
    local operCards = args.lstOperCards
    local opercard = args.nOperCard
    local newcard = args.nNewCard
    
    
    local seatNo = jav_get_localseat(operseat)    
    local seatInfo = jav_table:getSeat(operseat)
        
    -- 先将新牌加到手牌中
    if  seatInfo:isBlindHand() then
        newcard = getBlindId()
        table.insert(seatInfo.hand_cards,newcard)
    else
        table.insert(seatInfo.hand_cards,newcard)
    end
    
    -- 对手牌排序
    seatInfo:sortHand( true )
    
    if  seatInfo:isBlindHand() then
        opercard = seatInfo.hand_cards[1]
    else  
    end 
    
    local delCards = clone(operCards)
    local keycard = nil
    
    for i=1,#operCards do
        if operCards[i]== opercard then
            table.remove(delCards,i)
            break
        end
    end
    
    keycard = delCards[1]
    
    seatInfo:delHand( opercard )
     
    seatInfo:delNewCard()
    
    local isMopai = false
    if opercard == newcard then
        isMopai = true 
    end
    
    local operArgs = {}
    operArgs.stackCards = args.lstOperCards
    operArgs.mChairId = args.nOperSeat
    operArgs.delCard = opercard    -- 应该删除的一张牌
    operArgs.newCard = newcard
    operArgs.seatNo = seatNo
    operArgs.keyCard = keycard   -- 已经碰牌中某一张cardid
    operArgs.isMopai = isMopai
    g_event:SendEvent( CTS_STACKOPER_PENGGANG, operArgs )
    
end

-- 暗杠
function DRTable:doAnGangOper( args )

    args = clone( args )
    
    local byoperseat = args.nOperSeatBy
    local operseat = args.nOperSeat
    local operCards = args.lstOperCards
    local opercard = args.nOperCard
    local newcard = args.nNewCard

    -- 设置手牌的结构牌
    local seatNo = jav_get_localseat(operseat)    
    local seatInfo = jav_table:getSeat(operseat)
    
    -- 先将新牌加到手牌中
    if  seatInfo:isBlindHand() then
        newcard = getBlindId()
    else
    end
    
    table.insert(seatInfo.hand_cards,newcard)
   
    -- 对手牌排序
    seatInfo:sortHand( true )

    local delCards = {}
    delCards = clone(operCards)

    -- 盲删判断
    if  seatInfo:isBlindHand() then
        delCards = {}
        delCards[1] = seatInfo.hand_cards[1] 
        delCards[2] = seatInfo.hand_cards[2]
        delCards[3] = seatInfo.hand_cards[3]
        delCards[4] = seatInfo.hand_cards[4]
    end

    -- 删除牌操作    
    for i = 1, #delCards do          
        seatInfo:delHand( delCards[i] )
    end
    
    seatInfo:delNewCard()
    
    local isDealMopi = false
    for i=1,#delCards do
        if delCards[i] == newcard then
            isDealMopi = true
            break
        end
    end

    local operArgs = {}
    operArgs.stackCards = args.lstOperCards
    operArgs.mChairId = args.nOperSeat
    operArgs.mDelCards = delCards
    operArgs.newCard = newcard
    operArgs.operFlag = args.nOper
    operArgs.seatNo = seatNo
    operArgs.isDealMopai = isDealMopi
    operArgs.isBlind = seatInfo:isBlindHand()
    
    g_event:SendEvent( CTS_STACKOPER_ANGAGN, operArgs )
    
end

-- 结构牌操作
function DRTable:onRecOperResult( event_id, event_args )
    -- 播放操作音效
    self:OnPlayOperAudio(event_args)
    
    if event_args.nOper == OPER_PENG then

        self:doPeng( event_args )

    elseif event_args.nOper == OPER_ZHI_GANG then

        self:doZhiGang( event_args )

    elseif event_args.nOper == OPER_PENG_GANG then

        self:doPengGang( event_args )

    elseif event_args.nOper == OPER_AN_GANG then

        self:doAnGangOper( event_args )

    elseif event_args.nOper == OPER_LCHI or event_args.nOper == OPER_MCHI or event_args.nOper == OPER_RCHI then
        self:doChiOper( event_args)
    end

    -- 动画效果通告
    local operseat = event_args.nOperSeat
    local seatNo = jav_get_localseat(operseat)
    self:UpdateGrabPile(event_args.nOperSeat,event_args.nOper, event_args.lstOperCards )
    g_event:SendEvent( CTC_OPER_STACKSHOW, { seatNo = seatNo, operFlag = event_args.nOper })
    
    return g_event.RET_EXCLUSIVE
    
end

--更新结构牌
function DRTable:UpdateGrabPile(chairId, oper,  lstOperCards)

    local seatInfo = jav_table:getSeat(chairId)
    
    --当前操作是直杠和碰杠    
    if oper == OPER_ZHI_GANG or oper == OPER_PENG_GANG then
        for idx, val in pairs(seatInfo.lstGrabPile) do
	   	   if val.type == OPER_PENG then
	   	       if math.floor(val.lstCards[1]/10) == math.floor(lstOperCards[1]/10) then
                    val.type = oper
                    val.lstCards = lstOperCards
                    return
	   	       end
	   	   end
	   end
	end
	
    local tbl = {type = oper, lstCards = lstOperCards }
    table.insert(seatInfo.lstGrabPile, tbl)
end


function DRTable:OnPlayOperAudio(args)
    local oper = args.nOper
    local chairid = args.nOperSeat
    local sex = jav_get_chairsex(chairid)
    if operCanPeng(oper) then
        oper = "peng"
    elseif operCanChi(oper)then
        oper = "chi"
    elseif operCanGang(oper)then
        oper = "gang"
    end
    
    local oper = string.format(OPER_AUDIO,sex,oper)
    g_audio:PlaySound(oper)
    
end
--第一次出牌
function DRTable:onRecvFirstPlay( event_id,event_args )
    
    g_event:SendEvent( CTC_MSG_FIRSTPLAY, event_args )
end


-- 发牌消息
function DRTable:OnDealCards(event_id,event_args)
    
    local chairid = jav_get_mychairid()
    local seatInfo = jav_table:getSeat(chairid)
    local tchairid = jav_next_chairid(chairid,false)
    local tseatInfo = jav_table:getSeat(tchairid)
    
    g_methods:CopyTable( event_args.lstHandCards, seatInfo.hand_cards )
    seatInfo.blindHands = false
    
    -- 对家的废牌 (模拟玩家牌背手牌)
    tseatInfo.hand_cards = {}
    for i = 1, 13 do
        table.insert( tseatInfo.hand_cards, getBlindId() )
    end
    
    if event_args.lstHandCards[1] == 99 then
        seatInfo.blindHands = true
        seatInfo.hand_cards = {}
        for i = 1, 13 do
            table.insert( seatInfo.hand_cards, getBlindId() )
        end
    end
    
    
        
    -- 如果自己是庄，则有新牌
    if self.bankerseat == jav_get_mychairid() then
        if event_args.nNewCard == 99 then
            seatInfo.newcard = getBlindId()
        else
            seatInfo.newcard = event_args.nNewCard
        end
    else
        jav_table:getSeat(tchairid).newcard = getBlindId()
    end
    
    -- 设置庄家有新牌
    jav_table:getSeat(self.bankerseat).has_newcard = true
    
end

-- 游戏开始
function DRTable:OnRecGameBegin( event_id, event_args )

    -- 系统日志
    local text = g_library:QueryConfig( "text.hall_gamebegin" )
    jav_room:PushSystemLog( text )

    -- 准备阶段全数据重置
    self:ResetData()
    self.bTingPai = false
    --激活任务栏
    jav_active_taskbar( true )
    
    g_event:SendEvent(E_CLIEN_GAMEBEGIN, event_args )
    
end

-- 游戏结束
function DRTable:OnRecGameEnd( event_id, event_args )

    -- 系统日志
    self.tingSrvData = nill 
 
    local text = g_library:QueryConfig( "text.hall_gameend" )
    jav_room:PushSystemLog( text )
    
end

-- 重置游戏基础分信息
function DRTable:onSetBaseScore( event_id, event_args )

    -- 变量更新
    self.basescore = event_args.nBaseScore
   
end

-- 设置游戏房间信息
function DRTable:onGameConfig( event_id,event_args)

    self.nServiceFee = event_args.nServiceFee   -- 服务费
    self.waittime = event_args.nWaitTime
    self.nMinFan  = event_args.nMinFan
    self.canMakeCard = ( event_args.nCanMakeCard == 1 )
 --  local room_key = "text.room_mode_" .. jav_tableinfo.gamemode
--    --    local room_name = g_library:QueryConfig( room_key )
--    --    local text = g_library:QueryConfig( "text.hall_room_info" )
----    local gamename = jav_bg2312_utf8( jav_gameinfo.gamename )
    ----    local content = string.format( text, gamename, room_name, jav_tableinfo.tableid, jav_tableinfo.svrfee )
    ----    jav_room:PushSystemLog( content )
    --   
    local gameMode = 0 
    if jav_room_type(ROOM_SCORE) then
        gameMode = ROOM_SCORE
    elseif jav_room_type(ROOM_MONEY) then
        gameMode = ROOM_MONEY
    elseif jav_room_type(ROOM_MATCH) then
        gameMode = ROOM_MATCH
    elseif jav_room_type(ROOM_EASY) then
        gameMode = ROOM_EASY
    elseif jav_room_type(ROOM_QUENE) then
        gameMode = ROOM_QUENE
    else
        gameMode = ROOM_CUTTRUST
    end
    local room_key = "text.roommode_" .. gameMode
    local room_name = g_library:QueryConfig( room_key )
    local text = g_library:QueryConfig( "text.enterroom_1" )
    local gamename = jav_bg2312_utf8( jav_room.gamename )
    local content = string.format( text, gamename, room_name, jav_table.basescore, jav_table.nServiceFee, jav_table.tableid )
    jav_room:PushSystemLog( content )
    
    local text = g_library:QueryConfig( "text.enterroom_2" )
    local content = string.format( text,self.waittime  )
    jav_room:PushSystemLog( content )
    
    g_event:SendEvent( CTC_MSG_CONFIG, event_args )
    return true  
	
end

-- 游戏结算
function DRTable:OnGameSettle( event_id, event_args )
    
    -- 记录全保存
    self.settle = {}
    g_methods:CopyTable( event_args, self.settle )
        
end

-- 全卡片发布
function DRTable:OnShowAllCards( event_id, event_args )
    
    -- 记录全保存
    self.settle = {}
    g_methods:CopyTable( event_args, self.settle )
    
end

-- 用户离开座位
function DRTable:OnUserStandUp( event_id, event_args )

    DRTable.super.OnUserStandUp( self, event_id, event_args )
    
end

return DRTable