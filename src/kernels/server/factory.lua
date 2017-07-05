-- base_factroy.lua
-- 2015-02-10
-- KevinYuen
-- 对象工厂

local BaseObject = require( "kernels.object" )
local BaseFactory = class( "BaseFactory", BaseObject )

-- 构造
function BaseFactory:ctor()

    self.object_tag       = 10000   -- 对象UUID
    self.object_regmap    = {}      -- 注册表
    self.object_list      = {}      -- 实例表
    
end

-- 对象注册
function BaseFactory:Regist( obj_type, obj_class, obj_lua, obj_desc )

    -- 重复性检查
    local reg_info = self.object_regmap[obj_class]
    if reg_info ~= nil then
        g_methods:warn( "脚本对象[%s:%s]注册失败,重复注册...", obj_type, obj_class )
        return false
    end
    
    -- 注册
    self.object_regmap[obj_class] = {type = obj_type,
                                    name = obj_class,
                                    file = obj_lua,
                                    desc = obj_desc or "" }
    g_methods:debug( "脚本对象[%s:%s]注册完毕...", obj_type, obj_class )
    return true
    
end

-- 对象注销
function BaseFactory:Unregist( obj_class )

    -- 存在性检查
    local reg_info = self.object_regmap[obj_class]
    if reg_info == nil then
        g_methods:warn( "脚本对象[%s]注销失败,找不到注册信息...", obj_class )
        return false
    end
    
    -- 注销
    self.object_regmap[obj_class] = nil
    g_methods:debug( "脚本对象[%s:%s]注销完毕...", reg_info.type, obj_class ) 
    return true
    
end

-- 对象创建
function BaseFactory:Create( obj_class, obj_cfgid, args )

    -- 存在性检查
    local reg_info = self.object_regmap[obj_class]
    if reg_info == nil then
        g_methods:warn( "脚本对象[%s]创建失败,找不到注册信息...", obj_class )
        return nil
    end
    
    -- 创建
    local new_object = require( reg_info.file ).new() 
    if not new_object then
        g_methods:warn( "脚本对象[%s:%s]创建失败,脚本[%s]实例化失败...", reg_info.type, reg_info.name, reg_info.file ) 
        return nil
    end

    -- 初始化
    self.object_tag = self.object_tag + 1
    new_object.obj_tag = self.object_tag
    new_object.obj_type = reg_info.type 
    new_object.obj_class = reg_info.name 
    new_object.obj_cfgid = obj_cfgid or reg_info.name 
    args = args or {}
    if new_object.OnCreate ~= nil and new_object:OnCreate( args ) == false then
        g_methods:warn( "脚本对象[%s:%s]创建失败,初始化失败...", reg_info.type, reg_info.name ) 
        return nil
    end    
    
    -- 加入管理列表
    self.object_list[new_object.obj_tag] = new_object
    g_methods:debug( "脚本对象[%s:%s]创建完毕,Tag:%d...", new_object.obj_type, new_object.obj_class, new_object.obj_tag ) 
    
    return new_object
    
end

-- 对象按名查找
function BaseFactory:FindByName( obj_class )

    for tag, object in pairs( self.object_list ) do
        if object and object.obj_class == obj_class then
            return object
        end
    end
    return nil
    
end

-- 对象按Tag查找
function BaseFactory:FindByTag( obj_tag )
    return self.object_list[obj_tag] 
end

-- 对象销毁
function BaseFactory:Delete( obj_handle )

    for tag, object in pairs( self.object_list ) do
        if object == obj_handle then
            if object.OnDestroy ~= nil then
                object:OnDestroy()
                self.object_list[tag] = nil
                return true
            end
        end
    end
    return false
    
end

-- 对象销毁
function BaseFactory:DeleteByTag( obj_tag )

    -- 存在性检查
    local object = self.object_list[obj_tag]
    if not object then
        g_methods:warn( "脚本对象[Tag:%d]销毁失败,找不到实例...", obj_tag ) 
        return false
    end
    
    -- 销毁
    g_methods:debug( "脚本对象[%s:%s:%d]销毁...", object.obj_type, object.obj_class, object.obj_tag ) 
    if object.OnDestroy ~= nil then
        object:OnDestroy()
    end
    self.object_list[obj_tag] = nil
    
    return true
    
end

-- 对象按名销毁
function BaseFactory:DeleteByName( obj_class )

    -- 遍历整个列表,所有指定名字的对象全部销毁
    for tag, object in pairs( self.object_list ) do
        if object and object.obj_class == obj_class then
            self:DeleteByTag( tag )
        end
    end

end

-- 对象按类销毁
function BaseFactory:DeleteByType( obj_type ) 

    -- 遍历整个列表,所有指定类型的对象全部销毁
    for tag, object in pairs( self.object_list ) do
        if object and object.obj_type == obj_type then
            self:DeleteByTag( tag )
        end
    end 
    
end

-- 当前对象输出
function BaseFactory:Dump()
    
    g_methods:debug( "当前脚本对象输出..." )
    local count = 0
    for tag, object in pairs( self.object_list ) do
        if object then
            count = count + 1
            g_methods:debug( "\t[%d]: %s", count, g_methods:ObjectDetail( object ) )
        end
    end
    if count == 0 then
        g_methods:debug( "\t无对象..." )
    else
        g_methods:debug( "\t总计数量:%d", count )        
    end
end

return BaseFactory

