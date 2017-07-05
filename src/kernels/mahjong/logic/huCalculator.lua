-- HuCalculator.lua
-- 2016-05-19
-- Zhangh
-- 胡牌计算类：提供牌型计算接口及一些功能接口

import( "..define" )
import( ".fantypes" )

-- 麻将番数计算
local HuCalculator = class( "HuCalculator" )

-- 构造
function HuCalculator:ctor()
    self.lstHuGroup = {}  -- 拆牌后得到的所有胡牌组合
    self.lstFind = {}  -- 记录拆牌时得到的一种胡牌组合
end

-- 本文中用到的结构牌字典dictPileCards的形式为： { {lstCards, type}, {lstCards, type}, ...}
-- 单个结构牌的数据结构为{lstCards, type}，lstCards为结构牌中的牌数据，type为具体操作(例如左吃，暗杠等)

-- 传入手牌，计算可以胡哪些牌
function HuCalculator:CalcAllCanHuCards( lstHandCards )
    -- 手牌张数最多13张
    if table.getn(lstHandCards) > 13 then
        print("---- CalcAllCanHuCards error: cardnum more then 13 ")
        return {}
    end

    -- 将1-9所有的点数挨个代入，算出能胡的牌，但是字牌不能大于七张
    local lstCanHu = {}  -- 记录可以胡的牌的牌值，例如一万就记11
    for ctype=TYPE_WAN,TYPE_FENG do
        for point=POINT_1,POINT_9 do
            -- 字牌：东南西北中发白，最大牌点7
            if ctype == TYPE_FENG and point > POINT_7 then
                break
            end

            -- 这张牌是否可以胡
            local card = ctype * 100 + point * 10 + 1

            -- 代入这张牌，查看是否可以胡
            local lstCards = clone(lstHandCards)
            table.insert(lstCards, card)

            -- 计算各牌的张数
            local dictCardsNum = {}  -- 牌值为key，张数为value
            for i,v in pairs(lstCards) do
                local key = getCardTypePoint(v)  -- 牌值
                if dictCardsNum[key] == nil then
                    dictCardsNum[key] = 1
                else
                    dictCardsNum[key] = dictCardsNum[key] + 1
                end
            end
            
            -- 只需要找到一种胡牌组合即可，找到后记录牌值
            if self:StanderHu(dictCardsNum, 0, false, false) then
                table.insert(lstCanHu, getCardTypePoint(card))
            end
        end
    end

    return lstCanHu
end

-- 是否可以胡牌
-- 参数：手牌lstHandCards，胡的牌nHuCard，bCalcAll(是否计算所有的胡牌组合)
function HuCalculator:CanHu( lstHandCards, nHuCard, bCalcAll )
    -- 手牌 + 胡的牌
    local lstCards = clone(lstHandCards)
    table.insert(lstCards, nHuCard)

    -- 是否是七对牌型
    if self:IsQiDuiType(lstCards) then
        return true
    end

    -- 不是七对牌型时，按照标准胡牌来计算
    -- 计算得到所有可能的胡牌组合
    return self:CalcCombinationOfHu(lstCards, bCalcAll)
end

-- 计算剩余张数
function HuCalculator:ReMain( dictCardsNum )
    local nums = 0
    for k, v in pairs(dictCardsNum) do
        if k ~= 0 then
            nums = nums + v
        end
    end
    return nums
end 

-- 计算胡牌组合
-- 参数：
--      lstCards: 手牌 + 胡的牌
--      bCalcAll：是否计算所有的组合，若为false则只计算一种胡牌
function HuCalculator:CalcCombinationOfHu(lstCards, bCalcAll)
    if table.getn(lstCards) == 0 then
        return false
    end

    -- 清空胡牌组合的存储容器
    self.lstHuGroup = {}
    self.lstFind = {}

    -- 计算各牌的张数
    local dictCardsNum = {}  -- 牌值为key，张数为value
    for i,v in pairs(lstCards) do
        local key = getCardTypePoint(v)  -- 牌值
        if dictCardsNum[key] == nil then
            dictCardsNum[key] = 1
        else
            dictCardsNum[key] = dictCardsNum[key] + 1
        end
    end

    -- 计算得到所有可能的胡牌组合
    self:StanderHu(dictCardsNum, 0, bCalcAll, true)

    -- 是否有可用的胡牌组合
    return table.getn(self.lstHuGroup) > 0
end

-- 标准胡牌计算，通过拆分手牌来找出可胡牌的组合
-- 参数：dictCardsNum(手牌字典张数)，key-牌值，value-张数
--       nJiang(将牌)，bFindAll(是否查找所有的胡牌组合)
--       bRecord(是否要记录所有的查询结果)
-- 返回值：当bFindAll=false时，如果找到一种胡牌组合即返回true，未找到时返回false
--         当bFindAll=true时，函数一直返回false，所以不能以此来做是否可以胡的判断，应该判断lstHuGroup
function HuCalculator:StanderHu( dictCardsNum, nJiang, bFindAll, bRecord )
    -- 张数减至0，即代表找到一种胡牌组合（找到一个解）
    if self:ReMain(dictCardsNum) == 0 then
        --print('-- find a solution --')

        -- 是否需要记录查询结果
        if bRecord then
            -- 打印找到的一个解
--            for i,lst in pairs(self.lstFind) do
--                print('---- i=,', i)
--                for j,v in pairs(lst) do
--                    print(j,v)
--                end
--            end

            -- 记录已找到的胡牌组合
            table.insert(self.lstHuGroup, clone(self.lstFind))
        end

        -- 如果查找所有的胡牌组合，在找到一个解后，返回上一节点，继续找下一个解
        if bFindAll then
            --print('-- try to find other solution --')
            return false
        end
        
        -- 默认只需要找到一个解即可结束
        return true
    end

    -- 计算张数时，一定要按照牌值从小到大来
    local ncard = -1
    for i=11,60 do
        if dictCardsNum[i] ~= nil and dictCardsNum[i] > 0 then
            ncard = i
            break
        end
    end

    if ncard == -1 then
        print('standerhu error: ---> ncard=-1 <---')
        return false
    end

    -- 先从刻子开始拆
    if dictCardsNum[ncard] >= 3 then
        dictCardsNum[ncard] = dictCardsNum[ncard] - 3

        if bRecord then
            table.insert(self.lstFind, {ncard, ncard, ncard})
        end

        if self:StanderHu(dictCardsNum, nJiang, bFindAll, bRecord) then
            return true
        end

        -- 回溯
        if bRecord then
            table.remove(self.lstFind)
        end

        dictCardsNum[ncard] = dictCardsNum[ncard] + 3
    end

    -- 拆将
    if dictCardsNum[ncard] >= 2 and nJiang == 0 then

        dictCardsNum[ncard] = dictCardsNum[ncard] - 2
        nJiang = ncard

        if bRecord then
            table.insert(self.lstFind, {ncard, ncard})
        end

        if self:StanderHu(dictCardsNum, nJiang, bFindAll, bRecord) then
            return true
        end

        -- 回溯
        if bRecord then
            table.remove(self.lstFind)
        end

        dictCardsNum[ncard] = dictCardsNum[ncard] + 2
        nJiang = 0
    end

    -- 计算顺子组合
    local ncard2 = ncard + 1
    local ncard3 = ncard + 2
    if ncard < 40 then  -- 序数牌
        if dictCardsNum[ncard2] ~= nil and dictCardsNum[ncard3] ~= nil then
            if dictCardsNum[ncard2] > 0 and dictCardsNum[ncard3] > 0 and ncard % 10 < 8 then
                dictCardsNum[ncard] = dictCardsNum[ncard] - 1
                dictCardsNum[ncard2] = dictCardsNum[ncard2] - 1
                dictCardsNum[ncard3] = dictCardsNum[ncard3] - 1

                if bRecord then
                    table.insert(self.lstFind, {ncard, ncard2, ncard3})
                end

                if self:StanderHu(dictCardsNum, nJiang, bFindAll, bRecord) then
                    return true
                end

                -- 回溯
                if bRecord then
                    table.remove(self.lstFind)
                end
 
                dictCardsNum[ncard] = dictCardsNum[ncard] + 1
                dictCardsNum[ncard2] = dictCardsNum[ncard2] + 1
                dictCardsNum[ncard3] = dictCardsNum[ncard3] + 1
            end
        end
    end

    return false
end

