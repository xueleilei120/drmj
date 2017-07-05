-- object.lua
-- 2015-01-26
-- KevinYuen
-- 游戏对象基类

local BaseObject = class( "BaseObject" )

-- 初始化
function BaseObject:OnCreate( args )

    -- 参数赋值
    if args ~= nil then
        g_methods:CopyTable( args, self )
    end    
    g_methods:debug( "对象[%s]创建...", g_methods:ObjectDetail( self ) ) 
    
    return true
    
end

-- 销毁
function BaseObject:OnDestroy()
    g_methods:debug( "对象[%s]销毁...", g_methods:ObjectDetail( self ) ) 
end

-- 激活前
function BaseObject:PreActived()
    g_methods:debug( "对象[%s]激活前准备...", g_methods:ObjectDetail( self ) )  
end

-- 激活
function BaseObject:Actived()
    g_methods:debug( "对象[%s]激活...", g_methods:ObjectDetail( self ) )   
end

-- 反激活
function BaseObject:InActived()    
    g_methods:debug( "对象[%s]反激活.", g_methods:ObjectDetail( self ) )    
end

return BaseObject