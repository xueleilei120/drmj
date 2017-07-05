-- methods.lua
-- 2015-04-08
-- KevinYuen
-- 房间级快捷方法定义

-- 发送通讯版本号
function jav_send_version( version )
    local msg = { key = "gameframever", ver = version }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
end

-- 玩家准备
function jav_ready()

    if jav_isready( jav_self_uid ) == false then
        local msg = { key = "cmd", context = "iamready" }
        jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
    end
end

-- 打开银行
function jav_openbank()
    local msg = { key = "cmd", context = "openbank" }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
end

-- 玩家聊天
function jav_userchat( content )

    local player = jav_queryplayer_byUID( jav_self_uid )
    if not player then
        return false
    end
    
    -- 观战玩家聊天条件限制
    if jav_iswatcher( jav_self_uid ) then
    
        -- expdegree>=6 或者 relive>0
        if player.expdegree < 6 and player.relive <= 0 then
            local text = g_library:QueryConfig( "text.chat_watcher_nolevel" )
        g_event:SendEvent( E_CLIENT_SYSCHAT, { info = text } )
            return false
        end 
    
        -- newvip==true 且 newvipactive==true 且 vip>0
        if player.newvip == false or player.newvipactive == false or player.vip <= 0 then
            local text = g_library:QueryConfig( "text.chat_watcher_notvip" )
            g_event:SendEvent( E_CLIENT_SYSCHAT, { info = text } )
            return false
        end
    
        -- 旁观时间>30秒
        local now_time = os.time()
        local luc_time = g_save.configs.system.launch_time
        local pas_time = os.difftime( now_time, luc_time )
        if pas_time <= 30 then
            local text = g_library:QueryConfig( "text.chat_watcher_notime" )
            g_event:SendEvent( E_CLIENT_SYSCHAT, { info = text } )
            return false 
        end
    
    end

    local msg = { key = "htmlchat", type = 2, area = 2, sort = jav_room.sort, uid = 0, context = content }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
end

-- 发送自定义消息
function jav_send_message( msgKey, msgArgs )
    msgArgs = msgArgs or {}
    msgArgs.key = msgKey
    local msgJson = json.encode( msgArgs )
    jav_room.main_connect:SendGameMsg( msgJson )
    g_methods:log( "发布游戏消息: %s\t %s", msgKey, msgJson )
end

-- 获取指定UID的座位号
function jav_getchairid_byUID( uid )
    return jav_table:getChairId( uid )  
end

-- 获取指定UID的玩家信息
function jav_queryplayer_byUID( uid )
    return jav_table:queryUser(uid) 
end

-- 获取指定座位号的玩家信息
function jav_queryplayer_bychairid( chairid )
    return jav_table:queryPlayer( chairid )
end

-- 获取指定座位号的占座玩家信息
function jav_query_dateplayer_bychairid( chairid )
    return jav_table:queryDatePlayer( chairid )
end

-- 获取主角座位号
function jav_get_mychairid()
    return jav_table:getChairId( jav_self_uid )
end

-- 获取指定座位号玩家的性别
-- 0：女  1：男
function jav_get_chairsex(chairid)
    local player = jav_queryplayer_bychairid(chairid)
    if player then
        return player.sex
    else
        return 0
    end
end

-- 获取本地位置(主角为0位)
function jav_get_localseat( chairid )
    return jav_table:toSeatNo( chairid )
end

-- 获取本地位置对应的座位号
function jav_get_chairid_bylocalseat( local_seat )
    return jav_table:toChairId( local_seat )
end

-- 指定座位号是否有效
function jav_isvalid_chairid( chairid )
    return jav_table:isGoodChairId( chairid )
end

-- 离开桌子(离开房间)
function jav_leftroom()

    local msg = { key = "cmd", context = E_HALL_REQ_LEFTTABLE }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) )
    
end

