-- game.lua
-- 2014-10-17
-- KevinYuen
-- 游戏启动脚本

require("config")
require("cocos.init")
require("framework.init")
require("kernels.init")

-- 垃圾收集
collectgarbage("collect")
--collectgarbage("setpause", 200)
--collectgarbage("setstepmul", 10000)

-- 随机种子
local seed = os.time()
math.randomseed( seed )
g_methods:debug( "随机种子[%d]...", seed )

-- 设置资源查询目录
local file_utils = cc.FileUtils:getInstance()
file_utils:addSearchPath( "../runtime/res/" )
file_utils:addSearchPath( "res/" )
file_utils:addSearchPath( "res/configs/" )
file_utils:addSearchPath( "res/anis/" )
file_utils:addSearchPath( "res/audios/" )

local MyApp = class( "MyApp", cc.mvc.AppBase )

function MyApp:ctor()
    MyApp.super.ctor(self)          
end

-- 游戏启动
function MyApp:run()

    -- 全局变量定义
    g_application = self

    -- 核心脚本初始化
    kernel_create() 
    
    -- 扑克模块加载
    require( "game.init" )
    
    -- 模块初始化
    g_modules:LoadAll()
        
    -- 进入菜单场景
    self:SwitchScene( "scene.login" )  
    
end 

function MyApp:exit()

    g_methods:debug( "游戏即将退出!" )

    -- 模块销毁
    g_modules:UnloadAll()
    
    -- 核心脚本销毁
    kernel_destroy()

    g_methods:debug( "游戏退出!" )
    
    MyApp.super.exit(self)
    
end

-- 场景切换
-- loading_scene_id: 配置后则使用过渡场景,老资源可以提前卸载
function MyApp:SwitchScene( target_scene_id, loading_scene_id )

    -- 记录当前场景
    self.last_sceneid = ""
    local run_scene = display.getRunningScene()
    if run_scene then
        self.last_sceneid = run_scene.scene_id
    end
    
    -- 重复切换不处理
    if self.last_sceneid == target_scene_id then
        return
    end

    self.last_sceneid = target_scene_id
    
    -- 是否需要过渡
    local need_loading = false
    if loading_scene_id and loading_scene_id ~= "" then
        need_loading = true
    end

    -- 确认当前要加载的场景
    local load_scene_id = target_scene_id
    if need_loading == true then
        load_scene_id = loading_scene_id
    end

    -- 从场景库中查找配置
    local scene_config = g_library:QueryConfig( load_scene_id )
    if not scene_config then
        g_methods:error( "切换场景失败,没有找到过渡场景[%s]的配置信息...", load_scene_id )
        return false
    end 

    -- 确认加载场景对应的场景类
    local scene_class = scene_config["class"]
    if not scene_class or scene_class == "" then
        g_methods:error( "切换场景失败,没有找到过渡场景[%s]的场景类配置...", load_scene_id )
        return false
    end
    
    -- 老场景资源卸载
    if run_scene and run_scene.SceneInActived then
        run_scene:SceneInActived()
    end

    -- 场景创建
    local args = { target_scene_id = target_scene_id }
    local load_scene = g_factory:Create( scene_class, load_scene_id, args )
    if not load_scene then
        g_methods:error( "切换场景失败,没有找到过渡场景[%s]的场景类[%s]注册信息...", load_scene_id, scene_class )
        return false
    end
    
    -- 一次性加载并切换场景
    load_scene:PreloadAllAtOnce()
    
    if need_loading == false then
        load_scene:ScenePrepareActived()
    end
    
    display.replaceScene( load_scene, "fade", 0.1, display.COLOR_WHITE )      
    
end

return MyApp
