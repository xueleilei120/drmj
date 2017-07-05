-- view.lua
-- 2015-04-07
-- KevinYuen
-- 基本视图控制

local BaseObject = require( "kernels.object" )
local CompView = class(  "CompView", BaseObject )
local MsgBox = require( "game.table.nodes.msgbox" )

-- 激活
function CompView:Actived()

    CompView.super.Actived( self )  
    
    self.kick_timer = nil     -- 踢出事件句柄
            
    -- 界面绑定
    self.ui_layer = self.bind_scene:FindRoot():getChildByName( "ui_layer" );
    self.lay_node = self.bind_scene:FindRoot():getChildByName( "mj_layer" )
    self.lay_startShow = self.bind_scene:FindRoot():getChildByName( "pan_startshow" )    
    local center_node = self.lay_node:getChildByName( "center" )
    

    
    -- 玩家面板
    self.player_pans = {}
    self.playerInfo_pans = {}
    
    local uipanels = { "dn_player", "up_player" }
    local uiInfoPanels = { "dn_playerInfo", "up_playerInfo" }
    for index = 1, TABLE_MAX_USER do 
    
        local panel         = self.ui_layer:getChildByName( uipanels[index] )                
        local panel_info    = panel:getChildByName( "pan_info" ) 
        local panel_timer   = self.lay_node:getChildByName( "pan_timer"..index )  
        panel_timer:setVisible( false )  
        
        self.player_pans[index - 1] = {
            pan_root        = panel,                                                                                                -- 根节点
            pan_info        = panel_info,                                                                                           -- 名字和钱的节点
            img_photo       = panel:getChildByName( "pan_photo" ):getChildByName( "img_photo" ),                                     -- 头像
            img_photoEffect = panel:getChildByName( "pan_photo" ):getChildByName( "img_photomask" ),                                 -- 头像效果
            txt_nick        = panel_info:getChildByName( "txt_name" ),                                                               -- 昵称
            txt_money       = panel_info:getChildByName( "txt_money" ),                                                              -- 财富 
            img_vip         = panel_info:getChildByName( "img_vip" ),
            img_zhuang      = center_node:getChildByName( "pan_banker"..index ),                                                    -- 庄家标记
            img_ting        = center_node:getChildByName( "img_ting"..index ),                                                      -- 听牌标志
            img_ready       = self.ui_layer:getChildByName( "img_ready" .. index ),                                                  -- 准备标记 
            ani_opers       = self.ui_layer:getChildByName( "nod_operAnim" .. index ),                                               -- 操作动画标记
            nod_dice        = center_node:getChildByName( "dice" .. index ),                                                         -- 筛子  
            img_orientation = center_node:getChildByName( "img_orientation_" .. index ),
            pan_timer       = panel_timer,
            prog_timer      = self:CreateProgressTimer( panel_timer, "#daojishi.jindutiao.png" ),
            lbl_timer       = panel_timer:getChildByName( "lbl_timer" ),
            pan_mutilfan    = panel:getChildByName( "pan_photo" ):getChildByName( "pan_mutilfan" ),                                  -- 加倍番数
            lbl_mutilfan    =  panel:getChildByName( "pan_photo" ):getChildByName( "pan_mutilfan" ):getChildByName( "lbl_fan" )      --加倍番数
        }
        self.player_pans[index - 1].img_photo:openMouseTouch(true, self )
        local mouseInfo = self.ui_layer:getChildByName( uiInfoPanels[index] )  
        self.player_pans[index - 1].pan_mutilfan:openMouseTouch(true, self , true, true)


        self.playerInfo_pans[index-1] = {
            pan_root        = mouseInfo,                                                                       -- 根节点
            txt_nick        = mouseInfo:getChildByName( "lbl_name" ),                                          -- 昵称
            txt_money       = mouseInfo:getChildByName( "lbl_money" ),                                         -- 财富
            txt_gamelevel   = mouseInfo:getChildByName( "lbl_gamelevel" ),                                     -- 游戏级别
            text_gamenum    = mouseInfo:getChildByName( "lbl_gamenum" ),                                       -- 游戏盘数
            text_maxfan     = mouseInfo:getChildByName( "lbl_hepainum" )                                       -- 和牌最大番数 
        }

  end
    
    -- 初始化界面
    self.lay_startShow:setVisible( false )    
    for index = 0, TABLE_MAX_USER -1 do
        local panel = self.player_pans[index]
        panel.pan_root:setVisible( false )
        panel.img_zhuang:setVisible( false )
        panel.img_ting:setVisible( false )
        panel.img_ready:setVisible( false )
    end
    g_methods:setTextureAntiAlias("fnt_lose_num.png", true)
    g_methods:setTextureAntiAlias("bluenum.png", true)
    g_methods:setTextureAntiAlias("fnt_he_num.png", true)
    g_methods:setTextureAntiAlias("fnt_hutip_point.png", true)
    g_methods:setTextureAntiAlias("fnt_money.png", true)
    g_methods:setTextureAntiAlias("fnt_task_times.png", true)
    g_methods:setTextureAntiAlias("fnt_timer_num.png", true)
    g_methods:setTextureAntiAlias("fnt_win_num.png", true)

    -- 消息监听列表
    self.msg_hookers = {         
        { ESE_SCENE_ACTIVED,                handler( self, self.OnSceneActived ) },
        { E_CLIEN_GAMEBEGIN,                 handler( self, self.OnGameBegin ) },
        { E_CLIENT_ICOMEIN,                 handler( self, self.ClearUI)},
        { STC_MSG_GAMEEND,                  handler( self, self.OnRecGameEnd )}, 
        { E_CLIENT_SITDOWN,                 handler( self, self.OnUserSitdown ) },
        { E_CLIENT_STANDUP,                 handler( self, self.OnUserStandup ) },
        { E_CLIENT_USERREADY,               handler( self, self.onUserReady ) },
        { E_CLIENT_PROPCHANGED_MONEY,       handler( self, self.OnUserMoneyChanged ) },
        { STC_MSG_UPDATESTATE,              handler( self, self.OnUpdateGameState)},
        { STC_ASSIGNBANKER,                 handler( self, self.OnShowAssignBanker)},
        { STC_ASSIGNWALL,                   handler( self, self.OnShowWallDice)},
        { CTC_TIMERPROG_RESET,              handler( self, self.onTimerProgReseted ) },
        { CTC_OPER_STACKSHOW,               handler( self, self.OnPlayOperAnimation)},
        { CTC_OPER_DOUBLESHOW,              handler( self, self.OnPlayDoubleShow )},
        { CTC_PLAY_TINGANIM,                handler( self, self.onTingOper)},             -- 有人听牌了
        { STC_MSG_CUTRETURN,                handler( self, self.onCuttReturn)},     -- 处理掉线重入消息
        { STC_MSG_USERINFO,                 handler( self, self.OnRecUserInfo)},
        { STC_MSG_TURN,                     handler( self, self.onsetTurnChairid)},
        { STC_MSG_HUDOUBLE,                 handler( self, self.OnRecHuDouble )},
        { CTC_SHOW_MAXFAN,                  handler( self, self.OnRecHuDouble )},
        { STC_MSG_QUANFENG,                 handler( self, self.onShowQuanFeng)},         --圈风消息
        { STC_MSG_EXIT,                     handler( self, self.OnRecExit)},
        { CTC_MSG_CONFIG,                   handler( self, self.onGameConfig) }, 
        { STC_MSG_CANCELTING,               handler( self, self.onCancelTing)},      -- 取消听牌信息           
    }
    g_event:AddListeners( self.msg_hookers, "compview_events" )
    
    return true
    
