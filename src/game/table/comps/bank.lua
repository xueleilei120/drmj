-- bank.lua
-- 2015-04-17
-- KevinYuen
-- 保险箱控件

local BaseObject = require( "kernels.object" )
local CompBank = class(  "CompBank", BaseObject )

-- 激活
function CompBank:Actived()

    CompBank.super.Actived( self )  
    
    -- 界面绑定
    self.root_ui = self.bind_scene:FindRoot():getChildByName( "rt_wnd" )
    if not self.root_ui then
        g_methods:error( "CompBank激活失败,找不到界面资源..." )
        return false
    end
        
    -- 界面绑定
    self.bank_root = self.root_ui:getChildByName( "bank" )   

    if not self.bank_root then
        g_methods:error( "保险箱插件初始化失败,找不到保险箱界面..." )
        return false
    end
    
    -- 触发
    local btn_panel = self.root_ui:getChildByName( "sysbtns" )
    g_methods:ButtonClicked( btn_panel, "bank", function( sender, args )
                            self:OnOpenBank()
                        end )
    if jav_room_type(ROOM_MATCH) == true then
        g_methods:warn("禁止保险箱")
        local btn_bank = btn_panel:getChildByName( "bank" )
        g_methods:WidgetDisable(btn_bank, true)
    end 
    -- 关闭
    g_methods:ButtonClicked( self.bank_root, "close", function( sender, args )
                            self.bank_root:setVisible( false )
                        end )

    -- 取消
    g_methods:ButtonClicked( self.bank_root, "cancel", function( sender, args )
                            self.bank_root:setVisible( false )
                        end )
    
    -- 确认
    g_methods:ButtonClicked( self.bank_root, "take", function( sender, args )
                            self:OnTakeMoney()
                        end )
                        
    -- 加钱
    g_methods:ButtonClicked( self.bank_root, "add", function( sender, args )
                            self:OnAddTake()
                        end ) 
    
    -- 减钱
    g_methods:ButtonClicked( self.bank_root, "sub", function( sender, args )
                            self:OnSubTake()
                        end )
    
    -- 总钱数
    self.txt_money = self.bank_root:getChildByName( "money" )
    
    -- 钱输入
    self.edit_money = self.bank_root:getChildByName( "amount" )
    
    self.edit_money:addEventListener( function( sender, eventType, args )
        if  eventType == ccui.TextFiledEventType.insert_text or
            eventType == ccui.TextFiledEventType.delete_backward then 
            local new_text = self.edit_money:getString()           
            if g_methods:IsDigit( new_text ) then 
                local num = tonumber( new_text ) 
                if eventType == ccui.TextFiledEventType.insert_text then
                    if num > 0 then
                        self.input_money = num
                    elseif num == 0 then
                        self.input_money = 0
                        self.edit_money:setString( "" )
                    end
                else
                    self.input_money = num                 
                end
                if self.input_money > self.all_money then
                    self.input_money = self.all_money 
                    self.edit_money:setString( tostring( self.input_money ) )
                end      
                -- 取款金额+自身携带不能超过21亿
                local selfer = jav_queryplayer_byUID( jav_self_uid )
                
                
                if self.input_money + selfer.money > (math.pow(2,31) - 1) then
                    self.input_money = (math.pow(2,31) - 1) - selfer.money 
                    self.edit_money:setString( tostring( self.input_money ) )
                end
            else
                if new_text == "" then
                    self.input_money = 0
                end

                if self.input_money == 0 then
                    self.edit_money:setString( "" )
                else
                    self.edit_money:setString( tostring( self.input_money ) )
                end       
            end   
        end
    end )                                          
    
    -- 密码输入
    self.edit_keyword = self.bank_root:getChildByName( "keyword" )
    self.edit_keyword:addTouchEventListener( function( sender, eventType )
                                                if eventType == ccui.TextFiledEventType.attach_with_ime then
                                                    self.edit_keyword:setString("")
                                                elseif eventType == ccui.TextFiledEventType.detach_with_ime then        
                                                end
                                            end )
                                           
    -- 消息监听列表
    self.msg_hookers = {       
        { NGE_OPENBANK, handler( self, self.OnOpenBank ) },
        { E_HALL_BANKDEPOSIT, handler( self, self.OnSetBankMoney ) },
        { E_HALL_BANKDEPBACK, handler( self, self.OnBankOperBack ) }    
    }
    g_event:AddListeners( self.msg_hookers, "compbank_events" )
