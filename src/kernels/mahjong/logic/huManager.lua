-- huManager.lua
-- 2016-05-10
-- KevinYuen
-- 胡计算

import( ".fantypes" )

local socket = require "socket"

-- 牌型计算类
local hucalc = import(".huCalculator")
calculator = hucalc.new()

-- 麻将番数计算
local HuManager = class( "HuManager" )

-- 构造
function HuManager:ctor()
    
    self.tblArgs    = nil       -- 当前运算参数
    self.lstFans    = nil       -- 结果番数列表
    self.lstTypes   = nil       -- 结果牌型列表
    
end

-- 计算可胡牌型
-- args = {
--    lstPilecards 	-- 结构牌：{ {lstCards, type}, {lstCards, type}, ...}
--    lstHandCards  -- 手牌
--    nHuCard		-- 胡的牌
--    nQFengCard	-- 圈风牌
--    nMFengCard	-- 门风牌
--    bZiMo			-- 是否自摸
--    bTing         -- 是否报听
--    nWallLeftNum  -- 牌墙剩余张数
--    lstOprForHu   -- 特殊的胡牌列表
-- }

function HuManager:calHuTypes( args, filter ) 

    local t0 = socket.gettime();

    self.tblArgs = clone( args );
    
    -- 计算得到所有满足条件的胡牌类型列表
    local lstTypes = self:calcAllTypes(args)
    
    -- 过滤
    if filter == true then
        self.lstTypes = self:filtTypes(lstTypes);
    end
    
    if true then
        local t1 = socket.gettime();
        g_methods:log( "calHuTypes used time:" .. t1 - t0 .. "ms" )
    end
    
    return self.lstTypes;
    
end

-- 牌型过滤
function HuManager:filtTypes( lstTypes )

    lstTypes = lstTypes or self.lstTypes;

    -- 按照牌型从大到小开始过滤
    for i=1,#lstTypes do
        -- 这个牌型有哪些需要过滤的牌型
        local checktype = lstTypes[i]
        -- checktype牌型所对应的过滤列表
        local lstFilter = HU_TYPEFILTERS[checktype]
        if lstFilter ~= nil then
            -- 把需要过滤的牌型从胡牌列表中删除
            for j,filtertype in pairs(lstFilter) do
                -- 删除过滤牌型时，要从后往前remove
                for k=#lstTypes,1,-1 do
                    if lstTypes[k] == filtertype then
                        table.remove(lstTypes, k)
                    end
                end
            end
        end
    end

    return lstTypes    
end

-- 计算番数列表
function HuManager:calFans( lstTypes )

    lstTypes = lstTypes or self.lstTypes;
    
    self.lstFans = {}
    for i,hutype in pairs(lstTypes) do
    	-- 记录 hutype 对应的番数
    	table.insert(self.lstFans, HU_FANSMAP[hutype])
    end

    return self.lstFans; 
end

-- 计算总的基础番数
-- args = {
--    lstPilecards 	-- 结构牌：{ {lstCards, type}, {lstCards, type}, ...}
--    lstHandCards  -- 手牌
--    nHuCard		-- 胡的牌
--    nQFengCard	-- 圈风牌
--    nMFengCard	-- 门风牌
--    bZiMo			-- 是否自摸
--    bTing         -- 是否报听
--    nWallLeftNum  -- 牌墙剩余张数
--    lstOprForHu   -- 特殊的胡牌列表
-- }
function HuManager:totalizeHuFan( args, filter ) 
	-- 先计算所有的胡牌牌型
	local lstTypes = self:calHuTypes(args, filter)
    self:PrintList(lstTypes)
	
	-- 再计算牌型对应的番数列表
	local lstFan = self:calFans(lstTypes)
    self:PrintList(lstFan)
    
	-- 计算番数之和
	local nTotalFan = 0
	for i,fan in pairs(lstFan) do
		nTotalFan = nTotalFan + fan
	end

	return nTotalFan
end