end

function CompView:onMouseTouchMove( location, args )
    local uipanels = { "dn_playerInfo", "up_playerInfo" }
    for idx =0,  #self.player_pans do
        local pan_playerInfo = self.ui_layer:getChildByName( uipanels[ idx+1 ] )
        if self.player_pans[idx].pan_root:isVisible() and self.player_pans[idx].img_photo:hitTest( location )then
            if self.player_pans[idx].pan_mutilfan:hitTest( location ) and self.player_pans[idx].pan_mutilfan:isVisible() then 
                pan_playerInfo:setVisible( false )
            else
                pan_playerInfo:setVisible( true )
            end
        else
            pan_playerInfo:setVisible( false )
        end
    end

end
-- 反激活
function CompView:InActived()
    
    if self.kick_timer then
        g_methods:DeleteOnceCallback( self.kick_timer )
    end
            
    -- 事件监听注销
    g_event:DelListenersByTag( "compview_events" )
    
    CompView.super.InActived( self )


end

-- 处理玩家游戏界面切桌子的处理
function CompView:ClearUI( event_id,event_args )

	self:FreshSeatAtOnce(0, false)
    self:FreshSeatAtOnce(1, false)
    
end

-- 设置超时踢出
function CompView:onGameConfig( event_id,event_args)

    
    if self.kick_timer then
        g_methods:DeleteOnceCallback( self.kick_timer )
        self.kick_timer = nil
    end

    if jav_isplaying( jav_self_uid ) == true then
        return
    end

    if jav_iswatcher( jav_self_uid ) == true then
        return
    end
    
    self.kick_timer = g_methods:CreateOnceCallback( jav_table.waittime,
        function( args )
            g_methods:warn( "%d秒到了，踢出该玩家...",jav_table.waittime )
            app:exit()
        end )
end

-- 显示圈风
-- self.nQuanFeng = 1  # 当前轮的圈风（东1，南2，西3，北4）
function CompView:onShowQuanFeng( event_id,event_args )
    if event_args.nQuanFeng >4 or event_args.nQuanFeng <1 then
           return
    end
    
    local img_quanfengke = self.lay_node:getChildByName( "img_quanfengke" )
    img_quanfengke:loadTexture( "img.font.quanfengke."..event_args.nQuanFeng ..".png", ccui.TextureResType.plistType )

