-- wframe.lua
-- 2016-02-24
-- KevinYuen
-- 窗体框架

local BaseObject = require( "kernels.object" ) 
local CompWndFrame = class(  "CompWndFrame", BaseObject )

-- 激活
function CompWndFrame:Actived()

    CompWndFrame.super.Actived( self )  

    -- 界面绑定
    self.ui_layer   = self.bind_scene:FindRoot():getChildByName( "ui_frame" )
    self.txt_score  = self.ui_layer:getChildByName( "txt_basescore" )
    self.btn_quit   = g_methods:ButtonClicked( self.ui_layer, "btn_quit", handler( self, self.onBtnQuit ) )
    self.btn_max    = g_methods:ButtonClicked( self.ui_layer, "btn_max", handler( self, self.onBtnMax ) )
    self.btn_min    = g_methods:ButtonClicked( self.ui_layer, "btn_min", handler( self, self.onBtnMin ) )
    self.btn_help   = g_methods:ButtonClicked( self.ui_layer, "btn_help", handler( self, self.onBtnHelp ) )
    self.btn_set    = g_methods:ButtonClicked( self.ui_layer, "btn_set", handler( self, self.onBtnSet ) )
    self.btn_restore= g_methods:ButtonClicked( self.ui_layer, "btn_restore", handler( self, self.onBtnRestore ) )
    self.btn_charge = g_methods:ButtonClicked( self.ui_layer, "btn_charge", handler( self, self.onBtnCharge ) )
    local  pp = cc.Director:getInstance():getRunningScene():getName()
    if  app.last_sceneid == "scene.login" then 
        self.btn_charge:setVisible( false )
    else
        g_save.configs.system.nCharge = g_save.configs.system.nCharge or 1
               
        local animSprite = display.newSprite()
        self.chargeAnim  = g_library:CreateAnimation( "ani.charge" )    -- 资源
        local size =  self.btn_charge:getContentSize() 
        animSprite:setPosition( cc.p( size.width / 2, size.height / 2 ) )
        self.btn_charge:addChild(animSprite)
        animSprite:playAnimationForever( self.chargeAnim )    
        self.pan_chargetip = self.ui_layer:getChildByName("pan_chargetip")
        if g_save.configs.system.nCharge <=  3 then 
            g_save.configs.system.nCharge = g_save.configs.system.nCharge + 1
            self.pan_chargetip = self.ui_layer:getChildByName("pan_chargetip")
            if self.pan_chargetip  then
                self.pan_chargetip:setVisible( true )
                local lbl_content = self.pan_chargetip:getChildByName("text")
                lbl_content:setString( g_library:QueryConfig("text.chargetip") )
                self.pan_chargetip:runAction(cc.Sequence:create(cc.DelayTime:create(5),cc.CallFunc:create(function(sender, params)
                        sender:setVisible( false )
                    end
                )))
            end
        else
            if  self.pan_chargetip then
                self.pan_chargetip:setVisible( false )
            end
        end    
       
    end
    -- 消息监听列表
    self.msg_hookers = {         
        { STC_MSG_BASECORE,   handler( self, self.OnUpdateBaseScore)},
        { CTC_MSG_CONFIG,     handler( self, self.onRecvGameConfig) }

    }
    g_event:AddListeners( self.msg_hookers, "compwframe_events" )
    
    self.btn_max:setVisible( not jav_is_fullscreen() )
    self.btn_restore:setVisible( jav_is_fullscreen() )
    g_save.configs.system.isSet = g_save.configs.system.isSet or 0
    g_save.configs.system.isHelp = g_save.configs.system.isHelp or 0

    if g_save.configs.system.isHelp == 0 then
        local sprite = cc.Sprite:create("help.effect.png")
        sprite:setOpacity(0)
        local fd1  = cc.FadeTo:create(0.4,200)
        local fd2  = cc.FadeTo:create(0.4,0)
        local fd3  = cc.FadeTo:create(0.2,0)
        sprite:setName("effect")
        self.btn_set:addChild(sprite)
        local size = self.btn_set:getContentSize()
        sprite:setPosition(size.width/2,size.height/2)
        local rep = cc.RepeatForever:create(cc.Sequence:create(fd1, fd2, fd3))
        sprite:runAction(rep)
        
    end
    
    if g_save.configs.system.isHelp == 0 then
        local sprite = cc.Sprite:create("setting.effect.png")
        sprite:setOpacity(0)
        local fd1  = cc.FadeTo:create(0.4,200)
        local fd2  = cc.FadeTo:create(0.4,0)
        local fd3  = cc.FadeTo:create(0.2,0)
        sprite:setName("effect")
        self.btn_help:addChild(sprite)
        local size = self.btn_help:getContentSize()
        sprite:setPosition(size.width/2,size.height/2)
        local rep = cc.RepeatForever:create(cc.Sequence:create(fd1, fd2, fd3))
        sprite:runAction(rep)

    end 
    
    
    
    return true

end

-- 反激活
function CompWndFrame:InActived()

    -- 事件监听注销
    g_event:DelListenersByTag( "compwframe_events" )

    CompWndFrame.super.InActived( self )
end


--游戏配置数据
function CompWndFrame:onRecvGameConfig( event_id, event_args )
    local lbl_starthuscore = self.ui_layer:getChildByName( "lbl_starthuscore" )
    if event_args.nMinFan  > 0 and  lbl_starthuscore ~= nill then
        local text = string.format( g_library:QueryConfig("text.starthuscore"),event_args.nMinFan )
        lbl_starthuscore:setString(text) 
    end

end
-- 更新基础分
function CompWndFrame:OnUpdateBaseScore( event_id, event_args )
    
    local txt = string.format( "底注:%d", event_args.nBaseScore )
    self.txt_score:setString( txt )
    
end

function CompWndFrame:onBtnQuit( sender, args )
    onWindowRequireClose()
end

function CompWndFrame:onBtnMax( sender, args )

    jav_full_screen( true )
    self.btn_max:setVisible( false )
    self.btn_restore:setVisible( true )
    
end

function CompWndFrame:onBtnMin( sender, args )
    jav_min_window()
end


--快速充值
function CompWndFrame:onBtnCharge( sender, args  )

    local msg = { key = "cmd", context = E_HALL_REQ_WEBSHOP }
    if jav_room and jav_room.main_connect then 
         jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
    end
end

function CompWndFrame:onBtnRestore( sender, args )

    jav_full_screen( false )
    self.btn_max:setVisible( true )
    self.btn_restore:setVisible( false )
    
end

function CompWndFrame:onBtnHelp( sender, args )

    g_audio:PlaySound("anniu.mp3")
    g_event:PostEvent( E_CLIENT_OPENHELPVIEW )
    g_save.configs.system.isHelp = 1
    sender:removeChildByName("effect")
end

function CompWndFrame:onBtnSet( sender, args )

    g_audio:PlaySound("anniu.mp3")
    g_save.configs.system.isSet = 1
    g_event:PostEvent( E_CLIENT_OPENSETTINGVIEW )
    sender:removeChildByName("effect")

    
end
return CompWndFrame


