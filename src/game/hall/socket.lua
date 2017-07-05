-- socket.lua
-- 2015-01-11
-- KevinYuen
-- JAV网络连接

local bt = require( "framework.cc.utils.bit" )
local ba = require( "framework.cc.utils.ByteArray" )
local socket = require( "framework.cc.net.SocketTCP" )
local JavSocket = class( "JavSocket" )

-- 构造函数
function JavSocket:ctor( _name )

    -- 参数保存
    self.tcp_socket     = nil
    self.name           = _name or "unknown_socket"
    self.host           = "";
    self.port           = 0;
    self._retryConnect  = false;
    self.connected      = false
        
end

-- 连接
function JavSocket:Connect( _host, _port, _retryConnect )

    -- 如果已经连接了,无法再次连接(不同地址重新创建即可)
    if self.connected == true then
        g_methods:warn( "已经连接到服务器,重复连接请求拒绝处理..." )
        return false
    end

    -- 变量设置
    self.host           = _host;
    self.port           = _port;
    self._retryConnect  = _retryConnect;
    
    -- 首次先创建
    if self.tcp_socket == nil then
        self.tcp_socket = socket.new( self.host, self.port, self.retryConnect )
        self.tcp_socket:addEventListener( socket.EVENT_CONNECTED, handler(self, self.OnConnectSuc) )
        self.tcp_socket:addEventListener( socket.EVENT_CLOSE, handler(self,self.OnClose) )
        self.tcp_socket:addEventListener( socket.EVENT_CLOSED, handler(self,self.OnDisconnect) )
        self.tcp_socket:addEventListener( socket.EVENT_CONNECT_FAILURE, handler(self,self.OnConnectFailed ))
        self.tcp_socket:addEventListener( socket.EVENT_DATA, handler(self,self.OnReceiveData) )
    end
    
    -- 连接
    g_methods:warn( "[%s]尝试服务器连接:%s:[%d]...", self.name, self.host, self.port )
    self.tcp_socket:connect()
    jav_room:OnConnectionEvent( self.name, "start" )
    return true
       
end

-- 连接成功
function JavSocket:OnConnectSuc( _event )
    g_methods:warn( "[%s]服务器连接成功.", self.name )
    self.connected = true
    jav_room:OnConnectionEvent( self.name, "done" )
end

-- 连接失败
function JavSocket:OnConnectFailed( _event )
    g_methods:warn( "[%s]服务器连接失败.", self.name )
    self.connected = false
    jav_room:OnConnectionEvent( self.name, "failed" )
end

-- 连接关闭
function JavSocket:OnClose( _event )
    g_methods:warn( "[%s]服务器连接关闭.", self.name )
    self.connected = false
    jav_room:OnConnectionEvent( self.name, "closed" )
end

-- 连接断开
function JavSocket:OnDisconnect( _event )
    g_methods:warn( "[%s]服务器连接断开.", self.name )
    self.connected = false
    jav_room:OnConnectionEvent( self.name, "breaked" )
end

-- 接到数据
function JavSocket:OnReceiveData( _event )
    self:PushRecDataAndParse( _event.data )
end

-- 发送平台级消息
function JavSocket:SendFrameMsg( message )

    -- 没有连接则发送失败
    if  self.connected == false then
        g_methods:warn( "[%s]尚未连接到服务器,发送数据失败!", self.name )
        return false
    end
    
    -- 日志
    g_methods:output( "发布消息: %s.", message )

    -- 数据包组织,按照包大小的限制,将包分为若干子包发送   
    local pack_count = string.len( message ) / JNET_FRAMEJSON_DATA_MAXSIZE + 1
    local full_count = pack_count
    local last_remain = string.len(message) % JNET_FRAMEJSON_DATA_MAXSIZE
    if last_remain > 0 then
        full_count = full_count - 1 
    end
    
    -- 整包发送
    local pack_index = 1
    if math.floor( full_count ) > 0 then
        for index = 1, full_count do
            local header_st = stJavNetHeader()
            header_st.wSize = JNET_MAX_PAKSIZE
            header_st.bOrdinalMsg = 0
            header_st.bRequestMsg = 0
            header_st.bRespondMsg = 0
            header_st.bMainID = JNET_IPC
            header_st.bAssistantID = JNET_FRAMEID
            local header_bytes = stJavNetHeaderBytes()
            jav_bytes_comheader( header_st, header_bytes )
            local new_ba = ba.new()
            new_ba:setPos(1)
            new_ba:writeUByte( header_bytes.c1 )
            new_ba:writeUByte( header_bytes.c2 )
            new_ba:writeUByte( header_bytes.c3 )
            new_ba:writeUByte( header_bytes.c4 )
            new_ba:writeUByte( pack_index )
            new_ba:writeUByte( pack_count )   
            local fromp = JNET_FRAMEJSON_DATA_MAXSIZE * ( index - 1 ) + 1
            local endp = JNET_FRAMEJSON_DATA_MAXSIZE * index       
            local data = string.sub( message, fromp, endp )
            new_ba:writeUShort( string.len( data ) )
            new_ba:writeString( data )
            new_ba:setPos( 1 )
            self.tcp_socket:send( new_ba:readString( new_ba:getLen() ) )
            pack_index = pack_index + 1
        end
    end
    
    -- 剩余发送
    if last_remain > 0 then
        local header_st = stJavNetHeader()
        header_st.wSize = JNET_FRAMEJSON_HEADER_SIZE + last_remain
        header_st.bOrdinalMsg = 0
        header_st.bRequestMsg = 1
        header_st.bRespondMsg = 1
        header_st.bMainID = JNET_IPC
        header_st.bAssistantID = JNET_FRAMEID
        local header_bytes = stJavNetHeaderBytes()
        jav_bytes_comheader( header_st, header_bytes )
        local new_ba = ba.new()
        new_ba:setPos(1)
        new_ba:writeUByte( header_bytes.c1 )
        new_ba:writeUByte( header_bytes.c2 )
        new_ba:writeUByte( header_bytes.c3 )
        new_ba:writeUByte( header_bytes.c4 )
        new_ba:writeUByte( pack_index )
        new_ba:writeUByte( pack_count )     
        local data = string.sub( message, -last_remain )
        new_ba:writeUShort( string.len( data ) )
        new_ba:writeString( data )
        new_ba:setPos( 1 )
        local real_send = new_ba:readString( new_ba:getLen() )
        self.tcp_socket:send( real_send )
    end  
        