end

function CompView:OnRecHuDouble( event_id, event_args )

    if event_args.nMutiple > 0 then
       local seatNo = jav_get_localseat(event_args.nDoubleSeat)
       local player_pan =  self.player_pans[seatNo]
       player_pan.pan_mutilfan:setVisible( true )
       player_pan.lbl_mutilfan:setString( event_args.nMutiple  )
    end
	
end

-- 场景激活
-- 主动调用一次屏幕调整
function CompView:OnSceneActived( event_id, event_args )    
--WindowResized( { width = jav_client_width(), height = jav_client_height() } )    
end

-- 游戏结束
function CompView:OnRecGameEnd( event_id, event_args )

    for i = 0, TABLE_MAX_USER - 1 do
        local seatPan = self.player_pans[i]
        seatPan.img_zhuang:setVisible(false)  
        seatPan.img_ting:setVisible(false)  
        seatPan.pan_mutilfan:setVisible(false)
    end
    
    -- 取消头像闪
    self:PlayPhotoEffect(-1)

    jav_table.settles = event_args 


    local   reason = jav_table.settles.nEndReason 

    if      reason == END_REASON_NORMAL then
        local chairid = event_args.nWinner
        local sex = jav_get_chairsex(chairid)
        local huAudio = string.format(OPER_AUDIO,sex,"hu")
        g_audio:PlaySound(huAudio)
        local user = jav_queryplayer_bychairid( chairid )
        jav_table.settles.winnerUserName = user.nickname    
        local seatNo = jav_get_localseat( chairid )
        local cardId = event_args.nHuCard
        self:playHuEffect( seatNo, cardId )
        
        --赢家提示
        local wtext = g_library:QueryConfig( "text.winmoney" )
        local content = string.format( wtext,jav_format_richname( user.uid, 8), event_args.nRealWinnerScore  )  
        jav_room:PushSystemLog( content )

        --输家提示
        local ltext = g_library:QueryConfig( "text.losemoney" )
        user = jav_queryplayer_bychairid( event_args.nLoser  )
        if user then
            local content = string.format( ltext, jav_format_richname( user.uid, 8), event_args.nRealLoserScore  )  
            jav_room:PushSystemLog( content )
        end
    else
            g_event:PostEvent( CTE_SHOW_SETTLEMENT )
    end
    if      reason == END_REASON_RUNAWAY or
            reason == END_REASON_DISMISS then
            local text = g_library:QueryConfig( "text.hall_user_quit" )
            local sname = jav_format_richname( event_args.nRunawayUserID )     
            local content = string.format( text, sname ) 
            jav_room:PushSystemLog( content )
    end
    
    if jav_iswatcher( jav_self_uid ) then
        return  
    end
       
    if self.kick_timer then
        g_methods:DeleteOnceCallback( self.kick_timer )
    end
    self.kick_timer = g_methods:CreateOnceCallback( jav_table.waittime,
        function( args )
            g_methods:warn( "%d秒到了，踢出该玩家...",jav_table.waittime )
            app:exit()
        end )
    
end

function CompView:onsetTurnChairid( event_id,event_args )
    local chairid = event_args.nCurTurn 
    self:PlayPhotoEffect(chairid)
    
end

-- 掉线重入消息
function CompView:onCuttReturn( event_id,event_args)
	
	-- 隐藏准备好了图片
	self:OnUpdateGameState(event_id,event_args)
	
	--显示庄
	if event_args.nBanker ~=-1 then
	   self:freshBankerShow(false)
	end
	
	-- 设置听牌图片
	local lstTingSeat = event_args.lstTingSeat
	if #lstTingSeat>0 then
	   for i=1,#lstTingSeat do
	       if lstTingSeat[i] == jav_get_mychairid() then
                g_event:PostEvent( CTC_HANDCARDS_SETCHOOSE, { cardlst = {1} } ) 
	       end
	       event_args.nTingSeat = lstTingSeat[i]
	       self:onTingOper(event_id,event_args) 
	   end
	end
    for idx =1, #event_args.lstHuMultiple  do
        if event_args.lstHuMultiple [idx] > 1 then 
            self:OnRecHuDouble( nil,  {nDoubleSeat = idx -1 , nMutiple = event_args.lstHuMultiple [idx]})
	   end
	end
		
end

-- 阶段界面处理
function CompView:OnUpdateGameState(event_id,event_args)

    if event_args.state == STATE_WAITBEGIN then
    else
        for index=0,TABLE_MAX_USER-1 do
            self.player_pans[index].img_ready:setVisible(false) 
                        
        end
    end
    
end

