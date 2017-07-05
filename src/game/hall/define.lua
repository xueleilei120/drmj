-- define.lua
-- 2015-04-10
-- KevinYuen
-- JAVGame核心定义

JNET_VERSION        = 0         -- 通讯版本号
JNET_MAX_PAKSIZE    = 1024      -- 网络数据包大小限制
JNET_IPC            = 0x13      -- 主消息类型定义
JNET_FRAMEID        = 0x01      -- 辅助消息类型定义(平台级)
JNET_GAMEID         = 0x02      -- 辅助消息类型定义(游戏级)   


--struct stJavNetHeader {
--    unsigned short  wSize : 15;         //消息大小
--    unsigned short  bOrdinalMsg : 1;    //消息是否是有校验
--    unsigned char   bRequestMsg : 1;    //是否为请求消息
--    unsigned char   bRespondMsg : 1;    //是否为相应请求消息
--    unsigned char   bMainID : 6;        //主消息ID
--    unsigned char   bAssistantID;       //辅助消息ID
--};
JNET_HEADER_SIZE = 4            -- 通用网络消息统一消息头字节数

-- 平台级网络消息消息头字节数
-- (统一消息头占位)
-- BYTE index;
-- BYTE count;
-- WORD jsonLen;
-- char json[_MAX_STR_LEN];
JNET_FRAMEJSON_HEADER_SIZE = JNET_HEADER_SIZE + 4
JNET_FRAMEJSON_DATA_MAXSIZE = JNET_MAX_PAKSIZE - JNET_FRAMEJSON_HEADER_SIZE

-- 游戏自定义网络消息消息头字节数
-- (统一消息头占位)
-- BYTE data[MAX_PKG_SIZE-MSG_HEAD_SIZE];
JNET_GAMETRANS_HEADER_SIZE = JNET_HEADER_SIZE
JNET_GAMETRANS_DATA_MAXSIZE = JNET_MAX_PAKSIZE - JNET_GAMETRANS_HEADER_SIZE

-- 网络连接事件
E_CLIENT_MAINCONNECT         = "main_connected"      -- 主连接{ socket="", event="start|failed|done|breaked|closed" }
E_CLIENT_OTHERCONNECT        = "other_connected"     -- 其他连接{ socket="", event="" }

-- 大厅->客户端事件
E_HALL_GAMEINFO            = "gameinfo"            -- 房间数据更新(服务器下发)
E_HALL_TABLEINFO           = "tableinfo"           -- 桌子数据更新(服务器下发)
E_HALL_USERLIST            = "userlist"            -- 用户列表更新(服务器下发) { uid,uid,... }
E_HALL_USERUPDATED         = "userupdate"          -- 用户数据更新(服务器下发)
E_HALL_USERCOMEIN          = "usercomein"          -- 用户进入(服务器下发) { uid="" chairid="" }
E_HALL_USERLEFT            = "userleft"            -- 用户离开(服务器下发) { uid="" chairid="" }
E_HALL_USERCUT             = "usercut"             -- 用户断线(服务器下发) { uid="" chairid="" }
E_HALL_USERCUTRETURN       = "usercutreturn"       -- 用户断线重入(服务器下发) { uid="" chairid="" }
E_HALL_GAMEBEGIN           = "gamebegin"           -- 游戏开始
E_HALL_GAMEEND             = "gameend"             -- 游戏结束
E_HALL_REQ_LEFTTABLE       = "reqLefttable"        -- 退出桌子  
E_HALL_HTMLCHAT            = "htmlchat"            -- HTML聊天信息
E_HALL_SETRULE             = "setrule"             -- 设置规则 { "rule"规则标识 "time"等待时间 "scores"分数值 }
E_HALL_BONUSINFO           = "bonusinfo"           -- 财富宝箱 { "flag"标识 "chairid"座位号 "amounts"宝箱总和 }
E_HALL_BASEMONEY           = "basemoney"           -- 基础分更新 { "basemoney"基础分值 }
E_HALL_IMLIST              = "imlist"              -- 联系人列表
E_HALL_MSGBOX              = "msgbox"              -- 大厅提示框
E_HALL_BANKDEPOSIT         = "bankdeposit"         -- 保险箱取款数额下发[deposit]保险箱存款数额
E_HALL_BANKDEPBACK         = "bankoperrlt"         -- 保险箱操作返回
E_HALL_NEWREDPACKET        = "dispatchredpack"     -- 新的红包通知
E_HALL_ROBREDPACKET        = "grabrbag"            -- 抢红包
E_HALL_RLTREDPACKET        = "grabredpackrlt"      -- 抢红包结果
E_HALL_REQTASKLIST         = "reqTasklist"         --请求任务列表
E_HALL_TASKLIST            = "tasklist"            --任务列表
E_HALL_REQTASKOPENTREASURE = "reqTaskOpentreasure" --请求打开任务
E_HALL_TASKOPENTREASURE    = "taskopentreasure"    --打开任务返回
E_HALL_TASKUPDATE          = "taskupdate"          --任务更新
E_HALL_REQ_WEBSHOP         = "reqWechatchg"        -- 请求打开大厅兑换页面  

E_HALL_REQUIREWINDOWCLOSE  = "requirewindowclose"         -- 请求窗口关闭消息
E_HALL_FORCEEXITGAME       = "forceexitgame"        -- 强制窗口关闭
  

