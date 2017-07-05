-- controls.lua
-- 2016-02-16
-- 麻将操作控制

local BaseObject = require( "kernels.object" )
local CompControl = class(  "CompControl", BaseObject )
local HuTips = require( "game.table.nodes.huTips" )

local MJTableDR = require( "game.table.nodes.tableDR" )

-- 激活
function CompControl:Actived()

    CompControl.super.Actived( self )    
    
    self.wallmap    = {}        -- 牌墙映射表  
    self.operMap    = {}        -- 操作列表
    self.turnChairid    = -1        -- 当前操作玩家座位号
    self.opchoose   = false     -- 吃碰杠选牌模式
    self.opcards    = {}        -- 选牌模式有效牌列表
    
    --保存本地数据
    self.newrivercard = nil     -- 打入牌河的新牌对象
    self.chaTingCharidId   ={}       --
    self.tingChairIds = {}      -- 初始化听玩家座位号列表(保存服务器位置)
    self.bClickTing = true     --是否点听操作
    self.tingInfos = {}         -- 听牌玩家的听牌信息
    self.huTypeInfo = {}
    self.huTypeInfo[0] = {}     -- 玩家的胡牌信息
    self.huTypeInfo[1] = {}
    
    -- 创建牌桌控制
    self.lay_node = self.bind_scene:FindRoot():getChildByName( "mj_layer" )
    self.mjtable = MJTableDR.new( self.lay_node )   
    
    -- 可胡牌提示面板
    -- 界面绑定
    self.ui_layer = self.bind_scene:FindRoot():getChildByName( "ui_layer" )
    local huTipPanel = self.ui_layer:getChildByName( "pan_hutips" )
    self.pan_hutips = HuTips.new( huTipPanel )
    
    -- 抢杠胡的提示面板
    local qghPanel = self.ui_layer:getChildByName( "pan_grabgh" )
    self.pan_qgh = HuTips.new( qghPanel )

    local center_node = self.lay_node:getChildByName( "center" )     
    for index = 0, TABLE_MAX_USER - 1 do         
    
        local rotWall = center_node:getChildByName( "wall" .. index + 1 ) 
        local nodWall = rotWall:getChildByName( "node" )
        self.mjtable:bindWall( index, nodWall, DRWALL_CFG[index] )
        local slotWall = center_node:getChildByName( "slot" .. index + 1 )
        self.mjtable:getWall( index ).slotUI = slotWall 
        
        local nodRiver = center_node:getChildByName( "river" .. index + 1 )
        self.mjtable:bindRiver(index, nodRiver, DRRIVER_CFG[index], handler( self, self.onMJRiverCallback ) )
        
        local nodHand = self.lay_node:getChildByName( "hand" .. index + 1 )
        self.mjtable:bindHand( index, nodHand, DRHAND_CFG[index], handler( self, self.onMJHandCallback ) )      
                     
    end     
     
    -- 消息监听列表
    self.msg_hookers = {          
        -- hall msg
        { STC_MSG_GAMEEND,              handler( self, self.OnRecGameEnd ) },
        { E_CLIEN_GAMEBEGIN,            handler( self, self.OnGameBegin ) },
        { E_CLIENT_USERREADY,           handler( self, self.onUserReady ) },
        { E_CLIENT_ICOMEIN,             handler( self, self.ClearUI)},
              
        --Svr To Client
        { STC_MSG_UPDATESTATE,          handler( self, self.UpdateGameState )},
        --game msg
        { STC_ASSIGNBANKER,             handler( self, self.doMJWall )},
        { STC_ASSIGNWALL,               handler( self, self.SetWallOffset )}, 
        { STC_MSG_DEALCARD,             handler( self, self.ShowALLHandCards )},
        { CTC_TING_OPER,                handler( self, self.onTingOper)},
        { CTC_MSG_CHATING,              handler( self, self.onRecvChaTing)},

        
        -- playcard state
        { CTC_FIRSTOPER,                handler( self, self.onFirstPlay )},
        { CTC_PLAYCARD,                 handler( self, self.onPlayCard )},
        { CTC_SHOWNEWCARD,              handler( self, self.onshowNewCard )},
        { CTC_STACKOPER_PENGCHI,        handler(self,self.onDoPengChiOper)},
        { CTC_STACKOPER_ZHIGANG,        handler(self,self.onDoZhiGangOper)},
        { CTS_STACKOPER_PENGGANG,       handler(self,self.onDoPengGangOper)},
        { CTS_STACKOPER_ANGAGN,         handler(self,self.onDoAnGangOper)},
        { CTC_SETHANDCARDS,             handler (self,self.onSetHandCards)},
        { CTC_HANDCARDS_OPTUPDATE,      handler(self,self.onOptUpdate)},
        { STC_MSG_UPDATEHUTYPE,         handler(self,self.onUpdateHuType)},
        
        { CTC_HANDCARDS_SETCHOOSE,      handler( self, self.onSetHandChoices )},  
        { CTC_HANDCARDS_DELCHOOSE,      handler( self, self.onCleanHandChoices )}, 
        { CTC_HAND_FOCUSCHANGED,        handler( self, self.onHandFocusChange)},
        { CTE_SHOW_SETTLEMENT,          handler( self, self.OnSettlement ) },
        { STC_MSG_CUTRETURN,            handler( self, self.onCuttReturn)},     -- 处理掉线重入消息
        { CTC_CUTTER_HANDCARDINFO,      handler( self, self.onCutPlayHandInfo)},
        { STC_MSG_QGH,                  handler( self, self.onQGH) },    -- 抢杠胡
        { STC_MSG_HUDOUBLE,             handler( self, self.OnRecHuDouble )}, 
        { STC_MSG_TURN,                 handler( self, self.onsetTurnChairid)},
        { STC_MSG_CANCELTING,           handler( self, self.onCancelTing)},      -- 取消听牌信息
        { CTC_OPER_QI,                  handler( self, self.onRecQiOper)},
        { STC_MSG_ALLOWWATCH,           handler( self, self.onOptUpdate)},
        { E_CLIENT_ICOMEIN,             handler( self, self.onRecvSefComin ) },

        
    }
    g_event:AddListeners( self.msg_hookers, "compmjtbl_events" )    
    
    
    
    self.dealNos    = { 1, 1 }
    self.dealTimes  = 1
    self.dealerCnts = { 4, 4, 4, 4, 4, 4, 1, 1 }
end

-- 反激活
function CompControl:InActived()
    
    -- 事件监听注销
    g_event:DelListenersByTag( "compmjtbl_events" )
    
    CompControl.super.InActived( self )
