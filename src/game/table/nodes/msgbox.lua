-- msgbox.lua
-- 2015-04-17
-- KevinYuen
-- 消息框

TAG_MSGBOX_REF = 10000

local MessageBox = class(  "MessageBox")

-- 初始化
function MessageBox:ctor( node )
    self.root = node
    
    return true

end


-- 设置标题
function MessageBox:SetCaption( text )

    local dialog = self.root:getChildByName( "dialog" )
    local caption = dialog:getChildByName( "caption" )
    if caption then
        caption:setString( text )    
    end

end

-- 设置文本
function MessageBox:SetContent( text )

    local dialog = self.root:getChildByName( "dialog" )
    local content = dialog:getChildByName( "content" )
    if content then
        content:setString( text )
    end

end

-- 普通显示
function MessageBox:Show( caption_key, text_key, btns, callback ) 
    self:_ShowPanel( false, caption_key, text_key, btns, callback )
    --g_event:SendEvent( C_CLIENT_MSGBOXSHOW, { modal = false } )
end

-- 模态显示
function MessageBox:DoModal( caption_key, text_key, btns, callback ) 
    self:_ShowPanel( true, caption_key, text_key, btns, callback )
    --g_event:SendEvent( C_CLIENT_MSGBOXSHOW, { modal = true } )
end

--隐藏
function MessageBox:Close()
    self.root:setVisible( false )
    self.root:openMouseTouch( false )
end

-- 显示
function MessageBox:_ShowPanel( is_modall, caption_key, text_key, btns, callback )    

    local dialog = self.root:getChildByName( "dialog" )

    -- 标题&文本
    self:SetCaption( caption_key )
    self:SetContent( text_key )

    -- 按钮显隐设定
    local support_buttons = { "yes", "no", "confirm", "close" }
    for _, btn_name in pairs( support_buttons ) do

        local exist = g_methods:IsInTable( btns, btn_name )
        local button = g_methods:WidgetVisible( dialog, btn_name, exist )
        if exist and button and callback then
            g_methods:ButtonClicked( dialog, btn_name, 
                function( sender, args )
                    self.btn_name = btn_name   
                    callback( btn_name )
                end )
        end
    end

    self.root:openMouseTouch( true, nil, true )
    self.root:setVisible( true )

end

return MessageBox

 