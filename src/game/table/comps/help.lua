-- help.lua
-- 2015-11-19
-- Help Moudle

local BaseObject = require( "kernels.object" )
local CompHelp = class(  "CompHelp", BaseObject )

-- 激活
function CompHelp:Actived()

    CompHelp.super.Actived( self )
    self.ui_main = self.bind_scene:FindRoot():getChildByName( "pan_help" )   
    self.pan_btns = self.ui_main:getChildByName("pan_btns")
    self.list_type = self.ui_main:getChildByName("list")
    
    local pan_chk = self.ui_main:getChildByName("pan_chk")
    self.chk_defaultopen = pan_chk:getChildByName("chk")
    -- 消息监听列表
    self.msg_hookers = {         
        { E_CLIENT_OPENHELPVIEW,                handler( self, self.OnUIMainViewOpened ) }
    
    }
    g_event:AddListeners( self.msg_hookers, "compotherops_events" )
    
    

    -- help 模块列表
    self.list_module = {
        {moduleName="88",           isHighLight = true,       cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --玩法说明  
        {moduleName="64",           isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --操作说明
        {moduleName="48",           isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --牌型说明
        {moduleName="32",           isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --功能说明
        {moduleName="24",           isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },         --常见问题说明
        {moduleName="16",           isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --玩法说明  
        {moduleName="12",           isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --操作说明
        {moduleName="8",            isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --牌型说明
        {moduleName="6",            isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) },        --功能说明
        {moduleName="other",        isHighLight = false,      cbBtn=handler(self, self.OnHelpModuleBtnClicked) }         --常见问题说明
    }
    --绑定关闭Button事件
    g_methods:ButtonClicked( self.ui_main, "btn_close",  handler(self, self.OnUIMainViewClosed))
    self.chk_defaultopen:addEventListener(handler(self, self.OnCheckBoxClicked))
    if g_save.configs.isDefaultHelpOpen == nil then 
        g_save.configs.isDefaultHelpOpen = 1
    end
    
    if g_save.configs.isDefaultHelpOpen == 1 then
        g_event:PostEvent( E_CLIENT_OPENHELPVIEW )
        self.chk_defaultopen:setSelected( true)
    else
        self.ui_main:setVisible(false)
        self.chk_defaultopen:setSelected( false )
    end
    
    self:BindMoudleBtnsEvent( self.pan_btns, self.list_module)
    self.ui_main:openMouseTouch(true, self, true, true)
    
    return true
end

--绑定各个模块Buttond的事件
function CompHelp:BindMoudleBtnsEvent(parent, list_module)
    for i=1, #list_module do
        local pan_btn = parent:getChildByName("pan_"..list_module[i].moduleName)
    
        g_methods:ButtonClicked( pan_btn, "btn",  list_module[i].cbBtn)
    end
end

--处理Buttond的事件
function CompHelp:OnHelpModuleBtnClicked( sender,  agrs)
    for i=1, #self.list_module do
        self.list_module[i].isHighLight = false
        local btnName = sender:getParent():getName()
        if btnName == "pan_"..self.list_module[i].moduleName then
            self.list_module[i].isHighLight = true            
        end
    end

    self:DispatchModouleEvent(self.list_module)
end

--打开Help界面
function CompHelp:OnUIMainViewOpened(event_id, event_args)

    self.ui_main:setVisible(true)

    self:DispatchModouleEvent( self.list_module )
    
end

--关闭Help界面
function CompHelp:OnUIMainViewClosed(event_id, event_args)
    if self._eventListenerMouse then
        local dispatch = self.ui_main:getEventDispatcher()
        dispatch:removeEventListener( self._eventListenerMouse )
        self._eventListenerMouse = nil
    end
    self.ui_main:setVisible(false)
end

--模块事件处理
function CompHelp:DispatchModouleEvent(list_module)

    for i=1, #list_module do
        local pan_btn = self.pan_btns:getChildByName("pan_"..list_module[i].moduleName)
        g_methods:WidgetVisible(pan_btn, "bg",  list_module[i].isHighLight)
        g_methods:WidgetDisableByName(pan_btn, "btn",  list_module[i].isHighLight)
        if  list_module[i].isHighLight then 
            self.list_type:removeAllChildren()
            local img_type = cc.Sprite:create( "fantype/help.type."..list_module[i].moduleName..".png" )
            img_type:setAnchorPoint( 0, 0 )
            self.list_type:setInnerContainerSize( img_type:getContentSize() )
            local img_size = img_type:getContentSize()
            local scr_size = self.list_type:getContentSize()
            if img_size.height < scr_size.height then
                img_type:setPosition( cc.p( 0, scr_size.height - img_size.height ) )
            end 
            
            self.list_type:addChild( img_type )
            self.list_type:jumpToTop()
        end
    end
end

function CompHelp:onMouseTouchDown(location, args )
    local ret = self.ui_main:hitTest( location )
    if ret == false  then
        self.ui_main:setVisible( false )
    end
end

-- Checkbox点击
function CompHelp:OnCheckBoxClicked(sender, args)

    if args == 1 then
        g_save.configs.isDefaultHelpOpen = 0

    else
        g_save.configs.isDefaultHelpOpen = 1
    end
end

-- 反激活
function CompHelp:InActived()

    -- 事件监听注销
    g_event:DelListenersByTag( "compotherops_events" )
    CompHelp.super.InActived( self )
end

return CompHelp