function CompView:onTingOper( event_id,event_args )

    local chairid = event_args.nTingSeat
    local seatNo = jav_get_localseat(chairid)
    local panel = self.player_pans[seatNo]
    panel.img_ting:setVisible( true ) 
    if event_args.bCutReturn == false then 
        self:playTingEffect(seatNo) 
    end
    
end


function CompView:onCancelTing(event_id,event_args)
    local chairid = event_args.nSeat
    local seatNo = jav_get_localseat(chairid)
    local panel = self.player_pans[seatNo]
    panel.img_ting:setVisible( false )
end

--收到玩家游戏信息
function CompView:OnRecUserInfo( event_id,event_args )
    for idx = 1, TABLE_MAX_USER do
        local seatNo = jav_get_localseat( idx -1 )
        if seatNo >= 0 then
            self.playerInfo_pans[seatNo].text_gamenum:setString(string.format(g_library:QueryConfig("text.gameround"),event_args.lstRound[idx] ))
            self.playerInfo_pans[seatNo].text_maxfan:setString(string.format(g_library:QueryConfig("text.gamemaxfan"),event_args.lstMaxFan[idx] ))
            local player = jav_queryplayer_bychairid( idx-1 )
            if player then
                self.playerInfo_pans[seatNo].txt_gamelevel:setString(string.format(g_library:QueryConfig("text.playergamelevel"),jav_bg2312_utf8(player.lvname)))  
            end     
         end
    end
end

-- 游戏开始
function CompView:OnGameBegin(event_id,event_args)
    
    
    for i = 0, TABLE_MAX_USER - 1 do
        local seatPan = self.player_pans[i]
        seatPan.img_ready:setVisible(false)  
    end
    if  self.kick_timer then
        g_methods:DeleteOnceCallback( self.kick_timer )
        self.kick_timer = nil
    end
    g_audio:PlaySound("start.mp3")
    self:playRoundStartEffect()
    
end

-- 玩家坐下
function CompView:OnUserSitdown( event_id, event_args ) 
    
    if event_args.chairid == jav_get_mychairid() then
    
        if jav_isplaying(event_args.uid) then
        else
        
            g_audio:PlaySound( "jinru.mp3" )
        
        end  
    end
        
    self:FreshSeatAtOnce( event_args.chairid, true )
    for idx = 1 ,TABLE_MAX_USER do 
        local panel = self.player_pans[idx-1]
        panel.img_ting:setVisible( false )
    end

    local img_quanfengke = self.lay_node:getChildByName( "img_quanfengke" )
    img_quanfengke:loadTexture( "img.font.quanfengke."..1 ..".png", ccui.TextureResType.plistType )

end

-- 玩家站起
function CompView:OnUserStandup( event_id, event_args )  
    
    if event_args.chairid == jav_get_mychairid() then
        g_audio:PlaySound( "likai.mp3" )
    end
    
    self:FreshSeatAtOnce( event_args.chairid, false )

end

-- 玩家准备
function CompView:onUserReady( event_id, event_args )   


    local ready = jav_isready( event_args.uid )
    local charid = jav_getchairid_byUID( event_args.uid ) 
    local seatNo = jav_get_localseat(charid)
    local paninfo = self.player_pans[seatNo]
    
    
    paninfo.img_ready:setVisible( ready )
    
    
    if jav_iswatcher( jav_self_uid ) == true then
        return
    end
    if ready then
    
        self.player_pans[0].img_ting:setVisible(false)
        self.player_pans[1].img_ting:setVisible(false)
        
        if charid == jav_get_mychairid() and self.kick_timer then
            g_methods:DeleteOnceCallback( self.kick_timer )
            self.kick_timer = nil
        end
        
    end
    
end

-- 指定座位全刷新
-- chairid:     座位号
-- animFresh:   是否显示玩家个人信息
function CompView:FreshSeatAtOnce( chairid, animFresh )

    local seatNo = jav_get_localseat( chairid )
    local seatInfo = jav_table:getSeat( chairid )
    local seatPan = self.player_pans[seatNo]
    
    local playerInfo = self.playerInfo_pans[seatNo]
    
    -- 如果没有玩家
    if seatInfo.uid == nil or seatInfo.uid == 0 or (animFresh== false) then

        seatPan.img_zhuang:setVisible( false )
        seatPan.img_ting:setVisible( false )
        seatPan.img_ready:setVisible( false )
        seatPan.pan_root:setVisible( false )
        seatPan.img_orientation:setVisible( false )
        seatPan.pan_mutilfan:setVisible( false )
        return
        
    end 
    
    local player = jav_table:queryPlayer( chairid )
    if not player then
        g_methods:error( "座位显示刷新失败,本地座位[%d]找不到玩家:%d", seatNo, seatInfo.uid )
        return 
    end
    
    -- 刷新要显示的信息    
    seatPan.pan_root:setVisible( true )
    
    -- 名字
    local name = jav_shortcut_name( player.nickname, 10 )
    seatPan.txt_nick:setString( name )
    
    playerInfo.txt_nick:setString( name )

    -- 更新头像
    local pinfo = PLAYER_PHOTOS[chairid][player.sex]
    seatPan.img_photo.config = pinfo      
    seatPan.img_photo:loadTexture( pinfo.photo, ccui.TextureResType.plistType )
    seatPan.img_photoEffect:loadTexture( pinfo.photomask, ccui.TextureResType.plistType )
    seatPan.img_photoEffect:setVisible( false )
    seatPan.img_orientation:loadTexture( "img.font."..chairid..".png", ccui.TextureResType.plistType )
    seatPan.img_orientation:setVisible( true )
    -- VIP等级
    local strVipImg = "img.lv0.png"
    if player.vip > 0 then 
        strVipImg = "img.graylv"..player.vip..".png"
        if player.newvipactive == true then
            strVipImg = "img.lv"..player.vip..".png"
        end
    end
    -- 如果vip是0 ，则不显示vip
    seatPan.img_vip:loadTexture( strVipImg, ccui.TextureResType.plistType )
    --seatPan.img_vip:setVisible( player.vip > 0 )
    
    -- 财富
    self:OnUserMoneyChanged( "", { uid = seatInfo.uid } )    
    
    -- 准备
    self:onUserReady( "", { uid = seatInfo.uid } )

    -- 庄家
  --  self:freshBankerShow( animFresh )
    
