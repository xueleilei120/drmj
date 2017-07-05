--define.lua
--基本的麻将定义

--麻将牌的类型
TYPE_WAN            = 1             -- 万
TYPE_TIAO           = 2             -- 条
TYPE_TONG           = 3             -- 筒
TYPE_FENG           = 4             -- 风和剑
TYPE_HUA            = 5             -- 普通花

TYPE_PAIBEI         = 99           -- 牌背

--麻将牌的点数
POINT_1             = 1             --东 春  1
POINT_2             = 2             --南 夏  2
POINT_3             = 3             --西 秋  3
POINT_4             = 4             --北 冬 4
POINT_5             = 5             --中 梅 5
POINT_6             = 6             --发 兰 6
POINT_7             = 7             --白 竹 7
POINT_8             = 8             --菊 8
POINT_9             = 9             -- 9
   
-- 张数索引
IDX_1               = 1
IDX_2               = 2
IDX_3               = 3 
IDX_4               = 4 

-- 资源尺寸
SIZE_SMALL          = "s"             -- 小
SIZE_NORMAL         = "m"             -- 中
SIZE_LARGE          = "b"             -- 大

-- 放置方向
PDIR_UP             = "u"           -- 上方
PDIR_DOWN           = "d"           -- 下方
PDIR_LEFT           = "l"           -- 左 （朝向为左）
PDIR_RIGHT          = "r"           -- 右 （朝向为右）

-- 显示方式
SHOW_LI             = "l"           -- 立起
SHOW_DAO            = "d"           -- 放倒

-- 排列方式
SCHEME_LEFT2RIGHT   = "L2R"         -- 左到右
SCHEME_RIGHT2LEFT   = "R2L"         -- 右到左
SCHEME_UP2BOTTOM    = "U2B"         -- 上到下
SCHEME_BOTTOM2UP    = "B2U"         -- 下到上

-- 麻将牌资源方向前缀
CARDFROMAT          = "#card_%s_%s_%s_%d.png"   -- 自己的手牌(方向，大小，显示方式，点数)

-- 获取牌的资源编号
function getCardRes( cId, putDir, resSize, showFlag )

    if cId <= 100 or cId > 10000 then   -- 牌背
        return string.format( CARDFROMAT, putDir, resSize, showFlag, TYPE_PAIBEI )
    else
        return string.format( CARDFROMAT, putDir, resSize, showFlag, cId / 10 )
    end
    
end
 
-- 获取大资源
function getCardResLarge( cid, dir, showFlag )
    return getCardRes( cid, dir, SIZE_LARGE, showFlag )
end

-- 获取中资源
function getCardResNormal( cid, dir, showFlag )
    return getCardRes( cid, dir, SIZE_NORMAL, showFlag )
end

-- 获取小资源
function getCardResSmall( cid, dir, showFlag )
    return getCardRes( cid, dir, SIZE_SMALL, showFlag )
end 
 
-- 获取麻将花色
function getCardType( cardid ) 
    return math.floor( cardid /100 )
end

-- 获取麻将点数
function getCardPoint( cardid )
    return math.floor( cardid / 10 ) % 10
end

-- 获取麻将花色点数
function getCardTypePoint( cardid )
    return math.floor( cardid / 10 )
end

-- 获取张数索引
function getCardIdx( cardid )
    return cardid % 10
end

-- 获取废牌UID(显示牌背)
BLIND_CARDTRACKER = 10000
function getBlindId()
    BLIND_CARDTRACKER = BLIND_CARDTRACKER + 1
    return BLIND_CARDTRACKER
end
