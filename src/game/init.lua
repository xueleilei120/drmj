-- init.lua
-- 2015-01-05
-- KevinYuen
-- 场景相关注册

g_methods:log( "游戏模块注册开始..." )

-- 初始化
local handler_init = function()

    -- 脚本载入
    require( "game.hall.define" )
    require( "game.hall.methods" )    
    require( "game.hall.details" )
    require( "game.table.define" )
	require( "kernels.mahjong.logic.fantypes" )

    -- 对象注册
    g_factory:Regist( "service",    "JavRoom",          "game.hall.room",                   "游戏房间" )
    g_factory:Regist( "scene",      "JavSceneLogin",    "game.hall.login",                  "登录场景" )

    g_factory:Regist( "service",    "MJTable",          "game.table.table",                 "麻将桌服务" )
    g_factory:Regist( "service",    "MJLogic",          "game.table.logic",                 "麻将游戏逻辑" )
    
    g_factory:Regist( "component",  "CompView",         "game.table.comps.view",            "主视图组件" )
    g_factory:Regist( "component",  "CompControl",      "game.table.comps.control",         "麻将控制组件" ) 
    g_factory:Regist( "component",  "CompOperators",    "game.table.comps.mainOps",         "玩家操作组件" ) 
    g_factory:Regist( "component",  "CompSettle",       "game.table.comps.settle",          "结算组件" )  
    g_factory:Regist( "component",  "CompHelp",         "game.table.comps.help",            "帮助组件" ) 
    g_factory:Regist( "component",  "CompChat",         "game.table.comps.chat",            "聊天栏组件" )
    g_factory:Regist( "component",  "CompPlayerList",   "game.table.comps.plist",           "玩家列表组件" )
    g_factory:Regist( "component",  "CompBank",         "game.table.comps.bank",            "保险箱组件" )
    g_factory:Regist( "component",  "CompTask",         "game.table.comps.task",            "任务组件" )
    g_factory:Regist( "component",  "CompDoubleTask",         "game.table.comps.huntTask",            "任务组件" )
    g_factory:Regist( "component",  "CompSetting",      "game.table.comps.setting",         "设置组件" )
    g_factory:Regist( "component",  "CompWndFrame",     "game.table.comps.wframe",          "外框组件" )    
    g_factory:Regist( "component",  "CompDebug",        "game.table.comps.debug",           "调试组件" )
        
    -- 场景库载入
    g_library:AddLibrary( "scene", "scenes.json" )
    
    -- 窗体尺寸监听
    local windowResizedHandle = cc.EventListenerCustom:create( "APP.WINDOW_RESIZE_EVENT", onWindowResized )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority( windowResizedHandle, 1 )

    -- 窗体关闭监听
    local windowCloseHandle = cc.EventListenerCustom:create( "APP.WINDOW_REQUIRE_CLOSE", onWindowRequireClose )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority( windowCloseHandle, 1 )

    -- 游戏房间创建
    g_methods:log( "创建JAV游戏房间..." )
    jav_room = g_factory:Create( "JavRoom" )
    
end

-- 销毁
local handler_destroy = function()
    
    -- 插件注销
    g_factory:Unregist( "MJTable" )
    g_factory:Unregist( "MJLogic" )
    g_factory:Unregist( "CompView" )
    g_factory:Unregist( "CompControl" )
    g_factory:Unregist( "CompOperators" )
    g_factory:Unregist( "CompHelp" )
    g_factory:Unregist( "CompSettle" )
    g_factory:Unregist( "CompChat" )
    g_factory:Unregist( "CompPlayerList" )
    g_factory:Unregist( "CompBank" )
    g_factory:Unregist( "CompTask" )
    g_factory:Unregist( "CompWndFrame" )
    g_factory:Unregist( "CompDebug" )

    -- 对象销毁
    g_factory:Unregist( "JavSceneLogin" )
    g_factory:Unregist( "JavRoom" )

    -- 游戏房间调度中心
    g_factory:Delete( jav_room )
    jav_room = nil
    g_methods:log( "销毁JAV游戏房间..." )
    
end

-- 窗体尺寸变化处理
function onWindowResized( event )

    local msg = json.decode( event:getDataString() )
    WindowResized( msg )
end