end

--播放头像动画
function CompView:PlayPhotoEffect( chairid )

    --停止所有头像动画
    for idx = 0, #self.player_pans do 
        local playe_pan = self.player_pans[ idx ]
       playe_pan.img_photoEffect:stopAllActions()
       playe_pan.img_photoEffect:setVisible( false )
    end
    
    if chairid == -1 then
        return 
    end
    
    local player = jav_queryplayer_bychairid( chairid ) 
    
    --玩家不存在
    if not player then
        return
    end
    
    local pinfo = PLAYER_PHOTOS[chairid][player.sex]
    local seatNo = jav_get_localseat( chairid )
    local playe_pan = self.player_pans[seatNo]
    playe_pan.img_photoEffect:setVisible( true )
    local fadeOut = cc.FadeOut:create(0.5)
    local fadeIn =  cc.FadeIn:create(0.5)
    playe_pan.img_photoEffect:runAction(cc.RepeatForever:create(cc.Sequence:create( fadeOut,fadeIn )))
    
end

-- 玩家财富改变
function CompView:OnUserMoneyChanged( event_id, event_args )    

    local player = jav_queryplayer_byUID( event_args.uid )
    
    if player == nil then
        return
    end
    
    local seatInfo = jav_table:getSeat(player.chairid)
    if player.uid == seatInfo.uid then
        local seatNo = jav_get_localseat( player.chairid )
        local seatPan = self.player_pans[seatNo]
        seatPan.txt_money:setString( tostring( player.money ) )
        
        local playerInfo = self.playerInfo_pans[seatNo]
        playerInfo.txt_money:setString( tostring( player.money ) )
        
    end
    
end


-- 切牌骰子和庄骰子显示
function CompView:OnShowAssignBanker( event_id, event_args )

    if #event_args.lstBankerDices > 1 then

        self:showDice( true, event_args.lstBankerDices )
        g_methods:CreateOnceCallback( SECS_DICEROLL_BANKER, function( args )
            self:showDice( false )
            self:freshBankerShow(true)    
        end )
        
    else
        self:freshBankerShow(false)
    end
    
end

-- 显示庄动画和庄
function CompView:freshBankerShow( animFresh )

    -- 没庄直接隐藏
    self.player_pans[0].img_zhuang:setVisible( false )
    self.player_pans[1].img_zhuang:setVisible( false )
    
    if jav_table.bankerseat == -1 then
        return        
    end

    local seatNo = jav_get_localseat( jav_table.bankerseat )
    local imgBanker = self.player_pans[seatNo].img_zhuang 
    
    --播放定庄动画   
    if animFresh == nil or animFresh == true then
    
        self:playBankerAnim( seatNo )
        local fade = cc.FadeIn:create( 0.3 )
        local scal = cc.ScaleTo:create( 0.5, 1.2 )
        local scal2 = cc.ScaleTo:create( 0.3, 1.0 )
        local sequc = cc.Sequence:create( scal, scal2 )
        local action = cc.Spawn:create( fade, sequc )
        imgBanker:setVisible( true )
        imgBanker:setOpacity( 50 )
        imgBanker:setScale( 0.5 )
        imgBanker:runAction( action )
        
    else

        imgBanker:setOpacity( 255 )
        imgBanker:setScale( 1.0 )
        imgBanker:setVisible( true )
        
    end
        
end

-- 播放切排墙骰子动画
function CompView:OnShowWallDice(event_id,event_args)

    self:showDice( true, event_args.lstWallDices )

    g_methods:CreateOnceCallback( SECS_DICEROLL_WALL, function( args )
        self:showDice( false )   
    end )
        
