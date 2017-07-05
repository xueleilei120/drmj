-- module.lua
-- 2015-02-10
-- KevinYuen
-- 模块管理

local BaseObject = require( "kernels.object" )
local ModuleManager = class( "ModuleManager", BaseObject )

-- 构造
function ModuleManager:ctor()

    self.modules = {}   -- 模块列表
    
end

-- 模块注册
function ModuleManager:Regist( module_name, handler_init, handler_destroy, module_desc )

    local add_data = function( tbl, item_key, item_args )
    
        -- 重复加入检测
        if tbl[item_key] then return false end
        -- 添加
        tbl[item_key] = item_args
        return true
        
    end
    
    local ret = add_data( self.modules, module_name,
        {   isloaded        = false,
            name            = module_name,
            load_func       = handler_init, 
            unload_func     = handler_destroy,
            desc            = module_desc or "" } )

    if ret == true then
        g_methods:debug( "模块[%s]注册完毕...", module_name )
    else
        g_methods:warn( "模块[%s]注册失败...", module_name )
    end
    
    return ret

end

-- 模块注销
function ModuleManager:Unregist( module_name )

    local del_data = function( tbl, item_key )
    
        -- 存在性检测
        if not tbl[item_key] then return false end
        
        -- 删除
        tbl[item_key] = nil
        return true
        
    end
    
    local ret = del_data( self.modules, module_name )
    if ret == true then
        g_methods:debug( "模块[%s]注销完毕...", module_name )
    else
        g_methods:warn( "模块[%s]注销失败,找不到...", module_name )
    end
    
    return ret

end

-- 模块加载
function ModuleManager:Load( module_name )

    -- 表项加载
    local load_item = function( tbl, item_key )
    
        -- 合法性检测
        local item_info = tbl[item_key]
        if  item_info == nil or 
            item_info.isloaded == nil or 
            item_info.load_func == nil then
            g_methods:error( "表项[%s]加载失败,参数不完整..", item_key )
            return false
        end
        -- 已经加载的不处理
        if item_info.isloaded == true then
            g_methods:warn( "表项[%s]已经加载,重复加载不予处理...", item_key )
            return false
        else
            item_info.load_func()
            tbl[item_key].isloaded = true
            return true
        end
        
    end
    
    local ret = load_item( self.modules, module_name )
    if ret == true then
        g_methods:debug( "模块[%s]加载完毕...", module_name )
    else
        g_methods:warn( "模块[%s]加载失败,找不到...", module_name )
    end
    
    return ret

end

-- 模块卸载
function ModuleManager:Unload( module_name )

    -- 表项卸载(专用)
    local unload_item = function( tbl, item_key )
    
        -- 合法性检测
        local item_info = tbl[item_key]
        if  item_info == nil or 
            item_info.isloaded == nil or 
            item_info.unload_func == nil then
            g_methods:error( "表项[%s]卸载失败,参数不完整..", item_key )
            return false
        end
        -- 已经卸载的不处理
        if item_info.isloaded == false then
            g_methods:warn( "表项[%s]已经卸载,重复卸载不予处理...", item_key )
            return false
        else
            item_info.unload_func()
            tbl[item_key].isloaded = false
            return true
        end
        
    end
    
    local ret = unload_item( self.modules, module_name )
    if ret == true then
        g_methods:debug( "模块[%s]卸载完毕...", module_name )
    else
        g_methods:warn( "模块[%s]卸载失败,找不到...", module_name )
    end
    
    return ret

end

-- 模块全加载
function ModuleManager:LoadAll()
    for module_id, module_config in pairs( self.modules ) do
        self:Load( module_id )
    end    
end

-- 模块全卸载
function ModuleManager:UnloadAll()
    for module_id, module_config in pairs( self.modules ) do
        self:Unload( module_id )
    end
end

return ModuleManager

