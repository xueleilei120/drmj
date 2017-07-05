-- base.lua
-- 2014-10-29
-- KevinYuen
-- 游戏场景基类

local BaseScene = class(   "BaseScene", function() return display.newScene("BaseScene") end )

-- 初始化
function BaseScene:OnCreate( args )

    self.scene_class    = self.obj_class 
    self.components     = {}                -- 场景插件组
    self.active_now     = false            -- 当前是否激活中
    self.configs        = {}                -- 配置信息  
    self:ConfigScene( self.obj_cfgid )
    
end

-- 销毁
function BaseScene:OnDestroy()
end

-- STEP1: 具体场景配置
function BaseScene:ConfigScene( scene_id )

    g_methods:debug( "场景[%s]加载[%s]开始...", g_methods:ObjectDetail( self ), scene_id );

    -- 不需要scene_id也认为正确,忽略即可
    if scene_id == nil or scene_id == "" then
        self.scene_id = ""
        g_methods:debug( "场景[%s]没有加载特定的编号配置,视为特定场景...", g_methods:ObjectDetail( self ) );        
        return true
    end

    -- 记录场景编号
    self.scene_id = scene_id

    -- 场景配置加载
    self.configs = g_library:QueryConfig( scene_id )
    if not self.configs then
        g_methods:error( "\t配置文件[%s]不存在,场景加载失败!", scene_id )
        return false
    end

    -- 服务创建
    local svr_list = self.configs["services"]
    if svr_list then
        for _, svrid in pairs(svr_list) do
            g_factory:Create( svrid, svrid, { bind_scene = self } ) 
        end
    end     

    -- 插件加载
    local comp_list = self.configs["components"]
    if comp_list then
        for _, cmp_name in pairs(comp_list) do    
            self:AddComponent( cmp_name ) 
        end
    end

    g_methods:debug( "场景[%s]加载[%s]结束...", g_methods:ObjectDetail( self ), scene_id );
    return true
    
end

-- STEP2: 场景资源预加载(外部不要调用)
function BaseScene:PreloadResources()

    -- 专属查询路径添加
    local searchs = self.configs["search_paths"]
    if searchs then     

        g_methods:debug( "\t专属查询路径添加开始..." )
        local file_utils = cc.FileUtils:getInstance()
        for _, path in pairs(searchs) do  
            file_utils:addSearchPath( path )
            g_methods:debug( "\t\t %s", path )
        end
        g_methods:debug( "\t专属查询路径添加结束..." )

    end

    -- 专属对象库添加
    local libraries = self.configs["libraries"]
    if libraries then
        g_methods:debug( "\t专属对象库添加开始..." )
        for key, path in pairs( libraries ) do  
            g_library:AddLibrary( key, path )
        end
        g_methods:debug( "\t专属对象库添加结束..." )        
    end

    -- 预加载资源读取    
    local preloads = self.configs["preloads"]
    if preloads then

        g_methods:debug( "\t资源预加载开始..." )

        -- 独立图片预加载
        local single_imgs = preloads["images"]
        if single_imgs then
            g_methods:debug( "\t\t独立图片预加载..." )
            for _, image_file in pairs(single_imgs) do
                local asyncHandler = function() end
                display.addImageAsync( image_file, asyncHandler )
                g_methods:debug( "\t\t\t %s", image_file )
            end
        end

        -- 组合图片预加载
        local image_frames = preloads["frames"]
        if image_frames then
            g_methods:debug( "\t\t组合图片预加载..." )
            for _, res_key in pairs(image_frames) do
                local res_file = res_key .. ".plist"
                local res_png = res_key .. ".png"
                display.addSpriteFrames( res_file, res_png )
                g_methods:debug( "\t\t\t %s:%s.", res_key, res_file )
            end
        end

        -- 骨骼动画预加载
        local armatures = preloads["armatures"]
        if armatures then
            g_methods:debug( "\t\t骨骼图片预加载..." )
            for armature_key, armature_file in pairs( armatures ) do
                local manager = ccs.ArmatureDataManager:getInstance()
                manager:addArmatureFileInfo( armature_file )
                g_methods:debug( "\t\t\t %s:%s.", armature_key, armature_file )
            end
        end

        -- 音乐文件预加载
        local musics = preloads["musics"]
        if musics then
            g_methods:debug( "\t\t音乐文件预加载..." )
            for _, id in pairs(musics) do                
                local music_file = "audios/" .. id
                audio.preloadMusic( music_file )
                g_methods:debug( "\t\t\t %s...", music_file )
            end
        end

        -- 音效文件预加载
        local sounds = preloads["sounds"]
        if sounds then
            g_methods:debug( "\t\t音效文件预加载..." )
            for _, id in pairs(sounds) do 
                local sound_file = "audios/" .. id
                audio.preloadSound( sound_file )
                g_methods:debug( "\t\t\t %s...", sound_file )
            end
        end
        g_methods:debug( "\t资源预加载完毕..." )
    end    

    -- 发布消息
    local data = { scene_class = self.scene_class, scene_id = self.scene_id, step = "preload" }
    g_event:_SendEvent( ESE_SCENE_READY, data )