-- 获取顺子个数为nStraightNum的胡牌组合
-- 参数：nStraightNum(要满足的顺子个数)，bEqualTo(顺子数是否一定要等于nStraightNum)
-- bEqualTo=true时，一定要等于；否则为大于等于
function HuCalculator:GetHuListByStraight(nStraightNum, bEqualTo)
    local lstHuFind = {}

    -- 遍历所有的胡牌组合
    for i,lstHu in pairs(self.lstHuGroup) do
        -- 遍历一种胡牌组合中的所有结构（刻、将、顺）
        local nCount = 0
        for j,lstStruct in pairs(lstHu) do
            if table.getn(lstStruct) == 3 then  -- 刻或顺
                if lstStruct[1] ~= lstStruct[2] and 
                   lstStruct[2] ~= lstStruct[3] and
                   lstStruct[1] ~= lstStruct[3] then  -- 顺子
                    nCount = nCount + 1
                end
            end
        end

        -- 记录符合顺子个数要求的胡牌组合
        if nCount > 0 then
            if bEqualTo then  -- 等于
                if nCount == nStraightNum then
                    table.insert(lstHuFind, lstHu)
                end
            else
                -- 大于等于
                if nCount >= nStraightNum then
                    table.insert(lstHuFind, lstHu)
                end
            end
        end
    end

    return lstHuFind
end

-- 获取刻子个数为nKeNum的胡牌组合
-- 参数：nKeNum(要满足的刻子个数)，bEqualTo(刻子数是否一定要等于nKeNum)
-- bEqualTo=true时，一定要等于；否则为大于等于
function HuCalculator:GetHuListByKe(nKeNum, bEqualTo)
    local lstHuFind = {}

    -- 遍历所有的胡牌组合
    for i,lstHu in pairs(self.lstHuGroup) do
        -- 遍历一种胡牌组合中的所有结构（刻、将、顺）
        local nCount = 0
        for j,lstStruct in pairs(lstHu) do
            if table.getn(lstStruct) == 3 then  -- 刻或顺
                if lstStruct[1] == lstStruct[2] and 
                   lstStruct[1] == lstStruct[3] then  -- 刻子
                    nCount = nCount + 1
                end
            end
        end

        -- 记录符合刻子个数要求的胡牌组合
        if nCount > 0 then
            if bEqualTo then
                if nCount == nKeNum then
                    table.insert(lstHuFind, lstHu)
                end
            else
                if nCount >= nKeNum then
                    table.insert(lstHuFind, lstHu)
                end
            end
        end
    end

    return lstHuFind
end

-- 从一种胡牌组合中取出所有的顺子
-- 参数：lstHu(胡牌组合)，形式为{{11,12,13},{11,11,11},{12,13,14},{12,13,14},{15,15}}，即由哪些刻将顺组成
-- 返回：该牌型组合中的所有顺子，例如{{11,12,13},{12,13,14},{12,13,14}}，列表元素均为牌值(花色和牌点的组合值)
function HuCalculator:GetStraightListFromHuList( lstHu )
    local lstStraight = {}
    -- 遍历胡牌组合
    for j,lstStruct in pairs(lstHu) do
        if table.getn(lstStruct) == 3 then  -- 刻或顺
            -- 记录顺子
            if lstStruct[1] ~= lstStruct[2] and 
               lstStruct[2] ~= lstStruct[3] and
               lstStruct[1] ~= lstStruct[3] then
                table.insert(lstStraight, lstStruct)
            end
        end
    end

    return lstStraight
end

-- 从一种胡牌组合中取出所有的刻子
-- 参数：lstHu(胡牌组合)，形式为{{11,12,13},{11,11,11},{12,13,14},{12,13,14},{15,15}}，即由哪些刻将顺组成
-- 返回：该牌型组合中的所有刻子，例如{{11,11,11}}，列表元素均为牌值(花色和牌点的组合值)
function HuCalculator:GetKeListFromHuList( lstHu )
    local lstKe = {}
    -- 遍历胡牌组合
    for j,lstStruct in pairs(lstHu) do
        if table.getn(lstStruct) == 3 then  -- 刻或顺
            -- 记录刻子
            if lstStruct[1] == lstStruct[2] and
               lstStruct[1] == lstStruct[3] then
                table.insert(lstKe, lstStruct)
            end
        end
    end

    return lstKe
end

-- 从一种胡牌组合中取出将牌
-- 参数：lstHu(胡牌组合)，形式为{{1,2,3},{1,1,1},{2,3,4},{2,3,4},{5,5}}，即由哪些刻将顺组成
-- 返回：将牌
function HuCalculator:GetJiangFromHuList( lstHu )
    -- 遍历胡牌组合
    for j,lstStruct in pairs(lstHu) do
        if table.getn(lstStruct) == 2 then  -- 将
            return lstStruct[1]
        end
    end

    return 0
end

-- 计算牌列表中风箭的张数，返回字典
-- 传入参数：所有的牌（手牌+结构牌+胡的牌）
function HuCalculator:GetFengAndJianNumdict( lstCards )
    -- 东南西北中发白及其对应的张数
    local tbFengJianNum = { [MJ_Card_East] = 0, 
                            [MJ_Card_South] = 0, 
                            [MJ_Card_West] = 0, 
                            [MJ_Card_North] = 0, 
                            [MJ_Card_Zhong] = 0, 
                            [MJ_Card_Fa] = 0, 
                            [MJ_Card_Bai] = 0,}  

    -- 记录风箭的张数
    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)  -- 花色
        if ctype == TYPE_FENG then
            local value = getCardTypePoint(v)  -- 牌值
            tbFengJianNum[value] = tbFengJianNum[value] + 1
        end
    end

    return tbFengJianNum
end

-- 判断是否是连续的牌
-- 传入参数：牌列表(lstCards)，需要连续的个数(nConsecutiveCount)
-- 参数形式：lstCards = {111,121, ...}
function HuCalculator:IsConsecutiveCards( lstCards, nConsecutiveCount )
    -- 连续的数值必须为2个及2个以上
    if nConsecutiveCount <= 1 then
        return false
    end

    -- 先对传入的牌列表进行升序排序
    local lstT = clone(lstCards)
    table.sort(lstT)

    local nCount = 1
    local nCmpValue = getCardTypePoint(lstT[1])
    for i,v in pairs(lstT) do
        local ctype = getCardType(v)  -- 花色
        -- 连续的概念只针对序数牌
        if ctype >= TYPE_WAN and ctype <= TYPE_TONG then
            local value = getCardTypePoint(v)  -- 牌值
            if value ~= nCmpValue then
                if value == nCmpValue + 1 then  -- 连续数值
                    nCount = nCount + 1
                    if nCount >= nConsecutiveCount then
                        return true
                    end
                else
                    -- 数值不再连续，重新计数
                    nCount = 1
                end
                -- 只要发生变化，就要更新比较值
                nCmpValue = value
            end
        else
            break
        end
    end

    return false
end

-- 判断是否是连续的数值
-- 传入参数：数值列表(lstValue)，数值之间的差值(nDif)，需连续的个数(nConsecutiveCount)
-- 参数形式：lstValue = {11,12, ...}
function HuCalculator:IsConsecutiveValues( lstValue, nDif, nConsecutiveCount )
    -- 连续的数值必须为2个及2个以上
    if nConsecutiveCount <= 1 then
        return false
    end

    -- 相邻数值的差值至少为1
    if nDif < 1 then
        return false
    end

    -- 先对传入的数值列表进行升序排序
    local lstT = clone(lstValue)
    table.sort(lstT)

    for i,value in pairs(lstT) do
        local nFromValue = value  -- 从哪个值开始查找
        local nCount = 1  -- 连续个数
        local nCmpValue = nFromValue + nDif  -- 每次用于比较的值

        -- 连续的概念只针对序数牌
        local ctype = math.floor(value/10)  -- 花色
        if ctype >= TYPE_WAN and ctype <= TYPE_TONG then
            for j,v in pairs(lstT) do
                if v == nCmpValue then
                    nCount = nCount + 1
                    if nCount >= nConsecutiveCount then
                        return true
                    end
                    -- 查找下一个值
                    nCmpValue = nCmpValue + nDif

                elseif v > nCmpValue then
                    break
                end
            end
        else
            break
        end
    end

    return false
end

-- 判断是否是为清一色牌型：全部由同一种序数牌（条筒万）组成
-- 参数：所有牌（手牌+胡的牌+结构牌）
function HuCalculator:IsQingYiSeType( lstCards )
    -- 取第一张牌的花色作为比较的基准值
    local cardtype = getCardType(lstCards[1])  -- 取出花色
    
    -- 清一色一定是万条筒
    if cardtype < TYPE_WAN or cardtype > TYPE_TONG then
        return false
    end

    -- 检查所有的牌是否是同一种花色
    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)
        if ctype ~= cardtype then
            return false
        end
    end

    return true 
end

-- 计算清一色牌型：全部由同一种序数牌（条筒万）组成
-- 参数：所有的牌（手牌+结构牌+胡的牌）
function HuCalculator:CalcQingYiSeType( lstCards )
    if self:IsQingYiSeType(lstCards) then
        return {HU_FLUSH}
    end
    return {} 
