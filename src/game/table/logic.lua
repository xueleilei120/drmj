-- logic 模块
-- 2016-2-19
-- 吉森(josen)
-- 达人麻将逻辑部分

require( "framework.cc.utils.bit" )
local BaseObject = require( "kernels.object" )
local MJLogic = class( "MJLogic", BaseObject )

-- 初始化
function MJLogic:OnCreate( args )
    MJLogic.super.OnCreate( self, args )
    return true    
end

-- 销毁
function MJLogic:OnDestroy()
    MJLogic.super.OnDestroy( self )    
end

return MJLogic