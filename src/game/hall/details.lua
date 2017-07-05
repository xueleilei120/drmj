-- details.lua
-- 2015-04-10
-- KevinYuen
-- 细则处理

-- 玩家属性改变细化映射表
PLAYER_PROPCHANGED_MAP = {}
-- 玩家状态改变细化映射表
PLAYER_STATECHANGED_MAP = {}

-- 注册
jav_regist_players_changed_callback = function( map, key, callback )

    -- 重复判断
    if map[key] then
        g_methods:error( "不能重复注册相同状态的处理方法", key )
        return false
    end
    
    -- 加入
    map[key] = callback
    return true
    
end

-- 金钱变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_MONEY,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_MONEY, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
                             

-- VIP变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_VIP,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_VIP, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
   
-- VIP变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_NEWVIP,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_NEWVIP, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
                                        
-- VIP变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_VIPPAT,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_VIPPAT, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
                                        
-- 积分变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_SCORE,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_SCORE, { uid = player_uid, old = old_value, new = new_value } )
                                        end )                                        
                                        
-- 获胜次数变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_WIN,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_WIN, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
                                        
-- 失败次数变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_LOST,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_LOST, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
                                        
-- 平局次数变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_PEACE,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_PEACE, { uid = player_uid, old = old_value, new = new_value } )
                                        end )
                               
-- 胜率变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_WINRATE,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_WINRATE, { uid = player_uid, old = old_value, new = new_value } )
                                        end )         

-- 掉线率变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_CUTRATE,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_CUTRATE, { uid = player_uid, old = old_value, new = new_value } )
                                        end )     
                                        
-- 网速变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_NETSPEED,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_NETSPEED, { uid = player_uid, old = old_value, new = new_value } )
                                        end )    
                                        
-- 经验变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_EXPDEGREE,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_EXPDEGREE, { uid = player_uid, old = old_value, new = new_value } )
                                        end )    
                                        
-- 经验变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_LVNAME,
                                        function( player_uid, prop_key, old_value, new_value )
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_LVNAME, { uid = player_uid, old = old_value, new = new_value } )
                                        end )    
                                    
-- 权限变化处理
jav_regist_players_changed_callback(    PLAYER_PROPCHANGED_MAP, 
                                        E_CLIENT_PROPCHANGED_RIGHT,
                                        function( player_uid, prop_key, old_value, new_value )
                                            -- 观战为站立状态
                                            -- 允许动态切换,影响seatinfo的座位上玩家信息,需要及时更新
                                              if old_value ~= new_value then
                                                local chairid = jav_getchairid_byUID( player_uid )
                                                local seat_info = jav_table:getSeat(chairid)
                                                if seat_info ~= nil and seat_info.uid ~= player_uid  then
                                                        if jav_isdating( player_uid ) or jav_iswathcer( player_uid ) then 
                                                            jav_table:getSeat(chairid).uid = player_uid  
                                                            jav_reset_seatsinfo( chairid )
                                                        else
                                                              jav_table:getSeat(chairid).uid = 0
                                                              jav_reset_seatsinfo( chairid )
                                                       end
                                                        g_methods:debug("玩家预约坐下的位置：uid:%s, chairid:%s",player_uid,chairid)
                                                 end
                                            else
                                    
                                            end
                                            g_event:SendEvent( E_CLIENT_PROPCHANGED_RIGHT, { uid = player_uid, old = old_value, new = new_value } )
                                        end )     

-- 玩家准备状态切换
jav_regist_players_changed_callback(    PLAYER_STATECHANGED_MAP,
                                        HUS_IAMREADY,
                                        function( player_uid, state_key, to_true )                                        
                                            g_event:SendEvent( E_CLIENT_USERREADY, { uid = player_uid })
                                        end )
                                        
-- 玩家观战状态切换
jav_regist_players_changed_callback(    PLAYER_STATECHANGED_MAP,
                                        HUS_WATCHER,
                                        function( player_uid, state_key, to_true ) 
                                            g_event:SendEvent( E_CLIENT_USERWATCH, { uid = player_uid } )
                                            
                                            -- 观战为站立状态
                                            -- 允许动态切换,影响seatinfo的座位上玩家信息,需要及时更新
                                            if to_true == true then
                                                -- 站起,如果是玩家,需要与座位数据松绑
                                                local chairid = jav_getchairid_byUID( player_uid )
                                                local seat_info = jav_table:getSeat(chairid)
                                                if seat_info ~= nil and seat_info.uid == player_uid then
                                                    jav_table:getSeat(chairid).uid = 0
                                                    g_methods:debug("玩家站起的位置：uid:%s, chairid:%s",player_uid,chairid)
                                                    local user = jav_table:queryUser( player_uid )
                                                    g_event:SendEvent( E_CLIENT_STANDUP, { uid = player_uid, chairid = chairid, nickname = user.nickname, isShowMsg = true  } )                                            
                                               end
                                            else
                                                
                                            end
                                                                             
                                        end )
                                        
-- 玩家游戏状态切换
jav_regist_players_changed_callback(    PLAYER_STATECHANGED_MAP,
                                        HUS_PLAYING,
                                        function( player_uid, state_key, to_true )                                        
                                            g_event:SendEvent( E_CLIENT_USERPLAY, { uid = player_uid })
                                        end )
                                        
-- 玩家掉线状态切换
jav_regist_players_changed_callback(    PLAYER_STATECHANGED_MAP,
                                        HUS_CUTTING,
                                        function( player_uid, state_key, to_true )                                        
                                            g_event:SendEvent( E_CLIENT_USERCUTTING, { uid = player_uid } )
                                        end )