end

-- 计算混一色牌型：由字牌和一种序数牌组成
-- 参数：所有的牌（手牌+结构牌+胡的牌）
function HuCalculator:CalcHunYiSeType( lstCards )
    local bZi = false  -- 是否有字牌
    local nNumberCardType = -1  -- 记录最先出现的序数牌的花色

    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)  -- 花色
        if ctype == TYPE_FENG then  -- 字牌
            bZi = true
        elseif ctype < TYPE_FENG then  -- 序数牌
            if nNumberCardType == -1 then
                nNumberCardType = ctype
            else
                -- ctype和最先记录的序数牌花色不同
                if nNumberCardType ~= ctype then
                    return {}
                end
            end
        end
    end

    -- 必须要同时有字牌和序数牌
    if not bZi or nNumberCardType == -1 then
        return {}
    end

    return {HU_HUNYIS} 
end

-- 判断是否是为字一色牌型：全部由字牌（东南西北中发白）组成
-- 参数：所有的牌（手牌+结构牌+胡的牌）
function HuCalculator:CalcZiYiSeType( lstCards )
    -- 取第一张牌的牌型作为比较的基准值
    local cardtype = getCardType(lstCards[1])  -- 取出花色

    -- 检查所有的牌是否是字牌（东南西北中发白）
    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)
        if ctype ~= TYPE_FENG then
            return {}
        end
    end

    return {HU_FLUSHOFZI} 
end

-- 是否是七对牌型：胡牌由7个对子组成，无结构牌
-- 参数：lstCards(手牌+胡的牌)
function HuCalculator:IsQiDuiType( lstCards )
    -- 一定是14张牌
    if table.getn(lstCards) ~= 14 then
        return false
    end

    -- 把lstCards里的数值(例如111)全部转换为牌值（花色和牌点的组合值，例如11）
    local lstValue = {}
    for i,v in pairs(lstCards) do 
        local key = getCardTypePoint(v)  -- 牌值作为key
        if lstValue[key] == nil then
            lstValue[key] = 1
        else
            lstValue[key] = lstValue[key] + 1
        end
    end
        
    -- 每个key对应的值（即张数）应该为2的倍数 
    for key,num in pairs(lstValue) do
        if num % 2 ~= 0 then
            return false
        end
    end
    
    return true
end

-- 计算七对、连七对牌型
-- 连七对牌型：由一种花色序数牌组成序数相连的7个对子的和牌
-- 参数：lstCards(手牌+胡的牌)
function HuCalculator:CalcQiDuiTypes( lstCards )
    -- 是否是七对
    if not self:IsQiDuiType(lstCards) then
        return {}
    end
    
    local lstHuTypes = {}
    -- 七对
    table.insert(lstHuTypes, HU_QID)
    
    -- 牌连续
    if not self:IsConsecutiveCards(lstCards, 7) then
        return lstHuTypes
    end

    -- 清一色
    if not self:IsQingYiSeType(lstCards) then
        return lstHuTypes
    end
    
    -- 连七对
    table.insert(lstHuTypes, HU_LIANQID)

    return lstHuTypes
end

-- 是否是百万石牌型：万牌的清一色，且所有万牌上的数字之和>=100
-- 例如556666777788889999，计算5*2 + 6*4 + 7*4 + 8*4 + 9*4 = 130
-- 参数：所有的牌（手牌 +结构牌+胡的牌）
function HuCalculator:CalcBaiWanDanType( lstCards )
    -- 清一色
    local bQingYiSe = self:IsQingYiSeType(lstCards)
    if not bQingYiSe then
        return {}
    end

    -- 全是万
    local cardtype = getCardType(lstCards[1])
    if cardtype ~= TYPE_WAN then
        return {}
    end

    -- 计算牌点总和
    local nTotal = 0
    for i,v in pairs(lstCards) do
        nTotal = nTotal + getCardPoint(v)  -- 取出牌点
    end

    if nTotal >= 100 then
        return {HU_BAIWAND}
    end
    
    return {} 
end

-- 计算清龙牌型：和牌里有相同花色的123456789，不计较是否是三个顺子
-- 参数：所有的牌(手牌+胡的牌+结构牌)
function HuCalculator:CalcQingLongType( lstCards )
    -- 遍历序数牌
    local lstType = {TYPE_WAN, TYPE_TIAO, TYPE_TONG,}
    local lstPoint = {1,2,3,4,5,6,7,8,9}

    -- clone 并且排序
    local lstT = clone(lstCards)
    table.sort(lstT)

    for i,tp in pairs(lstType) do
        local pt = lstPoint[1]
        local count = 0
        for j,v in pairs(lstT) do
            local cardtype = getCardType(v)
            local point = getCardPoint(v)
            -- 1-9的顺子必须是同种花色
            if cardtype == tp and point == pt then
                count = count + 1
                pt = pt + 1

                if count == 9 then
                    return {HU_QINGLONG}
                end
            end
        end
    end

    return {}
end

-- 是否是九莲宝灯牌型：由一种花色序数牌按1112345678999组成的特定牌型
-- 参数：13张手牌 
function HuCalculator:CalcJiuLianBaoDengType( lstHandCards )
    -- 牌全部在手牌中，固定13张手牌，不包括胡的那张牌
    if table.getn(lstHandCards) ~= 13 then
        return {}
    end
    
    -- 清一色
    local bQingYiSe = self:IsQingYiSeType(lstHandCards)
    if not bQingYiSe then
        return {}
    end

    -- 从小到大排序
    local lstT = clone(lstHandCards)
    table.sort(lstT)

    --- 九莲宝灯为特定的1112345678999牌型
    local lstJLBD = {1,1,1,2,3,4,5,6,7,8,9,9,9,}

    -- 和lstJLBD逐个比较，一定要全部吻合才对
    for i,v in pairs(lstT) do
        local point = getCardPoint(v)
        if point ~= lstJLBD[i] then
            return {}
        end
    end

    return {HU_JIULIANBD}
end

-- 计算所有暗刻相关的胡牌牌型：四暗刻、三暗刻、双暗刻
-- 暗刻只会存在于手牌中，暗杠也算是暗刻，暗杠只存在于结构牌中；如果是放炮，手牌刻子中包含胡的牌，则只能算明刻
-- 参数：lstCards(手牌+胡的牌)，dictPileCards(结构牌)，nHuCard(胡的牌)，bZiMo(是否自摸)
function HuCalculator:CalcAnKeHuTypes( lstCards, dictPileCards, nHuCard, bZiMo )
    local nAnKeNum = 0  -- 暗刻数(包括暗刻和暗杠的数量) 

    -- 结构牌中的暗杠数
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == AN_GANG then  -- 暗杠(算一个暗刻)
            nAnKeNum = nAnKeNum + 1
        end
    end

    -- 胡的牌的牌值
    local nHuValue = getCardTypePoint(nHuCard)

    -- 从手牌中获取刻子相关的胡牌组合
    local lstHu = self:GetHuListByKe(1, false)
    if table.getn(lstHu) > 0 then  -- 手牌中有暗刻
        -- 记录每种胡牌组合里的刻子数
        local lstKeNum = {}
        -- 遍历符合刻子要求的所有胡牌组合，找出匹配的牌型
        for i,lstSub in pairs(lstHu) do
            -- 该胡牌组合中的刻子列表
            local lstKe = self:GetKeListFromHuList(lstSub)
            local num = table.getn(lstKe)

            -- 放炮时，要判断胡的牌是不是在刻子里
            if not bZiMo then
                -- 胡的那张牌是否在刻子中
                local bInKeList = false
                for i,lst in pairs(lstKe) do
                    for j,v in pairs(lst) do
                        if v == nHuValue then
                            bInKeList = true
                            break
                        end
                    end
                end
                
                -- 在刻子中找到胡的牌，如果在顺子中也能找到，那就算他是胡的顺子，仍为暗刻
                if bInKeList then
                    -- 该胡牌组合中的顺子列表
                    local lstStraight = self:GetStraightListFromHuList(lstSub)
                    local bInStraight = false
                    for i,lst in pairs(lstStraight) do
                        for j,v in pairs(lst) do
                            if v == nHuValue then
                                bInStraight = true
                                break
                            end
                        end
                    end

                    -- 顺子中没有，说明胡的就是那个刻子，算作明刻
                    if not bInStraight then
                        num = num - 1
                    end
                end
            end
            
            table.insert(lstKeNum, num)
        end

        -- 所有的组合中，最大的刻子数
        local nMaxNum = math.max(unpack(lstKeNum))
        nAnKeNum = nAnKeNum + nMaxNum
    end

    local lstHuTypes = {}
    -- 四暗刻
    if nAnKeNum >= 4 then
        table.insert(lstHuTypes, HU_SIANKE)
    end

    -- 三暗刻
    if nAnKeNum >= 3 then
        table.insert(lstHuTypes, HU_SANANKE)
    end

    -- 双暗刻
    if nAnKeNum >= 2 then
        table.insert(lstHuTypes, HU_SHUANGANK)
    end

    return lstHuTypes
