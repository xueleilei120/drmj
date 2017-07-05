-- setting.lua
-- 2016-02-24
-- KevinYuen
-- 处理基本的打牌操作，包括吃，碰，杠，听，胡等

local BaseObject = require( "kernels.object" ) 
local CompSetting = class(  "CompSetting", BaseObject )

-- 激活
function CompSetting:Actived()

    CompSetting.super.Actived( self )  

    -- 界面绑定
    self.ui_main = self.bind_scene:FindRoot():getChildByName( "pan_setting" )   

    --背景音乐
    self:InitSlider( "pan_music",  g_audio:GetBGVolume())
    
    --音效
    self:InitSlider( "pan_audio",  g_audio:GetSoundVolume())
      
    --设置旁观
    local chk_watch = self.ui_main:getChildByName( "chk_watch" )
    chk_watch:addEventListener(handler(self, self.OnChkWatchClicked))

    
    --button 事件注册
    g_methods:ButtonClicked( self.ui_main, "btn_close",  handler(self, self.OnViewClosed))

    -- 消息监听列表
    self.msg_hookers = {         
        { E_CLIENT_OPENSETTINGVIEW,         handler( self, self.OnViewOpened) },
        { STC_MSG_CUTRETURN,                handler( self, self.onRecvCutReturn)},
        { E_CLIENT_ICOMEIN,                 handler( self, self.onRecvSefComin ) }

    }
    g_event:AddListeners( self.msg_hookers, "compsetting_events" )
    self.ui_main:openMouseTouch(true, self, true, true)
    
    return true

end

--自己进入
function CompSetting:onRecvSefComin(  event_id, event_args  )
    local chk_watch = self.ui_main:getChildByName( "chk_watch" )
    chk_watch:setSelected( false   )
    self.ui_main:setVisible( false )
end


--滑动初始化
function CompSetting:InitSlider( name, vol )
    local pan_music = self.ui_main:getChildByName( name )
    local prog_music = pan_music:getChildByName( "prog" )
    prog_music:addEventListener(handler(self, self.OnSliderChanged))
    prog_music:setPercent( vol * 100 )   
end

--掉线回来
function CompSetting:onRecvCutReturn(  event_id, event_args  )

   local chk_watch = self.ui_main:getChildByName( "chk_watch" )
   chk_watch:setSelected( event_args.bAllowWatch   )
  
end


--滑动条滑动事件监听
function CompSetting:OnSliderChanged( sender, args )
	local  parent =  sender:getParent()
	local  percent = sender:getPercent()
    local  name = parent:getName()
    
    if name == "pan_audio" then
        g_audio:SetSoundVolume( percent/100 ) 
    elseif name == "pan_music" then
        g_audio:SetBGVolume( percent/100 )
    end
end

--打开 VIEW 
function CompSetting:OnViewOpened( event_id, event_args )
    self.ui_main:setVisible( true )
    g_methods:WidgetVisible( self.ui_main,"chk_watch", not jav_iswatcher( jav_self_uid ) )
    g_methods:WidgetVisible( self.ui_main,"lbl_watch", not jav_iswatcher( jav_self_uid ) )
    
end

--点击事件
function CompSetting:onMouseTouchDown(location, args )
    local ret = self.ui_main:hitTest( location )
    if ret == false  then
        self.ui_main:setVisible( false )
    end
end

--关闭 VIEW
function CompSetting:OnViewClosed( sender, args )
    self.ui_main:setVisible( false )
    if self._eventListenerMouse then
        local dispatch = self.ui_main:getEventDispatcher()
        dispatch:removeEventListener( self._eventListenerMouse )
        self._eventListenerMouse = nil
    end
end

-- 反激活
function CompSetting:InActived()

    -- 事件监听注销
    g_event:DelListenersByTag( "compsetting_events" )

    CompSetting.super.InActived( self )
end

function CompSetting:OnChkWatchClicked( sender, params )
	
    g_methods:log("设置属性"..params )
    
    local bAllow = false
    if params == 0 then
        bAllow = true
    end
    
    jav_send_message( CTS_MSG_ALLOWWATCH, { bAllow  = bAllow } )

end

return CompSetting


