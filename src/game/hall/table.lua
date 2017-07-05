-- table.lua
-- 2015-01-11
-- KevinYuen
-- 游戏桌

require( "framework.cc.utils.bit" )
local BaseObject = require( "kernels.object" )
local BaseTable = class( "BaseTable", BaseObject )

-- 初始化
function BaseTable:OnCreate( args )

    -- 全局变量保存
    jav_table = jav_table or self
    
    BaseTable.super.OnCreate( self, args )
    
    -- 变量
    self.seatList = {}      -- 座位列表
    self.userList = {}      -- 用户列表
        
    -- 消息监听列表
    self.msg_hookers = {         
        { E_HALL_TABLEINFO,         handler( self, self.OnRecvTableInfo ) }, 
        { E_HALL_USERLIST,          handler( self, self.OnRecvUserList ) },
        { E_HALL_USERUPDATED,       handler( self, self.OnRecUserUpdate ) },
        { E_HALL_USERCOMEIN,        handler( self, self.OnRecUserComeIn ) },
        { E_HALL_USERLEFT,          handler( self, self.OnRecUserLeft ) },
        { E_HALL_USERCUT,           handler( self, self.OnRecUserCut ) },
        { E_HALL_USERCUTRETURN,     handler( self, self.OnRecUserCutReturn ) },
        { E_CLIENT_SITDOWN,         handler( self, self.OnUserSitDown ) },
        { E_CLIENT_STANDUP,         handler( self, self.OnUserStandUp ) }              
    }
    
    -- 消息监听
    g_event:AddListeners( self.msg_hookers, "base_table_events" )
    
    return true 
    
end

-- 销毁
function BaseTable:OnDestroy()

    -- 事件监听注销
    g_event:DelListenersByTag( "base_table_events" )
   
    -- 游戏玩法服务销毁
    g_factory:Delete( self.logic )
    
    -- 全局变量销毁
    jav_table = nil
    
    BaseTable.super.OnDestroy( self )
    
end

-- 获取指定座位
function BaseTable:getSeat( chairid )
    
    local seat = self.seatList[chairid]
    if seat then
        return seat
    end

    g_methods:error( "尝试获取非法座位失败:%d", chairid )
    
end

-- 全座位重置
function BaseTable:resetSeats()
    
    for _, seat in pairs( self.seatList ) do
        seat:reset()
    end
    
end

-- 获取用户列表
function BaseTable:getUserList()
    return self.userList
end

-- 查找用户
function BaseTable:queryUser( uid )

    local user = self.userList[uid]
    if not user then
        g_methods:warn( "查找用户失败,不存在相关数据:%d", uid )
    end
    return user
    
end

-- 查找玩家
function BaseTable:queryPlayer( chairid )
    
    local seat = self:getSeat( chairid )
    if seat and seat.uid > 0 then
        return self:queryUser( seat.uid )
    end
    
    g_methods:warn( "查找指定座位的玩家失败,座位为空:%d", chairid )
    return nil
    
end

-- 查找预约玩家
function BaseTable:queryDatePlayer( chairid )

    for uid, player in pairs( self.userList ) do
        if player and player.chairid == chairid and jav_isdating( uid ) then 
            return player 
        end
    end
    return nil
end

-- 获取指定用户的服务器座位号
function BaseTable:getChairId( uid )
    
    local user = self:queryUser( uid )
    if user then
        return user.chairid
    end
    
    g_methods:warn( "获取指定用户的服务器座位号失败:%d", uid )
    return -1
    
end

-- 服务器座位转本地座位号 chairid->seatNo 
function BaseTable:toSeatNo( chairid )
    
    local myChairId = self:getChairId( jav_self_uid ) 
    local mSeatNo = chairid - myChairId    
    if mSeatNo < 0 then
        mSeatNo = mSeatNo + TABLE_MAX_USER
    end
    return mSeatNo
    
end

-- 服务器座位转本地座位号 chairid->seatNo 
function BaseTable:toChairId( seatNo )

    local myChairId = self:getChairId( jav_self_uid ) 
    local chairId = seatNo + myChairId
    if chairId >= TABLE_MAX_USER then
        chairId = chairId - TABLE_MAX_USER
    end
    return chairId  
    
end

-- 座位号是否有效
function BaseTable:isGoodChairId( chairid )

    if chairid >= 0 and chairid < TABLE_MAX_USER then
        return true
    else
        return false
    end
    
end

