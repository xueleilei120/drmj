-- debug.lua
-- 2016-02-16
-- 调试操作

local BaseObject = require( "kernels.object" )
local CompDebug = class(  "CompDebug", BaseObject )

local CmdListPanel = require( "kernels.node.nodeCmdList" )
local TestUnitsPanel = require( "kernels.node.nodeTestUnits" )

-- 激活
function CompDebug:Actived()

    CompDebug.super.Actived( self )    

    self.cmpcotrl = self.bind_scene:FindComponent( "CompControl", true )
    self.mjtable = self.cmpcotrl.mjtable
            
    -- 键盘监听
    self.listen_keyboard = cc.EventListenerKeyboard:create()
    self.listen_keyboard:registerScriptHandler( handler( self, self.OnKeyboardReleased ), cc.Handler.EVENT_KEYBOARD_RELEASED )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority( self.listen_keyboard, 1 )
    
end

-- 反激活
function CompDebug:InActived()

    -- 键盘监听移除
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:removeEventListener( self.listen_keyboard )
    self.listen_keyboard = nil
    
    CompDebug.super.InActived( self )
end

-- 初始化测试单元
function CompDebug:InitTestUnits()

    local units = {
        { "做牌墙",     handler( self, self.onTestBuildWall ) },
        { "发手牌",     handler( self, self.onTestBuildHands ) },
        { "清理牌桌",   handler( self, self.onTestResetTable ) },
        { "加倍动画",   handler( self, self.onTestDoubleAnim ) },
        { "停牌动画",   handler( self, self.onTestTingPai ) },
        { "手牌推倒",   handler( self, self.onTestFalldownHand ) },
        { "逃跑结算",   handler( self, self.onTestRunSettle ) },
        { "荒局结算",   handler( self, self.onTestHuangSettle ) },
        { "赢家结算",   handler( self, self.onTestWinnerSettle ) },
        { "双倍面板",   handler( self, self.onTestDoubleTask ) },
        { "开始托管",   handler( self, self.onTestOpenTrust ) },
        { "取消托管",   handler( self, self.onTestCloseTrust ) },
        { "加倍界面",   handler( self, self.onTestDoubleHu ) },
        
    }
    self.testUnits:ResetUnits( units )
    
end

-- 基本排布测试
function CompDebug:onTestBasic( keycode, event )

    if keycode == cc.KeyCode.KEY_F1 and jav_table.canMakeCard == true then
    
        if not self.cmdList then 
            self.cmdList = CmdListPanel.new( "../cmdlist.json" )
        end
        
        self.cmdList:togShow()
        return
        
    end

    if keycode == cc.KeyCode.KEY_F2 and jav_is_debugmode() == true then

        -- 测试单元模块
        if not self.testUnits then
            self.testUnits = TestUnitsPanel.new()
            self:InitTestUnits()
        end
        
        self.testUnits:togShow()        
        return
        
    end

end


-- 做牌墙
function CompDebug:onTestBuildWall()

    self.mjtable:buildWall( function()
        g_methods:log( "牌墙初始化完毕" ) 
    end, SECS_BUILDWALLS, OFFSET_BUILDWALLS )
    
end
 
-- 发手牌
function CompDebug:onTestBuildHands()

    -- 切牌
    local seatNo = math.random( 1, 2 )
    local walIdx = math.random( 1, 16 )
    self.cmpcotrl:buildWallmap( 1, walIdx )
    g_methods:log( "设定牌墙起始点:%d, %d", seatNo, walIdx ) 

    -- 发牌
    local cIds = { [0] = {}, [1] = {} }
    for i = 1, 13 do
        table.insert( cIds[0], self.mjtable:getTempCard() )
        table.insert( cIds[1], self.mjtable:getTempCard() )
    end
    cIds[1][1] = 165
    cIds[1][2] = 176
    cIds[1][3] = 166
    cIds[1][4] = 177
    table.insert( cIds[0], self.mjtable:getTempCard() )
    self.cmpcotrl:buildMJHands( 0, cIds, function()
        g_methods:log( "发牌完毕!" )
    end )  
    
end

-- 牌桌清理
function CompDebug:onTestResetTable()
    self.mjtable:resetAll()
end

-- 加倍动画
function CompDebug:onTestDoubleAnim()
    g_event:PostEvent( CTC_OPER_DOUBLESHOW, { seatNo = 0, times = math.random( 1, 5 ) } )
end

-- 停牌动画
function CompDebug:onTestTingPai()

    local view = self.bind_scene:FindComponent( "CompView", true )
    view:playTingEffect( 0 )
    view:playTingEffect( 1 )
    
end

-- 手牌推倒
function CompDebug:onTestFalldownHand()
    self.mjtable:fallDownHand( 0, true )
    self.mjtable:fallDownHand( 1, true )