end

-- 计算所有杠相关的胡牌牌型：四杠、三杠、双暗杠、双明杠、暗杠、明杠
-- 杠只会存在在结构牌中
-- 参数：结构牌
function HuCalculator:CalcGangHuTypes( dictPileCards )
    local nMingGangNum = 0  -- 明杠数
    local nAnGangNum = 0  -- 暗杠数

    -- 找出结构牌中的杠，记录明杠和暗杠的数量
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == ZHI_GANG or oper == PENG_GANG then  -- 明杠
            nMingGangNum = nMingGangNum + 1
        elseif oper == AN_GANG then  -- 暗杠
            nAnGangNum = nAnGangNum + 1
        end
    end

    local nGangNum = nMingGangNum + nAnGangNum
    local lstHuTypes = {}
    -- 四杠
    if nGangNum == 4 then
        table.insert(lstHuTypes, HU_SIGANG)
    end

    -- 三杠
    if nGangNum >= 3 then
        table.insert(lstHuTypes, HU_SANG)
    end

    -- 双暗杠
    if nAnGangNum >= 2 then
        table.insert(lstHuTypes, HU_SHUANGANG)
    end

    -- 双明杠
    if nMingGangNum >= 2 then
        table.insert(lstHuTypes, HU_SHUANGMINGG)
    end

    -- 暗杠
    if nAnGangNum >= 1 then
        table.insert(lstHuTypes, HU_ANGANG)
    end

    -- 明杠
    if nMingGangNum >= 1 then
        table.insert(lstHuTypes, HU_MINGG)
    end

    return lstHuTypes
end

-- 计算所有风刻相关的胡牌牌型：大四喜、小四喜、三风刻、圈风刻、门风刻
function HuCalculator:CalcFengKeHuTypes( dictFengAndJian, nMenFeng, nQuanFeng )
    -- 东南西北
    local lstFeng = {MJ_Card_East, MJ_Card_South, MJ_Card_West, MJ_Card_North,}
    -- 门风的牌值
    local nMenFengValue = getCardTypePoint(nMenFeng)
    -- 圈风的牌值
    local nQuanFengValue = getCardTypePoint(nQuanFeng)

    local nFengKeNum = 0  -- 风刻数
    local nFengDuiNum = 0 -- 风牌对子数
    local bMenFeng = false -- 是否有门风
    local bQuanFeng = false -- 是否有圈风

    for i,feng in pairs(lstFeng) do  
        local num = dictFengAndJian[feng]  -- 风牌对应的张数
        if num ~= nil then
            if num >= 3 then  -- 刻子或杠
                nFengKeNum = nFengKeNum + 1

                -- 门风标识
                if feng == nMenFengValue then
                    bMenFeng = true
                end

                -- 圈风标识
                if feng == nQuanFengValue then
                    bQuanFeng = true
                end

            elseif num == 2 then  -- 对子
                nFengDuiNum = nFengDuiNum + 1
            end
        end

    end

    local lstHuTypes = {}

    -- 大四喜：由4副风刻（或杠）组成的和牌
    if nFengKeNum == 4 then
        table.insert(lstHuTypes, HU_BSIXI)
    end

    -- 小四喜：风牌的三副刻子（杠），第四种风牌作将
    if nFengKeNum == 3 and nFengDuiNum == 1 then
        table.insert(lstHuTypes, HU_SSIXI)
    end

    -- 三风刻：胡牌型中含有任意三副风牌刻或杠
    if nFengKeNum >= 3 then
        table.insert(lstHuTypes, HU_SANFENGK)
    end

    -- 圈风刻：与圈风相同的风刻
    if bQuanFeng then
        table.insert(lstHuTypes, HU_QUANFENGK)
    end

    -- 门风刻：与门风相同的风刻
    if bMenFeng then
        table.insert(lstHuTypes, HU_MENFENGK)
    end

    return lstHuTypes
end

-- 计算所有箭刻相关的胡牌牌型：大三元、小三元、双箭刻、箭刻
function HuCalculator:CalcJianKeHuTypes( dictFengAndJian )
    -- 中发白
    local lstJian = {MJ_Card_Zhong, MJ_Card_Fa, MJ_Card_Bai,}
    
    local nJianKeNum = 0  -- 箭刻数
    local nJianDuiNum = 0 -- 箭牌对子数

    for i,jian in pairs(lstJian) do  
        local num = dictFengAndJian[jian]  -- 箭牌对应的张数
        if num ~= nil then
            if num >= 3 then  -- 刻子或杠
                nJianKeNum = nJianKeNum + 1
            elseif num == 2 then  -- 对子
                nJianDuiNum = nJianDuiNum + 1
            end
        end
    end

    local lstHuTypes = {}

    -- 大三元：有中发白组成的三副刻子或杠
    if nJianKeNum == 3 then
        table.insert(lstHuTypes, HU_BSANYUAN)
    end

    -- 小三元：中发白三种箭牌中两种的刻或杠，加上第三种的一对
    if nJianKeNum == 2 and nJianDuiNum == 1 then
        table.insert(lstHuTypes, HU_SSANYUAN)
    end

    -- 双箭刻：和牌时手中有中发白三副箭牌中的任意两副
    if nJianKeNum >= 2 then
        table.insert(lstHuTypes, HU_SHUANGJIANK)
    end

    -- 箭刻
    if nJianKeNum >= 1 then
        table.insert(lstHuTypes, HU_JIANKE)
    end

    return lstHuTypes
end

-- 计算混幺九牌型：全部由序数牌1、9或字牌组成的和牌
-- 参数：所有的牌(手牌+结构牌+胡的牌)
function HuCalculator:CalcHunYaoJiu( lstCards )
    -- 序数牌里只有1或9，其他均为字牌
    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)  -- 花色
        -- 为序数牌时，牌点只能是1或9
        if ctype < TYPE_FENG then
            local point = getCardPoint(v) -- 牌点
            if point ~= POINT_1 and point ~= POINT_9 then
                return {}
            end
        else
            -- 除序数牌之外，剩下的牌均为字牌（风箭）
            if ctype ~= TYPE_FENG then
                return {}
            end
        end
    end

    return {HU_HUNYIJ}
end

-- 计算老少副牌型：一种花色牌的123、789两副顺子
-- 可以同时出现2个花色的老少副，例如 123789万、123789筒、北北
-- 参数：dictPileCards(结构牌)
function HuCalculator:CalcLaoShaoFu( dictPileCards )
    -- 记录顺子结构里的牌值
    local lstPileValue = {}

    -- 找出结构牌中的顺子
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
        	-- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        end
    end

    -- 顺子数
    local nStraightNum = table.getn(lstPileValue)

    -- 结构牌数
    local nPileNum = table.getn(dictPileCards)

    -- 非顺子的结构牌超过3个，必不成此牌型
    if nPileNum - nStraightNum >= 3 then
        return {}
    end

    -- 如果结构牌中至少有2个顺子，判断是否为老少副
    if nStraightNum >= 2 then
        -- 顺子为123,789，且花色相同
        local lstShao = {}
        local lstLao = {}
        for i,v in pairs(lstPileValue) do
        	point = v % 10  -- 牌点
        	if point == 1 then  -- 找到少
        		table.insert(lstShao, v)
        	elseif point == 7 then  -- 找到老
        		table.insert(lstLao, v)
        	end
        end

        -- 老少配对
        for i,shao in pairs(lstShao) do
        	ctype = math.floor(shao/10)  -- 少的花色
        	for j,lao in pairs(lstLao) do
        		ctype2 = math.floor(lao/10)  -- 老的花色
        		if ctype == ctype2 then
        			return {HU_LAOSHAOF}
        		end
        	end
        end

        -- 名额已满，放弃查找
        if nPileNum == 4 or nStraightNum == 4 then
        	return {}
        end
    end

    -- 结构牌中的顺子数不够，需要从手牌中找出1个以上的顺子组合
    local lstHu = self:GetHuListByStraight(1, false)
    if table.getn(lstHu) == 0 then
        -- 没找到顺子组合的牌型
        return {}
    end

    -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
    for i,lstSub in pairs(lstHu) do
    	-- 记录手牌 + 结构牌的所有顺子
        local lstValue = clone(lstPileValue)

        -- 取出手牌中拆分的顺子
        local lstStraight = self:GetStraightListFromHuList(lstSub)
        for j,lst in pairs(lstStraight) do
            -- 记录顺子结构的最小的一张牌
            local lstT = clone(lst)
            table.sort(lstT)
            table.insert(lstValue, lstT[1])
        end

        -- 从所有的顺子中查找是否有老少副：顺子为123,789，且花色相同
        local lstShao = {}
        local lstLao = {}
        for j,v in pairs(lstValue) do
        	point = v % 10  -- 牌点
        	if point == 1 then  -- 找到少
        		table.insert(lstShao, v)
        	elseif point == 7 then  -- 找到老
        		table.insert(lstLao, v)
        	end
        end

        -- 老少配对
        for j,shao in pairs(lstShao) do
        	ctype = math.floor(shao/10)  -- 少的花色
        	for j,lao in pairs(lstLao) do
        		ctype2 = math.floor(lao/10)  -- 老的花色
        		if ctype == ctype2 then
        			return {HU_LAOSHAOF}
        		end
        	end
        end
    end

    return {}
