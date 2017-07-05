-- define.lua
-- 2014-10-20
-- KevinYuen
-- 游戏常量定义

-- 抗锯齿切换范围
ANITALIAS_MIN           = 0.9   -- 最小比例
ANITALIAS_MAX           = 1.1   -- 最大比例 

-- 基本常量定义
TABLE_MIN_USER          = 2     -- 最小人数
TABLE_MAX_USER          = 2     -- 最大人数

------------------------------------------------------------------------------------------
--
-- 达人麻将版消息定义
------------------------------------------------------------------------------------------
--
-- 游戏主阶段定义
PSTATE_NONE             = 0     -- 空的游戏状态
STATE_WAITBEGIN         = 1
STATE_BEGIN             = 2
STATE_ASSIGNBANKER      = 3
STATE_ASSIGNWALL        = 4
STATE_DEALCARD          = 5
STATE_PLAYCARD          = 6
STATE_END               = 7

-- 游戏结束原因
END_REASON_NORMAL       = 0     -- 正常结束
END_REASON_RUNAWAY      = 1     -- 逃跑结束
END_REASON_SURRENDER    = 2     -- 投降结束
END_REASON_DISMISS      = 3     -- 解散结束
END_REASON_NOWINNER     = 4     -- 荒局结束


-- 服务器->客户端游戏消息定义
-- WaitBegin State
STC_MSG_BASECORE        = "key_stc_basescore"
STC_MSG_CONFIG          = "key_stc_config"

--DealCard State
STC_ASSIGNBANKER        = "key_stc_banker"    -- 定庄
STC_ASSIGNWALL          = "key_stc_wall"      -- 定牌墙
STC_MSG_DEALCARD        = "key_stc_dealcard"  -- 发手牌


--PlayCard State
STC_MSG_FIRSTPLAY       = "key_stc_firstplay"           -- 玩家第一次操作
STC_MSG_PLAYCARD        = "key_stc_playcard"            -- 服务器的确认打牌消息
STC_MSG_OPER            = "key_stc_oper"                -- oper
STC_MSG_GETNEWCARD      = "key_stc_getnewcard"
STC_MSG_OPERRESULT      = "key_stc_oper_result"          -- 操作结果
STC_MSG_DOUBLETASK      = "key_stc_doubletask"
STC_MSG_DOUBLETASKFINISH= "key_stc_dtaskfinish"

STC_MSG_CHATING         = "key_stc_chating"             --查听
STC_MSG_TING            = "key_stc_ting"
STC_MSG_GAMEEND         = "key_stc_end"
STC_MSG_TRUST           = "key_stc_trust"               -- 托管结果{ nSeat, bTrust }
STC_MSG_OPTINFO         = "key_stc_optinfo"             -- 自己听牌后，对家的牌信息（手牌和牌堆）
STC_MSG_CARDINFO        = "key_stc_cardinfo"             -- 自己听牌后，对家的牌信息（手牌和牌堆）
STC_MSG_UPDATEHUTYPE    = "key_stc_updatehutype"        -- 更新玩家的手牌和牌堆信息
STC_MSG_SELECTHU        = "key_stc_selecthu"
STC_MSG_QGH             = "key_stc_qgh"                 -- 抢杠胡操作
STC_MSG_EXIT            = "key_stc_exit"                -- 强制离开       

STC_MSG_SETHAND        = "key_stc_gmsethand"            -- 做牌消息

STC_MSG_UPDATESTATE     = "key_stc_updategamestage"     -- 更新游戏状态
STC_MSG_HUDOUBLE        = "key_stc_hudouble"            -- 加倍结果
STC_MSG_CUTRETURN       = "key_stc_cutreturn"           -- 掉线重入消息
STC_MSG_USERINFO        = "key_stc_userinfo"            -- 玩家游戏数据
STC_MSG_TURN            = "key_stc_turn"                -- 当前轮次的玩家
STC_MSG_CANCELTING      = "key_stc_cancelting"          --  取消听牌
STC_MSG_ALLOWWATCH      = "key_stc_allowwatch"          -- 允许旁观


STC_MSG_QUANFENG        = "key_stc_quanfeng"            -- 圈风消息
STC_SHOW_TOTALSCORE     = "key_stc_totalscore"          -- 显示总积分{ bShow, nTotalScor }

-- 客户端->服务器游戏消息定义
CTS_MSG_DEALCARD        = "key_cts_dealcard"  
CTS_MSG_PLAYCARD        = "key_cts_playcard"
CTS_MSG_OPER            = "key_cts_oper"
CTS_MSG_HUDOUBLE        = "key_cts_hudouble"
CTS_MSG_TRUST           = "key_cts_trust"               -- 托管{ bTrust }
CTS_MSG_ALLOWWATCH      = "key_cts_allowwatch"          -- 允许旁观