end

-- 逃跑结算
function CompDebug:onTestRunSettle()

    jav_table.settles = 
    {
        nWinner     = jav_get_mychairid(), 
        nEndReason  = END_REASON_RUNAWAY
    }
    
    local settle = self.bind_scene:FindComponent( "CompSettle", true )
    settle:OnSettlement()
    
end

-- 荒局结算
function CompDebug:onTestHuangSettle()

    jav_table.settles =
    {
        nWinner     = jav_get_mychairid(), 
        nEndReason  = END_REASON_NOWINNER
    }
    
    local settle = self.bind_scene:FindComponent( "CompSettle", true )
    settle:OnSettlement()
    
end
        
-- 正常结算
function CompDebug:onTestWinnerSettle()

    jav_table.settles = 
    {
        nWinner     = jav_get_mychairid(), 
        nEndReason  = END_REASON_NORMAL
    }
    
    local settle = self.bind_scene:FindComponent( "CompSettle", true )
    settle:OnSettlement()

end

-- 
function CompDebug:onTestDoubleTask()
    local ui_layer = self.bind_scene:FindRoot():getChildByName( "ui_layer" )   
    self.root = ui_layer:getChildByName("pan_targetR")
    self.img_dn = self.root:getChildByName("img_dn")
    self.img_up = self.root:getChildByName("img_up")
    self.ui_main = self.root:getChildByName("pan_bg")
    self.pan_anim = self.ui_main:getChildByName("pan_anim")
    self.ui_main:setOpacity( 0 ) 
    local pan_mj = self.ui_main:getChildByName( "pan_mj" )
    self.ui_main:setCascadeOpacityEnabled(true)
    pan_mj:setCascadeOpacityEnabled(true)
    pan_mj:updateSizeAndPosition()
    self.root:setVisible( true )
    self.ui_main:runAction( cc.Sequence:create(cc.FadeIn:create( 2 ),cc.CallFunc:create(
    function ()
            self.wanChengAnim = sp.SkeletonAnimation:create( "wancheng.json", "wancheng.atlas", 1.0 )
            self.pan_anim:removeAllChildren()
            self.pan_anim:setVisible( true )
            self.pan_anim:addChild(self.wanChengAnim )
            local size = self.pan_anim:getContentSize()
            self.wanChengAnim:setPosition(size.width/2, size.height/2)
            self.wanChengAnim:setToSetupPose()
            
          self.wanChengAnim:setAnimation(0, "wancheng", false )
    end
    ) ))
end

-- 开始托管
function CompDebug:onTestOpenTrust()
    --g_event:PostEvent( STC_MSG_TRUST, { nSeat = jav_get_mychairid(), bTrust = true } )
    cc.Director:getInstance():getTextureCache():setAliasTexParameters()
end

-- 取消托管
function CompDebug:onTestCloseTrust()

    --g_event:PostEvent( STC_MSG_TRUST, { nSeat = jav_get_mychairid(), bTrust = false } )
    --cc.Director:getInstance():getTextureCache():setAnitAliasTexParameters() 

    local txt = cc.Director:getInstance():getTextureCache():getTextureForKey( "fnt_win_num.png" )
    if txt then 
        txt:setAntiAliasTexParameters()
    end
end
        
-- 加倍界面
function CompDebug:onTestDoubleHu()

    local opers = self.bind_scene:FindComponent( "CompOperators", true )
    
    if opers.pan_huDouble:isVisible() then
        opers.pan_huDouble:setVisible( false ) 
        opers.pan_huDouble:openMouseTouch( false, nil, true, true )
    else
        opers.pan_huDouble:setVisible( true ) 
        opers.pan_huDouble:openMouseTouch( true, nil, true, true )
    end
end

-- 牌堆测试
function CompDebug:onTestStackPush( keycode, event )

    if keycode == cc.KeyCode.KEY_3 then
        local cId = self.mjtable:getTempCard()
        self.mjtable:getHand(0):push( cId, cc.p( 0, 30 ), 0.5, true )
        cId = self.mjtable:getTempCard()
        self.mjtable:getHand(1):push( cId, cc.p( 0, 30 ), 0.5, true )
    end

    if keycode == cc.KeyCode.KEY_4 then
        self.keyCard = self.mjtable:getTempCard()
        local IdB = self.mjtable:getTempCard()
        local IdC = self.mjtable:getTempCard()
        self.mjtable:pushStack( 0, STACK_LPEN, { self.keyCard, IdB, IdC }, { true, false, false }, 0.5 )
    end
    
    if keycode == cc.KeyCode.KEY_5 then
        local IdB = self.mjtable:getTempCard()
        local IdC = self.mjtable:getTempCard()
        local IdD = self.mjtable:getTempCard()
        self.mjtable:resetStackByKeyId( 0, self.keyCard, STACK_GANG, { self.keyCard, IdB, IdC, IdD }, { false, true, true, false }, 0.5  )
    end

    if keycode == cc.KeyCode.KEY_7 then
        self.tPos = self.tPos or 0
        self.tPos = self.tPos + 1
        local IdA = self.mjtable:getTempCard()
        self.mjtable:mpFromWall( 1, IdA, 1, self.tPos, function( seatNo )
            g_methods:log( "摸牌完毕!" )
        end )
    end

    if keycode == cc.KeyCode.KEY_8 then
        self.mjtable:getHand(0):delMP()
    end

    if keycode == cc.KeyCode.KEY_9 then
        self.mjtable:buildWall( function()
            g_methods:log( "牌墙初始化完毕" ) 
        end, 0.8 )
    end
    
