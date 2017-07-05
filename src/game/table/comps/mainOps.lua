-- onShowOperPanel.lua
-- 2016-02-24
-- 
-- 处理基本的打牌操作，包括吃，碰，杠，听，胡等

local BaseObject = require( "kernels.object" )
local CompOperators = class(  "CompOperators", BaseObject )
local OperPanel = require( "game.table.nodes.stackOps" )
local EatSelect = require( "game.table.nodes.eatSelect" )
local GangSelect = require( "game.table.nodes.gangSelect" )
local SpineButton = require( "kernels.node.nodeSpineButton" )
local MsgBox = require( "game.table.nodes.msgbox" )




-- 激活
function CompOperators:Actived()

    CompOperators.super.Actived( self )  
    
    self.seatNo = -1   -- 当前操作的玩家座位号
    self.btntype = ""   -- 记录当前的已经click的按钮

    -- 界面绑定
    self.ui_layer = self.bind_scene:FindRoot():getChildByName( "ui_layer" )
    self.lay_node = self.bind_scene:FindRoot():getChildByName( "mj_layer" )
    local center_node = self.lay_node:getChildByName( "center" )
    --换背景
    self.pan_changebg =  self.ui_layer:getChildByName( "pan_changebg" )
    self.btn_changebg = g_methods:ButtonClicked( 
        self.ui_layer, 
        "btn_changebg", 
        function( sender, params ) 
            self.pan_changebg:setVisible(not self.pan_changebg:isVisible())
        end )
        
    self.pan_changebg:openMouseTouch(true,
        {
            onMouseTouchDown = function ( btn, localPos )
            	
            end,
        
            onMouseTouchUp = function ( btn, localPos )
                if not self.pan_changebg:isPickup( localPos ) and not self.btn_changebg:hitTest( localPos )then
                    self.pan_changebg:setVisible( false )
                end
            end
        }
    
    
    
    
    
    )
    g_save.configs.system.nBg =  g_save.configs.system.nBg or 1
    self:onChangeBg( g_save.configs.system.nBg )
    for idx = 1, #BG_CFG do 
        
        g_methods:ButtonClicked( 
            self.pan_changebg, 
            "btn_bg_"..idx, 
            function( sender, args ) 
                    local name = sender:getName()
                    for idx = 1, #BG_CFG do 
                        if "btn_bg_"..idx == name then
                              self:onChangeBg(idx)
                              g_save.configs.system.nBg = idx
                              break
                        end
                    end
            end )
    end
    
    g_methods:ButtonClicked( 
            self.ui_layer, 
            "btn_box", 
            function( sender, args ) 
                local msg = { key = "cmd", context = "reqStateMsgNavigateGameActivity" }
                jav_room.main_connect:SendFrameMsg( json.encode( msg ) ) 
            end )
    -- 吃牌提示面板
    local eatPanel = self.lay_node:getChildByName( "pan_chis" )
    self.eat_select = EatSelect.new( eatPanel, handler( self, self.onEatSelectCallback ) ) 

    -- 杠牌提示面板
    local gangPanel = self.lay_node:getChildByName( "pan_gangs" )
    self.gang_select = GangSelect.new( gangPanel, handler( self, self.onGangSelectCallback ) ) 
    
    -- 吃碰杠操作面板    
    local pan_opers = self.lay_node:getChildByName( "pan_opers" )
    self.pan_opers = OperPanel.new( pan_opers, handler( self, self.onOperPanelCallback ) )
  ---  self.pan_opers:Show( OPER_PENG_GANG )
  
    --弹出框
    local pan_msgbox = self.bind_scene:FindRoot():getChildByName( "pan_msgbox" )
    self.pan_msgbox = MsgBox.new( pan_msgbox )
        
    self.pan_fanTip = self.ui_layer:getChildByName( "pan_faninfo" )
    self.pan_fanTip:setVisible( false )
    
    self.pan_selectHuDouble = self.ui_layer:getChildByName( "pan_selectHuDouble" )
    self.pan_selectHuDoubleBg = self.pan_selectHuDouble:getChildByName( "pan_bg" )

    -- 胡牌加倍选择框
    self.pan_huDouble = self.ui_layer:getChildByName( "pan_huDouble" )  
    self.pan_huDoubleBg = self.pan_huDouble:getChildByName( "pan_bg" )

    g_methods:ButtonClicked(    self.pan_huDoubleBg, 
                                "btn_he",     
                                function ( sender, args )
                                    g_audio:PlaySound("anniu.mp3")
                                    jav_send_message( CTS_MSG_HUDOUBLE, { nOper = OPER_HU } )
        end )

    g_methods:ButtonClicked(    self.pan_huDoubleBg, 
                                "btn_add",  
                                function ( sender, args )
                                    g_audio:PlaySound("anniu.mp3")
                                    jav_send_message( CTS_MSG_HUDOUBLE, { nOper = OPER_DOUBLE } )
                                end )
    
    -- 托管相关
    self.lay_trust = self.bind_scene:FindRoot():getChildByName( "pan_trust" )