end

function CompControl:ClearUI(event_id,event_args) 

    if jav_isplaying(jav_self_uid) == false then
        self.mjtable:resetAll()
        self.newrivercard = nil     -- 牌河新牌失效    
    end
end

-- 胡牌加倍
function CompControl:onRecvSefComin( event_id,event_args)

        if event_args.uid ==  jav_self_uid then
            if self.dealerTick then
                local scheduler = cc.Director:getInstance():getScheduler()
                scheduler:unscheduleScriptEntry( self.dealerTick )
                self.dealerTick = nil
            end
            self.mjtable:showHandGray(0,false )
            g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
            self.mjtable:getHand(0).touchLock = 0
            g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 0, secs = 0, total = 0 } )
            g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 1, secs = 0, total = 0 } )
            self.mjtable:resetAll()
            self.newrivercard = nil     -- 牌河新牌失效   
            self.newrivercard = nil     -- 打入牌河的新牌对象
            self.chaTingCharidId   ={}       --
            self.tingChairIds = {}      -- 初始化听玩家座位号列表(保存服务器位置)
            self.bClickTing = true      --是否点听操作
            self.tingInfos = {}         -- 听牌玩家的听牌信息
            self.huTypeInfo = {}
            self.huTypeInfo[0] = {}     -- 玩家的胡牌信息
            self.huTypeInfo[1] = {}
        end
end


-- 胡牌加倍
function CompControl:OnRecHuDouble( event_id,event_args)
    self.pan_qgh:close()
end


--处理抢杠胡的操作
function CompControl:onQGH( event_id,event_args)

    local seatNo = jav_get_localseat(event_args.nGangSeat)
    local gangCard = event_args.nHuCard
    
    local cards = {}
    local card = { id = gangCard }
    table.insert(cards,card)
    
    self.pan_qgh:show(seatNo,cards)

end

function CompControl:onRecQiOper (  event_id,event_args  )
	if self.bClickTing == false then
        
	end
end

-- 掉线重入
function CompControl:onCuttReturn( event_id,event_args )

    -- 初始化牌墙
    self.mjtable:buildWall( function()
                            end, 0, OFFSET_BUILDWALLS )
                            
    -- 切牌墙
    if event_args.nWallDiceSum >0 then
        self:SetWallOffset(event_id,event_args)
    else     
        return    -- 尚未切排墙，不需要继续处理
    end
        
    -- 设置玩家的听列表
    self.tingChairIds = event_args.lstTingSeat
    
    -- 当前操作
    self.turnChairid = event_args.nCurTurn 
    
    local seatNo = jav_get_localseat(self.turnChairid)

    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = seatNo, secs = event_args.nTime , total = event_args.nTime  } )
    
    -- 处理玩家的结构牌和牌河的牌
    local seatNo = jav_get_localseat(0)
    self:onCutSetRiver(seatNo,event_args.lstRiverCards1,event_args.lstRiverOpCardIdx1,event_args.nTingPlayIdx1,event_args.lastPlayCardId)
    
    local seatNo = jav_get_localseat(1)
    self:onCutSetRiver(seatNo,event_args.lstRiverCards2,event_args.lstRiverOpCardIdx2,event_args.nTingPlayIdx2,event_args.lastPlayCardId)
    
    -- 减牌墙
    self:onCutSetWall(event_args.nWallFrontNum,event_args.nWallTailNum)
    
end

-- 设置掉线回来的牌墙
function CompControl:onCutSetWall(nWallFrontNum,nWallTailNum  )
	
	if nWallFrontNum == 0 then
	   return
	end
	
	for i=1,nWallFrontNum do
        local item = self:popWallFromMapFront()
        local wall = self.mjtable:getWall( item.wall )
        wall:pop( item.idx )
	end
	
	if nWallTailNum == 0 then
	   return 
	end
	
	for i=1,nWallTailNum do
	   local item = self:popWallFromMapBack()
       local wall = self.mjtable:getWall( item.wall )
       wall:pop( item.idx)
	end

end

-- 重置玩家的牌河信息
function CompControl:onCutSetRiver( seatNo,lstRiverCards,lstRiverOpCardIdx,nTingPlayIdx,lastPlayCardId )
    
    if #lstRiverCards == 0 then
        return 
    end
    
    local mjRiver = self.mjtable:getRiver( seatNo )
    
    for i= 1,#lstRiverCards do
        local cardid = lstRiverCards[i]
        local river_card = nil
        if nTingPlayIdx == i then 
            river_card = mjRiver:push(cardid,true)
            if g_methods:IsInTable(lstRiverOpCardIdx,i) then
                river_card:setBeCPG(true)
            end        
        elseif g_methods:IsInTable(lstRiverOpCardIdx,i) then
            river_card = mjRiver:push(cardid,false)
            river_card:setBeCPG(true)
        else
            river_card = mjRiver:push(cardid,false)
        end   
        if cardid == lastPlayCardId then
            self.newrivercard = river_card
            if nTingPlayIdx == i then
                river_card:setFingerMark( true, "ani.blueStone", OFFSET_STONEHOR )
                river_card:showMask( true, "#img.redmask2.png", true )
            else
                river_card:setFingerMark( true, "ani.blueStone", OFFSET_STONEVER )
                river_card:showMask( true, "#img.redmask1.png", true )
            end
            
        end
        river_card:setVisible(true) 
    end

--    -- 先给牌河中加牌
--    local river_card = mjRiver:push( id, putHor )
--    river_card:setVisible( false )
end

-- 重置掉线回来后玩家的手牌信息
function CompControl:onCutPlayHandInfo( event_id,event_args )

    local seatNo = event_args.seatNo
    local chairid = event_args.chairid
    local mjHand = self.mjtable:getHand( seatNo )
    
    mjHand:clean(true)
    
    local hancards = event_args.hand_cards
    for i= 1,#hancards do
        mjHand:push(hancards[i])
    end
    
    if event_args.newCard ~= -1 then
        mjHand:setMP(event_args.newCard)
    end
    
    self.mjtable:sortHands(seatNo,true) 
    
    self:onCutSetStack(seatNo,event_args.lstGrabPile,event_args.lstGrabPileType)
    
    -- 此处也需要考虑到玩家正听牌选择中的情况
    if g_methods:IsInTable(self.tingChairIds,chairid) then
        -- 只有是自己听牌时，才需要处理
        if chairid ~= jav_get_mychairid() then
            return 
        end
        g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = {event_args.newCard} } )
    end
    
end