end

-- 发送游戏自定义消息
function JavSocket:SendGameMsg( message )

    -- 没有连接则发送失败
    if  self.connected == false then
        g_methods:error( "[%s]尚未连接到服务器,发送数据失败!", self.name )
        return false
    end
    
    -- 游戏数据不能超过指定长度
    local msg_len = string.len( message )
    if msg_len > JNET_GAMETRANS_DATA_MAXSIZE then
        g_methods:error( "[%s]发送数据长度超过自定义消息限制,发送失败!", self.name )
        return false
    end
    
    -- 游戏数据为空,不发送
    if msg_len == 0 then
        g_methods:error( "[%s]发送空数据,发送失败!", self.name )
        return false
    end
    
    local header_st = stJavNetHeader()
    header_st.wSize = JNET_GAMETRANS_HEADER_SIZE + msg_len
    header_st.bOrdinalMsg = 0
    header_st.bRequestMsg = 1
    header_st.bRespondMsg = 1
    header_st.bMainID = JNET_IPC
    header_st.bAssistantID = JNET_GAMEID
    local header_bytes = stJavNetHeaderBytes()
    jav_bytes_comheader( header_st, header_bytes )
    local new_ba = ba.new()
    new_ba:setPos(1)
    new_ba:writeUByte( header_bytes.c1 )
    new_ba:writeUByte( header_bytes.c2 )
    new_ba:writeUByte( header_bytes.c3 )
    new_ba:writeUByte( header_bytes.c4 )
    new_ba:writeString( message )
    new_ba:setPos( 1 )
    local real_send = new_ba:readString( new_ba:getLen() )
    self.tcp_socket:send( real_send )

end