end

-- 验证指定层,没有直接创建
function BaseScene:CheckSceneLayer( layer_data, parent_layer )

    local layer_name = layer_data[1]
    local layer = parent_layer:getChildByName( layer_name )
    if layer == nil then
        layer = display.newNode()
        layer:setName( layer_name )
        layer:setTouchEnabled( false )
        layer:setTouchSwallowEnabled( false )
        parent_layer:addChild( layer )
        g_methods:debug( "场景[%s]基础层[%s]补全...", g_methods:ObjectDetail( self ), layer_name )
    end       

    return layer    
end

-- STEP3: 主场景预加载(外部不要调用)
function BaseScene:PreloadSceneNode()

    g_methods:debug( "场景[%s]主场景节点加载开始...", g_methods:ObjectDetail( self ) )

    -- 如果有场景文件,那么通过文件加载(文件需要有节点层次规则)
    local scene_file = self.configs["scene_file"]
    if scene_file and scene_file ~= "" then
        local pathInfo = io.pathinfo(scene_file)
        if ".csb" == pathInfo.extname then
            self.scene_root = cc.uiloader:load( scene_file )
        else
            self.scene_root = ccs.GUIReader:getInstance():widgetFromJsonFile( scene_file )
        end
    else
        self.scene_root = display.newNode()
        self.scene_root:setName( "SceneRoot" )
        self.scene_root:setTouchEnabled( false )
    end
    
    if self.scene_root then
        self:addChild( self.scene_root )
    end
    
    g_methods:debug( "场景[%s]主场景节点加载结束...", g_methods:ObjectDetail( self ) )

    -- 发布消息
    local data = { scene_class = self.scene_class, scene_id = self.scene_id, step = "load_scene" }
    g_event:_SendEvent( ESE_SCENE_READY, data )

end

-- STEP4: 相关界面预加载(外部不要调用)
function BaseScene:PreloadLayouts()

    g_methods:debug( "场景[%s]相关界面加载...", g_methods:ObjectDetail( self ) )

    -- 发布消息
    local data = { scene_class = self.scene_class, scene_id = self.scene_id, step = "load_layouts" }
    g_event:_SendEvent( ESE_SCENE_READY, data )

end

-- STEP5: 场景激活前(渲染前)准备(外部不要调用)
function BaseScene:ScenePrepareActived()

    g_methods:debug( "场景[%s]激活前准备开始..", g_methods:ObjectDetail( self ) )

    -- 场景插件组激活前准备
    g_methods:debug( "\t场景插件组激活..." )
    for i, comp in pairs( self.components ) do
        if comp then
            comp:PreActived() 
        end
    end    

    g_methods:debug( "场景[%s]激活前准备完毕..", g_methods:ObjectDetail( self ) )

    -- 发布消息
    local data = { scene_class = self.scene_class, scene_id = self.scene_id, step = "prepare_done" }
    g_event:_SendEvent( ESE_SCENE_READY, data )

end

-- 预加载全部数据
function BaseScene:PreloadAllAtOnce()

    g_methods:debug( "场景[%s]一次性预加载开始..", g_methods:ObjectDetail( self ) )
    self:ConfigScene( self.obj_cfgid )
    self:PreloadResources()
    self:PreloadSceneNode()
    self:PreloadLayouts()
    g_methods:debug( "场景[%s]一次性预加载完毕..", g_methods:ObjectDetail( self ) )

end