end

-- 基本排布测试
function CompDebug:onTestWallDealer( keycode, event )

    if keycode == cc.KeyCode.KEY_3 then
        local cIds = { [0] = {}, [1] = {} }
        for i = 1, 13 do
            table.insert( cIds[0], self.mjtable:getTempCard() )
            table.insert( cIds[1], self.mjtable:getTempCard() )
        end
        table.insert( cIds[0], self.mjtable:getTempCard() )
        self.cmpcotrl:buildMJHands( 0, cIds, function()
            g_methods:log( "发牌完毕!" )
        end )  
    end

    if keycode == cc.KeyCode.KEY_4 then
        local cd = self.cmpcotrl:popWallFromMapBack()
        local IdA = self.mjtable:getTempCard()
        self.mjtable:mpFromWall( 0, IdA, cd.wall, cd.idx, function( seatNo )
            g_methods:log( "摸牌完毕!" ) 
        end )
    end

    if keycode == cc.KeyCode.KEY_5 then
        local cd = self.cmpcotrl:popWallFromMapFront()
        local IdA = self.mjtable:getTempCard()
        self.mjtable:mpFromWall( 0, IdA, cd.wall, cd.idx, function( seatNo )
            g_methods:log( "摸牌完毕!" ) 
        end )
    end
    
    if keycode == cc.KeyCode.KEY_6 then
        --self.mjtable:getHand(0):delMP()

--        local IdA = self.mjtable:getTempCard()
--        self.mjtable:getHand(0):push( IdA )
--        self.mjtable:getHand(0):sortBy( function( a, b )
--            return a.id > b.id
--        end )
        
        --self.mjtable:sortHands( 0, true )
        local IdA = self.mjtable:getTempCard()
        self.mjtable:pushToRiverBlind( 1, 2, IdA, false, function()
            g_methods:log( "翻牌完毕!" )
        end )
    end
    
    if keycode == cc.KeyCode.KEY_7 then
        self.mjtable:sortHands( 0, false, true, 0.8, function()
            g_methods:log( "翻牌完毕!" )
        end )
    end
    
    if keycode == cc.KeyCode.KEY_8 then
        self.mjtable:getHand(0):clean( false )
        self.mjtable:getHand(1):clean( false )
        self.mjtable:getWall(0):clean()
        self.mjtable:getWall(1):clean()
    end
    
    if keycode == cc.KeyCode.KEY_9 then

        local ids = {}
        for i = 1, 13 do
            table.insert( ids, self.mjtable:getTempCard() )
        end
        self.mjtable:resetHands( 1, ids, true )
    end
end

-- UI测试
function CompDebug:onTestUIFunctions( keycode, event )

    if keycode == cc.KeyCode.KEY_3 then
            
        local center_node = self.cmpcotrl.lay_node:getChildByName( "center" )
        local diceNode1 = center_node:getChildByName( "dice1" )
        local diceNode2 = center_node:getChildByName( "dice2" )
        local wtRollAni = g_library:CreateAnimation( "ani.whiteDiceRoll" )
        self.testDice1 = display.newSprite()
        diceNode1:addChild( self.testDice1 )
        local size = diceNode1:getContentSize()
        self.testDice1:setPosition( cc.p( size.width / 2, size.height / 2 ) )
        self.testDice1:playAnimationOnce( wtRollAni, false, function( dice )
            local png = string.format( "wtdiceKey%d.png", math.random( 1, 6 ) )
            local frm = display.newSpriteFrame( png ) 
            self.testDice1:setSpriteFrame( frm )
        end, 0 )

        self.testDice1:playAnimationOnce( wtRollAni, false, function( dice )
            local png = string.format( "wtdiceKey%d.png", math.random( 1, 6 ) )
            local frm = display.newSpriteFrame( png ) 
            self.testDice1:setSpriteFrame( frm )
        end, 0 )
        
        
    end
    
    if keycode == cc.KeyCode.KEY_4 then        
        
