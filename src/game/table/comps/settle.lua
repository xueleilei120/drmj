-- 结算框信息
-- 2016-2-22
-- gaoxe

local BaseObject = require( "kernels.object" )
local CompSettle = class(  "CompSettle", BaseObject )
local HuTypeGrid =require("game.table.nodes.huTypeGrid") 

-- 激活
function CompSettle:Actived()

    CompSettle.super.Actived( self )    

    -- 界面绑定
    self.lay_node       = self.bind_scene:FindRoot():getChildByName( "pan_settle" )
    local pan_bg        = self.lay_node:getChildByName( "pan_bg" )
    self.nod_black      = self.lay_node:getChildByName( "ani_black" )
    self.node_anim      = pan_bg:getChildByName( "pan_anim" )
    self.ui_main        = pan_bg:getChildByName( "pan_frame" )
    self.item           = self.ui_main:getChildByName("item")
    self.pan_cardtype   = self.ui_main:getChildByName("pan_cardtype")
    self.huTypeGrid     = HuTypeGrid.new(HuTypeGrid)


    self.lay_node:setVisible( false )
    self.lay_node:openMouseTouch( true, nil, true ) 
    self.pan_cardtype:addChild( self.huTypeGrid )

    -- 继续游戏
    self.btn_continue = g_methods:ButtonClicked(    pan_bg, "btn_continue", 
                                                    function ( sender, args )
                                                        sender:setOpacity( 255 )
                                                        self.lay_node:setVisible( false )
                                                        self.node_anim:removeAllChildren()
                                                        jav_ready()
                                                    end )
    -- 离开游戏                                                    
    self.btn_leave =    g_methods:ButtonClicked(    pan_bg, "btn_cancel", 
                                                    function ( sender, args )
                                                        sender:setOpacity( 255 )
                                                        app:exit()
                                                    end )
                                                    
    -- 消息监听列表
    self.msg_hookers = {      
        { E_CLIENT_USERREADY,       handler( self, self.onUserReady ) },
        { CTE_SHOW_SETTLEMENT,      handler( self, self.OnSettlement ) },
        { E_CLIENT_ICOMEIN,         handler( self, self.ClearUI)}
    }
    g_event:AddListeners( self.msg_hookers, "compsettle_events" ) 
    
end

function CompSettle:ClearUI(event_id,event_args)
    self.btn_continue:setOpacity( 255 )
    self.lay_node:setVisible( false )
    self.node_anim:removeAllChildren()
end


-- 玩家准备
function CompSettle:onUserReady( event_id, event_args )
    
    local chariId = jav_table:getChairId(event_args.uid) 

    if chariId == -1 then
        return 
    end

    local seatNo =  jav_table:toSeatNo( chariId )

    if seatNo == 0 then 
        if jav_isready( event_args.uid ) == true then
            self.lay_node:setVisible( false )
            self.node_anim:removeAllChildren()
        end
    end
   
end

-- 按钮淡进显示
function CompSettle:fadeInButtons()
    
    if jav_iswatcher( jav_self_uid ) then
        return
    end
    
    self.btn_continue:setOpacity( 0 )
    self.btn_continue:setVisible( true )
    self.btn_continue:runAction( cc.FadeIn:create( 0.5 ) )
    
    self.btn_leave:setOpacity( 0 )
    self.btn_leave:setVisible( true )
    self.btn_leave:runAction( cc.FadeIn:create( 0.5 ) )    
    
end

-- 逃跑结算处理
function CompSettle:runAwaySettle()
        
    local skeAnim = sp.SkeletonAnimation:create( "ani_taopao.json", "ani_taopao.atlas", 1.0 )
    skeAnim:registerSpineEventHandler(  function( event ) 
                                            self:fadeInButtons()
                                        end, 
                                        sp.EventType.ANIMATION_COMPLETE )
    skeAnim:setAnimation( 0, "start", false )
    self.node_anim:addChild( skeAnim )
    local size = self.node_anim:getContentSize()
    skeAnim:setPosition( cc.p( size.width / 2, size.height / 2 ) )
    
end

-- 流局结算处理
function CompSettle:noWinnerSettle()

    local skeAnim = sp.SkeletonAnimation:create( "ani_huangju.json", "ani_huangju.atlas", 1.0 )
    skeAnim:registerSpineEventHandler(  function( event ) 
        self:fadeInButtons()
    end, 
    sp.EventType.ANIMATION_COMPLETE )
    skeAnim:setAnimation( 0, "start", false )
    self.node_anim:addChild( skeAnim )
    local size = self.node_anim:getContentSize()
    skeAnim:setPosition( cc.p( size.width / 2, size.height / 2 ) )
    
