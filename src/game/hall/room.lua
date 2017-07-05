-- center.lua
-- 2015-01-10
-- KevinYuen
-- 游戏房间

local jav_socket = import( ".socket" )
local BaseObject = require( "kernels.object" )
local JavRoom = class( "JavRoom", BaseObject )

-- 初始化
function JavRoom:OnCreate( args )

    JavRoom.super.OnCreate( self, args )   

    -- 配置总表加载
    self.configs = g_methods:ImportJson( "javgame.json" )
    if not self.configs then
        g_methods:error( "JAV游戏房间创建失败,找不到配置文件:javgame.json..." )
        return false
    end

    -- TABLE_MAX_USER定义检查
    if TABLE_MAX_USER == nil then
        g_methods:error( "JAV游戏房间创建失败,TABLE_MAX_USER必须定义..." )
        return false
    end
    
    -- 房间数据重置
    self:ResetRoom()

    -- 大厅事件监听
    self.msg_hookers = {
            { E_HALL_GAMEINFO, handler( self, self.OnRecRoomInfo ) },
            { E_CLIENT_MAINCONNECT, handler( self, self.OnMainNetEvent ) }
        }
    g_event:AddListeners( self.msg_hookers, "jav_room_events" )

    JavRoom.super.OnDestroy( self ) 
    
    return true
end

-- 销毁
function JavRoom:OnDestroy()

    -- 事件监听解除
    g_event:DelListenersByTag( "jav_room_events" )
    
    return true
    
end

-- 尝试连接
function JavRoom:ConnectServer()

    -- 主SOCKET创建
    if self.main_connect == nil then
        g_methods:log( "创建JAV主连接服务..." )
        self.main_connect = jav_socket.new( "jav_main_socket" )
    end

    -- 尝试连接
    local main_config = self.configs["main_server"]
    local ip_addr = jav_get_hallhost()
    local ip_port = jav_get_hallport()  
    local re_conn = main_config["reconnect"]
    self.main_connect:Connect( ip_addr, ip_port, re_conn )
    
end

-- 全房间数据重置
function JavRoom:ResetRoom()
end
       
-- 收到游戏房间数据
function JavRoom:OnRecRoomInfo( event_id, event_args )

    -- 覆盖更新
    g_methods:CopyTable( event_args, self ) 
    self:ResetRoom()
      
end

-- 接收SOCKET连接回调通告
function JavRoom:OnConnectionEvent( socket_id, event_type )

    -- 消息发布   
    local event_id = E_CLIENT_OTHERCONNECT
    if self.main_connect.name == socket_id then
        event_id = E_CLIENT_MAINCONNECT
    end
    
    local data = { socket = socket_id, event = event_type  }
    g_event:SendEvent( event_id, data )
    
end

-- 压入新的日志缓存
function JavRoom:PushSystemLog( content )
     
    if content and content ~= "" then
        table.insert( jav_systemlogs, content )
        g_event:SendEvent( E_CLIENT_SYSCHAT, { info = content } )
    end
end

-- 主连接事件
function JavRoom:OnMainNetEvent( event_id, event_args )

    -- 连接断开提示后关闭游戏
    if  event_args.event == "closed" or 
        event_args.event == "failed" or
        event_args.event == "breaked" then 

        -- 直接关闭
        app:exit()

        -- 提示关闭
        --        local modal_layer = require( "kernels.node.nodeModal" ).new()
        --        if not modal_layer:BindUIJSON( "msgbox.json" ) then
        --            return
        --        end
        --
        --        local pan_message = modal_layer:GetRoot():getChildByName( "panel" )
        --        
        --        local txt_content = pan_message:getChildByName( "content" )
        --        txt_content:setString( "已经与服务器断开连接,点击确认关闭游戏..." )
        --
        --        g_methods:WidgetVisible( pan_message, "yes", false )
        --        g_methods:WidgetVisible( pan_message, "no", false )
        --        g_methods:WidgetVisible( pan_message, "confirm", true )
        --        
        --        local btn_confirm = pan_message:getChildByName( "confirm" )    
        --        btn_confirm:addTouchEventListener(
        --            function( sender, eventType )
        --                if eventType == ccui.TouchEventType.ended then
        --                    app:exit()
        --                end
        --            end )
    end

end

return JavRoom