--        local view = self.bind_scene:FindComponent( "CompView", true )
--        view:playRoundStartEffect()
        g_event:PostEvent( CTC_OPER_BANKER, { seatNo = 0 } )
    end
    
    if keycode == cc.KeyCode.KEY_5 then
        
        local hand = self.mjtable:getHand(0)
        if #hand.cards < 5 then
            return
        end
        
        local chooses = {}
        table.insert( chooses, hand.cards[1].id )
        table.insert( chooses, hand.cards[3].id )
        table.insert( chooses, hand.cards[5].id )
        --table.insert( chooses, hand:getMP().id ) 
        self.cmpcotrl:openOperChoose( true, chooses )
        
    end

    if keycode == cc.KeyCode.KEY_6 then
        
        local oper = self.bind_scene:FindComponent( "CompOperators", true )
        self.track = self.track or 1
        self.track = self.track + 1 
        local stacks = {}
        local cnt = self.track % 3 + 1
        for i = 1, cnt do
            local cardlst = {}
            table.insert( cardlst, self.mjtable:getTempCard() )
            table.insert( cardlst, self.mjtable:getTempCard() )
            table.insert( cardlst, self.mjtable:getTempCard() )
            table.insert( stacks, cardlst )
        end
        
        oper.eat_select:show( stacks, math.random( 1, cnt ) )
        
    end

    if keycode == cc.KeyCode.KEY_7 then

        local oper = self.bind_scene:FindComponent( "CompOperators", true )
        oper.eat_select:close()
        
    end

    if keycode == cc.KeyCode.KEY_8 then

--        local oper = self.bind_scene:FindComponent( "CompOperators", true )
--        self.track = self.track or 1
--        self.track = self.track + 1 
--        local stacks = {}
--        local cnt = self.track % 3 + 1
--        for i = 1, cnt do
--            local cardlst = {}
--            table.insert( cardlst, self.mjtable:getTempCard() )
--            table.insert( cardlst, self.mjtable:getTempCard() )
--            table.insert( cardlst, self.mjtable:getTempCard() )
--            table.insert( cardlst, self.mjtable:getTempCard() )
--            table.insert( stacks, cardlst )
--        end
--
--        oper.gang_select:show( stacks, math.random( 1, cnt ) )

        --local oper = self.bind_scene:FindComponent( "CompSettle", true )
        --oper:OnShowPanel()
        
        
        local infos = {}
        local cnt = math.random( 1, 13 )
        for i = 1, 1 do
            local card = {
                id = self.mjtable:getTempCard(),
                count = math.random( 1, 4 ),
                points = math.random( 1, 30 )
            }
            table.insert( infos, card )
        end
        local oper = self.bind_scene:FindComponent( "CompOperators", true )
        oper.pan_hutips:show( infos )
        
        
--        local canPlay = {112,113}
--        local canHu = {{134,145},{123,164,172}}
--        local huCardnum = {{2,3},{3,4,5}}
--        local huFan = {{23,34},{34,45,32}}
--
--        local tingInfos = {}
--
--        for i= 1,#canPlay do
--            local cards = {}
--            cards.card = canPlay[i]
--            for j=1,#canHu[i] do
--                local card = {
--                    id = canHu[i][j],
--                    count = huCardnum[i][j],      --张数
--                    points = huFan[i][j]  -- 番数           
--                }
--                table.insert(cards,card)
--            end
--            table.insert(tingInfos,cards)
--        end
--        
--        local card = 113
--        for i=1,#tingInfos do
--            if tingInfos[i].card == card then
--                local cards = tingInfos[i]
--                local oper = self.bind_scene:FindComponent( "CompOperators", true )
--                oper.pan_hutips:show( cards )
--            end
--        end
        
    end

    if keycode == cc.KeyCode.KEY_9 then

        --local oper = self.bind_scene:FindComponent( "CompOperators", true )
        --oper.gang_select:close()

--        local oper = self.bind_scene:FindComponent( "CompSettle", true )
--        oper:OnClosePanel()

        local oper = self.bind_scene:FindComponent( "CompOperators", true )
        oper.pan_hutips:close()
        
        --g_event:PostEvent( CTC_OPER_DOUBLESHOW, { seatNo = 0, times = 2 } )
    end
end
    
-- 监听按键
function CompDebug:OnKeyboardReleased( keycode, event )

    -- 基本调试(占用F1-F4键)
    self:onTestBasic( keycode, event )
    
    -- 扩展调试(占用3-9键)  
    --self:onTestWallDealer( keycode, event )
    --self:onTestStackPush( keycode, event )
 --   self:onTestUIFunctions( keycode, event )
      
end

return CompDebug