--    self.btn_trust = g_methods:ButtonClicked( 
--                                self.ui_layer, 
--                                "btn_trust", 
--                                function( sender, args ) 
--                                    g_audio:PlaySound("anniu.mp3")
--                                    jav_send_message( CTS_MSG_TRUST, { bTrust = true } )
--                                end )
                                
    g_methods:ButtonClicked(    self.lay_trust, 
                                "btn_cancel",  
                                function ( sender, args )
                                    g_audio:PlaySound("anniu.mp3")
                                    jav_send_message( CTS_MSG_TRUST, { bTrust = false } )
                                end )                                  

    -- 游戏开始
    local nod = self.bind_scene:FindRoot():getChildByName( "mj_layer" )
    local cen = nod:getChildByName( "center" )
    self.pan_start =  cen:getChildByName( "pan_start" )
    local size =  self.pan_start:getContentSize()
    self.btn_start = SpineButton.new("kaishi","kaishi", 
            function( sender, btnState )
            if btnState == "pressedUp" then
                g_audio:PlaySound("anniu.mp3")
                self.btn_start:SetTouchEnabled( false )
                jav_ready()
            end
         end
      )
    self.btn_start:SetContentSize(size.width,  size.height)
    self.pan_start:addChild( self.btn_start )
    self.pan_start:setVisible( false )

    -- 消息监听列表
    self.msg_hookers = {                 
        { E_CLIENT_ICOMEIN,         handler( self, self.onRecvSefComin ) },
        { E_CLIENT_USERREADY,       handler( self, self.onUserReady ) },        
        { CTC_TIMERPROG_TIMEOUT,    handler( self, self.OnOperTimeout )},
        { CTC_PLAYCARD,             handler( self, self.OnPlayCard )},
        { CTC_MSG_OPER,             handler( self, self.onShowOperPanel)},
        { STC_MSG_SELECTHU,         handler( self, self.OnRecSelectHu)},
        { CTE_SHOW_MSGBOX,          handler( self, self.OnShowMsgBox)},
        { STC_MSG_GAMEEND,          handler( self, self.OnRecGameEnd )},
        { E_CLIEN_GAMEBEGIN,        handler( self, self.OnGameBegin ) },
        { STC_MSG_HUDOUBLE,         handler( self, self.OnRecHuDouble )},
        { STC_MSG_TRUST,            handler( self, self.OnRecTrustFresh )},
        { STC_MSG_TURN,             handler( self, self.onsetTurnChairid)},
        { STC_MSG_CUTRETURN,        handler( self, self.onCuttReturn)},     -- 处理掉线重入消息
        { STC_SHOW_TOTALSCORE,      handler( self, self.onShowTotalScore )},   
        { CTC_FRESH_FANTIP,         handler( self, self.onFreshFanTip ) },   
        { CTC_TING_TIP,             handler( self, self.onOpenTingTip)}
    }
    g_event:AddListeners( self.msg_hookers, "CompOperators_events" )

    return true

end

-- 反激活
function CompOperators:InActived()

    -- 事件监听注销
    g_event:DelListenersByTag( "CompOperators_events" )
    CompOperators.super.InActived( self )
    
end