end

-- 展示/隐藏骰子
function CompView:showDice( show, dicenums )
    
    -- 先清理掉老的骰子
    for i = 0, TABLE_MAX_USER - 1 do
        self.player_pans[i].nod_dice:removeAllChildren()
    end
    
    if show == false then
        return
    end
    
    g_audio:PlaySound("Chip.mp3")
    
    local diceRes = {
        [0] = { ani = "ani.whiteDiceRoll", key = "wtdiceKey" },
        [1] = { ani = "ani.blueDiceRoll", key = "blueDiceKey" },
    }

    for i = 0, TABLE_MAX_USER - 1 do
    
        local diceNode = self.player_pans[i].nod_dice
        local aniDice = display.newSprite()
        diceNode:removeAllChildren()
        diceNode:addChild( aniDice )
        aniDice.reskDic = diceRes[i].key
        aniDice.diceNum = dicenums[i+1]

        local size = diceNode:getContentSize() 
        aniDice:setPosition( cc.p( size.width / 2, size.height / 2 ) )
        local diceRollAni = g_library:CreateAnimation( diceRes[i].ani )
        aniDice:playAnimationOnce( diceRollAni, false, function(sender, args )
            local png = string.format( "%s%d.png", aniDice.reskDic, aniDice.diceNum ) 
            local frm = display.newSpriteFrame( png ) 
            aniDice:setSpriteFrame( frm )
        end, 0 )  
        
    end
 
end

-- 播放游戏开始动画
function CompView:playRoundStartEffect()
    
    local root = self.lay_startShow:getChildByName( "pan_start" )
    
    local onPlayDone = function()
        self.lay_startShow:setVisible( false )
        if self.start_role1 then
            self.start_role1:runAction( cc.RemoveSelf:create() )
            self.start_role1 = nil
        end
        if self.start_role2 then
            self.start_role2:runAction( cc.RemoveSelf:create() )
            self.start_role2 = nil  
        end
        if self.start_light then
            self.start_light:runAction( cc.RemoveSelf:create() )
            self.start_light = nil  
        end
        self.start_spine = nil
        self:onPlayRoundStartDone()
    end        
    
    -- 发光效果展示
    local start_light = root:getChildByName( "nod_light" )
    if start_light then
        local info = self.player_pans[0].img_photo.config
        self.start_light = sp.SkeletonAnimation:create( "faguang.json", "faguang.atlas", 1.0 )
        start_light:addChild( self.start_light )
        self.start_light:setAnimation( 0, "start", false )
    end
    
            
    -- 游戏开始文本效果
    local nod_start = root:getChildByName( "nod_text" )
    if nod_start then
        self.start_spine = sp.SkeletonAnimation:create( "duiju.json", "duiju.atlas", 1.0 )
        nod_start:addChild( self.start_spine )
        self.start_spine:registerSpineEventHandler( function( event ) 
            g_methods:debug( "播放完毕" )
            self.start_spine:runAction( 
                cc.Sequence:create( cc.DelayTime:create( 0.2 ), 
                                    cc.CallFunc:create( onPlayDone ),
                                    cc.RemoveSelf:create() ) )
        end, sp.EventType.ANIMATION_COMPLETE )
        self.start_spine:setAnimation( 0, "start", false )
    end
    
    -- 左角色展示
    local start_role1 = root:getChildByName( "nod_role1" )
    if start_role1 then
        local info = self.player_pans[0].img_photo.config
        self.start_role1 = sp.SkeletonAnimation:create( info.anim .. ".json", info.anim .. ".atlas" , 1.0 )
        start_role1:addChild( self.start_role1 )
        self.start_role1:setAnimation( 0, info.action, false )
    end
    

    -- 右角色展示
    local start_role2 = root:getChildByName( "nod_role2" )
    if start_role2 then
        local info = self.player_pans[1].img_photo.config
        if info ~= nil then 
            self.start_role2 = sp.SkeletonAnimation:create( info.anim .. ".json", info.anim .. ".atlas", 1.0 )
            start_role2:addChild( self.start_role2 )
            self.start_role2:setAnimation( 0, info.action, false )
        end
    end
    
    self.lay_startShow:setVisible( true )
            
end

-- 播放开始动画完毕
function CompView:onPlayRoundStartDone()
    g_methods:log( "播放开始动画完毕!" )
end

-- 定庄动画播放
function CompView:playBankerAnim( seatNo )
    
    local panel = self.player_pans[seatNo]
    if panel == nil then
        g_methods:error( "定庄动画播放失败,无效的位置:%d", seatNo )
        return false
    end

    local anim = sp.SkeletonAnimation:create( "cgpthz.json", "cgpthz.atlas", 1.0 )
    panel.ani_opers:removeAllChildren()
    panel.ani_opers:addChild( anim )
    local size = panel.ani_opers:getContentSize()
    anim:setPosition( size.width / 2, size.height / 2 )
    anim:registerSpineEventHandler( function( event )
        anim:runAction( cc.Sequence:create( cc.DelayTime:create( 0.1 ), cc.RemoveSelf:create() ) )
    end, sp.EventType.ANIMATION_COMPLETE )

    anim:setAnimation( 0, "zhuang-da", false ) 
    