end

-- 计算一色双龙会牌型：一种花色的两个老少副(123、789)，5为将牌
-- 此为特定牌型：123,123,789,789,55
-- 参数：所有的牌(手牌+胡的牌+结构牌)
function HuCalculator:CalcYiSeShuangLongHui( lstCards )
    -- 必须是14张牌
    if table.getn(lstCards) ~= 14 then
        return {}
    end

    -- 123,123,789,789,55 拆解为 11223355778899
    local lstSLH = {POINT_1, POINT_1, POINT_2, POINT_2, POINT_3, POINT_3,
                    POINT_5, POINT_5,
                    POINT_7, POINT_7, POINT_8, POINT_8, POINT_9, POINT_9,}

    local lstT = clone(lstCards)
    table.sort(lstT)

    for i,v in pairs(lstT) do
        local point = getCardPoint(v)  -- 牌点
        if point ~= lstSLH[i] then
            return {}
        end
    end

    -- 必须是清一色
    if not self:IsQingYiSeType(lstCards) then
        return {}
    end

    return {HU_FLUSHOFTWOLONG}
end

-- 计算一色四同顺牌型：有4副完全相同的顺子
-- 例如：123,123,123,123,白白
-- 参数：lstCards(手牌+胡的牌)，dictPileCards(结构牌)
function HuCalculator:CalcYiSeSiTongShun( lstCards, dictPileCards )
	-- 记录顺子结构里的牌值
    local lstPileValue = {}

    -- 找出结构牌中的顺子
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
        	-- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        else
        	-- 出现顺子之外的结构牌，必不成此牌型
        	return {}
        end
    end

    -- 顺子数
    local nStraightNum = table.getn(lstPileValue)

    -- 必须是14张
    if nStraightNum*3 + table.getn(lstCards) ~= 14 then
        return {}
    end

    -- 结构牌中的顺子不足4个
   	if nStraightNum < 4 then
		-- 除结构牌的顺子外，还需要满足的顺子数
        local nLeftNum = 4 - nStraightNum

        -- 结构牌中的顺子数不够，需要从手牌中找出nLeftNum个顺子
        local lstHu = self:GetHuListByStraight(nLeftNum, false)
        if table.getn(lstHu) == 0 then
            -- 没找到顺子组合的牌型
            return {}
        end

        -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
        for i,lstSub in pairs(lstHu) do
        	-- 记录手牌 + 结构牌的所有顺子
            local lstValue = clone(lstPileValue)

            -- 取出手牌中拆分的顺子
            local lstStraight = self:GetStraightListFromHuList(lstSub)
            for i,lst in pairs(lstStraight) do
                -- 记录顺子结构的最小的一张牌
                local lstT = clone(lst)
                table.sort(lstT)
                table.insert(lstValue, lstT[1])
            end

            -- 验证顺子是否全部相同
		   	if lstValue[1] == lstValue[2] and
               lstValue[1] == lstValue[3] and
               lstValue[1] == lstValue[4] then
		   		return {HU_FLUSHOFSIS}
		   	end
        end

   	else
   		-- 结构牌中的顺子已足够，验证顺子是否全部相同
	   	if lstPileValue[1] == lstPileValue[2] and
           lstPileValue[1] == lstPileValue[3] and
           lstPileValue[1] == lstPileValue[4] then
	   		return {HU_FLUSHOFSIS}
	   	end
   	end

    return {} 
end

-- 计算一色三同顺牌型：有3副完全相同的顺子
-- 参数：dictPileCards(结构牌)
function HuCalculator:CalcYiSeSanTongShun( dictPileCards )
    -- 记录顺子结构里的牌值
    local lstPileValue = {}

    -- 找出结构牌中的顺子
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
        	-- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        end
    end

    -- 顺子数
    local nStraightNum = table.getn(lstPileValue)

    -- 结构牌数
    local nPileNum = table.getn(dictPileCards)

    -- 非顺子的结构牌超过2个，必不成此牌型
    if nPileNum - nStraightNum >= 2 then
        return {}
    end

    -- 如果结构牌中至少有3个顺子，判断是否存在3个相同顺子
    if nStraightNum >= 3 then
        local dictNum = {}
        for i,value in pairs(lstPileValue) do
            if dictNum[value] == nil then
                dictNum[value] = 1
            else
                dictNum[value] = dictNum[value] + 1
            end

            -- 找到完全相同的3副顺子
            if dictNum[value] >= 3 then
                return {HU_FLUSHOFSANS}
            end
        end

        -- 名额已满，放弃查找
        if nPileNum == 4 or nStraightNum == 4 then
        	return {}
        end
    end

    -- 除结构牌的顺子外，还需要满足的顺子数
    local nLeftNum = 3 - nStraightNum

    -- 结构牌中的顺子数不够，至少需要从手牌中找出nLeftNum个顺子
    local lstHu = self:GetHuListByStraight(nLeftNum, false)
    if table.getn(lstHu) == 0 then
        -- 没找到顺子组合的牌型
        return {}
    end

    -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
    for i,lstSub in pairs(lstHu) do
    	-- 记录手牌 + 结构牌的所有顺子
        local lstValue = clone(lstPileValue)

        -- 取出手牌中拆分的顺子
        local lstStraight = self:GetStraightListFromHuList(lstSub)
        for j,lst in pairs(lstStraight) do
            -- 记录顺子结构的最小的一张牌
            local lstT = clone(lst)
            table.sort(lstT)
            table.insert(lstValue, lstT[1])
        end

        -- 从所有的顺子中查找是否有3个相同的顺子
        local dictNum = {}
        for j,value in pairs(lstValue) do
            if dictNum[value] == nil then
                dictNum[value] = 1
            else
                dictNum[value] = dictNum[value] + 1
            end

            -- 找到完全相同的3副顺子
            if dictNum[value] >= 3 then
                return {HU_FLUSHOFSANS}
            end
        end
    end

    return {}
end

-- 计算一色四节高牌型：四连刻，为一种花色4副依次递增一位数的刻子或杠
-- 参数：结构牌
function HuCalculator:CalcYiSeSiJieGao( dictPileCards )
    -- 记录刻杠结构里的牌值
    local lstPileValue = {}
    
    -- 计算结构牌中的刻杠数
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        -- 吃除外就是碰杠
        if oper ~= LCHI and oper ~= MCHI and oper ~= RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
            -- 记录刻杠的牌值
            local value = getCardTypePoint(lstcards[1])
            table.insert(lstPileValue, value)
        else
            -- 出现其他结构牌必不成此牌型
            return {}
        end
    end

    local nKeGangNum = table.getn(lstPileValue)

    -- 该牌型的刻杠数一定是4个
    -- 如果结构牌的刻杠不够4个，就要计算手牌中可拆出的刻子
    if nKeGangNum < 4 then
        -- 手牌中应该包括的刻子数
        local nLeftNum = 4 - nKeGangNum
        -- 获取刻子相关的胡牌组合
        local lstHu = self:GetHuListByKe(nLeftNum, true)
        if table.getn(lstHu) == 0 then
            -- 没找到
            return {}
        end

        -- 遍历符合刻子要求的所有胡牌组合，找出匹配的牌型
        for i,lstSub in pairs(lstHu) do
            local lstValue = clone(lstPileValue)

            -- 取出刻子列表
            local lstKe = self:GetKeListFromHuList(lstSub)
            -- 取出刻子的牌
            for i,lst in pairs(lstKe) do
                -- 每个刻子里的牌值都是一样的，只需要记录一张即可
                table.insert(lstValue, lst[1])
            end

            -- 是否4张连续
            if self:IsConsecutiveValues(lstValue, 1, 4) then
                -- 只要找到符合的即返回
                return {HU_FLUSHOFSIJG}
            end
        end

    elseif nKeGangNum == 4 then
        -- 结构牌中刻杠已满足要求，计算是否4张连续
        if self:IsConsecutiveValues(lstPileValue, 1, 4) then
            return {HU_FLUSHOFSIJG}
        end
    end

    return {}