--如果收到掉线重入消息，则关闭开始按钮，避免在游戏结束的临界点掉线回来，可以看到开始按钮
function CompOperators:onCuttReturn(event_id,event_args)
    self.pan_start:setVisible( false )
    self.btn_start:SetTouchEnabled( false )
end

function CompOperators:onsetTurnChairid( event_id,event_args )
    self.eat_select:close()
    self.gang_select:close()
    self.pan_opers:Close()
end

-- 显示总输赢
function CompOperators:onShowTotalScore( event_id, event_args )

    self.pan_fanTip:setVisible( event_args.bShow )
    
    local wins = self.pan_fanTip:getChildByName( "num_allwin" )
    local strBaseScore  = tostring( jav_table.basescore ) 
    local len = string.len(strBaseScore)   
    local bitNum  = 0 
    if len == 2 then
        bitNum = 3
    elseif len == 3 then
       bitNum =2
    elseif len == 4 then
       bitNum = 1
    elseif len == 5 then
       bitNum = 0
    end

    if math.abs(event_args.nTotalScore)  > 10000 then
        local str = string.format("%d",bitNum)
        wins:setString( string.format("%.0"..str.."f万", event_args.nTotalScore/10000)  )
    else
        wins:setString( tostring( event_args.nTotalScore ) )
    end
    if event_args.nTotalScore > 0 then
        wins:setColor( cc.c3b( 242, 242, 63 ) )
    else
        wins:setColor( cc.c3b( 255, 71, 41 ) )
    end

    local numMF = self.pan_fanTip:getChildByName( "num_zm" )
    numMF:setString( "0" )

    local numDP = self.pan_fanTip:getChildByName( "num_dpao" ) 
    numDP:setString( "0" )
    
end

-- 刷新胡牌番数提示
function CompOperators:onFreshFanTip( event_id, event_args )

    local numMF = self.pan_fanTip:getChildByName( "num_zm" )
    numMF:setString( tostring( event_args.moPt ) )

    local numDP = self.pan_fanTip:getChildByName( "num_dpao" ) 
    numDP:setString( tostring( event_args.dnPt ) )
    
end

--底层服务开始
function CompOperators:OnGameBegin(  event_id,event_args )
    self.pan_start:setVisible( false )
    self.btn_start:SetTouchEnabled( false )
end

-- 托管通告
function CompOperators:OnRecTrustFresh( event_id,event_args )
    
    if jav_iswatcher( jav_self_uid ) then
        return 
    end
    
    local seatNo = jav_get_localseat( event_args.nSeat )
    
    if seatNo == 0 then

        local btrust = event_args.bTrust
        self.lay_trust:setVisible( btrust )
        self.lay_trust:openMouseTouch( btrust, nil, false, true )
        
    end
    
end