function updateDisplay()
    display.size               = cc.Director:getInstance():getWinSize()
    display.width              = display.size.width
    display.height             = display.size.height
    display.cx                 = display.width / 2
    display.cy                 = display.height / 2
    display.c_left             = -display.width / 2
    display.c_right            = display.width / 2
    display.c_top              = display.height / 2
    display.c_bottom           = -display.height / 2
    display.left               = 0
    display.right              = display.width
    display.top                = display.height
    display.bottom             = 0
    display.widthInPixels      = display.sizeInPixels.width
    display.heightInPixels     = display.sizeInPixels.height
end

function WindowResized( args )

    g_methods:log( "\t 窗体尺寸改变: width:%d, height:%d", args.width, args.height )
    
    -- 更新全局变量
    updateDisplay()
    
    --cc.Director:getInstance():setProjection( cc.DIRECTOR_PROJECTION2_D )
    
    -- 尺寸改变
--    local glview = cc.Director:getInstance():getOpenGLView()
--    glview:setFrameSize( args.width, args.height )
--    if args.width > CONFIG_SCREEN_WIDTH and args.height > CONFIG_SCREEN_HEIGHT then
--        cc.Director:getInstance():getTextureCache():setAliasTexParameters()
--        glview:setDesignResolutionSize( args.width, args.height, cc.ResolutionPolicy.EXACT_FIT )
--    else    
--        cc.Director:getInstance():getTextureCache():setAnitAliasTexParameters() 
--        glview:setDesignResolutionSize( CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, cc.ResolutionPolicy.EXACT_FIT )
--    end
     
    -- 通知当前场景,及时改变
    local scene = cc.Director:getInstance():getRunningScene()
    if scene and scene.scene_root then
    
        -- 根节点尺寸变化
        scene.scene_root:setContentSize( display.width, display.height )
        scene.scene_root:setPosition( cc.p( 0, 0 ) )

        -- 标题栏改变
        local pCaption = scene.scene_root:getChildByName( "ui_frame" );
        if pCaption then
            local sz = pCaption:getContentSize()
            pCaption:setContentSize( display.width, sz.height )
        end
        
    end
        
    -- 游戏桌界面特殊处理
    autoResizeTable()
    
end

-- 窗体关闭请求
function onWindowRequireClose( event )

    -- 游戏没有开始可以直接退出
    if  jav_table == nil or 
        jav_isplaying( jav_self_uid ) == false then
            jav_leftroom()
            g_methods:CreateOnceCallback( 0.5, function()
                app:exit() 
            end )
        return
    end
    g_event:SendEvent( CTE_SHOW_MSGBOX )
    
end

-- 桌子等比缩放更新
function autoResizeTable()

--    local scene = cc.Director:getInstance():getRunningScene()
--    if not scene or not scene:FindRoot() then
--        g_methods:warn( "正比缩放失败,没有激活的场景..." )
--        return
--    end
--    
--    -- 游戏桌界面特殊处理
--    local table_resize = function( sender, args )
--                
--        -- 根据具体游戏进行界面布局手动计算重置
--        local ui_wnd = scene:FindRoot():getChildByName( "ui_layer" )
--        if not ui_wnd then
--            g_methods:warn( "缩放失败,窗体获取失败..." )
--            return
--        end
--        
--        if RTWND_ISEXPANDED == false then
--            lt_wnd:setContentSize( cc.size( display.width - RTWND_XOFFSET, display.height ) )
--            lt_wnd:setPosition( cc.p( 0, 0 ) )
--            rt_wnd:setContentSize( rt_wnd:getContentSize().width, display.height )
--            rt_wnd:setPosition( cc.p( display.width - RTWND_XOFFSET, 0 ) )
--        else
--            lt_wnd:setContentSize( cc.size( display.width - rt_wnd:getContentSize().width, display.height ) )
--            lt_wnd:setPosition( cc.p( 0, 0 ) )
--            rt_wnd:setContentSize( rt_wnd:getContentSize().width, display.height )
--            rt_wnd:setPosition( cc.p( display.width - rt_wnd:getContentSize().width, 0 ) )
--        end
--        
--    end
--    
--    local delay = cc.DelayTime:create( 0.01 )
--    local callfunc = cc.CallFunc:create( table_resize )
--    scene:runAction( cc.Sequence:create( delay, callfunc ) )
    
end

-- 模块注册
g_modules:Regist( "ModulePoker", handler_init, handler_destroy, "游戏模块" )

g_methods:log( "游戏模块注册结束..." )

