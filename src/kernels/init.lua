-- init.lua
-- 2015-01-05
-- KevinYuen
-- 核心脚本初始化

require( "kernels.define" )
require( "kernels.node.nodeTouch" )

-- 创建对象工厂和模块工厂
g_factory = require( "kernels.server.factory" ).new()
g_modules = require( "kernels.server.module" ).new()
g_methods = require( "kernels.server.methods" ).new()

-- 获取当前版本
function kernel_getversion()
    return "v1.0.1"
end

-- 核心脚本初始化
function kernel_create()
    
    g_methods:debug( "核心脚本初始化开始..." )
    
    g_methods:debug( "\t核心服务注册..." )
    
    -- 服务注册
    g_factory:Regist( "service",    "BaseLibrary",      "kernels.server.library",   "基础配置库" )
    g_factory:Regist( "service",    "SaveData",         "kernels.server.save",      "存档数据" )
    g_factory:Regist( "service",    "EventCenter",      "kernels.server.event",     "事件中心" )
    g_factory:Regist( "service",    "AudioManager",     "kernels.server.audio",     "音效管理" )

    -- 场景注册
    g_factory:Regist( "scene",      "BaseScene",        "kernels.scene.base",       "基础场景" )
    g_factory:Regist( "scene",      "LoadingScene",     "kernels.scene.load",       "过渡场景" )
    
    -- 核心服务实例化
    g_methods:debug( "\t核心服务实例化..." )
    g_mainrole = nil
    g_library = g_factory:Create( "BaseLibrary" )
    g_save = g_factory:Create( "SaveData" )
    g_event = g_factory:Create( "EventCenter" )
    g_audio = g_factory:Create( "AudioManager" )
    
    -- 本地化文本库加载
    local local_file = "chinese.json"
    if device.language ~= "cn" then
        local_file = "english.json"
    end
    g_library:AddLibrary( "text", local_file )
    
    
    -- 音量初始化
    local now_musicVol = g_save.configs.system.music_volume
    g_audio:SetBGVolume( now_musicVol )
    local now_soundVol = g_save.configs.system.sound_volume
    g_audio:SetSoundVolume( now_soundVol )

    g_methods:debug( "核心脚本初始化结束..." )

end

-- 核心脚本销毁
function kernel_destroy()

    g_methods:debug( "核心脚本销毁开始..." )

    -- 场景类注销
    g_factory:Unregist( "LoadingScene" )
    g_factory:Unregist( "BaseScene" )

    -- 核心服务注册
    g_factory:Unregist( "BaseLibrary" )
    g_factory:Unregist( "SaveData" )
    g_factory:Unregist( "EventCenter" )
    g_factory:Unregist( "AudioManager" )

    -- 存档
    g_save:Shutdown()

    -- 服务卸载/注销
    g_factory:DeleteByType( "service" )

    g_methods:debug( "核心脚本销毁完毕..." )
    
    -- 输出残留日志
    --g_factory:dump()

end