-- 获取下一个位置 
function jav_next_chairid( chairid, only_valid )

    if only_valid == nil then 
        only_valid = true
    end

    -- 位置判断
    if jav_isvalid_chairid( chairid ) == false then
        g_methods:warn( "jav_next_chairid:位置[%d]无效...", chairid )
        return -1
    end

    -- 遍历全座位,查询满足条件的下个位置
    local next_seat = chairid 
    for index = 1, TABLE_MAX_USER - 1 do
        next_seat = next_seat + 1
        next_seat = ( next_seat + TABLE_MAX_USER ) % TABLE_MAX_USER
        if only_valid == true then
            if jav_table:getSeat(next_seat).uid > 0 then
                return next_seat
            end
        else
            return next_seat
        end
    end

    g_methods:warn( "jav_next_chairid:失败..." )
    return -1

end

-- 获取上一个位置
function jav_last_chairid( chairid, only_valid )

    -- 位置判断
    if jav_isvalid_chairid( chairid ) == false then
        g_methods:error( "获取牌桌位置[%d]失败,参数位置无效...", chairid )
        return -1
    end

    -- 遍历全座位,查询满足条件的下个位置
    local next_seat = chairid
    for index = 1, TABLE_MAX_USER - 1 do
        next_seat = next_seat - 1
        next_seat = ( next_seat + TABLE_MAX_USER ) % TABLE_MAX_USER
        if only_valid == true then
            if jav_table:getSeat(next_seat).uid > 0 then
                return next_seat
            end
        else
            return next_seat
        end
    end

    g_methods:warn( "jav_last_chairid:失败..." )
    return -1

end

-- 玩家状态检查
function jav_has_state( uid, state_flag )

    -- 存在性判断
    local user = jav_queryplayer_byUID( uid )
    if not user then
        g_methods:warn( "jav_iswatcher:玩家[%d]没有记录...", uid )
        return false
    end

    -- 位标志判断
    local ret = bit.band( user.state, state_flag )
    return ret ~= 0
    
end

-- 是不是观众
function jav_iswatcher( uid )
    return jav_has_state( uid, HUS_WATCHER )    
end

-- 是不是准备好了
function jav_isready( uid )
    return jav_has_state( uid, HUS_IAMREADY )   
end

-- 是不是掉线了
function jav_iscutting( uid )
    return jav_has_state( uid, HUS_CUTTING ) 
end

-- 是不是允许旁观
function jav_iscanwatch( uid )
    return jav_has_state( uid, HUS_ALLOWWATCH ) 
end

-- 是不是在游戏中
function jav_isplaying( uid )
    return jav_has_state( uid, HUS_PLAYING ) 
end

-- 玩家权限检查
function jav_has_right( uid, right_flag )

    -- 存在性判断
    local user = jav_queryplayer_byUID( uid )
    if not user then
        g_methods:warn( "jav_iswatcher:玩家[%d]没有记录...", uid )
        return false
    end

    -- 位标志判断
    local ret = bit.band( user.right, right_flag )
    return ret ~= 0

end

-- 房间类型
function jav_room_type( type_flag )
    local ret = bit.band( jav_room.flag, type_flag )
    return ret ~= 0
end

-- 是不是预约
function jav_isdating( uid )
    return jav_has_right( uid, PRT_SUBSCRIBER )
end

