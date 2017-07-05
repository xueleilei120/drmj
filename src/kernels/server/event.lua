-- event.lua
-- 2014-10-28
-- KevinYuen
-- 自家消息中心

local BaseObject = require( "kernels.object" )
local EventCenter = class( "EventCenter", BaseObject )

-- 初始化
function EventCenter:OnCreate( args )

    EventCenter.super.OnCreate( self, args )
    
    -- 监听返回值定义
    self.RET_PASS   = 0         -- 普通处理
    self.RET_EXCLUSIVE = 1      -- 独占处理

    -- 参数初始化
    self.hcounter = 1           -- 句柄计数器
    self.iscaching = false      -- 消息缓冲
    self.listeners = {}         -- 监听者列表
    self.msgcaches = {}         -- 缓存消息队列
    self.maincache = 1          -- 主缓冲
    self.backcache = 2          -- 副缓冲
    
    -- 创建高频计时器用来发布Post消息
    local sched = cc.Director:getInstance():getScheduler()
    self.ticker = sched:scheduleScriptFunc( function( dt ) 
                                                self:_PopCaches()
                                            end, 0.01, false )
end

-- 销毁
function EventCenter:OnDestroy()

    -- 计时器销毁
    local sched = cc.Director:getInstance():getScheduler()
    sched:unscheduleScriptEntry( self.ticker )
    self.ticker = nil
    
    EventCenter.super.OnDestroy( self ) 
    
end

-- 打开/关闭消息缓存功能
function EventCenter:OpenCache( opened )

    self.iscaching = opened
    --jav_opencache( opened )
    if opened == true then
        g_methods:output( "开启消息缓存" )
    else
        g_methods:output( "关闭消息缓存" )
	self:_PopCaches()
    end
    
end

-- 发送自定义消息
function EventCenter:SendEvent( event_id, event_args )

    -- 如果处于缓存阶段,那么缓存,否则直接发布
    if self.iscaching == true then
        self:_CacheEvent( event_id, event_args )
    else
        self:_SendEvent( event_id, event_args )
    end

end

-- 发送自定义消息
function EventCenter:PostEvent( event_id, event_args )
    
    -- 直接缓存
    self:_CacheEvent( event_id, event_args )
    
end

-- 监听消息
function EventCenter:AddListener( event_id, _callback, _tag )
    
    -- 参数合法性检查
    if event_id == ""  or not _callback then
        g_methods:error( "监听自定义失败,参数无效!" )
        return -1
    end
    
    -- 该事件首次监听
    if self.listeners[event_id] == nil then
        self.listeners[event_id] = {}
    end
    
    -- 句柄生成并加入管理
    self.hcounter = self.hcounter + 1
    table.insert( self.listeners[event_id], 
                        { 
                        handle = self.hcounter,
                        callback = _callback,
                        tag = _tag
                        })        
    return self.hcounter
    
end

-- 解除监听
function EventCenter:DelListener( _handle )
    
    -- 参数合法性检查
    if not _handle or _handle <= 0 then
        g_methods:warn( "解除监听失败,监听句柄无效!" );
        return false
    end
    
    -- 遍历删除
    for id, listeners in pairs( self.listeners ) do
        for key, lsn in pairs( listeners ) do
            if lsn and lsn.handle == _handle then
                table.remove( listeners, key )
                return true
            end
        end
    end

    -- 没有找到
    g_methods:error( "解除监听失败,没有找到句柄[%d]的监听回调!", _handle )
    return false
    
end

-- 批量监听消息
function EventCenter:AddListeners( event_list, _tag )

    -- 参数合法性检查
    if not event_list or #event_list == 0 or not _tag then
        g_methods:error( "批量监听失败,参数不完备!" )
        return false
    end

    -- 逐个加入监听
    for _, item in pairs( event_list ) do
        self:AddListener( item[1], item[2], _tag )
    end

    return true

end

-- 解除所有指定Tag的监听
function EventCenter:DelListenersByTag( _tag )

    -- 参数合法性检查
    if _tag == nil then
        g_methods:warn( "解除监听失败,参数Tag无效!" );
        return false
    end

    -- 遍历删除
    local del_count = 0
    for id, listeners in pairs( self.listeners ) do
        for key, lsn in pairs( listeners ) do
            if lsn and lsn.tag == _tag then
                table.remove( listeners, key )
                del_count = del_count + 1  
                break              
            end
        end
    end

    g_methods:debug( "解除[%d]个Tag为[%s]的监听绑定...", del_count, tostring(_tag) )
    return true
    
end

-- 解除所有监听
function EventCenter:CleanListeners()
    
    self.listeners = {}
    g_methods:debug( "解除所有自定义事件的监听." )
    
end

-- 弹出缓存消息
function EventCenter:_PopCaches()

    -- 缓存期间不执行该操作
    if self.iscaching == true then
        return
    end
    
    while #self.msgcaches > 0 do     
    
        if self.iscaching == true then
            break 
        end
        
        local event = self.msgcaches[1]
        table.remove( self.msgcaches, 1 )
        if event and event.id then
            self:_SendEvent( event.id, event.args )
        end
         
    end
    
--    -- 缓存独立出来
--    local caches = clone( self.msgcaches )
--    self.msgcaches = {}
--
--    -- 消息全发布
--    for _, event in pairs( caches ) do
--        self:_SendEvent( event.id, event.args )
--    end
    
end

-- 缓存消息
function EventCenter:_CacheEvent( event_id, event_args )

    if event_id == nil then
        g_methods:error( "缓存消息失败,无效的消息编号!" )
    else
        --g_methods:debug( "缓存消息: " .. event_id )
        table.insert( self.msgcaches, { id = event_id, args = event_args } )
    end    
    
end

-- 插入消息最缓存最前面
function EventCenter:_InsertFront( event_id, event_args )

    if event_id == nil then
        g_methods:error( "插入缓存消息失败,无效的消息编号!" )
    else
        table.insert( self.msgcaches, 1, { id = event_id, args = event_args } )
    end
end

-- 发布消息
function EventCenter:_SendEvent( event_id, event_args )

    if jav_is_debugmode() == false then
        g_methods:log( "DEAL EVENT->[%20s]", event_id )
    else
        g_methods:log( "DEAL EVENT->[%20s] ARGS:%s", event_id , json.encode( event_args ) )
    end
    
    local lsnlist = self.listeners[event_id]
    if lsnlist then
        local temps = clone( lsnlist )
        for _, lsn in pairs( temps ) do
            local ret = lsn.callback( event_id, event_args )
            if ret == self.RET_EXCLUSIVE then
                break 
            end
        end
    end
    
end

return EventCenter