-- 接受的数据压入缓存开始解析
function JavSocket:PushRecDataAndParse( data )

    -- 新数据压入到缓存中
    self.rec_cache = self.rec_cache or "" 
    self.rec_cache = self.rec_cache .. data 
    
    -- 初始化当前消息缓存
    self.cur_message = self.cur_message or {}
    
    -- 新建字节序开始解析数据
    local head_st = stJavNetHeader()
    local new_ba = ba.new()
    new_ba:writeBuf( self.rec_cache )
    new_ba:setPos(1)
    
    -- 循环解析整个缓存,直到出现残包的情况
    local msg_count = 1
    while true do
    
        -- 读完了结束
        if new_ba:getPos() >= new_ba:getLen() then
            self.rec_cache = ""
            break
        end
    
        -- JNET_HEADER_SIZE字节通用消息头解析
        local head_bytes = new_ba:readBuf(JNET_HEADER_SIZE)
        jav_fill_comheader( head_bytes, head_st )
        
        -- 判断是否是整包
        local is_intact = true
        local remain_bytes = new_ba:getLen() - new_ba:getPos() + 1
        if remain_bytes < head_st.wSize - JNET_HEADER_SIZE then
            is_intact = false
            g_methods:log( "收到残包..等待中.." )
        else
            g_methods:log( "收到整包..等待中.." )
        end    
        
        -- 残包下次处理
        if is_intact == false then
            -- 字节序退后JAV_NET_HEADER_SIZE字节
            new_ba:setPos( new_ba:getPos() - JNET_HEADER_SIZE )
            self.rec_cache = new_ba:readString( remain_bytes + JNET_HEADER_SIZE )
            break
        else        
            -- 整包处理        
            -- 组织新数据包
            local new_msg = {
                size        = head_st.wSize,
                ordinal     = head_st.bOrdinalMsg,
                reqst       = head_st.bRequestMsg,
                respond     = head_st.bRespondMsg,
                main_id     = head_st.bMainID,
                assi_id     = head_st.bAssistantID,
                send_done   = false,
                pack_index  = 1,
                pack_count  = 1
            }
            
            -- NCN_FRAME_JSON
            if head_st.bAssistantID == JNET_FRAMEID then
                new_msg.pack_index = new_ba:readUByte()
                new_msg.pack_count = new_ba:readUByte()
                new_msg.json_length = new_ba:readUShort()
                new_msg.json_data = new_ba:readString( head_st.wSize - JNET_FRAMEJSON_HEADER_SIZE )
            -- NCN_GAME_TRANS
            elseif head_st.bAssistantID == JNET_GAMEID then
                new_msg.json_data = new_ba:readString( head_st.wSize - JNET_GAMETRANS_HEADER_SIZE )
            end
            
            -- 检测是否是独立包
            if  new_msg.pack_count == 1 then 
                if new_msg.pack_index == new_msg.pack_count then
                    -- 检测是否存在尚未发送的缓存包
                    if self.cur_message and self.cur_message.send_done == false then
                        g_methods:error( "收到新数据包,存留残包直接丢弃..." )
                    else
                        self.cur_message = new_msg
                        self:PostMsgPack()
                    end
                    self.cur_message = nil
                else
                    g_methods:error( "数据包解析错误,发现非法的独立数据包..." )
                end
            else
                -- 检测是否为首包
                if new_msg.pack_index == 1 then 
                    -- 检测是否存在尚未发送的缓存包
                    if self.cur_message and self.cur_message.send_done == false then
                        g_methods:error( "数据包丢失..." )
                    end
                    self.cur_message = new_msg
                    self.cur_message.send_done = false
                else
                    -- 是否为尾包
                    if new_msg.pack_index == new_msg.pack_count then
                        -- 检测缓存包是否有效且序列对应
                        if  self.cur_message == nil or 
                            self.cur_message.send_done ~= false or 
                            self.cur_message.pack_index ~= new_msg.pack_index - 1 then
                            g_methods:error( "数据包残缺,无法有效使用..." )
                        else
                            -- 组合为完整数据包
                            self.cur_message.size = self.cur_message.size + new_msg.size
                            self.cur_message.json_length = self.cur_message.json_length + new_msg.json_length
                            self.cur_message.json_data = self.cur_message.json_data .. new_msg.json_data
                            self.cur_message.pack_index = new_msg.pack_index
                            self:PostMsgPack()
                        end
                        self.cur_message = nil
                    else
                        -- 中间包
                        -- 检测缓存包是否有效且序列对应
                        if  self.cur_message == nil or 
                            self.cur_message.send_done ~= false or 
                            self.cur_message.pack_index ~= new_msg.pack_index - 1 then
                            g_methods:error( "数据包残缺,无法有效使用..." )
                            self.cur_message = nil
                        else
                            -- 组合为完整数据包
                            self.cur_message.size = self.cur_message.size + new_msg.size
                            self.cur_message.json_length = self.cur_message.json_length + new_msg.json_length
                            self.cur_message.json_data = self.cur_message.json_data .. new_msg.json_data
                            self.cur_message.pack_index = new_msg.pack_index
                        end
                    end
                end
            end
        end 
    end
    
end

-- 完整包发送
function JavSocket:PostMsgPack()

    g_methods:log( "发布完整包..." )
    self:DumpMsgPack( self.cur_message, false )
    
    self.cur_message.send_done = true
    local json_tbl = json.decode( self.cur_message.json_data )
    if  self.cur_message.assi_id == JNET_FRAMEID or 
        self.cur_message.assi_id == JNET_GAMEID then
        g_event:SendEvent( json_tbl.key, json_tbl )
    else
        g_methods:warn( "收到未处理的消息..." )
    end
end

-- 包信息输出
function JavSocket:DumpMsgPack( msg_pack, all_dump )

    if all_dump == true then
        g_methods:log( "包数据打印:" )
        g_methods:log( "\t包大小: " .. msg_pack.size )
        g_methods:log( "\t是否有校验: " .. msg_pack.ordinal )
        g_methods:log( "\t是否为请求消息: " .. msg_pack.reqst )
        g_methods:log( "\t是否为相应请求消息: " .. msg_pack.respond )
        g_methods:log( "\t主消息ID: " .. msg_pack.main_id )
        g_methods:log( "\t辅助消息ID: " .. msg_pack.assi_id )
    end

    if msg_pack.assi_id == JNET_FRAMEID then
        g_methods:log( "\t消息为NCN_FRAME_JSON类型... " )
        if all_dump == true then
            g_methods:log( "\t包个数: " .. msg_pack.pack_count )
            g_methods:log( "\t包序列: " .. msg_pack.pack_index )
            g_methods:log( "\tJSON长度: " .. msg_pack.json_length )
        end
        g_methods:output( "平台消息: " .. msg_pack.json_data )
    elseif msg_pack.assi_id == JNET_GAMEID then
        g_methods:log( "\t消息为NCN_GAME_TRANS类型... " )
        g_methods:output( "游戏消息: " .. msg_pack.json_data )
    end
    
end

return JavSocket