-- msgbox对话框的实现，启动计时器
-- args 需要添加的相关的数值信息
-- content:对话框中显示的信息，txt_content：对话框中显示的空间句柄
--btn_confirm:按钮名称{“yes”,"no"，“confirm"}, callback:回调函数，interval：超时时间
function jav_msgboxtimer( content, content_args, btns, callback, interval )

    local modal_layer = require( "kernels.node.nodeModal" ).new()
    if not modal_layer:BindUIJSON( "msgbox.json" ) then
        return
    end

    local pan_message = modal_layer:GetRoot():getChildByName( "panel" )

    -- 判断是否需要显示按钮
    local find_btn = function( btns, key )
        for _, name in pairs( btns ) do
            if name == key then
                return true
            end
        end
        return false
    end
    
    local support_buttons = { "yes", "no", "confirm" }
    for _, btn_name in pairs( support_buttons ) do
        local exist = find_btn( btns, btn_name )
        g_methods:WidgetVisible( pan_message, btn_name, exist )
        
        if exist and callback then
            local clicked = function( sender, args )
                callback( sender:getName() )
            end
            g_methods:ButtonClicked( pan_message, btn_name, clicked )
        end
    end

    local txt_content = pan_message:getChildByName( "content" )    
        
    -- 特殊不定参数的格式化方法
    -- 参数划分以{}替换的方式完成
    local specailFormat = function( content, args )

        local pos = string.find( content, "{}" )
        local text = ""
        while pos and #args > 0 do
            local text2 = string.sub( content, 1, pos - 1 )
            text = text.. text2 .. tostring( args[1] )
            content = string.sub( content, pos + 2 )
            pos = string.find( content, "{}" )
            table.remove( args, 1 )
        end
        if content ~= "" then
            text = text .. content 
        end
        return text
    end

    if content_args and #content_args > 0 then 
        content = specailFormat( content, content_args )
    end     
    txt_content.raw_text = content
    
    txt_content:setString( specailFormat( content, { interval } ) )  
    
    if interval > 0 then
        local quit_schdule = nil
        local sched = cc.Director:getInstance():getScheduler()  
        
        local secTicker = function( dt )
            interval = interval - 1
            if interval < 0 then
                sched:unscheduleScriptEntry(quit_schdule)
                quit_schdule = nil
                callback()
            else
                local txt_content = pan_message:getChildByName( "content" )    
                txt_content:setString( specailFormat( txt_content.raw_text, { interval } ) )   
            end
        end 
    
        quit_schdule = sched:scheduleScriptFunc( secTicker, 1.0, false )
    end
end
    
-- 名字截取
function jav_shortcut_name( nickname, relen )

    local name = jav_bg2312_utf8( nickname )
    local chars, count = g_methods:SplitChar( name )
    local cutstr, cutted, real_len = "", false, 0
    
    -- 先判断一次总长度
    for _, char in pairs( chars ) do
        local len = string.len( char )
        if len == 1 then    real_len = real_len + 1
        else                real_len = real_len + 2     
        end
    end

    -- 剪裁
    if real_len > relen then
        cutted = true
        for _, char in pairs( chars ) do
            local len = string.len( char )
            local tmp = relen
            if len == 1 then
                tmp = tmp - 1
            else
                tmp = tmp - 2
            end
            if tmp >= 0 then
                cutstr = cutstr .. char
                relen = tmp 
            else
                break
            end
        end
        name = cutstr .. "..."
    end
    
    return name
    
end

-- 获取金钱缩写
function jav_format_money( money )

    -- 空判断
    if not money then
        return 0
    end

    -- 百万级为限
    -- 不到百万显示数字
    -- 超过百万显示万级数字,零头省略
    if money < 1000000 then
        return tostring( money )
    elseif money < 100000000 then
        local wmoney = math.floor( money / 10000 )
        return string.format( "%d万", wmoney )
    else
        local wmoney = math.floor( money / 100000000 )
        return string.format( "%d亿", wmoney )
    end
end

-- 名字格式化(全信息格式串,用于富文本输出)
function jav_format_richname( uid, relen )
    local player = jav_queryplayer_byUID( uid )
    if not player then
        return ""
    end
    local txt = ""
    local name = player.nickname
    if relen and relen > 0 then
        name = jav_shortcut_name( player.nickname, relen)
    else
       name = jav_bg2312_utf8( player.nickname )
    end
    
    local vip_key = "vip.config" .. player.vip
    local vip_config = g_library:QueryConfig( vip_key )

    if player.vip == 0 then
        txt = string.format("%s<%s>","#0xF2F23FFF",name)
        return txt
    end

    if not player.newvipactive  then
        txt = string.format( "%s<%s%s>", "#0xF2F23FFF", vip_config.grayicon, name )
    else
        txt = string.format( "%s<%s%s>", vip_config.color, vip_config.icon, name )
    end

    return txt
end

--处理界面关闭事件
function jav_windowrequireclose()
    g_event:SendEvent( E_HALL_REQUIREWINDOWCLOSE )
end



