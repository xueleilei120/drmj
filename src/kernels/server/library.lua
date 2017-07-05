-- library.lua
-- 2015-01-17
-- KevinYuen
-- 对象库

--[[--

管理所有游戏对象,通过命名规则统一管理
对象库为JSON格式的配置文件,通过EXCEL配置,工具导出,对象配置属性可以完全不同

标准对象类型有:
    item:       道具
    state:      状态
    object:     对象
    animation:  帧动画
    armature:   骨骼动画

对象库配置文件命名规则:
    [库编号].json
        比如: 
                item.json       -- 道具库
                object.json     -- 对象库
    
对象编号命名规则:
    [库编号].[对象编号]
        比如:
                item.tangcubaigu                -- 道具库-糖醋排骨
                
查找规则
    编号支持二级库查找
]]

local BaseObject = require( "kernels.object" )
local BaseLibrary = class( "BaseLibrary", BaseObject )

-- 初始化
function BaseLibrary:OnCreate( args )
    BaseLibrary.super.OnCreate( self, args )   
    self.database = {}  -- 载入数据库 
end

-- 销毁
function BaseLibrary:OnDestroy()
    BaseLibrary.super.OnDestroy( self )  
end

-- 解析对象类型
function BaseLibrary:ParseObjectType( object_id )

    -- 拆分
    local splits = string.split( object_id, '.' )
    if not splits or #splits < 2 then
        return "", object_id
    end
    
    -- 组合    
    local lib_type, real_id = splits[1], splits[2]
    if #splits > 2 then
        for index = 3, #splits do
            --real_id = real_id + "." + splits[index]
            real_id = string.format( "%s.%s", real_id, splits[index] )
        end
    end

    return lib_type, real_id

end

-- 添加对象库
function BaseLibrary:AddLibrary( lib_key, lib_path )
                
    -- 库创建
    if not self.database[lib_key] then
        self.database[lib_key] = {}
        g_methods:log( "创建新库[%s]...", lib_key )
    end
        
    -- 加载
    self.database[lib_key] = g_methods:ImportJson( lib_path )
    if not self.database[lib_key] then
        g_methods:error( "添加对象库失败,对象库配置文件读取失败! %s.", lib_path )  
        return false        
    else
        g_methods:log( "添加对象库[%s]成功! 载入文件:%s.", lib_key, lib_path )
    end
    
    return true
end

-- 删除对象库
function BaseLibrary:DelLibrary( lib_key )

    -- 存在性判断
    if not self.database[lib_key] then
        g_methods:warn( "卸载对象库失败,指定库[%s]并未添加过!", lib_key )
        return false
    end

    -- 卸载
    if self.database[lib_key] then
        self.database[lib_key] = nil
        g_methods:log( "卸载对象库成功! %s.", lib_key )
    end
    
    return true

end

-- 获取对象库
function BaseLibrary:GetLibrary( lib_key )

    -- 存在性判断
    if not self.database[lib_key] then
        g_methods:warn( "获取对象库失败,指定库[%s]并未添加过!", lib_key )
        return nil
    end

    return self.database[lib_key]

end

-- 清空数据库
function BaseLibrary:Clean()

    self.database = {}
    g_methods:log( "对象数据库清理成功!." )
    
end

-- 查找指定对象配置
function BaseLibrary:QueryConfig( object_id )

    -- 类别解析
    local lib_key, real_id = self:ParseObjectType( object_id )
    if lib_key == "" or real_id == "" then
        return nil, string.format( "不合规范的对象编号配置[%s],请按照[主库.编号]的方式命名配置库文件名..", object_id )
    end
    
    -- 子库是否存在
    if not self.database[lib_key] then
        return nil, string.format( "查找对象[%s]的配置失败,找不到其匹配的库[%s]信息...", object_id,  lib_key )
    end
    
    -- 查找
    local object_config = self.database[lib_key][object_id]
    if not object_config then
        return nil, string.format( "查找指定配置失败,参数对象配置找不到[%s]...", object_id )
    end
    
    return object_config
    
end

-- 根据配置创建一个帧动画
function BaseLibrary:CreateAnimation( anim_id )

    -- 动画查找,如果已经加载了直接返回
    local anim_cache = cc.AnimationCache:getInstance()
    local animation = anim_cache:getAnimation( anim_id )
    if animation then
        return animation, animation.max_size
    end
    
    -- 否则通过配置创建
    local anim_config, faild_reason = self:QueryConfig( anim_id )
    if not anim_config then
    	g_methods:warn( faild_reason )
        return nil
    end
    return self:CreateAnimationEx( anim_config )
end  


function BaseLibrary:CreateAnimationEx( anim_config )

    -- 如果存在序列帧PLIST则加载
    local frames_plist = anim_config["file"]
    if frames_plist and frames_plist ~= "" then
        local res_file = frames_plist .. ".plist"
        local res_png = frames_plist .. ".png"
        display.addSpriteFrames( res_file, res_png )
    end

    -- 组成帧动画
    local frame_count = anim_config["frames"]
    local frame_files = anim_config["format"]
    local frame_fps   = anim_config["fps"]
    local frame_start = anim_config["startf"] or 0
    local frames = display.newFrames( frame_files, frame_start, frame_count )
    local animation = nil
    if sec then 
        animation = display.newAnimation( frames, sec / frame_count )
    else
        animation = display.newAnimation( frames, 1 / frame_fps )
    end

    -- 统计最大帧的尺寸
    local width = frames[1]:getRect().width
    local height = frames[1]:getRect().height
    if #frames > 1 then
        for index = 2, #frames do
            local rct = frames[index]:getRect()
            if rct.width > width then
                width = rct.width
            end
            if rct.height > height then
                height = rct.height
            end
        end
    end

    animation.max_size = { width = width, height = height }
    return animation, animation.max_size
    
end  
return BaseLibrary