end

-- 反激活
function CompBank:InActived()
    
    -- 事件监听注销
    g_event:DelListenersByTag( "compbank_events" )
    CompBank.super.InActived( self )
end

-- 打开保险箱
function CompBank:OnOpenBank( event_id, event_args )    

    -- 不能重复显示
    if self.bank_root:isVisible() then
        return
    end    
    
    -- 数据归零
    self.txt_money:setVisible( false )
    self.edit_money:setString( "" )
    self.edit_keyword:setString( "" )
    self.input_money = 0
    
    -- 显示
    self.bank_root:setVisible( true )

    -- 请求保险箱
    local msg = { key = "cmd", context = "querybank" }
    jav_room.main_connect:SendFrameMsg( json.encode( msg ) ) 
    
end

-- 大厅保险箱提款许可
function CompBank:OnSetBankMoney( event_id, event_args )  

    local money = event_args.deposit
    self.txt_money:setString( money )
    self.all_money = tonumber( money )
    self.txt_money:setVisible( true )

end
  
-- 取钱
function CompBank:OnTakeMoney()    

    local take = self.edit_money:getString()
    local key = self.edit_keyword:getString()
    
    if take == nil or string.len(take)==0 then
        local text = g_library:QueryConfig( "text.bank_acount_empty" )
        g_event:SendEvent( E_CLIENT_SYSCHAT, { info = text } )
        return 
    end
   
    if key == nil or string.len(key)==0 then
        local text = g_library:QueryConfig( "text.bank_password_empty" )
        g_event:SendEvent( E_CLIENT_SYSCHAT, { info = text } )
        return 
    end
    -- 取钱申请
    if tonumber( take ) > 0 then
        local msg = { key = "bankoper", oper = "draw", nums = tonumber(take), psw = key }
        jav_room.main_connect:SendFrameMsg( json.encode( msg ) ) 
    end

    -- 关闭
    self.bank_root:setVisible( false )

end

-- 大厅保险箱结果返回
function CompBank:OnBankOperBack( event_id, event_args )  

    local text = ""    
    if event_args.rlt == 1 then
        text = g_library:QueryConfig( "text.bank_" .. event_args.oper .. "_ok" )
    elseif event_args.rlt == 9 then
        text = g_library:QueryConfig( "text.bank_draw_9" )
    else
        local reason = jav_bg2312_utf8( event_args.info )
        local fmt = g_library:QueryConfig( "text.bank_" .. event_args.oper .. "_error" )     
        text = string.format( fmt, reason )
    end
    g_event:SendEvent( E_CLIENT_SYSCHAT, { info = text } )
    
end

-- 加钱
function CompBank:OnAddTake()    

    local step = 0
    if self.all_money <= 0 then
        return
    end
    if self.all_money <= 10 then
        step = 1
    else     
        local mi = math.log10( self.all_money ) - 1
        step = math.pow( 10, math.floor( mi ) )
        if step <= 0 then
            step = 1
        end 
    end

    local tmoney = self.edit_money:getString()
    if not tmoney or tmoney == "" then
        tmoney = "0"
    end 
    
    -- 不能超过存款上限
    self.input_money = tonumber( tmoney ) + step
    if self.input_money > self.all_money then
        self.input_money = self.all_money
    end
    
    -- 取款金额+自身携带不能超过21亿
    local selfer = jav_queryplayer_byUID( jav_self_uid )
    if self.input_money + selfer.money > (math.pow(2,31) - 1)  then
        self.input_money = (math.pow(2,31) - 1) - selfer.money 
    end
    
    self.edit_money:setString( tostring( self.input_money ) )            
end

-- 减钱
function CompBank:OnSubTake()   
    local step = 0
    if self.all_money <= 0 then
        return
    end
    if self.all_money <= 10 then
        step = 1
    else        
        local mi = math.log10( self.all_money ) - 1
        step = math.pow( 10, math.floor( mi ) )
        if step <= 0 then
            step = 1
        end 
    end

    local tmoney = self.edit_money:getString()
    if not tmoney or tmoney == "" then
        self.edit_money:setString("")   
    else
        self.input_money = tonumber( tmoney ) - step
        if self.input_money < 0 then
            self.input_money = 0
        end
        self.edit_money:setString( tostring( self.input_money ) )   
    end 
    
end

return CompBank

 