function CompOperators:OnRecSelectHu( event_id, event_args )
    
     if jav_iswatcher( jav_self_uid ) then
        return
     end

    if event_args.nHuSeat == jav_get_mychairid() then
    
        self.pan_huDouble:setVisible(true) 
        self.pan_huDouble:openMouseTouch( true, nil, true, true )
        self.pan_selectHuDouble:setVisible(false) 
        self.pan_selectHuDouble:openMouseTouch( false, nil, true, true )

        local lbl_money = self.pan_huDoubleBg:getChildByName("lbl_money")
        lbl_money:setString(event_args.nHuMoney )
        local lbl_totalfan = self.pan_huDoubleBg:getChildByName("lbl_totalfan")
        local strTotalDouble = string.format( g_library:QueryConfig("text.totalDouble"), event_args.nHuFan )
        
        local btn_he = self.pan_huDoubleBg:getChildByName("btn_he")
        btn_he:removeChildByName("effect")
        
        local btn_add = self.pan_huDoubleBg:getChildByName("btn_add")
        btn_add:removeChildByName("effect")  
        if event_args.bCanHu  == false then
            strTotalDouble = string.format(g_library:QueryConfig("text.totalDouble_2"), jav_table.nMinFan)
        else
            if event_args.bClearOpponent  == true then
                strTotalDouble = g_library:QueryConfig("text.totalDouble_1")
            end
        end
        --和动画
       if event_args.bCanHu  == true then
            local anim = sp.SkeletonAnimation:create( "hepai_anniu.json", "hepai_anniu.atlas", 1.0 )
            anim:setName("effect")
            btn_he:addChild( anim )
            local size = btn_he:getContentSize()
            anim:setPosition( size.width / 2, size.height / 2 )
            anim:setAnimation( 0, "start", true ) 
            g_methods:WidgetDisable( btn_he, false)

       else
            g_methods:WidgetDisable( btn_he, true)
       
       end
        
        --加倍动画
        anim = sp.SkeletonAnimation:create( "jiabei_anniu.json", "jiabei_anniu.atlas", 1.0 )
        anim:setName("effect")
        btn_add:addChild( anim )
        local size = btn_add:getContentSize()
        anim:setPosition( size.width / 2, size.height / 2 )
        anim:setAnimation( 0, "start", true ) 
        
        lbl_totalfan:setString(strTotalDouble)
        --  text.totalDouble
        self.pan_huDoubleBg:updateSizeAndPosition()
        
    else
    
        self.pan_selectHuDouble:setVisible(true) 
        self.pan_selectHuDouble:openMouseTouch( true, nil, true, true )
        self.pan_huDouble:setVisible(false)
        self.pan_huDouble:openMouseTouch( false, nil, true, true )

        local pan_money = self.pan_selectHuDoubleBg:getChildByName("pan_money")
        local lbl_money = pan_money:getChildByName("lbl_money")
        lbl_money:setString(event_args.nDoubleHuMoney )
        pan_money:updateSizeAndPosition()
        self.pan_selectHuDoubleBg:updateSizeAndPosition()
	end
end

function CompOperators:OnRecGameEnd(event_id,event_args)

    self.pan_huDouble:setVisible( false ) 
    self.pan_selectHuDouble:setVisible(false) 
    self.pan_huDouble:openMouseTouch( false, nil, true, true )
    self.pan_selectHuDouble:openMouseTouch( false, nil, true, true )

    if self.lay_trust:isVisible() then
        self.lay_trust:setVisible( false )
        self.lay_trust:openMouseTouch( false, nil, true )
    end
    
    -- 清理按钮操作界面
    self.eat_select:close()
    self.gang_select:close()
    self.pan_opers:Close()
    
end

function CompOperators:onShowOperPanel(event_id,event_args)

    self.curOpers = clone( event_args )
    
    self.btntype = ""     -- 重新设置按钮的click
    
    local seatNo = jav_get_localseat( event_args.nOperSeat )
    self.seatNo = seatNo
