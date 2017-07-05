-- login.lua
-- 2014-10-20
-- KevinYuen
-- 登陆场景

local BaseScene = import( "...kernels.scene.base" )
local JavSceneLogin = class(  "JavSceneLogin", BaseScene )

-- 构造初始化
function JavSceneLogin:ctor()
    JavSceneLogin.super.ctor( self, "JavSceneLogin" )
end

-- STEP5: 场景激活前(渲染前)准备(外部不要调用)
function JavSceneLogin:ScenePrepareActived()
    JavSceneLogin.super.ScenePrepareActived( self ) 
    return true;
end

-- 进入场景
function JavSceneLogin:SceneActived()

    JavSceneLogin.super.SceneActived( self )

    -- 界面绑定
    self.op_desc = self:FindNode( "prog_tip" )
    if self.op_desc then
        self.op_desc:enableOutline( cc.c4b( 0, 0, 0, 255 ), 1 )
        local txt = g_library:QueryConfig( "text.server_connect_trying" )
        self.op_desc:setString( txt )
        --self.op_desc:setVisible( jav_is_debugmode() )
    end

    -- 事件绑定监听
    self.msg_hookers = {
        { E_CLIENT_MAINCONNECT, handler( self, self.OnConnectionEvent ) },
        { E_HALL_GAMEINFO,      handler( self, self.OnRoomUpdatedEvent ) },
        { ESE_SCENE_READY,      handler( self, self.HandleSceneReady ) }
    }
    g_event:AddListeners( self.msg_hookers, "login_events" )

    -- 首先进行场景预加载
    local load_scene = function( sender, args )
        -- 提示更新
        local txt = g_library:QueryConfig( "text.server_userlistdata_updated" )
        self.op_desc:setString( txt )

        -- 从场景库中查找配置
        self.target_scene_id = "scene.play"
        app.last_sceneid = self.target_scene_id
        local scene_config = g_library:QueryConfig( self.target_scene_id )
        if not scene_config then
            g_methods:error( "场景过渡失败,没有找到目标场景[%s]的配置信息...", self.target_scene_id )
            return false
        end 

        -- 确认加载场景对应的场景类
        local scene_class = scene_config["class"]
        if not scene_class or scene_class == "" then
            g_methods:error( "场景过渡失败,没有找到目标场景[%s]的场景类配置...", self.target_scene_id )
            return false
        end

        -- 场景创建,通知数据准备
        self.target_scene_instance = g_factory:Create( scene_class, self.target_scene_id, { scene_id = self.target_scene_id } )
        self.target_scene_instance:retain()
        self.target_scene_instance:PreloadResources()
        local txt = g_library:QueryConfig( "text.scene_created_done" )
        self.op_desc:setString( txt ) --string.format( txt, self.target_scene_id ) )
    end
       
    -- 屏幕进行一次自适应调节
    local auto_resize = function( sender, args )
        local size = cc.Director:getInstance():getWinSize()
        WindowResized( size )
    end
    
    local delay = cc.DelayTime:create( 0.3 )
    local callfunc = cc.CallFunc:create( auto_resize )
    local delay2 = cc.DelayTime:create( 0.3 )
    local loadfunc = cc.CallFunc:create( load_scene )    
    self:runAction( cc.Sequence:create( delay, callfunc, delay2, loadfunc ) ) 
     
end

-- 离开场景
function JavSceneLogin:SceneInActived()

    -- 事件解除监听
    g_event:DelListenersByTag( "login_events" )
    JavSceneLogin.super.SceneInActived( self )

end


-- 监听连接事件
function JavSceneLogin:OnConnectionEvent( event_id, event_args )

    if      event_args.event == "start" then

        -- 提示更新
        local txt = g_library:QueryConfig( "text.server_connect_trying" )
        self.op_desc:setString( txt )

    elseif  event_args.event == "failed" then

        -- 提示更新
        local txt = g_library:QueryConfig( "text.server_connect_failed" )
        self.op_desc:setString( txt )

    elseif  event_args.event == "done" then

        -- 提示更新
        local txt = g_library:QueryConfig( "text.server_connect_ok" )
        self.op_desc:setString( txt )

        -- 延迟版本验证
        self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( 
            function( dt )
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                local txt = g_library:QueryConfig( "text.server_connect_verify" )
                self.op_desc:setString( txt )
                jav_send_version( JNET_VERSION )
            end, 
            0.3, false )

    elseif  event_args.event == "breaked" then

        -- 提示更新
        local txt = g_library:QueryConfig( "text.server_connect_breaked" )
        self.op_desc:setString( txt )

    elseif  event_args.event == "closed" then

        -- 提示更新
        local txt = g_library:QueryConfig( "text.server_connect_closed" )
        self.op_desc:setString( txt )

    else
        g_methods:error( "捕获到无效的连接事件类型[%s:%s]...", event_args.socket, event_args.event )
    end

end

-- 首次收到游戏房间数据更新
function JavSceneLogin:OnRoomUpdatedEvent( event_id, event_args )

    -- 提示更新
    local txt = g_library:QueryConfig( "text.server_roomdata_updated" )
    self.op_desc:setString( txt )

    g_event:OpenCache( true )
    display.replaceScene( self.target_scene_instance )
    self.target_scene_instance:release()
    g_event:DelListenersByTag( "login_events" )
    
end

-- 监听ESE_KERNEL_SCENE_READY消息
function JavSceneLogin:HandleSceneReady( event_id, event_args )

    -- 场景准备完毕后准备进行新场景切换    
    if  event_args.scene_id ~= self.target_scene_id then
        g_methods:error( "捕获到不合逻辑的场景数据准备事件[%s]!", event_args.scene_id  )
    else

        -- 根据step不同确认加载阶段
        if event_args.step == "preload" then

            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( 
                function( dt )
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    self.target_scene_instance:PreloadSceneNode()
                end, 
                0.01, false )

        elseif event_args.step == "load_scene" then

            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( 
                function( dt )
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    self.target_scene_instance:PreloadLayouts()
                end,
                0.01, false )

        elseif event_args.step == "load_layouts" then

            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( 
                function( dt )
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    self.target_scene_instance:ScenePrepareActived()
                end,
                0.01, false )

        elseif event_args.step == "prepare_done" then  

            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( 
                function( dt )
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    -- 尝试连接
                    jav_room:ConnectServer()
                end,
                0.05, false )

        else
            g_methods:error( "场景阶段准备事件,STEP错误:%s.", event_args.step )
        end
    end

end

return JavSceneLogin