-- 客户端内部消息
E_CLIENT_SYSCHAT                    = "syschat"             -- 系统聊天消息 { info="" }
E_CLIENT_ICOMEIN                    = "icomein"             -- 自己进入房间 { uid="" chairid="" }
E_CLIENT_SITDOWN                    = "usersitdown"         -- 玩家进入座位 { uid="" chairid="" }
E_CLIENT_STANDUP                    = "userstandup"         -- 玩家离开座位 { uid="" chairid="" }
E_CLIENT_USERREADY                  = "userready"           -- 玩家准备状态改变{ uid="" }
E_CLIENT_USERMONEY                  = "usermoney"           -- 玩家财富改变{ uid="" money="" }
E_CLIENT_USERWATCH                  = "userwatch"           -- 玩家旁观状态变化{ uid="", state= "" }
E_CLIENT_USERPLAY                   = "userplay"            -- 玩家游戏状态{ uid="", state= "" }
E_CLIENT_USERCUTTING                = "usercutting"         -- 玩家掉线了{ uid="", state= "" }
E_CLIENT_USERVIPACTIVE              = "uservipactive"       -- 玩家vip激活状态改变{ uid="", vipactive=""}
E_CLIENT_USERVIP                    = "usernewvip"          -- 玩家newvip改变{ uid="", newvip=""}
E_CLIENT_USERSCORE                  = "userscore"           -- 玩家积分改变{ uid="", score=""}
E_CLIENT_USERVIP                    = "uservip"             -- 玩家vip等级改变{ uid="", vip=""}
E_CLIENT_DCLICKPLAYER               = "dclickplayer"        -- 双击列表玩家{ uid="" }
E_CLIENT_OPENHELPVIEW               = "openhelpview"        -- 打开help view
E_CLIENT_OPETASKVIEW                = "opentaskview"        -- 打开task view
E_CLIENT_OPENSETTINGVIEW            = "opensettingview"     -- 打开setting view
E_CLIENT_SETCHATEDIT                = "setchateditbox"      -- 设置当前聊天输入内容{ text="" }

E_CLIENT_PROPCHANGED_MONEY          = "money"               -- 玩家属性名定义
E_CLIENT_PROPCHANGED_VIP            = "vip"
E_CLIENT_PROPCHANGED_NEWVIP         = "newvip"
E_CLIENT_PROPCHANGED_SCORE          = "score"
E_CLIENT_PROPCHANGED_VIPPAT         = "newvipactive"
E_CLIENT_PROPCHANGED_LVNAME         = "lvname"
E_CLIENT_PROPCHANGED_RIGHT          = "right"
E_CLIENT_PROPCHANGED_WIN            = "win"
E_CLIENT_PROPCHANGED_PEACE          = "peace"  
E_CLIENT_PROPCHANGED_LOST           = "lost"
E_CLIENT_PROPCHANGED_WINRATE        = "winrate"
E_CLIENT_PROPCHANGED_CUTRATE        = "cutrate"
E_CLIENT_PROPCHANGED_NETSPEED       = "netspeed"
E_CLIENT_PROPCHANGED_EXPDEGREE      = "expdegree"
E_CLIEN_GAMEBEGIN                   = "c_gamebegin"           -- 游戏开始


-- 玩家大厅&房间状态位标记
HUS_NOTALLOWINVITE      = 0x01                  -- 不允许接受邀请
HUS_CUTTING             = 0x02                  -- 掉线状态
HUS_STOPEQUIP_3         = 0x04                  -- 不和IP前3位相同的用户游戏
HUS_ALLOWWATCH          = 0x08                  -- 允许其他用户旁观
HUS_STOPEQUIP           = 0x10                  -- 不和相同IP的用户游戏
HUS_PLAYING             = 0x20                  -- 游戏状态
HUS_WATCHER             = 0x40                  -- 旁观状态
HUS_IAMREADY            = 0x80                  -- 准备好

-- 房间类型
ROOM_SCORE              = 0x01                  -- 积分房间
ROOM_MONEY              = 0x02                  -- 财富房间
ROOM_MATCH              = 0x04                  -- 比赛房间
ROOM_EASY               = 0x08                  -- 休闲模式
ROOM_QUENE              = 0x10                  -- 排队房间
ROOM_CUTTRUST           = 0x20                  -- 掉线托管房间，即玩家一旦掉线，不会因为超过3分钟而变为强退

-- 权限标记
PRT_SUBSCRIBER          = 0x20000000            -- 占座

-- 聊天类型定义
CHAT_SYSTEM             = 0                     -- 系统聊天
CHAT_JINGJI             = 1                     -- 竞技赛
CHAT_USER               = 2                     -- 玩家
CHAT_BUGLE              = 3                     -- 小喇叭
CHAT_GM                 = 4                     -- GM

-- 聊天范围定义
CHAT_AREA_HALL          = 1                     -- 房间右侧显示
CHAT_AREA_GAME          = 2                     -- 游戏右侧显示
CHAT_AREA_CHAT          = 3                     -- 游戏聊天框
CHAT_AREA_MARQUEE       = 4                     -- 跑马灯显示
CHAT_AREA_STATIC        = 8                     -- 游戏中显示

-- 全局jav变量定义
jav_self_uid            = 0                     -- 本地用户的UID  