-- 计算所有满足条件的胡牌牌型
-- args = {
--    lstPilecards 	-- 结构牌：{ {lstCards, type}, {lstCards, type}, ...}
--    lstHandCards  -- 手牌
--    nHuCard		-- 胡的牌
--    nQFengCard	-- 圈风牌
--    nMFengCard	-- 门风牌
--    bZiMo			-- 是否自摸
--    bTing         -- 是否报听
--    nWallLeftNum  -- 牌墙剩余张数
--    lstOprForHu   -- 特殊的胡牌列表
-- }
function HuManager:calcAllTypes( lstArgs )
    local args = clone(lstArgs)
    local dictPileCards = args[1]
    local lstHandCards = args[2]
    local nHuCard = args[3]
    local nQuanFeng = args[4]
    local nMenFeng = args[5]
    local bZiMo = args[6]
    local bTing = args[7]
    local nWallLeftNum = args[8]
    local lstSpecialHu = args[9]
    
    -- 先判断传入的牌是否可以胡牌
    if calculator:CanHu(lstHandCards, nHuCard, true) then
        -- 手牌  + 结构牌 + 胡的牌
        local lstAllCards = {}
        table.insert(lstAllCards, nHuCard)
        
        for i,v in pairs(lstHandCards) do
            table.insert(lstAllCards, v)
        end
        
        -- 手牌 + 胡的牌
        local lstHandHu = clone(lstAllCards)
        
        for i,v in pairs(dictPileCards) do
            for j,card in pairs(v.lstCards) do
            	print('idx: '..i..'card='..card)
                table.insert(lstAllCards, card)
            end
        end
        
        table.sort(lstAllCards)
        table.sort(lstHandHu)
            
        local lstHuTypes = {}
        -- 计算风箭张数
--        for i,v in pairs(lstAllCards) do
--        	print(i,v)
--        end

        local dictFengAndJian = calculator:GetFengAndJianNumdict(lstAllCards)
        print('dictFengAndJian[east]:', dictFengAndJian[MJ_Card_East])
        print('dictFengAndJian[south]:', dictFengAndJian[MJ_Card_South])
        print('dictFengAndJian[west]:', dictFengAndJian[MJ_Card_West])
        print('dictFengAndJian[north]:', dictFengAndJian[MJ_Card_North])
        print('dictFengAndJian[zhong]:', dictFengAndJian[MJ_Card_Zhong])
        print('dictFengAndJian[fa]:', dictFengAndJian[MJ_Card_Fa])
        print('dictFengAndJian[bai]:', dictFengAndJian[MJ_Card_Bai])

        -- 大四喜、小四喜、三风刻、圈风刻、门风刻
        table.insert(lstHuTypes, calculator:CalcFengKeHuTypes(dictFengAndJian, nMenFeng, nQuanFeng))
        -- 大三元、小三元、双箭刻、箭刻
        table.insert(lstHuTypes, calculator:CalcJianKeHuTypes(dictFengAndJian))
        -- 九莲宝灯
        table.insert(lstHuTypes, calculator:CalcJiuLianBaoDengType(lstHandCards))
        -- 四杠、三杠、双暗杠、双明杠、暗杠、明杠
        table.insert(lstHuTypes, calculator:CalcGangHuTypes(dictPileCards))
        -- 连七对、七对
        table.insert(lstHuTypes, calculator:CalcQiDuiTypes(lstHandHu))
        -- 百万石
        table.insert(lstHuTypes, calculator:CalcBaiWanDanType(lstAllCards))
        -- 字一色
        table.insert(lstHuTypes, calculator:CalcZiYiSeType(lstAllCards))
        -- 四暗刻、三暗刻、双暗刻
        table.insert(lstHuTypes, calculator:CalcAnKeHuTypes(lstHandHu, dictPileCards, nHuCard, bZiMo))
        -- 一色双龙会
        table.insert(lstHuTypes, calculator:CalcYiSeShuangLongHui(lstAllCards))
        -- 一色四同顺
        table.insert(lstHuTypes, calculator:CalcYiSeSiTongShun(lstHandHu, dictPileCards))
        -- 一色四节高
        table.insert(lstHuTypes, calculator:CalcYiSeSiJieGao(dictPileCards))
        -- 一色四步高
        table.insert(lstHuTypes, calculator:CalcYiSeSiBuGao(dictPileCards))
        -- 混幺九
        table.insert(lstHuTypes, calculator:CalcHunYaoJiu(lstAllCards))
        -- 清一色
        table.insert(lstHuTypes, calculator:CalcQingYiSeType(lstAllCards))
        -- 一色三同顺
        table.insert(lstHuTypes, calculator:CalcYiSeSanTongShun(dictPileCards))
        -- 一色三节高
        table.insert(lstHuTypes, calculator:CalcYiSeSanJieGao(dictPileCards))
        -- 清龙
        table.insert(lstHuTypes, calculator:CalcQingLongType(lstAllCards))
        -- 一色三步高
        table.insert(lstHuTypes, calculator:CalcYiSeSanBuGao(dictPileCards))
        -- 大于五、小于五
        table.insert(lstHuTypes, calculator:CalcFiveTypes(lstAllCards))
        -- 妙手回春、海底捞月
        table.insert(lstHuTypes, calculator:CalcMSHCAndHDLY(bZiMo, nWallLeftNum))
        -- 碰碰和
        table.insert(lstHuTypes, calculator:CalcPengPengHu(lstHandHu, dictPileCards))
        -- 混一色
        table.insert(lstHuTypes, calculator:CalcHunYiSeType(lstAllCards))
        -- 全求人
        table.insert(lstHuTypes, calculator:CalcQuanQiuRen(dictPileCards, bZiMo))
        -- 全带幺
        table.insert(lstHuTypes, calculator:CalcQuanDaiYao(dictPileCards))
        -- 不求人、门前清、自摸
        table.insert(lstHuTypes, calculator:CalcZiMoTypes(dictPileCards, bZiMo))
        -- 平和
        table.insert(lstHuTypes, calculator:CalcPingHu(lstHandHu, dictPileCards))
        -- 四归一
        table.insert(lstHuTypes, calculator:CalcSiGuiYi(lstHandHu, dictPileCards))
        -- 断幺
        table.insert(lstHuTypes, calculator:CalcDuanYao(lstAllCards))
        -- 二五八将、幺九头
        table.insert(lstHuTypes, calculator:CalcJiangTypes())
        -- 报听
        table.insert(lstHuTypes, calculator:CalcBaoTing(bTing))
        -- 一般高
        table.insert(lstHuTypes, calculator:CalcYiBanGao(dictPileCards))
        -- 连六
        table.insert(lstHuTypes, calculator:CalcLianLiu(lstAllCards))
        -- 老少副
        table.insert(lstHuTypes, calculator:CalcLaoShaoFu(dictPileCards))
        -- 幺九刻
        table.insert(lstHuTypes, calculator:CalcYaoJiuKe(dictPileCards))
        -- 边张、坎张、单钓将
        table.insert(lstHuTypes, calculator:CalcBianKanDanDiao(lstHandCards, nHuCard))
        
        -- 把特殊胡牌类型也加进去
        table.insert(lstHuTypes, lstSpecialHu)
       
        -- 转换为一维列表
        local lstCalc = {}
        for i,lst in pairs(lstHuTypes) do
        	for j,hutype in pairs(lst) do
        		table.insert(lstCalc, hutype)
        	end
        end

        table.sort(lstCalc)

        g_methods:log('----- calc all Types -----')
        self:PrintList(lstCalc)

        return lstCalc
    end
    
    return {}