-- 重置玩家的结构牌信息
function CompControl:onCutSetStack( seatNo,lstGrabPile,lstGrabPileType)
    local lstGrabPile = clone(lstGrabPile)
    local lstGrabPileType = clone(lstGrabPileType)

    if #lstGrabPile == 0 then
        return
    end
    
    local mjHand = self.mjtable:getHand( seatNo )
    
    for i=1,#lstGrabPileType do
    
        local stackList = lstGrabPile[i]
        local stackType = lstGrabPileType[i]
        if stackType == OPER_PENG then
            self.mjtable:pushStack( seatNo, STACK_MPEN, stackList, { false, true, false }, 0 )
    
        elseif stackType == OPER_LCHI then
            self.mjtable:pushStack( seatNo, STACK_MCHI, stackList, { true, false, false }, 0 ) 
    
        elseif stackType == OPER_MCHI then
            self.mjtable:pushStack( seatNo, STACK_MCHI, stackList, { false, true, false }, 0 )
    
        elseif stackType == OPER_RCHI then
            self.mjtable:pushStack( seatNo, STACK_MCHI, stackList, { false, false, true }, 0)
            
        elseif stackType == OPER_AN_GANG then
            stackList[1]=99
            stackList[2]=99
            stackList[4]=99
            self.mjtable:pushStack( seatNo, STACK_GANG, stackList, { false, true, true,false }, 0 )
        elseif stackType == OPER_ZHI_GANG or stackType == OPER_PENG_GANG then
            self.mjtable:pushStack( seatNo, STACK_GANG, stackList, { false, true, true,false }, 0 )
        end    
    end
    mjHand:forceUpdate()
end
--底层服务开始
function CompControl:OnGameBegin(event_id,event_args)

    self.mjtable:resetAll()
    self.newrivercard = nil     -- 牌河新牌失效   
    
end

-- 游戏结束，则初始化相关数据
function CompControl:OnRecGameEnd(event_id,event_args)

    self.wallmap    = {}        -- 牌墙映射表  
    self.operMap    = {}        -- 操作列表
    self.turnChairid    = -1        -- 当前操作玩家座位号
    self.opchoose   = false     -- 吃碰杠选牌模式
    self.opcards    = {}        -- 选牌模式有效牌列表
    self.tingChairIds= {}        -- 初始化听玩家座位号
    self.chaTingCharidId = {}
    self.tingInfos = {}
    self.huTypeInfo = {}
    self.huTypeInfo[0]={}
    self.huTypeInfo[1]={}
    
    self.pan_hutips:close()        -- 胡牌信息框消失 
    self.pan_qgh:close()
    
    self.pan_hutips:close() -- 将胡牌信息清掉
    
    -- 此处添加抢杠胡的特殊处理
    self:onGameEndQGH(event_args)
    
    --    self.newrivercard = nil     -- 牌河新牌失效

    -- 发牌阶段强制结束处理
    if self.dealerTick then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry( self.dealerTick )
        self.dealerTick = nil
    end
    
    -- 去掉听牌灰牌(自己和对家)
    g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
    self.mjtable:showHandGray(1,false)
    self:cleanHandCardsMarks( 0 )
end

-- 游戏结束后，处理枪杠胡的处理
function CompControl:onGameEndQGH( arg )

    if arg.bQGH then
    
        local chairid = arg.nHuSeatBy
        local seatNo = jav_get_localseat(chairid)
        local mjHand = self.mjtable:getHand(seatNo)
        mjHand:pop(arg.nHuCard)
        mjHand:updateHands()
        
    else
        return
    end
  
end

-- 状态切换
function CompControl:UpdateGameState( event_id,event_args)

    --游戏结束后，超时关掉
    if event_args.state == STATE_END then
        g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 0, secs = 0, total = 0 } )
        g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 1, secs = 0, total = 0 } )
    end
    
end

function CompControl:onHandFocusChange( event_id,event_args)

    local seatNo = event_args.seatNo
    local focus = event_args.focus
    
    local chairid = jav_get_chairid_bylocalseat(seatNo)
    
    if focus == false then
        self.pan_hutips:close()
    else
        if g_methods:IsInTable(self.tingChairIds,chairid) then
            if #self.huTypeInfo[chairid]>0 then
                self.pan_hutips:show( seatNo, self.huTypeInfo[chairid])
            end     
        end     
    end

end

function CompControl:OnSettlement( event_id, event_args )

    local settleInfo = jav_table.settles
    for i = 0, TABLE_MAX_USER - 1 do
        self.mjtable:getRiver(i).node:setVisible( false )
        self.mjtable:getWall(i).node:setVisible( false )
        self.mjtable:getHand(i):forceUpdate()
        self.mjtable:fallDownHand( i, true, false )
    end
    
    -- 流局和逃跑不需要特殊处理
    if (settleInfo.nEndReason == 4) or (settleInfo.nEndReason==1) then

    else
    
        local wchairid = settleInfo.nWinner
        local wseatNo = jav_get_localseat(wchairid)
        local wmjHand = self.mjtable:getHand(wseatNo) 
        if wmjHand then
        
            local mp = wmjHand:getMP()
            if mp ~=nil then
                wmjHand:delMP()
            end

            wmjHand:setMP(settleInfo.nHuCard)
            wmjHand:forceUpdate()
            self.mjtable:fallDownHand( wseatNo, false, true )
        end
        
    end
        
end

-- 跟新玩家的胡牌信息
function CompControl:onUpdateHuType( event_id,event_args)
    
    local chairid = event_args.nTingSeat
    local cards = {}
    local canHu = event_args.lstCanHu
    local huCardnum = event_args.lstCount
    local lstFPFan = event_args.lstFPFan
    local lstZMFan = event_args.lstZMFan
    
    local maxZM = 0
    local maxFP = 0
    
    local cards = {}
    for j=1,#canHu do
        local points = lstFPFan[j]
        if points > lstZMFan[j] then
            points =  lstZMFan[j]
        end
        
        local card = {
            id = canHu[j],
            count  = huCardnum[j],      --张数
            points = points,  -- 番数
            zmpts  = lstZMFan[j],
            fppts  = lstFPFan[j]           
        }
        table.insert(cards,card)
        
        if maxZM < lstZMFan[j] then
            maxZM = lstZMFan[j]
        end

        if maxFP < lstFPFan[j] then
            maxFP = lstFPFan[j]
        end
        
    end
   
    
    if event_args.bAllowWatch == false and jav_iswatcher( jav_self_uid ) then   
        self.huTypeInfo[chairid] = {}
        
    else
        self.huTypeInfo[chairid] = cards

    end
    
    local mchairId = jav_table:getChairId( jav_self_uid )
    if mchairId == chairid then
        g_methods:log("onUpdateHuType")

        g_event:PostEvent( CTC_FRESH_FANTIP, { moPt = maxZM, dnPt = maxFP } )
    end
    