SGE_CUTRETURN           = "s_returngame"                -- 中途返回游戏(全现场还原)（待定）

-- 客户端->客户端消息定义
CTC_TIMERPROG_RESET     = "c_timeprog_reset"            -- 倒计时进度条重置{ seatNo, secs = 0:关闭, X:计时, total:X 总时间 } 
CTC_TIMERPROG_TICK      = "c_timeprog_tick"             -- 倒计时进度条心跳{ seatNo, secs = X:剩余 }
CTC_TIMERPROG_TIMEOUT   = "c_timeprog_timeout"          -- 倒计时进度条超时结束{ seatNo }
CTC_TIMERPROG_BREAKOUT  = "c_timeprog_breakout"         -- 倒计时进度条被打断结束{ seatNo }
CTC_HANDCARDS_SETCHOOSE = "c_handcards_setchoose"       -- 手牌可选牌列表设定{ cardlst }
CTC_HANDCARDS_DELCHOOSE = "c_handcards_delchoose"       -- 手牌可选牌列表清理
CTC_HANDCARDS_OPTUPDATE = "c_handcards_optupdate"       -- 更新对家的手牌信息
CTC_CUTTER_HANDCARDINFO = "c_cutter_handinfo"           -- 掉线回来玩家的手牌信息（手牌和结构牌）
CTC_TING_OPER           = "c_ting_oper"                 -- 从table中转发玩家的听消息
CTC_MSG_CHATING         = "c_cha_ting"                  -- 从table中转发玩家的查听消息
CTC_MSG_OPER            = "c_oper"                      -- oper
CTC_MSG_FIRSTPLAY       = "c_firstplay"                 -- 玩家第一次操作
CTC_MSG_CUTRETURN       = "c_cutreturn"                 -- 掉线重入消息
CTC_MSG_CONFIG          = "c_config"                    --游戏数据配置



CTC_HAND_FOCUSCHANGED   = "c_hand_focuschanged"         -- 手牌聚焦改变{ seatNo, focus = true / false }
CTC_STACKOPER_PENGCHI   = "c_stackoper_peng_chi"        -- 碰吃操作
CTC_FIRSTOPER           = "c_first_oper"                -- 第一次操作信息
CTC_PLAYCARD            = "c_playcard"  
CTC_SHOWNEWCARD         = "c_show_newcard"    
CTC_STACKOPER_ZHIGANG   = "c_stackoper_zhigang"         -- 直杠操作     
CTS_STACKOPER_PENGGANG  = "c_stackoper_penggang"        -- 碰杠操作 
CTS_STACKOPER_ANGAGN    = "c_stackoper_angang"          -- 暗杠操作
CTC_OPER_STACKSHOW      = "c_oper_stackshow"            -- 牌型操作{ seatNo, operFlag } 
CTC_OPER_DOUBLESHOW     = "c_oper_doubleshow"           -- 加倍操作{ seatNo, times }
CTC_SETHANDCARDS        = "c_oper_sethandcards"         -- 重新设置手牌
CTE_SHOW_SETTLEMENT     = "c_show_settlement"           -- 显示结算面板
CTE_SHOW_MSGBOX         = "c_show_msgbox"               -- 显示MsgBox面板    
CTC_SHOW_MAXFAN         = "c_show_maxFan"               -- 玩家加倍后最大番数{ nDoubleSeat, times }

CTC_FRESH_FANTIP       = "c_fresh_fantip"               -- 更新番数显示{ moPt, dnPt }
CTC_PLAY_TINGANIM      = "c_play_tinganim"              -- 播放停牌动画
CTC_OPER_QI            = "c_oper_qi"                    -- 弃操作客户端内部
CTC_TING_TIP           = "c_ting_tip"                    -- 听提示

------------------------------------------------------------------------------------------
--
-- 达人麻将版常量定义
------------------------------------------------------------------------------------------
--
-- 牌组操作组合标记位定义
OPER_NULL               = 0x00000000
OPER_HU                 = 0x00000001                -- 胡
OPER_PENG               = 0x00000002                -- 碰
OPER_ZHI_GANG           = 0x00000004                -- 直杠
OPER_PENG_GANG          = 0x00000008                -- 面下 先碰后杠
OPER_AN_GANG            = 0x00000010                -- 暗杠
OPER_GANG               = 0x0000001C                -- 杠
OPER_LCHI               = 0x00000020                -- 吃前面张
OPER_MCHI               = 0x00000040                -- 吃中间张
OPER_RCHI               = 0x00000080                -- 吃后面张
OPER_CHI                = 0x000000E0                -- 吃
OPER_BUHA               = 0x00000100                -- 补花
OPER_PLAYCARD           = 0x00000200                -- 出牌
OPER_CANCEL             = 0x00000400                -- 取消
OPER_TING               = 0x00000800                -- 听牌
OPER_GETCARD            = 0x00001000                -- 获得牌（发新牌
OPER_CHI_TING           = 0x00002000                -- 吃听
OPER_PENG_TING          = 0x00004000                -- 碰听
OPER_DOUBLE             = 0x00010000                --加倍