-- 数据重置
function BaseTable:ResetData()

    self:resetSeats()
    
end

-- 更新座位当前的绑定用户
function BaseTable:CheckSeatBinder( player )

    -- 检查座位号是否有效 
    if self:isGoodChairId( player.chairid ) == false then
        g_methods:error( "座位[%d]绑定失败,用户[%d]的座位号非法...", player.chairid, player.uid )
        return
    end

    -- 如果是观众不处理
    local ret = bit.band( player.state, HUS_WATCHER )
    if ret ~= 0 then
        return
    end

    -- 如果是玩家,那么需要绑定到座位
    local seat_info = self:getSeat(player.chairid)
    if seat_info == nil then
        g_methods:error( "座位[%d]绑定失败,用户[%d]的座位号无效...", player.chairid, player.uid )
        return
    end

    -- 判断位置上是否已经存在绑定
    if seat_info.uid > 0 then
        g_methods:warn( "座位[%d]绑定玩家被直接替换[%d -> %d]...", player.chairid, seat_info.uid, player.uid )
    end

    -- 座位绑定,并重置
    seat_info.uid = player.uid
    g_methods:log( "玩家[%d]坐在了位置[%d]上...", player.uid, player.chairid )

    -- 发布用户上位事件
    local data = { uid = player.uid, chairid = player.chairid  }
    g_event:SendEvent( E_CLIENT_SITDOWN, data )

end

-- 收到玩家列表
function BaseTable:OnRecvUserList( event_id, event_args )
    
    -- 解析更新
    for index = 1, #(event_args.userarray) do 

        local player_tbl = event_args.userarray[index]

        -- chairid从1起始改变为0起始
        if player_tbl.chairid then 
            player_tbl.chairid = player_tbl.chairid - 1
        end

        -- 覆盖更新
        local player_uid = player_tbl.uid
        self.userList[player_uid] = self.userList[player_uid] or {}
        g_methods:CopyTable( player_tbl, self.userList[player_uid] ) 

        -- 判断是不是本地主角
        if self.userList[player_uid].ismyinfo == true then
        
            jav_self_uid = player_uid
            local data = { uid = player_uid, chairid = player_tbl.chairid  }
            g_event:SendEvent( E_CLIENT_ICOMEIN, data )
            
        end

        -- 检查是否上座位
        self:CheckSeatBinder( player_tbl )
    end

end

-- 收到玩家信息更新数据
function BaseTable:OnRecUserUpdate( event_id, event_args )

    --用户离开房间
    if self:getChairId(event_args.uid) == -1 then
        return 
    end

    -- UID必须存在
    local player_uid = event_args.uid
    if not player_uid then
        g_methods:warn( "玩家更新消息无效,必要参数不全..." )
        return
    end

    -- chairid从1起始改变为0起始
    if event_args.chairid then
        event_args.chairid = event_args.chairid - 1
    end

    self.userList[player_uid] = self.userList[player_uid] or {}

    -- 老信息保留
    local old_info = clone( self.userList[player_uid] )

    -- 新信息更新
    g_methods:CopyTable( event_args, self.userList[player_uid] ) 

    -- 如果是状态标记改变,细化状态改变通告
    if old_info.state and event_args.state then 

        -- 标记存在判断
        local has_flag = function( flags, flag )
            local ret = bit.band( flags, flag )
            return ret ~= 0
        end

        -- 映射表遍历
        for state, callback in pairs( PLAYER_STATECHANGED_MAP ) do

            local f_old = has_flag( old_info.state, state )
            local n_old = has_flag( event_args.state, state )
            if f_old ~= n_old and callback ~= nil then
                callback( player_uid, state, n_old == true )
                g_methods:debug( "玩家状态[%s]发生了改变...", tostring( player_uid ) ) 
            end

        end
    end

    --其他属性改变
    for prop, callback in pairs( PLAYER_PROPCHANGED_MAP ) do
        if event_args[prop] and callback ~= nil then
            callback( player_uid, prop, old_info[prop], event_args[prop] )
            g_methods:debug(  "玩家[%s]属性[%s]改变,[%s]->[%s]...", 
                tostring( player_uid ), prop, tostring( old_info[prop] ), tostring( event_args[prop] ) )
        end
    end

end