end

-- 计算一色三节高牌型：三连刻，为一种花色3副依次递增一位数的刻子或杠
function HuCalculator:CalcYiSeSanJieGao( dictPileCards )
	-- 记录刻杠结构里的牌值
    local lstPileValue = {}
    
    -- 计算结构牌中的刻杠数
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        -- 吃除外就是碰杠
        if oper ~= LCHI and oper ~= MCHI and oper ~= RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
            -- 记录刻杠的牌值
            local value = getCardTypePoint(lstcards[1])
            table.insert(lstPileValue, value)
        end
    end

    -- 结构牌里的刻杠不一定都相同
    local nKeGangNum = table.getn(lstPileValue)

    -- 结构牌数
    local nPileNum = table.getn(dictPileCards)

    -- 非刻杠的结构牌超过2个，必不成此牌型
    if nPileNum - nKeGangNum >= 2 then
        return {}
    end

    -- 如果结构牌中有至少3个刻杠，判断是否存在3连刻
    if nKeGangNum >= 3 then
    	-- 是否存在3连刻
        if self:IsConsecutiveValues(lstPileValue, 1, 3) then
        	return {HU_FLUSHOFSANJG}
        end

        -- 名额已满，放弃查找
        if nPileNum == 4 or nKeGangNum == 4 then
            return {}
        end
    end

    -- 除结构牌的刻杠外，还需要从手牌中找到满足的刻杠数
    local nLeftNum = 3 - nKeGangNum

    -- 结构牌中的刻杠数不够，至少需要从手牌中找出nLeftNum个刻子
    local lstHu = self:GetHuListByKe(nLeftNum, false)
    if table.getn(lstHu) == 0 then
        -- 没找到刻子组合的牌型
        return {}
    end

    -- 遍历符合刻子要求的所有胡牌组合，找出匹配的牌型
    for i,lstSub in pairs(lstHu) do
    	-- 记录手牌 + 结构牌的所有刻子
        local lstValue = clone(lstPileValue)

        -- 取出手牌中拆分的刻子
        local lstKe = self:GetKeListFromHuList(lstSub)
        for i,lst in pairs(lstKe) do
            table.insert(lstValue, lst[1])
        end

        -- 是否存在3连刻
        if self:IsConsecutiveValues(lstValue, 1, 3) then
        	return {HU_FLUSHOFSANJG}
        end
    end

    return {}
end

-- 计算一色四步高牌型：牌里有4组依次递增1位或依次递增2位的顺子
-- 例如：123,234,345,456 或 123,345,567,789
function HuCalculator:CalcYiSeSiBuGao( dictPileCards )
    -- 记录顺子结构里的牌值
    local lstPileValue = {}
    
    -- 计算结构牌中的顺子数
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
            -- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        else
            -- 出现其他的结构牌必不成此牌型
            return {}
        end
    end

    local nStraightNum = table.getn(lstPileValue)

    -- 该牌型的顺子数一定是4个
    -- 如果结构牌的顺子不够4个，就要计算手牌中可拆出的顺子
    if nStraightNum < 4 then
        -- 除结构牌的顺子外，还需要满足的顺子数
        local nLeftNum = 4 - nStraightNum
        -- 获取顺子相关的胡牌组合
        local lstHu = self:GetHuListByStraight(nLeftNum, true)
        if table.getn(lstHu) == 0 then
            -- 没找到
            return {}
        end

        -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
        for i,lstSub in pairs(lstHu) do
            local lstValue = clone(lstPileValue)

            -- 取出顺子列表
            local lstStraight = self:GetStraightListFromHuList(lstSub)
            -- 取出顺子的牌
            for i,lst in pairs(lstStraight) do
                -- 记录顺子结构的最小的一张牌
                local lstT = clone(lst)
                table.sort(lstT)
                table.insert(lstValue, lstT[1])
            end

            -- 是否4张依次递增1位或2位
            if self:IsConsecutiveValues(lstValue, 1, 4) or self:IsConsecutiveValues(lstValue, 2, 4) then
                -- 只要找到符合的即返回
                return {HU_FLUSHOFSIBG}
            end
        end

    elseif nStraightNum == 4 then
        -- 结构牌中的顺子已满足要求，计算是否4张依次递增1位或2位
        if self:IsConsecutiveValues(lstPileValue, 1, 4) or self:IsConsecutiveValues(lstPileValue, 2, 4) then
            return {HU_FLUSHOFSIBG}
        end
    end

    return {}
end 

-- 计算一色三步高牌型：牌里有3组依次递增1位或依次递增2位的顺子
function HuCalculator:CalcYiSeSanBuGao( dictPileCards )
	-- 记录顺子结构里的牌值
    local lstPileValue = {}
    
    -- 计算结构牌中的顺子数
     for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
            -- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        end
    end

    -- 顺子数
    local nStraightNum = table.getn(lstPileValue)

    -- 结构牌数
    local nPileNum = table.getn(dictPileCards)

    -- 非顺子的结构牌超过2个，必不成此牌型
    if nPileNum - nStraightNum >= 2 then
        return {}
    end

    -- 如果结构牌中至少有3个顺子，判断是否存在3个连续的顺子
    if nStraightNum >= 3 then
        -- 是否存在3张依次递增1位或2位
        if self:IsConsecutiveValues(lstPileValue, 1, 3) or self:IsConsecutiveValues(lstPileValue, 2, 3) then
            return {HU_FLUSHOFSANBG}
        end

        -- 名额已满，放弃查找
        if nPileNum == 4 or nStraightNum == 4 then
            return {}
        end
    end

	-- 除结构牌的顺子外，至少还需要满足的顺子数
    local nLeftNum = 3 - nStraightNum

    -- 获取顺子相关的胡牌组合
    local lstHu = self:GetHuListByStraight(nLeftNum, false)
    if table.getn(lstHu) == 0 then
        -- 没找到
        return {}
    end

    -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
    for i,lstSub in pairs(lstHu) do
        local lstValue = clone(lstPileValue)

        -- 取出顺子列表
        local lstStraight = self:GetStraightListFromHuList(lstSub)
        for i,lst in pairs(lstStraight) do
            -- 记录顺子结构的最小的一张牌
            local lstT = clone(lst)
            table.sort(lstT)
            table.insert(lstValue, lstT[1])
        end

        -- 是否存在3张依次递增1位或2位
        if self:IsConsecutiveValues(lstValue, 1, 3) or self:IsConsecutiveValues(lstValue, 2, 3) then
            -- 只要找到符合的即返回
            return {HU_FLUSHOFSANBG}
        end
    end

    return {}
end

-- 计算一般高牌型：和牌时，牌里有相同的2组顺子
function HuCalculator:CalcYiBanGao( dictPileCards )
	-- 记录顺子结构里的牌值
    local lstPileValue = {}

    -- 找出结构牌中的顺子
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
        	-- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        end
    end

    -- 顺子数
    local nStraightNum = table.getn(lstPileValue)

     -- 结构牌数
    local nPileNum = table.getn(dictPileCards)

    -- 非顺子的结构牌超过3个，必不成此牌型
    if nPileNum - nStraightNum >= 3 then
        return {}
    end

    -- 如果结构牌中至少有2个顺子，判断是否存在2个相同顺子
    if nStraightNum >= 2 then
        local dictNum = {}
        for i,value in pairs(lstPileValue) do
            if dictNum[value] == nil then
                dictNum[value] = 1
            else
                dictNum[value] = dictNum[value] + 1
            end

            -- 找到完全相同的2副顺子
            if dictNum[value] >= 2 then
                return {HU_YIBANG}
            end
        end

        -- 名额已满，放弃查找
        if nPileNum == 4 or nStraightNum == 4 then
            return {}
        end
    end

    -- 除结构牌的顺子外，还需要满足的顺子数
    local nLeftNum = 2 - nStraightNum

    -- 结构牌中的顺子数不够，至少需要从手牌中找出nLeftNum个顺子
    local lstHu = self:GetHuListByStraight(nLeftNum, false)
    if table.getn(lstHu) == 0 then
        -- 没找到顺子组合的牌型
        return {}
    end

    -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
    for i,lstSub in pairs(lstHu) do
    	-- 记录手牌 + 结构牌的所有顺子
        local lstValue = clone(lstPileValue)

        -- 取出手牌中拆分的顺子
        local lstStraight = self:GetStraightListFromHuList(lstSub)
        for i,lst in pairs(lstStraight) do
            -- 记录顺子结构的最小的一张牌
            local lstT = clone(lst)
            table.sort(lstT)
            table.insert(lstValue, lstT[1])
        end

        -- 从所有的顺子中查找是否有2个相同的顺子
        local dictNum = {}
        for i,value in pairs(lstValue) do
            if dictNum[value] == nil then
                dictNum[value] = 1
            else
                dictNum[value] = dictNum[value] + 1
            end

            -- 找到完全相同的2副顺子
            if dictNum[value] >= 2 then
                return {HU_YIBANG}
            end
        end
    end

    return {}