end

-- 更新对家手牌信息
function CompControl:onOptUpdate( event_id,event_args)

    local scheduler = cc.Director:getInstance():getScheduler()
    if self.dealerTick then
        scheduler:unscheduleScriptEntry( self.dealerTick )
        self.dealerTick = nil
    end
    
    local seatNo = jav_get_localseat(event_args.nFrom )
    local mjHand = self.mjtable:getHand( seatNo )
    
    mjHand:clean(true)
    
    local hancards = event_args.lstHandCards
    for i= 1,#hancards do
        mjHand:push(hancards[i])
    end

    if event_args.nNewCard ~= -1 then
        if mjHand:getMP() then
           mjHand:delMP()
        end
        mjHand:setMP(event_args.nNewCard)
    end

    self.mjtable:sortHands(seatNo,true) 

    -- 更新结构牌信息
    for i=1,#event_args.lstAnGang do
        local stackCards = event_args.lstAnGang[i]
        stackCards[1] = 99
        stackCards[2] = 99
        stackCards[4] = 99
        self.mjtable:resetStackByIndex( seatNo, event_args.lstGangIndex[i], STACK_GANG, stackCards, { false, true, true, false } )
    end
    
    mjHand:forceUpdate()
    
--    if g_methods:IsInTable(self.tingChairIds,event_args.nOpponent) then
--        self.mjtable:showHandGray(seatNo,true)
--    end
    
    --此处将自己的手牌全部置恢
    self.tingInfos = {}  -- 将听的消息数据清空
    
    
end

-- 重新刷新玩家的手牌
function CompControl:onSetHandCards( event_id,event_args)
    
    local seatNo = event_args.seatNo
    local mjHand = self.mjtable:getHand( seatNo )
    
    mjHand:clean(true)
    
    local hancards = event_args.handcards
    for i= 1,#hancards do
        mjHand:push(hancards[i])
    end
    
    local newCard = event_args.nNewCard
    if newCard >0 then
        local moPai = mjHand:getMP()
        if moPai then
            mjHand:delMP()
            mjHand:setMP(newCard)
        else
            mjHand:setMP(newCard)
        end
    end
    
    self.mjtable:sortHands(seatNo,true)

    mjHand:updateHands()
end

-- 取消听牌操作
function CompControl:onCancelTing( event_id,event_args )

    local chairid = event_args.nSeat
    g_methods:RemoveTblItem(self.tingChairIds,chairid)
    self.huTypeInfo[chairid] = {}
    -- 对家已经听牌，则需要展示对家手牌为灰掉
    if chairid ~= jav_get_mychairid() then
        local seatNo = jav_get_localseat(chairid)
        self.mjtable:showHandGray(seatNo,false)
    end
     
    -- 手牌处理
    if chairid  == jav_get_mychairid()  then 
      --self:onRecQiOper()
        g_methods:RemoveTblItem(self.tingChairIds,jav_get_mychairid())
        g_methods:RemoveTblItem(self.chaTingCharidId,jav_get_mychairid())
        
        local mjHand = self.mjtable:getHand(0)
        if mjHand.mopai  then 
            mjHand.mopai:setFingerMark( false)
            mjHand.mopai:showMask( false)
        end

        for i = 1, #mjHand.cards do
            mjHand.cards[i].card:setFingerMark( false)
            mjHand.cards[i].card:showMask( false )
        end        
        g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
   end
end

--查听处理
function CompControl:onRecvChaTing( event_id,event_args )
    
    -- 将自己的座位添加到听牌座位号中
    local chariId = event_args.nSeat
   if not g_methods:IsInTable(self.chaTingCharidId,chariId ) then
        table.insert(self.chaTingCharidId,chariId)
    end
   
    if chariId ~= jav_get_mychairid()then
        return 
    else

    local canPlay = event_args.lstCanPlay
    local canHu = event_args.lstCanHu
    local huCardnum = event_args.lstCount
    local zmFan = event_args.lstZMFan
    local fpFan = event_args.lstFPFan

        self.tingInfos = {}
        
        local maxCard = 0
        local maxZmPT = 0                

        for i= 1, #canPlay do
        
            local cards = {}
            cards.card = canPlay[i]
            
            for j = 1, #canHu[i] do
                local points = fpFan[i][j]
                if points > zmFan[i][j] then
                    points = zmFan[i][j]
                end
                
                local card = {
                    id      = canHu[i][j],
                    count   = huCardnum[i][j],      --张数
                    points  = points,  -- 番数   
                    zmpts   = zmFan[i][j],
                    fppts   = fpFan[i][j]       
                }
                table.insert( cards, card )
                
                if zmFan[i][j] > maxZmPT then
                    maxCard = canPlay[i]
                    maxZmPT = zmFan[i][j]
                end
                
            end
            
            table.insert(self.tingInfos,cards)
            
        end
        
        -- 最大牌标记
        local mjHand = self.mjtable:getHand(0)
        local idx, cd = mjHand:query( maxCard, false )
        if cd and cd.card then
           if  event_args.bTing == true then
                cd.card:showMask( true, "#img.card_frame.png", true )
                self.tipFanCard = maxCard
           end
        end
        for idx = 1, TABLE_MAX_USER do
            self:cleanHandCardsMarks( idx-1 )
        end
        -- 准听牌标记处理
        for i= 1, #canPlay do
            local cardId  = canPlay[i]
            local idx, cd = mjHand:query( cardId, false )
            if cd and cd.card then
                if  event_args.bTing == false then
                     cd.card:setFingerMark( true, "ani.blueMark", OFFSET_MARKVER )
                end
            end
        end 
            
    end
      
    	
end


-- 听牌操作显示
function CompControl:onTingOper( event_id,event_args )

    -- 将自己的座位添加到听牌座位号中
    local chairId = event_args.nTingSeat  
    
    if not g_methods:IsInTable(self.tingChairIds,chairId ) then
        table.insert(self.tingChairIds,chairId)
    end
    
    
    if chairId ~= jav_get_mychairid()then
        return 
    end
    --锁定首牌
    g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = event_args.lstCanPlay } )
    
    self:cleanHandCardsMarks( jav_table:toSeatNo( event_args.nTingSeat ) )
      
end