-- 是否可碰
function operCanPeng( operFlag )

    if  bit.band( operFlag, OPER_PENG ) ~= 0 then
        return true
    else
        return false
    end 
       
end

-- 是否可吃
function operCanChi( operFlag )

    if  bit.band( operFlag, OPER_LCHI ) ~= 0 or 
        bit.band( operFlag, OPER_MCHI ) ~= 0 or 
        bit.band( operFlag, OPER_RCHI ) ~= 0 then
        return true
    else
        return false
    end 

end

-- 是否可杠
function operCanGang( operFlag )

    if  bit.band( operFlag, OPER_ZHI_GANG ) ~= 0 or 
        bit.band( operFlag, OPER_PENG_GANG ) ~= 0 or 
        bit.band( operFlag, OPER_AN_GANG ) ~= 0 then
        return true
    else
        return false
    end 

end

-- 是否可弃牌
function operCanCancel( operFlag )

    if  bit.band( operFlag, OPER_CANCEL ) ~= 0 then
        return true
    else
        return false
    end 

end

-- 是否听牌
function operCanTing( operFlag )

    if  bit.band( operFlag, OPER_TING ) ~= 0 then
        return true
    else
        return false
    end 

end

-----------------------------------------------------------------------------------------
--达人麻将男女音效设置
--
-------------------------------------------------------------------------------
CARD_AUDIO = "card_%d_%d.mp3"    --性别，牌类型
ADD_AUDIO  = "add_%d_%d.mp3"     -- 性别，加倍次数 
OPER_AUDIO = "oper_%d_%s.mp3"    -- 性别，操作类型字符串

------------------------------------------------------------------------------------------
--
-- 达人麻将版变量定义
------------------------------------------------------------------------------------------
--
-- 变量定义
FACE_DIMENSION          = { 24, 24 }                -- 单表情的尺寸
FACE_OFFSET             = { 31, 31 }                -- 表情间偏移
FACE_ROWCOUNT           = 5                        -- 表情一行最大数量
WALL_COLCOUNT           = 16                        -- 排墙堆数
WALL_CARDCOUNT          = 64                        -- 牌墙总牌数   
BANKER_INITCARDS        = 14                        -- 庄家初始张数
OTHER_INITCARDS         = 13                        -- 闲家初始张数    

-- 本地延迟时间定义
DELAY_EXITGAME          = 5                         -- 延迟关闭
DELAY_TICKSHOWSECS      = 10                        -- 倒计时提醒时间线

-- 动画耗时定义
SECS_BUILDWALLS         = 0.6                       -- 牌墙创建+上升耗时
SECS_FLIPHANDS          = 0.4                       -- 手牌翻牌排序耗时
SECS_DICEROLL_BANKER    = 1.6                       -- 定庄掷筛子耗时
SECS_DICEROLL_WALL      = 1.5                       -- 切牌墙掷筛子耗时

-- 像素偏移定义
OFFSET_BUILDWALLS       = 80                        -- 牌墙上升偏移 
OFFSET_CARDFOCUSED      = 20                        -- 手牌聚焦弹起幅度
OFFSET_STONEHOR         = cc.p( 30, 60 )            -- 出牌蓝钻标记偏移
OFFSET_STONEVER         = cc.p( 27, 80 )            -- 出牌蓝钻标记偏移
OFFSET_MARKVER         = cc.p( 35, 107 )            -- 出牌蓝钻标记偏移

-- 踢出时间
TICK_TIME               = 3600                        -- 踢出时间设置

-- 颜色定义
COLOR_NORMAL            = cc.c3b( 255, 255, 255 )   -- 正常色
COLOR_DISABLED          = cc.c3b( 128, 128, 128 )   -- 无效色

------------------------------------------------------------------------------------------
--
-- 达人麻将牌桌静态配置
------------------------------------------------------------------------------------------

require( "kernels.mahjong.define" )


BG_CFG = {
    [1] = {
        bg      = "bg.1.jpg",        --背景图
        tb      = "table.1.jpg",      --桌子背景图     
        logo    = "table.logo.1.png"     --桌子的logo   
    },
    [2] = {
        bg      = "bg.2.jpg",        --背景图
        tb      = "table.2.jpg",      --桌子背景图     
        logo    = "table.logo.2.png"     --桌子的logo   
    },
    [3] = {
        bg      = "bg.3.jpg",        --背景图
        tb      = "table.3.jpg",     --桌子背景图     
        logo    = "table.logo.3.png"     --桌子的logo   
    }

}