--    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = seatNo, secs = event_args.nTime, total = event_args.nTime } )
            
	if event_args.nOperSeat == jav_get_mychairid() then
        self.pan_opers:Show(event_args.nOper)
        if operCanTing( event_args.nOper ) then
            g_save.configs.system.ting = g_save.configs.system.ting or 0
            g_save.configs.system.ting =  g_save.configs.system.ting + 1
            if g_save.configs.system.ting <= 3 then 
                local pan_tingTip  = self.lay_node:getChildByName("pan_tingtip")
                pan_tingTip:setVisible( true )
                local params =pan_tingTip:getLayoutParameter()
                g_methods:log(string.format("操作按钮：%d", #self.pan_opers.lstItemNodes))
                params:setMargin( { left = -135 + (5 -(#self.pan_opers.lstItemNodes))*100 } )
                self.lay_node:updateSizeAndPosition()
                pan_tingTip:runAction( cc.Sequence:create(cc.DelayTime:create(5), cc.CallFunc:create(function( sender, params )
                    sender:setVisible( false )
                end
                )))
            else
                g_save.configs.system.ting =  3
            end
        end
        
	end
	
end

-- 玩家坐下
function CompOperators:onRecvSefComin( event_id, event_args )

    if event_args.uid == jav_self_uid then
    
        if  jav_isready( jav_self_uid ) == false and
            jav_isplaying( jav_self_uid ) == false then
             self.pan_start:setVisible( true )
            self.btn_start:SetTouchEnabled( true )
        else
             self.pan_start:setVisible( false )
            self.btn_start:SetTouchEnabled( false )
        end
        
    end
    
end

-- 玩家准备
function CompOperators:onUserReady( event_id, event_args )
    --jav_table
    local chariId = jav_table:getChairId(event_args.uid) 
      
    if chariId == -1 then
        return 
    end
    
    local seatNo =  jav_table:toSeatNo( chariId )
    
    if seatNo == 0 then 
        if jav_isready( event_args.uid ) == true then
            self.pan_start:setVisible( false )
            self.btn_start:SetTouchEnabled( false )
        end
    end
   
    
end

--操作超时
function CompOperators:OnOperTimeout( event_id,event_args )
	
    if self.pan_opers:isShow() and event_args.seatNo == 0 then
        self.eat_select:close()
        self.gang_select:close()
        self.pan_opers:Close()
        g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
	end
	
end

--玩家出牌结果
function CompOperators:OnPlayCard( event_id,event_args )

    self:OnOperTimeout( "", { seatNo = event_args.seatNo } )
    
end

--收到加倍消息
function CompOperators:OnRecHuDouble( event_id, event_args )

    if jav_iswatcher( jav_self_uid )  then
        return
    end
    
    if event_args.nDoubleSeat == jav_get_mychairid() then
        g_event:PostEvent( CTC_OPER_DOUBLESHOW, { seatNo = jav_get_localseat(event_args.nDoubleSeat), times =  event_args.nCount} )
    end
    local chairid = event_args.nDoubleSeat
  --  if chairid == jav_get_mychairid() then
    local time = event_args.nCount
    local sex = jav_get_chairsex(chairid)
    local audio = string.format(ADD_AUDIO,sex,time)
    g_audio:PlaySound(audio)
    --end
    
	self.pan_huDouble:setVisible( false ) 
    self.pan_selectHuDouble:setVisible(false) 
    self.pan_huDouble:openMouseTouch( false, nil, true, true )
    self.pan_selectHuDouble:openMouseTouch( false, nil, true, true )
    
end
-- 获得新牌
function CompOperators:getNewCard(event_id,event_args)
	
end

-- 吃牌选择回调
function CompOperators:onEatSelectCallback( index )

    g_methods:debug( "吃牌选择:%d", index )    
    local msgArgs = { nOper = OPER_CHI, lstOperCards = self.curOpers.lstChiCards[index] }
    jav_send_message( CTS_MSG_OPER, msgArgs )
    g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
    self.eat_select:close()
    self.pan_opers:Close()
    
    --听提示隐藏
    g_event:PostEvent(CTC_TING_TIP, {isVisible = false})
    
    --去掉已操作玩家的超时
--    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = self.seatNo, secs = 0, total = 0 } )
    
end

-- 杠牌选择回调
function CompOperators:onGangSelectCallback( index )

    g_methods:debug( "杠牌选择:%d", index ) 
    local msgArgs = { nOper = OPER_GANG, lstOperCards = self.curOpers.lstGangCards[index] }
    jav_send_message( CTS_MSG_OPER, msgArgs )
    g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
    self.gang_select:close()
    self.pan_opers:Close()
    
    --去掉已操作玩家的超时
--    g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = self.seatNo, secs = 0, total = 0 } )
    
end

--弹出框回调
function CompOperators:onMsgBoxPanelCallback( btnType )
	
end

function CompOperators:OnShowMsgBox( event_id, event_args )
    self.pan_msgbox:DoModal( "", g_library:QueryConfig("text.exitgame_request"), {"yes", "no"}, function( btnType ) 
           self.pan_msgbox:Close()
            if btnType == "yes" then
                jav_leftroom()
                g_methods:CreateOnceCallback( 0.5, function()
                    app:exit() 
                end )
            end
    end
    ) 
end

-- 操作面板返回
function CompOperators:onOperPanelCallback( btnType, event )
    
    g_methods:log( string.format("操作类型：%s %s", btnType, event ) )
    
    local lstCards = {}
    if btnType == "chi" then
        lstCards = self.curOpers.lstChiCards 
    elseif btnType == "peng" then
        lstCards = self.curOpers.lstPengCards
    elseif btnType == "gang" then
        lstCards = self.curOpers.lstGangCards  
    end 
    
--    if event=="click" then
--        --需要增加一个全按钮重置
--        self.pan_opers:setAllItemNormal()
--        -- 设置需要的按钮状态（设置按钮为透明态）
--        self.pan_opers:setClarity(btnType)
--    end
    
    -- 如果有是选卡操作
    if #lstCards > 0 then
    
        -- 处理悬停明暗切换
        if event == "focused" or event == "unfocused" then     
            if event == "focused" then
                if #lstCards == 1 then    -- 只有一个组才显示，多组不显示
                    g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = lstCards[1] } )
                end
            else
                    g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
                     
                    if jav_table.tingSrvData then
                        g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = jav_table.tingSrvData.lstCanPlay } )
                    end
            end
        end        
        
        -- 处理点击事件
        if event == "click" then
            g_audio:PlaySound("anniu.mp3")
            -- 没得选,只有一组时候
            if #lstCards == 1 then
            
                if btnType == "chi" then 
                    jav_send_message( CTS_MSG_OPER, { nOper = OPER_CHI } ) 
                    self.pan_opers:Close()      
                elseif btnType == "peng" then   
                    jav_send_message( CTS_MSG_OPER, { nOper = OPER_PENG } )   
                    self.pan_opers:Close()                    
                elseif btnType == "gang" then
                    jav_send_message( CTS_MSG_OPER, { nOper = OPER_GANG } ) 
                    self.pan_opers:Close()
                end
                
                --去掉已操作玩家的超时
           --     g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = self.seatNo, secs = 0, total = 0 } )
                
                g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
            
            -- 有的选的情况    
            else

                if btnType == "chi" then 
                    jav_send_message( CTS_MSG_OPER, { nOper = OPER_CHI } )
                    self.gang_select:close()
                    self.eat_select:show( lstCards, #lstCards )                           
                elseif btnType == "gang" then
                    jav_send_message( CTS_MSG_OPER, { nOper = OPER_GANG } ) 
                    self.eat_select:close()
                    self.gang_select:show( lstCards, #lstCards )
                end
                
            end
                
        end
            
    else
    
        -- 非选卡操作处理点击事件,比如停,弃牌
        if event == "click" then
            g_audio:PlaySound("anniu.mp3")
            if btnType == "ting"  then
                jav_send_message( CTS_MSG_OPER, { nOper = OPER_TING } )
                self.pan_opers:DeleteItem(btnType)
            elseif btnType == "qi" then
                jav_send_message( CTS_MSG_OPER, { nOper = OPER_CANCEL } )
                g_event:PostEvent(CTC_OPER_QI)
                g_event:PostEvent(CTC_TING_TIP, {isVisible = false})
                self.pan_opers:Close()
            end  
            self.eat_select:close()
            self.gang_select:close()
            
            --去掉已操作玩家的超时
  --          g_event:PostEvent( CTC_TIMERPROG_RESET, { seatNo = self.seatNo, secs = 0, total = 0 } )
            
            g_event:PostEvent( CTC_HANDCARDS_DELCHOOSE )
        end
    
    end
    
 end
 
 --换背景
function CompOperators:onChangeBg( bgNo )
    local img_bg = self.bind_scene:FindRoot():getChildByName("bg")
    local center_node = self.lay_node:getChildByName( "center" )
    local pan_bg = center_node:getChildByName("pan_bg")
    local img_ltbg = pan_bg:getChildByName( "lt_bg" )
    local img_rtbg = pan_bg:getChildByName( "rt_bg" )
    local img_logo = pan_bg:getChildByName( "logo" )
    img_bg:loadTexture(BG_CFG[bgNo].bg)
    img_ltbg:loadTexture(BG_CFG[bgNo].tb)
    img_rtbg:loadTexture(BG_CFG[bgNo].tb)
    img_logo:loadTexture(BG_CFG[bgNo].logo)
end
 
function CompOperators:onOpenTingTip( eid,  params )
    local pan_tingTip  = self.lay_node:getChildByName("pan_tingtip")
    pan_tingTip:setVisible( params.isVisible )
 end

return CompOperators