-- 碰和吃的操作
function CompControl:onDoPengChiOper( event_id, event_args )

    -- 设置牌河里的操作牌为半透明
    local tSeatNo = jav_get_localseat( event_args.tChairId )
    local mjRiver = self.mjtable:getRiver( tSeatNo )
    local idx, cd = mjRiver:query( event_args.tRiverCard )
    cd.card:setBeCPG(true)
    
    -- 设置手牌的结构牌
    local mSeatNo = jav_get_localseat( event_args.mChairId )    
    local mjHand = self.mjtable:getHand( mSeatNo )
        
    -- 碰删除2牌操作    
    for i = 1, #event_args.mDelCards do        
        mjHand:pop( event_args.mDelCards[i] )        
    end
    
       
    mjHand:pop( event_args.mNewCard )
    mjHand:setMP( event_args.mNewCard )
    
    if event_args.operFlag == OPER_PENG then

        self.mjtable:pushStack( mSeatNo, STACK_MPEN, event_args.stackCards, { false, true, false }, 0.8 )

    elseif event_args.operFlag == OPER_LCHI then
    
        self.mjtable:pushStack( mSeatNo, STACK_MCHI, event_args.stackCards, { true, false, false }, 0.8 ) 
        
    elseif event_args.operFlag == OPER_MCHI then
        self.mjtable:pushStack( mSeatNo, STACK_MCHI, event_args.stackCards, { false, true, false }, 0.8 )
        
    elseif event_args.operFlag == OPER_RCHI then
    
        self.mjtable:pushStack( mSeatNo, STACK_MCHI, event_args.stackCards, { false, false, true }, 0.8 )
    end
    
    self.mjtable:sortHands(mSeatNo,true)
    mjHand:forceUpdate()
    
end

-- 直杠
function CompControl:onDoZhiGangOper(event_id,event_args)
    
    -- 设置牌河里的操作牌为半透明
    local tSeatNo = jav_get_localseat( event_args.tChairId )
    local mjRiver = self.mjtable:getRiver( tSeatNo )
    local idx, cd = mjRiver:query( event_args.tRiverCard )
    cd.card:setBeCPG(true)

    -- 设置手牌的结构牌
    local mSeatNo = jav_get_localseat( event_args.mChairId )    
    local mjHand = self.mjtable:getHand( mSeatNo )

    -- 碰删除2牌操作    
    for i = 1, #event_args.mDelCards do        
        mjHand:pop( event_args.mDelCards[i] )        
    end

    self.mjtable:pushStack( mSeatNo, STACK_GANG, event_args.stackCards, { false, true, true,false }, 0.8 )
    self.mjtable:sortHands(mSeatNo,true)
    mjHand:forceUpdate()

end

-- 面下杠(碰杠)
function CompControl:onDoPengGangOper(event_id,event_args)

    -- 设置手牌的结构牌
    local mSeatNo = jav_get_localseat( event_args.mChairId )    
    local mjHand = self.mjtable:getHand( mSeatNo )
    
    mjHand:delMP()
    
    if event_args.isMopai then
    else
        mjHand:push(event_args.newCard)
        mjHand:pop(event_args.delCard)
    end
        
    self.mjtable:resetStackByKeyId( mSeatNo, event_args.keyCard, STACK_GANG, event_args.stackCards, { false, true, true, false } )
    
    self.mjtable:sortHands(mSeatNo,true)
    mjHand:forceUpdate()
    
end

-- 暗杠
function CompControl:onDoAnGangOper(event_id,event_args)
    
    -- 设置手牌的结构牌
    local mSeatNo = jav_get_localseat( event_args.mChairId )    
    local mjHand = self.mjtable:getHand( mSeatNo )

    -- 暗杠删除牌操作    
    for i = 1, #event_args.mDelCards do        
        mjHand:pop( event_args.mDelCards[i] )        
    end    
    
    if event_args.isDealMopai then 
    else
        mjHand:delMP()
        mjHand:push(event_args.newCard)
    end

    local stackCards = event_args.stackCards
    
    -- 对家杠牌，服务器会发送牌背，只需要将自己的结构牌数据修改
    if event_args.isBlind == false then
        stackCards[1] = 99
        stackCards[2] = 99
        stackCards[4] = 99
    end 
    
    self.mjtable:pushStack( mSeatNo, STACK_GANG, stackCards, { false, true, true,false }, 0.8 )
    self.mjtable:sortHands(mSeatNo,true)
    mjHand:forceUpdate()

end

-- 左吃
function CompControl:LCHIOper(event_id,event_args)
end

-- 中吃
function CompControl:MCHIOper(event_id,event_args)
end

-- 右吃
function CompControl:RCHIOper(event_id,event_args)
end

-- 自己准备了，则清理界面
function CompControl:onUserReady(event_id,event_args)


    local chariId = jav_table:getChairId(event_args.uid) 

    if chariId == -1 then
        return 
    end

    local seatNo =  jav_table:toSeatNo( chariId )

    if seatNo == 0 then 
        if jav_isready( event_args.uid ) == true then
            self.mjtable:resetAll()
            self.newrivercard = nil     -- 牌河新牌失效   
        end
    end 
end

-- 设置当前操作玩家
function CompControl:onsetTurnChairid( event_id,event_args)

    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 0, secs = 0, total = 0 } )
    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 1, secs = 0, total = 0 } )
    self.turnChairid = event_args.nCurTurn 
    
    if g_methods:IsInTable(self.tingChairIds,jav_get_mychairid()) then
        g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = {1} } )
    else
        g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
    end
    
    local seatNo = jav_get_localseat(self.turnChairid)
    
    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = seatNo, secs = event_args.nTime , total = event_args.nTime  } )
    
end

-- 第一次操作开始
function CompControl:onFirstPlay(event_id,event_args)
    -- 初始化牌墙
    
    if self.dealTimes > #self.dealerCnts then
        g_methods:log("第一次出牌时发牌完毕")

        return
    else
       g_methods:log("第一次出牌时发牌未完毕")
        if self.dealerCBK then
            self.dealerCBK()
        end
        local scheduler = cc.Director:getInstance():getScheduler()
        if self.dealerTick then
            scheduler:unscheduleScriptEntry( self.dealerTick )
            self.dealerTick = nil
        end
    end
    self.mjtable:buildWall( function()
        end, 0, OFFSET_BUILDWALLS )

    -- 切牌墙
    if event_args.nWallDiceSum >0 then
        self:SetWallOffset(event_id,event_args)
    else     
        return    -- 尚未切排墙，不需要继续处理
    end

    -- 减牌墙
    self:onCutSetWall(event_args.nWallFrontNum,event_args.nWallTailNum)
    
    for idx = 1, TABLE_MAX_USER do
        local seatInfo = jav_table:getSeat( idx -1  )
        local  hancards = seatInfo.hand_cards
        local mjHand = self.mjtable:getHand( jav_table:toSeatNo( idx -1 ) )
         mjHand:clean()
        for i= 1,#hancards do
            mjHand:push(hancards[i])
        end
        if seatInfo.newcard and seatInfo.newcard ~= -1 then
            mjHand:setMP(seatInfo.newcard)
        end  
    end  
   