end

-- 测试示例
function HuManager:TestTotalizeHuFan()
    g_methods:log(string.format("----------- test ---------------" ))

    -- 结构牌
    local lstGrabPile = {}
    table.insert(lstGrabPile,{lstCards = {465, 466, 467, 468}, type=4})
    table.insert(lstGrabPile,{lstCards = {433, 431, 433}, type=2})
    table.insert(lstGrabPile,{lstCards = {424, 421, 424, 422}, type=16})
    -- table.insert(lstGrabPile,{lstCards = {174, 181, 194}, type=128})

    local lstHand = {151,161,171,191}

    local nHuCard = 192

    local nWallLeftNum = 21
    
    local bTing = false

    local  nFPFan = self:totalizeHuFan(
        {
            [1]  = lstGrabPile,
            [2]  = lstHand, 
            [3]  = nHuCard,
            [4]  = 411, 
            [5]  = 411,
            [6]  = false,
            [7]  = bTing,
            [8]  = nWallLeftNum ,
            [9]  = {},
        },
        true
    )
    g_methods:log(string.format("nFPFan  %d",nFPFan ))

    local  nZMFan = self:totalizeHuFan(
        {
            [1]  = lstGrabPile,
            [2]  = lstHand, 
            [3]  = nHuCard,
            [4]  = 411, 
            [5]  = 411 ,
            [6]  = true,
            [7]  = bTing,
            [8]  = nWallLeftNum ,
            [9]  = {},
        },
        true
    )
    g_methods:log(string.format("nZMFan  %d",nZMFan ))
    g_methods:log(string.format("--------------------------" ))
end

function HuManager:PrintList( tb )
    str = ''
    for i,v in pairs(tb) do
        str = str..v..','
    end
    g_methods:log(str)
end


return HuManager