end

-- 播放吃碰杠动画
-- operFlag: 操作标记组合
function CompView:OnPlayOperAnimation( event_id, event_args )

    local seatNo = event_args.seatNo
    local operFlag = event_args.operFlag
    local panel = self.player_pans[seatNo]
    if panel == nil then
        g_methods:error( "组牌动画播放失败,无效的位置:%d", seatNo )
        return false
    end
    
    local   operAction
    if      operCanPeng( operFlag ) then
            operAction = "peng"
    elseif  operCanChi( operFlag ) then
            operAction = "chi"
    elseif  operCanGang( operFlag ) then
            operAction = "gang"
    end
    
    if not operAction then
        g_methods:error( "组牌动画播放失败,无效的组合标记:%d", operFlag )
        return false
    end
    
    g_audio:PlaySound("Face.mp3")
    
    local anim = sp.SkeletonAnimation:create( "cgpth.json", "cgpth.atlas", 1.0 )
    panel.ani_opers:removeAllChildren()
    panel.ani_opers:addChild( anim )
    local size = panel.ani_opers:getContentSize()
    anim:setPosition( size.width / 2, size.height / 2 )
    anim:registerSpineEventHandler( function( event ) 
        
        g_methods:debug( "播放完毕" )
        anim:runAction( 
            cc.Sequence:create( cc.DelayTime:create( 0.2 ),
            cc.RemoveSelf:create() ) )
        end, sp.EventType.ANIMATION_COMPLETE )
    
    anim:setAnimation( 0, operAction, false ) 
    
end

-- 播放加倍动画
function CompView:OnPlayDoubleShow( event_id, event_args )

    local seatNo = event_args.seatNo
    local times  = event_args.times

    local anim = sp.SkeletonAnimation:create( "ani_jiabei.json", "ani_jiabei.atlas", 1.0 )   
    self.ui_layer:addChild( anim )
    anim:setPosition( display.width / 2, display.height / 2 )
    anim:registerSpineEventHandler( function( event ) 
        anim:runAction( 
            cc.Sequence:create( cc.DelayTime:create( 0.1 ),
                cc.RemoveSelf:create() ) )
    end, sp.EventType.ANIMATION_COMPLETE )
    local actName = string.format( "jiabei_cishu%d", times )
    anim:setAnimation( 0, actName, false ) 
    
end

-- 播放胡牌动画
function CompView:playHuEffect( seatNo, cardId )

    -- 播放文字特效
    if true then
    
        local panel = self.player_pans[seatNo]
        if panel == nil then
            g_methods:error( "播放胡牌动画失败,无效的位置:%d", seatNo )
            return false
        end
    
        local anim = sp.SkeletonAnimation:create( "cgpth.json", "cgpth.atlas", 1.0 )
        panel.ani_opers:removeAllChildren()
        panel.ani_opers:addChild( anim )
        local size = panel.ani_opers:getContentSize()
        anim:setPosition( size.width / 2, size.height / 2 )
        anim:registerSpineEventHandler( function( event ) 
            g_event:PostEvent( CTE_SHOW_SETTLEMENT )
            anim:runAction( 
                cc.Sequence:create( cc.DelayTime:create( 0.2 ),
                    cc.RemoveSelf:create() ) )
        end, sp.EventType.ANIMATION_COMPLETE )
    
        anim:setAnimation( 0, "he", false ) 
    end
    
    -- 播放麻将牌特效
    if true then
        
        local ctrl = self.bind_scene:FindComponent( "CompControl", true )
        local card = ctrl.mjtable:findCard( cardId )
 --       card:set
        if card and card.card then
        
            -- 电击效果
            local ani = g_library:CreateAnimation( "ani.blueLight" )            
            local spt = display.newSprite()
            card.card:addChild( spt, 100 )
            spt:setGlobalZOrder( 10000 )
            spt:setAnchorPoint( cc.p( 0.5, 0 ) )
            spt:setPosition( cc.p( card.card:getSize().width / 2, 0 ) )
            spt.parent = card.card
            spt:playAnimationOnce( ani, true, function( sender, args )
                local card = sender.parent
                card:setPosition( cc.p( card.rawX, card.rawY ) )
                card:stopAction( card.shak )
                card.shak = nil
                g_methods:debug( "胡牌雷电播放完毕" )
            end, 0 )  
            
            -- 抖动
            local x, y = card.card:getPosition()
            local move1 = cc.MoveTo:create( 0.03, cc.p( x-3, y ) )
            local move2 = cc.MoveTo:create( 0.06, cc.p( x+3, y ) )
            local sequc = cc.Sequence:create( move1, move2 )
            local shake = cc.RepeatForever:create( sequc )
            local act   = card.card:runAction( shake )
            card.card.rawX = x
            card.card.rawY = y
            card.card.shak = act
        end
    end
    