-- 牌墙配置
DRWALL_CFG = {
    [0] = {
        dir     = SCHEME_LEFT2RIGHT,
        cols    = 16,
        cdim    = cc.size( 48, 72 ),
        offset  = cc.p( -3, 13 )
    },
    [1] = { 
        dir     = SCHEME_RIGHT2LEFT,
        cols    = 16,
        cdim    = cc.size( 48, 72 ),
        offset  = cc.p( -3, 13 )
    },
}

-- 牌河配置
DRRIVER_CFG = {
    [0] = {
        dir     = SCHEME_LEFT2RIGHT,
        cols    = 12,
        cdim    = cc.size( 48, 72 ),
        offset  = cc.p( -3, -8 )
    },
    [1] = { 
        dir     = SCHEME_RIGHT2LEFT,
        cols    = 12,
        cdim    = cc.size( 48, 72 ),
        offset  = cc.p( -3, -8 )
    },
}

-- 手牌配置
DRHAND_CFG = {
    [0] = {
        dir     = SCHEME_LEFT2RIGHT,
        cols    = 13,
        cdim    = cc.size( 70, 103 ),
        offset  = cc.p( -5, 0 )
    },
    [1] = { 
        dir     = SCHEME_RIGHT2LEFT,
        cols    = 13,
        cdim    = cc.size( 48, 72 ),
        offset  = cc.p( -4, 0 )
    },
}

-- 胡牌提示配置
TIPHAND_CFG = {
    dir     = SCHEME_LEFT2RIGHT,
    cols    = 13,
    cdim    = cc.size( 48, 72 ),
    offset  = cc.p( 20, 0 )
}

------------------------------------------------------------------------------------------
--
-- Base库依赖达人麻将版方法定义
------------------------------------------------------------------------------------------

-- 获取手牌资源名
function getHandRes( seatNo, id, putHor )

    -- 自己用大牌
    if seatNo == 0 then
        if putHor and putHor == true then
            return getCardResLarge( id, PDIR_LEFT, SHOW_DAO )
        else
            return getCardResLarge( id, PDIR_UP, SHOW_LI )
        end
        -- 其他人用小牌
    else
        if putHor and putHor == true then
            return getCardResSmall( id, PDIR_LEFT, SHOW_DAO )
        else
            local chairid = jav_get_chairid_bylocalseat( seatNo )
            local seat = jav_table:getSeat( chairid )
            if seat.blindHands == true then
                return getCardResSmall( id, PDIR_UP, SHOW_LI )
            else
                return getCardResSmall( id, PDIR_UP, SHOW_DAO )
            end
        end
    end

end

-- 获取手牌倒下的资源名
function getHandFallRes( seatNo, id, putHor )

    -- 自己用大牌
    if seatNo == 0 then
        if putHor and putHor == true then
            return getCardResLarge( id, PDIR_LEFT, SHOW_DAO )
        else
            return getCardResLarge( id, PDIR_UP, SHOW_DAO )
        end
        -- 其他人用小牌
    else
        if putHor and putHor == true then
            return getCardResSmall( id, PDIR_LEFT, SHOW_DAO )
        else
            return getCardResSmall( id, PDIR_UP, SHOW_DAO )
        end
    end
    
end

-- 获取手牌牌背资源名
function getHandBackRes( seatNo, putHor )
    return getHandRes( seatNo, TYPE_PAIBEI, putHor )
end

-- 获取牌河资源名
function getRiverRes( seatNo, id, putHor )

    if putHor and putHor == true then
        return getCardResSmall( id, PDIR_LEFT, SHOW_DAO )
    else
        return getCardResSmall( id, PDIR_UP, SHOW_DAO )
    end

end

-- 获取牌河牌背资源名 
function getRiverBackRes( seatNo, putHor )
    return getRiverRes( seatNo, TYPE_PAIBEI, putHor )
end

------------------------------------------------------------------------------------------
--
-- 达人麻将牌桌角色头像及动画配置
------------------------------------------------------------------------------------------
--
PLAYER_PHOTOS = {
    [0] = {
        [0] = { photo = "renwu.1.png", photomask="renwu.1.1.png", anim = "NPC_Start", action = "girl01" },
        [1] = { photo = "renwu.3.png", photomask="renwu.3.3.png", anim = "NPC_Start", action = "boy01" }
    },
    [1] = {
        [0] = { photo = "renwu.2.png", photomask="renwu.2.2.png", anim = "NPC_Start", action = "girl02" },
        [1] = { photo = "renwu.4.png", photomask="renwu.4.4.png", anim = "NPC_Start", action = "boy02" }
    }
}