end

-- 计算幺九刻牌型：和牌时，牌里有一组序数牌1、9或字牌的刻子
-- 参数：dictPileCards（结构牌）
function HuCalculator:CalcYaoJiuKe( dictPileCards )
    -- 结构牌中是否有幺九刻
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        -- 吃除外就是碰杠
        if oper ~= LCHI and oper ~= MCHI and oper ~= RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
        	local ctype = getCardType(lstcards[1])  -- 花色
            if ctype == TYPE_FENG then  -- 字牌
            	return {HU_YIJIUK}
            elseif ctype < TYPE_FENG then  -- 序数牌
            	local point = getCardPoint(lstcards[1])  -- 牌点
            	if point == POINT_1 or point == POINT_9 then
            		return {HU_YIJIUK}
            	end
            end
        end
    end

    -- 结构牌中没有幺九刻，从手牌中寻找
	local lstHu = self:GetHuListByKe(1, false)
    if table.getn(lstHu) == 0 then
        -- 没找到刻子组合的牌型
        return {}
    end

    -- 遍历符合刻子要求的所有胡牌组合，找出匹配的牌型
    for i,lstSub in pairs(lstHu) do
    	-- 记录手牌 + 结构牌的所有刻子
        local lstValue = clone(lstPileValue)

        -- 取出手牌中拆分的刻子
        local lstKe = self:GetKeListFromHuList(lstSub)
        for i,lst in pairs(lstKe) do
        	local ctype = math.floor(lst[1]/10)  -- 花色
            if ctype == TYPE_FENG then  -- 字牌
            	return {HU_YIJIUK}
            elseif ctype < TYPE_FENG then  -- 序数牌
            	local point = lst[1]%10  -- 牌点
            	if point == POINT_1 or point == POINT_9 then
            		return {HU_YIJIUK}
            	end
            end
        end
    end

    return {}
end

-- 计算全带幺牌型：每组刻子、杠、顺子、将里都带有字牌或序数牌1、9
-- 例如 111,123,789,白白白,发发
-- 参数：dictPileCards(结构牌)
function HuCalculator:CalcQuanDaiYao( dictPileCards )
    -- 结构牌中是否有不带幺九牌的
    for i,dict in pairs(dictPileCards) do
        -- 结构牌的牌数据
        local lstcards = dict.lstCards
        local ctype = getCardType(lstcards[1])  -- 花色
        
        if ctype > TYPE_FENG then  -- 非字牌，非序数牌
            return {}
        end

        -- 序数牌里是否全带了幺九牌
        if ctype < TYPE_FENG then  
            local bfind = false
            for j,card in pairs(lstcards) do
                local point = getCardPoint(card)  -- 牌点
                if point == POINT_1 or point == POINT_9 then
                    bfind = true
                    break
                end
            end

            -- 存在非幺九牌
            if not bfind then
                return {}
            end
        end
    end

    -- 结构牌中全部有幺九牌，看下手牌拆分的结构中是否同样满足条件
    -- 只需要存在一种胡牌组合即可
    -- 遍历所有的胡牌组合
    for i,lstHu in pairs(self.lstHuGroup) do
        local bFindYaoJiu = true
        -- 遍历一种胡牌组合中的所有结构（刻、将、顺）
        -- lstStruct记录的都是牌值（花色+牌点）
        for j,lstStruct in pairs(lstHu) do
            local ctype = math.floor(lstStruct[1]/10)  -- 花色
    
            if ctype > TYPE_FENG then  -- 非字牌，非序数牌
                bFindYaoJiu = false
                break
            end

            -- 序数牌里是否全带了幺九牌
            if ctype < TYPE_FENG then  
                local bfind = false
                for k,value in pairs(lstStruct) do
                    local point = value % 10  -- 牌点
                    if point == POINT_1 or point == POINT_9 then
                        bfind = true
                        break
                    end
                end

                -- 存在非幺九牌
                if not bfind then
                    bFindYaoJiu = false
                    break
                end
            end
        end

        if bFindYaoJiu then
            return {HU_DAIYIJ}
        end
    end

    return {}
end

-- 计算平和牌型：全部为序数牌，4副顺子、序数牌作将
-- 参数：lstCards（手牌+胡的牌），dictPileCards(结构牌)
function HuCalculator:CalcPingHu( lstCards, dictPileCards )
    -- 记录顺子结构里的牌值
    local lstPileValue = {}

    -- 找出结构牌中的顺子
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            -- 结构牌的牌数据
            local lstcards = dict.lstCards
        	-- 记录顺子结构的最小的一张牌
            local lstT = clone(lstcards)
            table.sort(lstT)
            local value = getCardTypePoint(lstT[1])
            table.insert(lstPileValue, value)
        else 
        	-- 出现顺子之外的结构牌，必不成此牌型
        	return {}
        end
    end

    -- 顺子个数
    local nStraightNum = table.getn(lstPileValue)

    -- 该牌型的顺子数一定是4个
    -- 如果结构牌的顺子不够4个，就要计算手牌中可拆出的顺子
    if nStraightNum < 4 then
        -- 除结构牌的顺子外，还需要满足的顺子数
        local nLeftNum = 4 - nStraightNum

        -- 获取顺子相关的胡牌组合
        local lstHu = self:GetHuListByStraight(nLeftNum, true)
        if table.getn(lstHu) == 0 then
            -- 没找到
            return {}
        end
    end

    -- 执行到这里，表明顺子个数已满足，还需要判断是否为序数牌
    for i,v in pairs(lstCards) do
    	local ctype = getCardType(v)  -- 花色
    	if ctype > TYPE_TONG then
    		return {}
    	end
    end

    return {HU_PING}
end

-- 计算妙手回春、海底捞月
-- 妙手回春牌型：自摸牌墙上的最后一张牌
-- 海底捞月牌型：胡对家打出的最后一张牌
-- 参数：bZiMo(是否自摸)，nWallLeftNum(牌墙剩余张数)
function HuCalculator:CalcMSHCAndHDLY( bZiMo, nWallLeftNum )
    -- 牌墙已取完
    if nWallLeftNum == 0 then  
        if bZiMo then  -- 自摸
            return {HU_MIAOSHOUHC}  -- 自摸，妙手回春
        else
            return {HU_HAIDILAOY}  -- 放炮，海底捞月
        end
    end

    return {}
end

-- 计算连六牌型：一种花色6张连续的序数牌
-- 参数：所有的牌（手牌+结构牌+胡的牌）
function HuCalculator:CalcLianLiu( lstCards )
    local bConsecutive = self:IsConsecutiveCards(lstCards, 6)
    if bConsecutive then
        return {HU_LIANLIU}
    end

    return {}
end

-- 计算断幺牌型：胡牌时，牌里没有1、9及字牌
-- 参数：所有的牌(手牌+结构牌+胡的牌)
function HuCalculator:CalcDuanYao( lstCards )
    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)  -- 花色
        if ctype < TYPE_FENG then  -- 序数牌
            local point = getCardPoint(v)  -- 牌点
            if point == POINT_1 or point == POINT_9 then
                return {}
            end
        else
            return {}
        end
    end

    return {HU_DUANYIJIU}
end

-- 计算不求人、门前清、自摸
-- 不求人：没有吃碰明杠，自摸胡牌
-- 门前清：没有吃碰明杠，胡别人点的炮
function HuCalculator:CalcZiMoTypes( dictPileCards, bZiMo )
    local lstHuTypes = {}

    -- 自摸牌型
    if bZiMo then
        table.insert(lstHuTypes, HU_ZIMO)
    end

    -- 是否有吃碰明杠的结构牌
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper ~= AN_GANG then  -- 有非暗杠的结构牌
            return lstHuTypes
        end
    end

    if bZiMo then
        table.insert(lstHuTypes, HU_NOCHIPG)  -- 不求人
    else
        table.insert(lstHuTypes, HU_MENQIANQ) -- 门前清
    end

    return lstHuTypes
end

-- 计算全求人牌型：和牌全靠吃碰明杠，单调别人点炮的牌
-- 参数：dictPileCards（结构牌），bZiMo（是否自摸）
function HuCalculator:CalcQuanQiuRen( dictPileCards, bZiMo )
    -- 一定是点炮
    if bZiMo then
        return {}
    end

    -- 没有暗杠
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == AN_GANG then
            return {}
        end
    end

    -- 结构牌个数是4
    if table.getn(dictPileCards) ~= 4 then
        return {}
    end

    return {HU_QUANQIUREN}
end