-- 收到玩家进入数据
function BaseTable:OnRecUserComeIn( event_id, event_args ) 

    -- chairid从1起始改变为0起始
    if event_args.chairid then
        event_args.chairid = event_args.chairid - 1
    end

    -- 解析更新
    local player_uid = event_args.uid
    self.userList[player_uid] = {}
    g_methods:CopyTable( event_args, self.userList[player_uid] ) 

    -- 检查是否上座位
    self:CheckSeatBinder( event_args )

    -- 如果是玩家
    local content, text = "", "" 
    local iswatcher = jav_iswatcher( event_args.uid )
    if iswatcher == false then

        text = g_library:QueryConfig( "text.hall_user_comin" )
        local sname = jav_format_richname( event_args.uid  )        
        content = string.format( text, sname )

        -- 如果是观战
    else

        local chairid = self:getChairId( event_args.uid )
        local player = jav_queryplayer_bychairid( chairid )
        local myname = jav_format_richname( event_args.uid  )

        -- 座位没人为预约,有为观战
        if player ~= nil then
            text = g_library:QueryConfig( "text.hall_watcher_comin" )
            local sname = jav_format_richname( player.uid )
            content = string.format( text, myname, sname )
        else
            text = g_library:QueryConfig( "text.hall_yuyue_comin" )
            content = string.format( text, myname, chairid + 1 )
        end
    end

    jav_room:PushSystemLog( content )

end

-- 收到玩家离开数据
function BaseTable:OnRecUserLeft( event_id, event_args )

    -- 无效UID检查    
    if not self.userList[event_args.uid] then
        g_methods:warn( "玩家离开消息处理失败,找不到[%d]的玩家...", event_args.uid )
        return
    end
   

    -- 日志输出
    local user = self:queryUser( event_args.uid )
    if user then

        -- 系统日志
        local text = g_library:QueryConfig( "text.hall_user_left" )
        local sname = jav_format_richname( event_args.uid  )     
        local content = string.format( text, sname ) 
        jav_room:PushSystemLog( content )
    end

    -- 解除座位绑定
    local chairid = self:getChairId( event_args.uid )
    local seat_info = self:getSeat(chairid)
    if seat_info ~= nil and seat_info.uid == event_args.uid then

        -- 解除
        seat_info.uid = 0

        --发布玩家离开座位事件
        local data = { uid = event_args.uid, chairid = chairid  }
        g_event:SendEvent( E_CLIENT_STANDUP, data )

    end

    -- 记录更新   
    self.userList[event_args.uid] = nil

end

-- 收到玩家断线数据
function BaseTable:OnRecUserCut( event_id, event_args )

    -- 无效UID检查    
    if not self.userList[event_args.uid] then
        g_methods:warn( "玩家断线消息处理失败,找不到[%d]的玩家...", event_args.uid )
        return
    end

    -- 记录更新   
    --self.userList[data.uid] = nil

    -- 日志输出
    local user = self:queryUser( event_args.uid )
    if user then

        -- 系统日志
        local text = g_library:QueryConfig( "text.hall_user_cut" )
        local sname = jav_format_richname( event_args.uid  )     
        local content = string.format( text, sname ) 
        jav_room:PushSystemLog( content )
    end

end

-- 收到玩家断线重入数据
function BaseTable:OnRecUserCutReturn( event_id, event_args )

    -- 无效UID检查    
    if not self.userList[event_args.uid] then
        g_methods:warn( "玩家断线重入消息处理失败,找不到[%d]的玩家...", event_args.uid )
        return
    end 

    -- 如果是自己掉线,那么数据重置
    if event_args.uid == jav_self_uid then
        self:ResetData()
    end

    -- 日志输出
    local user = self:queryUser( event_args.uid )
    if user then

        -- 系统日志
        local text = g_library:QueryConfig( "text.hall_user_cutreturn" )
        local sname = jav_format_richname( event_args.uid  )     
        local content = string.format( text, sname ) 
        jav_room:PushSystemLog( content )
    end
    
end

-- 桌子数据重置
function BaseTable:OnRecvTableInfo( event_id, event_args )

    -- 覆盖更新
    g_methods:CopyTable( event_args, self )

    -- 房间内用户信息清空
    self.userList = {}

    -- 房间内系统日志缓存
    jav_systemlogs = {}
    
        
end

-- 用户上了座位
function BaseTable:OnUserSitDown( event_id, event_args )
    self:getSeat( event_args.chairid ):reset()
end

-- 用户离开座位
function BaseTable:OnUserStandUp( event_id, event_args )
    self:getSeat( event_args.chairid ):reset()
end

return BaseTable