end

-- 播放停牌动画
function CompView:playTingEffect( seatNo )

    local panel = self.player_pans[seatNo]
    if panel == nil then
        g_methods:error( "播放胡牌动画失败,无效的位置:%d", seatNo )
        return false
    end

    local anim = sp.SkeletonAnimation:create( "cgpth.json", "cgpth.atlas", 1.0 )
    panel.ani_opers:removeAllChildren()
    panel.ani_opers:addChild( anim )
    local size = panel.ani_opers:getContentSize()
    anim:setPosition( size.width / 2, size.height / 2 )
    anim:registerSpineEventHandler( function( event ) 
        anim:runAction( 
            cc.Sequence:create(cc.DelayTime:create( 0.2 ),
                cc.RemoveSelf:create() ) )
    end, sp.EventType.ANIMATION_COMPLETE )
    local chairid = jav_get_chairid_bylocalseat(seatNo)
    local sex = jav_get_chairsex(chairid)
    local huAudio = string.format(OPER_AUDIO,sex,"ting")
    g_audio:PlaySound(huAudio)
    anim:setAnimation( 0, "ting", false ) 
    
end

---------进度条倒计时------------------------
--
--
SEAT_TIMER_TAG = 800001

--创建倒计时进度条
function CompView:CreateProgressTimer( parent, progressFile )

    local sprite = display.newSprite( progressFile )
    local prog_timer = cc.ProgressTimer:create( sprite )
    prog_timer:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    local size = parent:getContentSize()
    prog_timer:setPosition(size.width/2,size.height/2)
    prog_timer:setBarChangeRate(cc.p(1, 0)) 
    prog_timer:setMidpoint(cc.p(0, 1))
    prog_timer:setReverseDirection(false)
    prog_timer:setPercentage(100)
    parent:addChild( prog_timer, 1 )
    return prog_timer

end

-- 进度条刷新
function CompView:onTimerProgTick( sender, args )

    args.panel.lbl_timer:setString( args.secs )
    if args.secs <= 0 then
        g_event:PostEvent( CTC_TIMERPROG_TIMEOUT, { seatNo = args.seatNo } )
        args.panel.pan_timer:setVisible( false )
        return
    else 
 --       g_event:PostEvent( CTC_TIMERPROG_TICK, { seatNo = args.seatNo, secs = args.secs } )
    end    
    if args.secs<=5 then
        g_audio:PlaySound("Clock.mp3")
    end

    args.panel.pan_timer:setVisible( args.secs > 0 and args.secs <= DELAY_TICKSHOWSECS )
    
    args.secs = args.secs - 1
    local progressTo = cc.ProgressTo:create( 1, ( args.secs / DELAY_TICKSHOWSECS ) * 100 )
    local cal = cc.CallFunc:create( handler( self, self.onTimerProgTick ), args )
    local act = sender:runAction( cc.Sequence:create( progressTo, cal ) )
    act:setTag( SEAT_TIMER_TAG )
    
end

-- 进度条刷新
function CompView:onTimerProgReseted( event_id, event_args )
    
    local seatNo = event_args.seatNo
    local secs   = event_args.secs
    
    local panel = self.player_pans[seatNo]
    if panel == nil then
        g_methods:error( "倒计时更新失败,无效的位置:%d", seatNo )
        return false
    end

    local oldAct = panel.prog_timer:getActionByTag( SEAT_TIMER_TAG )
    if oldAct then
        g_event:PostEvent( CTC_TIMERPROG_BREAKOUT, { seatNo = seatNo } )
    end  
    
    panel.prog_timer:stopAllActions()
    panel.pan_timer:setVisible( secs > 0 and secs <= DELAY_TICKSHOWSECS )
    
    if secs > 0 then      
        panel.prog_timer:setPercentage( ( secs / DELAY_TICKSHOWSECS ) * 100 )
        self:onTimerProgTick( panel.prog_timer, 
                              { seatNo = seatNo, 
                                panel = panel, 
                                secs = secs, 
                                total = DELAY_TICKSHOWSECS } )
    end
    
    return true
    
end

function CompView:OnRecExit(  event_id, event_args  )
    --弹出框
    local pan_msgbox = self.bind_scene:FindRoot():getChildByName( "pan_msgbox" )
    self.pan_msgbox = MsgBox.new( pan_msgbox )
    if jav_isplaying( jav_self_uid ) and jav_get_mychairid() ==  event_args.nSeat  then
        self.pan_msgbox:DoModal( "", g_library:QueryConfig("text.exitgame_reason_1_"..event_args.nReason ), {"confirm"}, function( btnType ) 
            self.pan_msgbox:Close()
            app:exit() 
        end
        ) 
    
    end
end
return CompView