-- 计算将牌相关的牌型：二五八将、幺九头
-- 二五八将牌型：将牌是二、五或八
-- 幺九头牌型：将牌是一或九
function HuCalculator:CalcJiangTypes()
	-- 边里所有的胡牌组合，找出将牌
	local bFind258 = false
	local bFind19 = false
    for i,lstHu in pairs(self.lstHuGroup) do
    	if bFind258 and bFind19 then
    		break
    	end
    	-- 得到一种胡牌组合中的将牌的牌值
    	local nJiangValue = self:GetJiangFromHuList(lstHu)
    	local ctype = math.floor(nJiangValue/10)  -- 将牌的花色
    	if ctype < TYPE_FENG then  -- 序数牌
    		local point = nJiangValue % 10  -- 将牌的牌点
    		if point == POINT_2 or point == POINT_5 or point == POINT_8 then
    			bFind258 = true
    		elseif point == POINT_1 or point == POINT_9 then
    			bFind19 = true
    		end
    	end
    end

    -- 记录牌型
    local lstHuTypes = {}

    if bFind258 then
    	table.insert(lstHuTypes, HU_ERWUB)
    end

    if bFind19 then
    	table.insert(lstHuTypes, HU_YIJIUT)
    end

    return lstHuTypes
end

-- 计算边张、坎张、单调将牌型（边张和坎张均不计单钓将）
-- 边张牌型：和牌时，单和123的3及789的7或1233和3、77879和7都为边张。手中有12345和3，56789和7不算边张
-- 坎张牌型：和牌时，和2张牌之间的牌。4556和5也算坎张，45567和6不算坎张
-- 单调将牌型：和单张牌，并且该张单牌为整副牌的将牌
-- 参数：lstHandCards(手牌)，nHuCard(胡的牌)
function HuCalculator:CalcBianKanDanDiao( lstHandCards, nHuCard )
	-- 三种牌型均为只听一张
    local lstCanHu = self:CalcAllCanHuCards(lstHandCards)
    if table.getn(lstCanHu) ~= 1 then
        return {}
    end

    -- 判断边张和坎张，胡的牌一定为序数牌，且都在顺子中
    local nHuType = getCardType(nHuCard)
    if nHuType < TYPE_FENG then
        -- 边张和坎张的牌点范围：2-8 （边张单和3或7）
        local nHuPoint = getCardPoint(nHuCard)
        if nHuPoint > POINT_1 and nHuPoint < POINT_9 then
            -- 获取顺子相关的胡牌组合
            local lstHu = self:GetHuListByStraight(1, false)
            if table.getn(lstHu) > 0 then
                -- 胡的牌的牌值
                local nHuValue = getCardTypePoint(nHuCard)

                -- 遍历符合顺子要求的所有胡牌组合，找出匹配的牌型
                for i,lstSub in pairs(lstHu) do
                    -- 记录nHuValue在各个顺子中的索引
                    local lstIdx = {}

                    -- 取出手牌中拆分的顺子
                    local lstStraight = self:GetStraightListFromHuList(lstSub)
                    for j,lst in pairs(lstStraight) do
                        for k,cardvalue in pairs(lst) do
                            if nHuValue == cardvalue then
                                table.insert(lstIdx, k)
                                break
                            end
                        end
                    end

                    -- 胡的牌如果同时出现在不同的顺子中，肯定不是坎或边
                    local nCmpIdx = lstIdx[1]
                    local bFind = true
                    for j,idx in pairs(lstIdx) do
                        if idx ~= nCmpIdx then
                            bFind = false
                            break
                        end
                    end

                    -- 胡的牌在顺子中的索引是固定的
                    if bFind then
                        if nCmpIdx == 3 and nHuPoint == POINT_3 then  -- 边张：123
                            return {HU_BIANZH}
                        elseif nCmpIdx == 1 and nHuPoint == POINT_7 then  -- 边张：789
                            return {HU_BIANZH}
                        elseif nCmpIdx == 2 then  -- 坎张
                            return {HU_KANZH}
                        end 
                    end
                end
            end
        end
    end

    -- 能走到这里就表示不是边张或坎张
    -- 是否为单调将
    local bDanDiaoJiang = true
    -- 无论有多少种胡牌组合，将都应该是胡的牌
    for i,lstHu in pairs(self.lstHuGroup) do
        local nJiangValue = self:GetJiangFromHuList(lstHu)
        -- 胡的牌即为将牌
        if nJiangValue ~= getCardTypePoint(nHuCard) then
            bDanDiaoJiang = false
            break
        end
    end

    if bDanDiaoJiang then
        return {HU_DANDIAOJ}
    end

    return {}
end

-- 计算四归一牌型：牌里有4张相同的牌归于一家的顺、刻或将中
-- 参数：lstCards(手牌+胡的牌)，dictPileCards(结构牌)
function HuCalculator:CalcSiGuiYi( lstCards, dictPileCards )
    -- 记录牌张数
    local dictCardsNum = {}
    local dictT = clone(dictPileCards)
    -- 去掉杠牌
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == ZHI_GANG or oper == AN_GANG or oper == PENG_GANG then
            table.remove(dictT, i)
        else
            -- 结构牌的牌数据
            local lstcards = dict.lstCards

            for j,card in pairs(lstcards) do
                local value = getCardTypePoint(card)
                if dictCardsNum[value] == nil then
                    dictCardsNum[value] = 1
                else
                    dictCardsNum[value] = dictCardsNum[value] + 1
                end
            end
        end
    end

    for i,card in pairs(lstCards) do
        local value = getCardTypePoint(card)
        if dictCardsNum[value] == nil then
            dictCardsNum[value] = 1
        else
            dictCardsNum[value] = dictCardsNum[value] + 1
        end
    end

    -- 查看一下剩下的牌中，是否还有张数是4张的牌
    for i,num in pairs(dictCardsNum) do 
        if num == 4 then
            return {HU_SIGUIY}
        end
    end

    return {}
end

-- 计算大于五和小于五牌型
-- 大于五牌型：由序数为6789的数牌组成的牌型，允许七对
-- 小于五牌型：由序数为1234的数牌组成的牌型，允许七对
-- 参数：所有的牌（手牌+结构牌+胡的牌）
function HuCalculator:CalcFiveTypes( lstCards )
    -- 记录最大的牌点和最小的牌点
    local nMaxPoint = POINT_1
    local nMinPoint = POINT_9
    for i,v in pairs(lstCards) do
        local ctype = getCardType(v)  -- 花色
        -- 一定要是序数牌
        if ctype >= TYPE_FENG then
            return {}
        end

        local point = getCardPoint(v)  -- 牌点

        -- 更新最大牌点
        if point > nMaxPoint then
            nMaxPoint = point
        end

        -- 更新最小牌点
        if point < nMinPoint then
            nMinPoint = point
        end
    end

    -- 确定牌型
    local lstHuTypes = {}
    if nMaxPoint < POINT_5 then  -- 小于五
        table.insert(lstHuTypes, HU_SMALLTHANFIVE)
    elseif nMinPoint > POINT_5 then  -- 大于五
        table.insert(lstHuTypes, HU_MORETHANFIVE)
    end

    return lstHuTypes
end

-- 计算碰碰和牌型：由4副刻子（或杠）、将牌组成的和牌
-- 参数：lstCards(手牌+胡的牌)，dictPileCards(结构牌)
function HuCalculator:CalcPengPengHu( lstCards, dictPileCards )
    -- 记录刻杠数
    local nKeGangNum = 0
    -- 是否有吃的结构牌
    for i,dict in pairs(dictPileCards) do
        local oper = dict.type  -- 结构牌类型
        if oper == LCHI or oper == MCHI or oper == RCHI then
            return {}
        else
            nKeGangNum = nKeGangNum + 1
        end
    end

    -- key:牌值，value：张数
    local tbCard = {}
    
    -- 计算张数
    for i,v in pairs(lstCards) do
        local cardvalue = getCardTypePoint(v)  -- 牌值
        if tbCard[cardvalue] ~= nil then
            tbCard[cardvalue] = tbCard[cardvalue] + 1
        else
            tbCard[cardvalue] = 1
        end
    end

    -- 验证张数：只有将是2张，其他牌均为至少3张
    local nCountTwo = 0  -- 有多少牌是两张的
    for i,num in pairs(tbCard) do
        if num == 1 then
            return {} 
        elseif num == 2 then
            nCountTwo = nCountTwo + 1
        else
            nKeGangNum = nKeGangNum + 1
        end
    end

    -- 4个刻或杠 + 1个将
    if nCountTwo ~= 1 or nKeGangNum ~= 4 then
        return {}
    end

    return {HU_PENGPENG}
end

-- 计算报听牌型：听牌后胡牌
function HuCalculator:CalcBaoTing( bTing )
    if bTing then
        return {HU_BAOTING}
    end
    return {}
end

return HuCalculator