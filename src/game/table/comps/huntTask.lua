-- 加倍任务界面区
-- 吉森 （josen）
-- 2016-2-19
local BaseObject = require( "kernels.object" )
local CompDoubleTask = class(  "CompDoubleTask", BaseObject )

-- 激活
function CompDoubleTask:Actived()

    CompDoubleTask.super.Actived( self )  
    local ui_layer = self.bind_scene:FindRoot():getChildByName( "ui_layer" )   
    self.root = ui_layer:getChildByName("pan_targetR")
    self.img_dn = self.root:getChildByName("img_dn")
    self.img_up = self.root:getChildByName("img_up")
    self.ui_main = self.root:getChildByName("pan_bg")
    self.pan_anim = self.ui_main:getChildByName("pan_anim")
    
    self.root:setVisible( false )
    self.img_dn:setVisible( false )
    self.img_up:setVisible( false )
    
    -- 界面绑定

    -- 消息监听列表
    self.msg_hookers = {         
        { STC_MSG_DOUBLETASK,           handler( self, self.OnRecDoubleTask ) } ,
        { STC_MSG_DOUBLETASKFINISH,     handler( self, self.OnRecDoubleTaskFinished ) },
        { CTE_SHOW_SETTLEMENT,          handler( self, self.OnSettlement ) },
        { E_CLIENT_SITDOWN,             handler( self, self.onUserSitdown ) }

        
    }
    g_event:AddListeners( self.msg_hookers, "compview_events" )
    return true

end
-- 坐下
function CompDoubleTask:onUserSitdown(  event_id, event_args )
    if event_args.uid == jav_self_uid then
        self.img_dn:setVisible( false )
        self.img_up:setVisible( false )
        self.root:setVisible( false )
        self.pan_anim:removeAllChildren()
    end
end

-- 结算
function CompDoubleTask:OnSettlement(  event_id, event_args )
    self.img_dn:setVisible( false )
    self.img_up:setVisible( false )
    self.root:setVisible( false )
    self.pan_anim:removeAllChildren()
end



--赏金任务
function CompDoubleTask:OnRecDoubleTask( event_id, event_args)
    
    g_methods:log("赏金任务")
    self.img_dn:setVisible( false )
    self.img_up:setVisible( false )
    self.pan_anim:removeAllChildren()
    
    if event_args.nDoubleTask == OPER_PENG  then
        self:RefreshView("peng", event_args)
    end

    if event_args.nDoubleTask == OPER_GANG  then
        self:RefreshView("gang", event_args)
    end

    if event_args.nDoubleTask == OPER_CHI  then
        self:RefreshView("chi", event_args)
    end

    if event_args.nDoubleTask == OPER_DOUBLE  then
        self:RefreshView("jiabei", event_args)
    end

    local pan_mj = self.ui_main:getChildByName( "pan_mj" )
    if event_args.nFinishSeat  and event_args.nFinishSeat ~= -1 then
        self.ui_main:setCascadeOpacityEnabled(true)
        pan_mj:setCascadeOpacityEnabled(true)
        self.ui_main:setOpacity( 255 )
        self.root:setVisible( true )         
    else
        self.ui_main:setOpacity( 0 )
        self.ui_main:setCascadeOpacityEnabled(true)
        pan_mj:setCascadeOpacityEnabled(true)
        self.root:setVisible( true )
        self.ui_main:runAction( cc.FadeIn:create( 2 ) )
    end
    
end

function CompDoubleTask:RefreshView( oper, args )
    local pan_op = self.ui_main:getChildByName("pan_op")
    local pan_mj = self.ui_main:getChildByName( "pan_mj" )
    local img_op = pan_op:getChildByName("img_op")
    local img_mj = pan_mj:getChildByName( "img_mj" )
    local lbl_mutil = self.ui_main:getChildByName( "lbl_mutil" )
    local lbl_times = pan_mj:getChildByName( "lbl_times" )
    local txt_mul_desc = self.ui_main:getChildByName("txt_mul_desc")
    local txt_op_desc = self.ui_main:getChildByName( "txt_op_desc" )
    img_op:loadTexture( "chufarenwu.font."..oper..".png", ccui.TextureResType.plistType )
    lbl_mutil:setString( args.nMultiple )
    txt_mul_desc:setString(string.format(g_library:QueryConfig("text.mutiltimes.format"),g_library:QueryConfig("text.ch."..args.nMultiple)))
    if oper == "jiabei" then
        txt_op_desc:setString(string.format(g_library:QueryConfig("text.huntdesc.format_2"),g_library:QueryConfig("text.ch."..args.nDoubleTimes)))
        lbl_times:setVisible( true )
        lbl_times:setString( args.nDoubleTimes )
        img_mj:setVisible( false )
    else    
        txt_op_desc:setString(string.format(g_library:QueryConfig("text.huntdesc.format_1"),g_library:QueryConfig("text."..oper),g_library:QueryConfig("text.cardtype."..args.nTaskCard)))
        lbl_times:setVisible( false )
        img_mj:setVisible( true )
        img_mj:setScale(0.8)
        local res = getRiverRes(0,args.nTaskCard*10, false)
        res = string.sub( res, 2 )

        img_mj:loadTexture( res, ccui.TextureResType.plistType )
    end
    self.ui_main:updateSizeAndPosition()
    for idx = 1, #args.lstFinishSeat  do 
        local parm = clone(args)
        parm.nFinishSeat = args.lstFinishSeat[idx]
        parm.isCutReturn =  true
        self:OnRecDoubleTaskFinished( nil, parm )
    
    end
end


--赏金任务完成
function CompDoubleTask:OnRecDoubleTaskFinished(event_id, event_args  )
	g_methods:log("赏金任务完成")
    if event_args.nFinishSeat == jav_get_mychairid() then
        self.img_dn:setVisible( true )
        --self.img_up:setVisible( false )
    else
       -- self.img_dn:setVisible( false )
        self.img_up:setVisible( true )
    end
    self.wanChengAnim = sp.SkeletonAnimation:create( "wancheng.json", "wancheng.atlas", 1.0 )
    self.wanChengAnim:registerSpineEventHandler(  function( event ) 
        if event.animation == "start" then 
            self.wanChengAnim:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
                self.wanChengAnim:setToSetupPose()
                self.wanChengAnim:setAnimation(0, "stop", false )
             end
            )))
     end
    end, 
    sp.EventType.ANIMATION_COMPLETE )
    self.pan_anim:removeAllChildren()
    self.pan_anim:setVisible( true )
    self.pan_anim:addChild(self.wanChengAnim )
    local size = self.pan_anim:getContentSize()
    self.wanChengAnim:setPosition(size.width/2, size.height/2)
    self.wanChengAnim:setToSetupPose()
    if event_args.isCutReturn and  event_args.isCutReturn == true then
        self.wanChengAnim:setAnimation(0, "stop", false )
    else
        self.wanChengAnim:setAnimation(0, "start", false )
    end
end


-- 反激活
function CompDoubleTask:InActived()

    -- 事件监听注销
    --    g_event:DelListenersByTag( "compview_events" )

    CompDoubleTask.super.InActived( self )
    
end

return CompDoubleTask