end

-- 初始化排墙
function CompControl:doMJWall(event_id,event_args)

    -- 初始化牌墙
    -- 显示骰子动画
    self.mjtable:buildWall( function()
                            end, SECS_BUILDWALLS, OFFSET_BUILDWALLS )
    
end

-- 设置切牌墙位置
function CompControl:SetWallOffset(event_id,event_args)

    -- 设置切牌墙的位置
    --计算需要切的牌墙的方位
    local wallChairid = nil
    if (event_args.nWallDiceSum %2)==0 then
        wallChairid = (jav_table.bankerseat + 1) % TABLE_MAX_USER
    else
        wallChairid = jav_table.bankerseat
    end
    
    local wallseatNo= jav_get_localseat(wallChairid)     
    
    self:buildWallmap(wallseatNo, WALL_COLCOUNT - event_args.nWallDiceSum )   
    g_methods:log( "设定牌墙起始点:%d, %d", wallseatNo, event_args.nWallDiceSum )   
    
end

-- 展示玩家手牌
function CompControl:ShowALLHandCards(event_id,event_args)

    -- 设置玩家手牌
    local cIds = {}        
    for i = 0 ,TABLE_MAX_USER-1 do 
    
        local seatInfo = jav_table:getSeat(i)
        local seat = jav_get_localseat(i)
        cIds[seat] = clone( seatInfo.hand_cards )
       
        if seatInfo.has_newcard then
            table.insert( cIds[seat], seatInfo.newcard )
        end
        
    end 
    
    -- 发手牌
    self:buildMJHands( jav_get_localseat(jav_table.bankerseat), cIds, function()
        self.mjtable:sortHands( 0, true, true, SECS_FLIPHANDS, function()
            jav_send_message( CTS_MSG_DEALCARD )
            g_methods:log( "翻牌完毕!" )
            jav_table:getSeat(jav_get_mychairid()):sortHand( true )
        end )
    end )  
end

-- 发送打牌操作
function CompControl:SendPlayCardMsg(cardid,cardidx)

    local msgArgs = { nPlayedCard = cardid, nCardIdxUI = cardidx }
    jav_send_message( CTS_MSG_PLAYCARD, msgArgs )
    g_methods:log( "发送打牌消息!" )
end

function CompControl:onPlayCard(event_id,event_args)

    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 0, secs = 0, total = 0 } )
    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = 1, secs = 0, total = 0 } )
    g_event:PostEvent(CTC_TING_TIP, {isVisible = false})

    local seatNo = event_args.seatNo
    
    local mjhand = self.mjtable:getHand(seatNo)
        
    local bTingPlay = event_args.bTingPlay
    
    -- 是牌背手牌
    if event_args.isBlindHand then
    
        self:pushRiverBlindCard(seatNo,event_args.playCardidx, event_args.playCardid,bTingPlay)
    else
        
        self:pushRiverCard(seatNo,event_args.playCardid,bTingPlay)
    end

    if event_args.isMoPai == false then
        mjhand:push(event_args.newCard)
        mjhand:delMP()
    else
        
    end
        
    self.mjtable:sortHands(seatNo,true)
    
    mjhand:updateHands()
    
    if bTingPlay then
        if event_args.chairid == jav_get_mychairid() then
            --        self.pan_hutips:close()
            g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
            self.mjtable:showHandGray(0,true)
            -- 最大牌标记
            if self.tipFanCard and self.tipFanCard ~= 0 then
                g_methods:log("CompControl:onCleanHandChoices")
                local mjHand = self.mjtable:getHand(0)
                local idx, cd = mjHand:query( self.tipFanCard, false )
                if cd and cd.card then
                    cd.card:showMask( false )
                end
                self.tipFanCard = 0
            end

            g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = {1} } ) 
        else   -- 两个人都听牌了，则重新设置牌灰色态
            if #self.tingChairIds == 2 then 
                self.mjtable:showHandGray(1,true)
            end
        end
    end
    
    self:focusRiverCards( 0, false )
    
    --播放停牌动画
    if bTingPlay then 
         local node = display.newNode()
         self.ui_layer:addChild(node)
         node.chairid = event_args.chairid
         node:runAction(
         
         cc.Sequence:create(
            cc.DelayTime:create(0.15),
            cc.CallFunc:create(function(sender, param)
                        g_event:PostEvent(CTC_PLAY_TINGANIM, {bCutReturn = false, nTingSeat = sender.chairid})
            
            end
            ),
            cc.RemoveSelf:create()
         )
         )
    end
    
    
    if g_methods:IsInTable(self.chaTingCharidId, event_args.chairid)   then
         g_methods:RemoveTblItem( self.chaTingCharidId, event_args.chairid )
    end
    
    if not g_methods:IsInTable(self.tingChairIds, jav_get_mychairid())   then
        g_methods:log("onPlayCard")
         g_event:PostEvent( CTC_FRESH_FANTIP, { moPt = 0, dnPt = 0 } )
    end
    
    self:cleanHandCardsMarks( jav_table:toSeatNo( event_args.chairid ) )
end

-- 展示新牌
function CompControl:onshowNewCard( event_id,event_args )
    
    local seatNo = event_args.seatNo
    local newcardid = event_args.newCard  
         
    if event_args.bReverse then 
        local cd = self:popWallFromMapBack()
        self.mjtable:mpFromWall( seatNo, newcardid, cd.wall, cd.idx, function( seatNo )
            g_audio:PlaySound("fapai.mp3")
            g_methods:log( "摸牌完毕!" ) 
        end ) 
    else
        local cd = self:popWallFromMapFront()
        self.mjtable:mpFromWall( seatNo, newcardid, cd.wall, cd.idx, function( seatNo )
            g_audio:PlaySound("fapai.mp3")
            g_methods:log( "摸牌完毕!" ) 
        end )
    end
    
    for i=1,#self.tingChairIds do
        if self.tingChairIds[i] == jav_get_mychairid() then
            g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = { newcardid } })
            break
        end
    end

end