end

-- 普通结算处理
function CompSettle:winnerSettle()
    
    local settleInfo = jav_table.settles
    self.huTypeGrid:ClearGridList()
    self.lstType={}

    --留级
    if settleInfo.nWinner == -1 then
        self.ui_main:setVisible( false )
        return
    end

    self.ui_main:setVisible( true )
    --获取昵称（需要完善）
    local lbl_winnerName = self.ui_main:getChildByName("lbl_winner")
    lbl_winnerName:setString(jav_bg2312_utf8(settleInfo.winnerUserName))

    --设置牌型
    for idx = 1, #settleInfo.lstHuType do 
        local item = self.item:clone()
        item:setVisible( true )
        local lbl_typename = item:getChildByName( "lbl_typename" )
        local lbl_fannum = item:getChildByName( "lbl_fannum" )
        lbl_fannum:setString(settleInfo.lstHuFan[idx])
        lbl_typename:setString(g_library:QueryConfig( "text.hutype."..settleInfo.lstHuType[idx] ))
        table.insert( self.lstType, {  chipid = settleInfo.lstHuType[idx], node = item}) 
    end
    self.huTypeGrid:AddBatNode( self.lstType, true )

    --和番数
    local lbl_he = self.ui_main:getChildByName("lbl_he")
    lbl_he:setString(settleInfo.nTotalTypeFan)

    --总计番数
    local lbl_totalfan = self.ui_main:getChildByName("lbl_totalfan")
    lbl_totalfan:setString(settleInfo.nTotalTypeFan*settleInfo.nTaskMulti*settleInfo.nHuMulti)

    --番数倍率
    local lbl_fanrate = self.ui_main:getChildByName("lbl_numrate")
    local strFanRate = ""
    --和牌倍率    
    if  settleInfo.nHuMulti >1 then
        strFanRate = string.format(strFanRate.."*加倍%s倍   ",settleInfo.nHuMulti)
    end
    --任务倍率
    if  settleInfo.nTaskMulti >1 then
        strFanRate = string.format(strFanRate.."*任务%s倍   ",settleInfo.nTaskMulti)
    end
    lbl_fanrate:setString(strFanRate )

    --设置自己输赢的money 
    local SETMYMONEY = function (name, isVisible)
        local  pan_money = self.ui_main:getChildByName( name )
        local lbl_money = pan_money:getChildByName( "lbl_money" )
        pan_money:setVisible( isVisible )
        lbl_money:setString( math.abs(settleInfo.nWinnerScore) )
        pan_money:updateSizeAndPosition()
    end
    if settleInfo.nWinner == jav_get_mychairid() then
        SETMYMONEY("pan_winmoney", true)
        SETMYMONEY("pan_losemoney", false)
        g_audio:PlaySound("EndWin.mp3")
    else
        SETMYMONEY("pan_winmoney", false)
        SETMYMONEY("pan_losemoney", true) 
        g_audio:PlaySound("EndLost.mp3")
    end

    self:fadeInButtons()
    self.ui_main:updateSizeAndPosition()
    
end

--结算处理
function CompSettle:OnSettlement( event_id, event_args )

    self.lay_node:setVisible( true )

    
    self.ui_main:setVisible( false )
    self.btn_continue:setVisible( false )
    self.btn_leave:setVisible( false )
    
    self.aniBlack = sp.SkeletonAnimation:create( "ani_black.json", "ani_black.atlas", 1.0 )
    self.aniBlack:registerSpineEventHandler(  function( event ) 
    
        self.aniBlack:runAction( cc.RemoveSelf:create() )
        
        local   reason = jav_table.settles.nEndReason 
        if      reason == END_REASON_RUNAWAY or
                reason == END_REASON_DISMISS then
                self:runAwaySettle()
        elseif  reason == END_REASON_NOWINNER then  
                g_audio:PlaySound("Drawn.mp3")
                self:noWinnerSettle()  
        else
                self:winnerSettle()
        end
        
    end, 
    sp.EventType.ANIMATION_COMPLETE )
    self.aniBlack:setAnimation( 0, "start", false )
    self.nod_black:addChild( self.aniBlack )
    local size = self.nod_black:getContentSize()
    self.aniBlack:setPosition( cc.p( size.width / 2, size.height / 2 ) )
    
end

-- 反激活
function CompSettle:InActived()

    g_event:DelListenersByTag( "compsettle_events" )
    CompSettle.super.InActived( self )
    
end

return CompSettle