-- 开始渲染
function BaseScene:onEnter()  
  
    self:SceneActived()   
    self:ListenBackKey()

    -- 自动缩放一次     
    if device.platform == "windows" or device.platform == "mac" then
        g_methods:CreateOnceCallback( 0.1, function()
            updateDisplay()
            local glview = cc.Director:getInstance():getOpenGLView()
            if  display.width > CONFIG_SCREEN_WIDTH and 
                display.height > CONFIG_SCREEN_HEIGHT then
                glview:setDesignResolutionSize( display.width, display.height, cc.ResolutionPolicy.EXACT_FIT )
            else    
                glview:setDesignResolutionSize( CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, cc.ResolutionPolicy.EXACT_FIT )
            end
            WindowResized( { width = display.width, height = display.height } )
        end )
    end
    
end

-- 不再渲染
function BaseScene:onExit()

    if self.quitgame_listener then
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:removeEventListener( self.quitgame_listener )
        self.quitgame_listener = nil
    end
    
    self:SceneInActived()
end

-- 游戏退出截获
function BaseScene:ListenBackKey()

    local onKeyReleased = function ( keycode, event )
--        if keycode == cc.KeyCode.KEY_BACKSPACE then
--            device.showAlert( "Confirm Exit", "Are you sure exit game ?", {"YES", "NO"}, 
--                function( event )
--                    if event.buttonIndex == 1 then
--                        app:exit()
--                    end
--                end )
--        end
    end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler( onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority( listener, self )
    self.quitgame_listener = listener

end

-- 场景前台激活
function BaseScene:SceneActived()

    g_methods:debug( "场景[%s]被激活...", g_methods:ObjectDetail( self ) )

    self.active_now = true

    -- 如果存在背景音乐,直接播放
    local bg_music = self.configs["bgmusic"]
    if bg_music then
        g_audio:AddBGMusics( bg_music )
        g_audio:PlayBG( true )
    end

    -- 已添加插件全激活
    g_methods:debug( "\t场景插件组激活..." )
    for i, comp in pairs( self.components ) do
        if comp then
            comp:Actived() 
        end
    end    

    -- 发布消息
    local data = { scene_class = self.scene_class, scene_id = self.scene_id }
    g_event:_SendEvent( ESE_SCENE_ACTIVED, data )

    -- 消息缓存关闭
    g_event:OpenCache( false )
    
end

-- 场景退出前台激活
function BaseScene:SceneInActived()

    g_methods:debug( "场景[%s]被反激活...", g_methods:ObjectDetail( self ) )

    self.active_now = false

    -- 背景音乐关闭
    local bg_music = self.configs["bgmusic"]
    if bg_music and bg_music ~= "" then
        g_audio:StopBG()
        g_methods:debug( "\t场景背景音乐停止..." )
    end

    -- 插件全清理
    self:CleanComponents()

    -- 预加载资源清理
    local preloads = self.configs["preloads"]
    if preloads then

        g_methods:debug( "\t预加载资源清理开始..." )
        -- 音效文件预加载
        local sounds = preloads["sounds"]
        if sounds then
            g_methods:debug( "\t\t音效文件卸载..." )
            for _, id in pairs(sounds) do
                local sound_file = "audios/" .. id
                audio.unloadSound( sound_file )
                g_methods:debug( "\t\t\t %s...", sound_file )
            end
        end

    end

    -- 专属对象库卸载
    local libraries = self.configs["libraries"]
    if libraries then
        g_methods:debug( "\t专属对象库卸载..." )
        for key, path in pairs( libraries ) do  
            g_library:DelLibrary( key )
        end     
    end

    -- 服务销毁
    local svr_list = self.configs["services"]
    if svr_list then
        for _, svrname in pairs(svr_list) do
            g_factory:DeleteByName( svrname ) 
        end
    end   

    -- 专属查询路径剔除
    local searchs = self.configs["search_paths"]
    if searchs then      
        g_methods:debug( "\t专属查询路径剔除..." )  
        local paths = cc.FileUtils:getInstance():getSearchPaths()
        for _, search_path in pairs(searchs) do     
            search_path = search_path .. "/"
            for key, path in pairs(paths) do
                local s, e = string.find( path, search_path )
                if s and e  == string.len( path ) then
                    paths[key] = nil
                    g_methods:debug( "\t\t %s", search_path )
                end
            end
        end

        paths = table.unique( paths, true )
        cc.FileUtils:getInstance():setSearchPaths(paths)
    end

    -- 发布消息
    local data = { scene_class = self.scene_class, scene_id = self.scene_id }
    g_event:_SendEvent( ESE_SCENE_INACTIVED, data )

    -- 界面销毁
    if self.scene_root then
        self.scene_root:removeFromParent()
        self.scene_root = 0
    end
    
end


-- 添加组件
function BaseScene:AddComponent( comp_name )

    -- 重复性检查
    local comp_obj = self:FindComponent( comp_name, true )
    if comp_obj ~= nil then
        g_methods:warn( "添加组件失败,组件[%s]重复添加...", comp_name )
        return comp_obj
    end

    -- 创建组件
    comp_obj = g_factory:Create( comp_name, comp_name, { bind_scene = self } )
    if comp_obj == nil then
        g_methods:warn( "添加组件失败,组件[%s]无效...", comp_name )
        return nil
    end    

    -- 记录并适时激活
    table.insert( self.components, comp_obj )
    if self.active_now then
        comp_obj:Actived()
    end
    
    g_methods:debug( "添加新组件[%s]成功...", g_methods:ObjectDetail( comp_obj ) )
    return comp_obj
    
end

-- 删除组件
function BaseScene:DelComponent( comp_name )

    -- 遍历查找
    for i, comp in pairs( self.components ) do
        if comp.obj_class == comp_name then
            comp:InActived()
            g_factory:Delete( comp )
            comp = nil
            g_methods:debug( "删除组件[%s]成功...", g_methods:ObjectDetail( comp_obj ) ) 
            return true
        end
    end
    
    g_methods:warn( "删除组件[%s]失败,组件不存在...", comp_name )
    return false
    
end

-- 获取组件
function BaseScene:FindComponent( comp_name, ignore_warn )

    -- 遍历查找
    for i, comp in pairs( self.components ) do
        if comp.obj_class == comp_name then
            return comp
        end
    end

    -- 找不到
    if ignore_warn ~= true then
        g_methods:warn( "查找组件[%s]失败,组件不存在...", comp_name )
    end
    return nil
    
end

-- 清空全部组件
function BaseScene:CleanComponents()

    g_methods:debug( "场景[%s]插件组销毁...", g_methods:ObjectDetail( self ) )
    for i, comp in pairs( self.components ) do
        if comp then
            comp:InActived()
            g_factory:Delete( comp )
        end
    end
    self.components = {}
    g_methods:debug( "场景[%s]插件组清空...", g_methods:ObjectDetail( self ) )

end

-- 打印组件信息
function BaseScene:DumpComponents()

    g_methods:debug( "场景[%s]组件信息如下:", g_methods:ObjectDetail( self ) )
    for i, comp in pairs( self.components ) do
        if comp then
            g_methods:debug( "\t%s.", comp.obj_class ) 
        end
    end

end

-- 创建新的对象
function BaseScene:CreateObject( object_id )

    -- 参数合法性检测
    if object_id == nil or object_id == "" then
        g_methods:error( "创建对象失败,对象编号无效!" )
        return nil
    end

    -- 查找对象配置信息
    local object_config = g_library:QueryConfig( object_id )
    if not object_config then
        g_methods:error( "创建对象[%s]失败,配置不存在!", object_id )
        return nil
    end

    -- 找到对象注册信息
    local obj_class = object_config.class
    local new_obj = g_factory:Create( obj_class, object_id )
    if not new_obj then
        g_methods:error( "创建对象失败,找不到对象注册信息! 类:%s, 编号:%s.", obj_class, object_id )
        return nil
    end

    -- 对象类创建并初始化
    if false == new_obj:ConfigObject( object_config ) then
        g_methods:error( "创建对象[%s]失败,对象配置失败...", g_methods:ObjectDetail( new_obj ) )
        return nil
    else
        g_methods:debug( "创建对象[%s]成功...", g_methods:ObjectDetail( new_obj ) )
        return new_obj     
    end

end

-- 获取场景根节点
function BaseScene:FindRoot()
    return self.scene_root
end

-- 通过名字获取某场景第一层次节点
function BaseScene:FindNode( node_name )    
    return self.scene_root:getChildByName( node_name )    
end

return BaseScene