-- 创建牌墙映射表
function CompControl:buildWallmap( startSeatNo, startWallCols )
    
    -- 牌墙起始跺数不能大于WALL_COLCOUNT跺
    if startWallCols < 1 or startWallCols > WALL_COLCOUNT then
        g_methods:error( "牌墙起始跺数非法:%d, %d", startSeatNo, startWallCols )
        return false
    end
    
    local orderNos = { 0, 1 }
    if startSeatNo == 1 then
        orderNos = { 1, 0 }
    end
    
    self.wallmap = {}
        
    -- 分三部分统计牌墙
    if startWallCols > 1 then
        for i = startWallCols, 1, -1 do
            table.insert( self.wallmap, { wall = orderNos[1], idx = i * 2 } )
            table.insert( self.wallmap, { wall = orderNos[1], idx = i * 2 - 1 } )
        end
    end

    for i = WALL_COLCOUNT, 1, -1 do
        table.insert( self.wallmap, { wall = orderNos[2], idx = i * 2 } )
        table.insert( self.wallmap, { wall = orderNos[2], idx = i * 2 - 1 } )
    end

    if startWallCols < WALL_COLCOUNT then
        for i = WALL_COLCOUNT, startWallCols + 1, -1 do 
            table.insert( self.wallmap, { wall = orderNos[1], idx = i * 2 } )
            table.insert( self.wallmap, { wall = orderNos[1], idx = i * 2 - 1 } )
        end
    end
    
    -- 判断映射表大小
    if #self.wallmap ~= WALL_CARDCOUNT then
        g_methods:error( "组件牌墙映射表失败!" )
        return false
    end
    
    return true
    
end

-- 从牌墙正序弹出一张牌
function CompControl:popWallFromMapFront( steps )

    if #self.wallmap == 0 then
        g_methods:error( "弹出牌墙牌失败!" )
        return nil
    end
    
    if steps == nil then
        steps = 0
    end
    
    local idx = steps + 1
    if idx > #self.wallmap then
        g_methods:error( "弹出牌墙牌失败!步长位置为空!%d", steps )
        return nil
    end 
    
    local item = self.wallmap[idx]
    table.remove( self.wallmap, idx )
    return item
    
end

