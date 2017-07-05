-- load.lua
-- 2014-10-20
-- KevinYuen
-- 游戏过渡场景

local BaseScene = import( ".base" )
local LoadingScene = class(  "LoadingScene", BaseScene )

-- 初始化
function LoadingScene:OnCreate( args )
    LoadingScene.super.OnCreate( self, args ) 
    self.loading_step = 5
    self.loading_update_seconds = 0.03
end

-- 销毁
function LoadingScene:OnDestroy()
    LoadingScene.super.OnDestroy( self )  
end

-- STEP4: 相关界面预加载(外部不要调用)
function LoadingScene:PreloadLayouts() 
    LoadingScene.super.PreloadLayouts( self )

    -- 背景图加载,居中显示
    local bg = self.configs["bg"]
    if bg and bg ~= "" then
        local bg_sprite = display.newSprite( bg, display.cx, display.cy )
        bg_sprite:setName( "bg_cloth" )    
        local bg_layer = self:FindNode( "Background" )
        if bg_layer then
            bg_layer:addChild( bg_sprite)
        end
    end

    -- 加载进度显示
    local prog = self.configs["prog"]
    if prog and prog ~= "" then
        local params = {}
        params.image = prog
        params.scale9 = false
        params.direction = 0
        params.percent = 100
        params.viewRect = cc.rect( 0, 0, 250, 13 )
        self.loading_bar = cc.ui.UILoadingBar.new(params)
        self.loading_bar:setPositionX( display.cx ) 
        self.loading_bar:setPositionY( 100 )
        self.loading_bar:setContentSize( 250, 13 )
        self.loading_bar:setAnchorPoint( 0.5, 0.5 )
        self.load_percent = 0
        self.loading_bar:setPercent( self.load_percent )
        self.scene_root:addChild( self.loading_bar )
    end
end

-- 进入场景
function LoadingScene:SceneActived()
    LoadingScene.super.SceneActived( self )

    self.scene_enter_handle = g_event:AddListener( ESE_SCENE_ACTIVED, handler( self, self.HandleSceneEnter ) )
    self.scene_exit_handle = g_event:AddListener( ESE_SCENE_INACTIVED, handler( self, self.HandleSceneExit ) )
    self.scene_ready_handle = g_event:AddListener( ESE_SCENE_READY, handler( self, self.HandleSceneReady ) )
end

-- 离开场景
function LoadingScene:SceneInActived()

    g_event:DelListener( self.scene_enter_handle )
    g_event:DelListener( self.scene_exit_handle )
    g_event:DelListener( self.scene_ready_handle )
    self.scene_enter_handle = nil
    self.scene_exit_handle = nil
    self.scene_ready_handle = nil

    LoadingScene.super.SceneInActived( self )
end

-- 监听ESE_KERNEL_SCENE_ACTIVED消息
function LoadingScene:HandleSceneEnter( event_id, event_args )

    -- 场景过渡阶段,消息步骤为:
    -- Loading ENTER消息
    -- 旧场景 EXIT消息
    -- 新场景 ENTER消息
    -- Loading EXIT消息
    -- 这里只处理新场景进入后需要做的事情
    if  event_args.scene_class ~= self.scene_class and event_args.scene_id ~= self.scene_id then
        g_methods:log( "新场景[%s]准备完毕,过渡场景即将关闭...", event_args.scene_id )
    end

end

-- 监听ESE_KERNEL_SCENE_INACTIVED消息
function LoadingScene:HandleSceneExit( event_id, event_args )

    -- 场景过渡阶段,消息步骤为:
    -- Loading ENTER消息
    -- 旧场景 EXIT消息
    -- 新场景 ENTER消息
    -- Loading EXIT消息
    -- 这里只处理旧场景退出后需要做的事情
    if  event_args.scene_class ~= self.scene_class and event_args.scene_id ~= self.scene_id then

        g_methods:log( "旧场景[%s]完全退出,过渡场景开始清理操作...", event_args.scene_id )

        display.removeUnusedSpriteFrames()
        g_methods:log( "无用的精灵纹理资源,帧资源清理完毕..." )

        cc.AnimationCache:destroyInstance()
        ccs.ArmatureDataManager:destroyInstance()
        g_methods:log( "动画缓存清理完毕..." )

        g_methods:log( "创建新场景[%s]开始...", self.target_scene_id )
        if self.loading_bar then
            self.load_percent = 30
            self.loading_bar:setPercent( self.load_percent )
        end

        -- 从场景库中查找配置
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
    end
end

-- 监听ESE_KERNEL_SCENE_READY消息
function LoadingScene:HandleSceneReady( event_id, event_args )

    -- 场景准备完毕后准备进行新场景切换    
    if  event_args.scene_id ~= self.target_scene_id then
        g_methods:error( "捕获到不合逻辑的场景数据准备事件[%s]!", event_args.scene_id  )
    else

        -- 根据step不同确认加载阶段
        if event_args.step == "preload" then

            local progressToPreloadSceneNode = function( dt )
                self.load_percent = self.load_percent + self.loading_step
                if self.loading_bar and self.load_percent < self.load_percent_target then
                    self.loading_bar:setPercent( self.load_percent )
                end
                if self.load_percent >= self.load_percent_target then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    self.target_scene_instance:PreloadSceneNode()
                end
            end
            self.load_percent_target = 50
            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( progressToPreloadSceneNode, self.loading_update_seconds, false )

        elseif event_args.step == "load_scene" then

            local progressToPreloadLayout = function( dt )
                self.load_percent = self.load_percent + self.loading_step
                if self.loading_bar and self.load_percent < self.load_percent_target then
                    self.loading_bar:setPercent( self.load_percent )
                end
                if self.load_percent >= self.load_percent_target then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    self.target_scene_instance:PreloadLayouts()
                end
            end
            self.load_percent_target = 70
            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( progressToPreloadLayout, self.loading_update_seconds, false )

        elseif event_args.step == "load_layouts" then

            local progressToPrepareActive = function( dt )
                self.load_percent = self.load_percent + self.loading_step
                if self.loading_bar and self.load_percent < self.load_percent_target then
                    self.loading_bar:setPercent( self.load_percent )
                end
                if self.load_percent >= self.load_percent_target then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    self.target_scene_instance:ScenePrepareActived()
                end
            end
            self.load_percent_target = 90
            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( progressToPrepareActive, self.loading_update_seconds, false )

        elseif event_args.step == "prepare_done" then  

            local progressToPrepareActive = function( dt )
                self.load_percent = self.load_percent + 1
                if self.loading_bar and self.load_percent < self.load_percent_target then
                    self.loading_bar:setPercent( self.load_percent )
                end
                if self.load_percent >= self.load_percent_target then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry( self.schedule_id )
                    display.replaceScene( self.target_scene_instance )
                    self.target_scene_instance:release()
                end
            end
            self.load_percent_target = 100
            self.schedule_id = cc.Director:getInstance():getScheduler():scheduleScriptFunc( progressToPrepareActive, 0.05, false )

        else
            g_methods:error( "场景阶段准备事件,STEP错误:%s.", event_args.step )
        end
    end

end

return LoadingScene