-- 从牌墙逆序弹出一张
function CompControl:popWallFromMapBack()

    if #self.wallmap == 0 then
        g_methods:error( "弹出牌墙牌失败!" )
        return nil
    end

    -- 如果尾部第一张是奇数序列,判断第二张是不是偶数
    local item1 = self.wallmap[#self.wallmap]
    if item1.idx % 2 == 1 and #self.wallmap > 1 then
        local item2 = self.wallmap[#self.wallmap-1]
        -- 如果是偶数,那么先弹出偶数
        if item2.idx % 2 == 0 then
            table.remove( self.wallmap, #self.wallmap - 1 )
            return item2
        end
    end
    
    table.remove( self.wallmap, #self.wallmap )
    return item1

end

-- 初始化手牌
-- fromSeatNo:庄家的本地位置
-- handIds：玩家手牌，第一个必须为庄家的牌
function CompControl:buildMJHands( fromSeatNo, handIds, callback )
    
    if #self.wallmap == 0 then
        g_methods:error( "初始化手牌失败,需要先建立牌墙映射表!" )
        return false
    end

    local seatNos = { 0, 1 }
    if  fromSeatNo == 1 then
        seatNos = { 1, 0 }
    end 

    if #handIds[seatNos[1]] ~= BANKER_INITCARDS or #handIds[seatNos[2]] ~= OTHER_INITCARDS then
        g_methods:error( "初始化手牌失败,庄家需要14张牌,闲家13张!" )
        return false
    end
    
    self.dealerCBK  = callback
    self.dealNos    = { 1, 1 }
    self.dealTimes  = 1
    self.dealerCnts = { 4, 4, 4, 4, 4, 4, 1, 1 }

    local scheduler = cc.Director:getInstance():getScheduler()
    local dealerOneTime = function( dt )
        if self.dealTimes > #self.dealerCnts then
            if self.dealerCBK then
                self.dealerCBK()
            end
            scheduler:unscheduleScriptEntry( self.dealerTick )
            self.dealerTick = nil
            return
        end

        local idx  = seatNos[(self.dealTimes - 1 ) % #seatNos + 1]
        local hand = self.mjtable:getHand( idx )

        for i = 1, self.dealerCnts[self.dealTimes] do
            g_audio:PlaySound("fapai.mp3")
            local item = self:popWallFromMapFront()
            local wall = self.mjtable:getWall( item.wall )
            wall:pop( item.idx, cc.p( 0, 20 ), 0.1, true )

            local cards = handIds[idx]
            local cardId = cards[self.dealNos[idx+1]]
            
            hand:push( cardId, cc.p( 0, 20 ), 0.1 + ((i-1)*0.05), true )

            self.dealNos[idx+1] = self.dealNos[idx+1] + 1

            -- 特殊处理:庄家最后一把跳牌抓2张
            if self.dealTimes == 7 then

                local item = self:popWallFromMapFront(1)
                local wall = self.mjtable:getWall( item.wall )
                wall:pop( item.idx, cc.p( 0, 20 ), 0.1, true )

                local cards = handIds[idx]
                local cardId = cards[self.dealNos[idx+1]]
                hand:setMP( cardId, cc.p( 0, 20 ), 0.1, true )

                self.dealNos[idx+1] = self.dealNos[idx+1] + 1

            end
            
        end

        self.dealTimes = self.dealTimes + 1

    end

    self.dealerTick = scheduler:scheduleScriptFunc( dealerOneTime, 0.2, false )
    dealerOneTime()
        
    return true
    
end

-- 重置手牌(仅手牌,不包含摸牌和牌堆)
function CompControl:rebuildMJHands( seatNo, cardIds, callback, orderUP, needFlip )

    local mjHand = self.mjtable:getHand(0)
    if mjHand == nil then
        g_methods:error( "重置手牌失败,无效的位置:%d", seatNo )
        return false
    end

end

-- 选牌模式事件
function CompControl:onSetHandChoices( event_id, event_args ) 
    self:openOperChoose( true, event_args.cardlst ) 
end
function CompControl:onCleanHandChoices( event_id, event_args )
    self:openOperChoose( false, {} )

   
end
        
-- 开启/关闭选牌模式
function CompControl:openOperChoose( open, cardList )

    self.opchoose = open    
    self.opcards  = cardList     
    
    local mjHand = self.mjtable:getHand(0)    
    if open== true then
        mjHand:updateHands( false )
    end
    
    local canChoose = function( tbl, id )
        for _, card in pairs( tbl ) do
            if card == id then
                return true
            end
        end
        return false 
    end
    
    -- 手牌处理
    for i = 1, #mjHand.cards do
    
        local card = mjHand.cards[i]
        if self.opchoose == false or canChoose( cardList, card.id ) == true then
            card.card:setColor( COLOR_NORMAL )
        else
            card.card:setColor( COLOR_DISABLED )
        end
        
    end
    
    -- 摸牌处理
    local mp = mjHand:getMP()
    if mp then

        if self.opchoose == false or canChoose( cardList, mp.id ) == true then
            mp:setColor( COLOR_NORMAL )
        else
            mp:setColor( COLOR_DISABLED )
        end
        
    end
    
end

function CompControl:pushRiverCard( seatNo, id, putHor )
    
    self.mjtable:pushToRiver( seatNo, id, putHor, function( seatNo, newCard, putHor )
        g_audio:PlaySound("chupai.mp3")
        if self.newrivercard == nil then
        
        else
            self.newrivercard:setFingerMark( false )
            self.newrivercard:showMask( false )
        end
        g_methods:log( "手牌入牌河完毕!" )  
        
        if newCard then
        
            self.newrivercard = newCard
            
            if putHor == true then
                newCard:setFingerMark( true, "ani.blueStone", OFFSET_STONEHOR )
                newCard:showMask( true, "#img.redmask2.png", true )
            else
                newCard:setFingerMark( true, "ani.blueStone", OFFSET_STONEVER )
                newCard:showMask( true, "#img.redmask1.png", true )
            end
        end
        
    end )
    
end

function CompControl:pushRiverBlindCard( seatNo, idx, id, putHor )
    
    self.mjtable:pushToRiverBlind( seatNo, idx, id, putHor, function( seatNo, newCard )
        g_audio:PlaySound("chupai.mp3")
        g_methods:log( "背牌打入牌河完毕!" )
        if self.newrivercard == nil then
        else
            self.newrivercard:setFingerMark( false )
            self.newrivercard:showMask( false )
        end
        
        if newCard then
        
            self.newrivercard = newCard
            
            if putHor == true then
                newCard:setFingerMark( true, "ani.blueStone", OFFSET_STONEHOR )
                newCard:showMask( true, "#img.redmask2.png", true )
            else
                newCard:setFingerMark( true, "ani.blueStone", OFFSET_STONEVER )
                newCard:showMask( true, "#img.redmask1.png", true )
            end
        end
        
    end )

end

-- 聚焦一类牌
function CompControl:focusRiverCards( ctp, focused )

    for i = 0, TABLE_MAX_USER - 1 do
    
        local river = self.mjtable:getRiver(i)
        for idx = 1, #river.cards do
        
            local temp = river.cards[idx]
            local ttp = getCardTypePoint( temp.id )
            temp.card:setBlink( ctp == ttp and focused )
        end
    end
    
end

-- 手牌事件通告
function CompControl:onMJHandCallback( hand, event, id )
    
    local myHand = self.mjtable:getHand(0)
    if myHand ~= hand or jav_table.gamestage ~= STATE_PLAYCARD then
        return
    end

    -- 是否可以操作
    if self.opchoose == true and #self.opcards > 0 then

        -- 手牌可操作判定
        local canChoose = false
        for _, card in pairs( self.opcards ) do
            if card == id then
                canChoose = true
                break
            end
        end 

        if canChoose == false then            
            return 
        end

    end

    local idx, card = hand:query( id )
    if card and card.card then
    
        if event == "focus" or event == "unfocus" then
            self:focusRiverCards( getCardTypePoint( id ), event == "focus" )
                        
            if event == "focus" then
                g_audio:PlaySound("tiaopai.mp3")
                card.card:setPositionY( OFFSET_CARDFOCUSED )
                if g_methods:IsInTable(self.chaTingCharidId, jav_get_mychairid())then
                    self.pan_hutips:close( )
                    for i=1,#self.tingInfos do
                        if self.tingInfos[i].card == card.card.id then
                            self.pan_hutips:show( 0, self.tingInfos[i] )
                            local maxMoPt = 0;
                            local maxFpPt = 0;

                            for j = 1, #self.tingInfos[i] do
                                local info = self.tingInfos[i][j]  
                                if maxMoPt < info.zmpts then
                                    maxMoPt = info.zmpts
                                end
                                if maxFpPt < info.points then
                                    maxFpPt = info.points
                                end
                            end
                            
                            if g_methods:IsInTable(self.tingChairIds,jav_get_mychairid()) then
                                g_methods:log("onMJHandCallback1111")

                                g_event:PostEvent( CTC_FRESH_FANTIP, { moPt = maxMoPt, dnPt = maxFpPt } )
                            end
                            
                            break
                        end
                    end           
                else
                    if not g_methods:IsInTable(self.tingChairIds,jav_get_mychairid()) then
                        g_event:PostEvent( CTC_FRESH_FANTIP, { moPt = 0, dnPt = 0 } )
                    end
                end         
            else 
                card.card:setPositionY( 0 )
                if g_methods:IsInTable(self.tingChairIds,jav_get_mychairid()) then
                    self.pan_hutips:close()
                    if jav_table.bTingPai == false then
                        g_methods:log("onMJHandCallback3333")

                        g_event:PostEvent( CTC_FRESH_FANTIP, { moPt = 0, dnPt = 0 } )
                    end
                end
            end
            
        end
        
        if card and card.card and event == "click" then
    
            -- 只处理当前操作玩家是自己
            if self.turnChairid == jav_get_mychairid() then
                local idx, acard = myHand:query( id )
                if not idx or not acard then
                    return
                end
                local mopai = myHand:getMP()
                if mopai == acard.card then
                    idx = -1
                end
                self:SendPlayCardMsg( id,idx )
                self:focusRiverCards( 0, false )
            else
            end
        end
    
    end

end

-- 牌河事件通告
function CompControl:onMJRiverCallback( river, event, id )
    
    if event == "focus" or event == "unfocus" then
        self:focusRiverCards( getCardTypePoint( id ), event == "focus" )
    end
end


--清除首牌Mask 
function CompControl:cleanHandCardsMarks( seatNo )
    local mjHand = self.mjtable:getHand( seatNo )
    if mjHand:getMP() then
        local cd  = mjHand:getMP()  
        cd:setFingerMark( false )
    end
    
    for _, cd in pairs( mjHand.cards ) do 
        cd.card:setFingerMark( false )
    end
end


return CompControl
