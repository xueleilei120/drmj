-- chat.lua
-- 2015-04-17
-- KevinYuen
-- 聊天控件

local BaseObject = require( "kernels.object" )
local CompChat = class(  "CompChat", BaseObject )

-- 激活
function CompChat:Actived()

    CompChat.super.Actived( self )  

    -- 加载快捷语
    self.short_words = g_methods:ImportJson( "shorts.json" )
    if not self.short_words then
        g_methods:warn( "找不到快捷语配置文件shorts.json..." )
    end

    -- 界面绑定
    self.root_ui = self.bind_scene:FindRoot():getChildByName( "ui_layer" )
    if not self.root_ui then
        g_methods:error( "CompChat激活失败,找不到界面资源..." )
        return false
    end

    -- 界面绑定
    self.pan_chat = self.root_ui:getChildByName( "pan_chat" )
    self.btn_hide = self.pan_chat:getChildByName( "btn_hide" )
    self.chat_root = self.pan_chat:getChildByName( "chat_root" )
    
    if not self.chat_root then
        g_methods:error( "聊天插件初始化失败,找不到聊天界面..." )
        return false
    end

    -- 聊天记录
    self.chat_view = self.chat_root:getChildByName( "chatlist" )
    self.chat_view:setJumpToBottom(true)
    -- 输入框

    -- 表情面板
    self.faces_view = g_methods:WidgetVisible( self.pan_chat, "pan_faces", false )

    -- 添加表情面板
    self:FreshFaces()
    
    local editor_root = self.chat_root:getChildByName( "pan_edit" )
    local edit_parent = editor_root:getChildByName( "edit_root" )

    self.edt_content = edit_parent:getChildByName( "edit" )
    self.edt_content:addTouchEventListener( function( sender, eventType )
        if eventType == ccui.TextFiledEventType.attach_with_ime then
        --            self.edt_content:setString("")
        elseif eventType == ccui.TextFiledEventType.delete_backward then    
            g_methods:error("删除字符串") 
        end
    end )

    -- *texture = new Texture2D()

    self.edt_content:addEventListener( function( sender, eventType )
        local text = self.edt_content:getString()    -- 得到当前输入框中的所有值
        --   g_methods:error( "文本框内容有变化-----eventType= %s，text=%s",tostring(eventType),tostring(text) )
        if eventType == 0 then   
        --        g_methods:error( "文本框选中状态-----eventType= %s，text=%s",tostring(eventType),tostring(text) )                    -- 
        --    self.edt_content:setString("")
        elseif eventType == 1 then 
        --        g_methods:error( "从文本框中移除聚焦----eventType= %s，text=%s",tostring(eventType),tostring(text) )
        elseif eventType == 2 then
        --       g_methods:error( "文本框添加输入-----eventType= %s，text=%s",tostring(eventType),tostring(text) )
        elseif eventType == 3 then
        --       g_methods:error( "文本框内容删除-----eventType= %s，text=%s",tostring(eventType),tostring(text) )

        end
    end )


    -- 发送按钮绑定
    self.btn_send = g_methods:ButtonClicked( editor_root, "btn_send", function( sender, eventType )
        self:SendCmd()
    end )

    -- 快捷语按钮绑定
    self.btn_shorts = g_methods:ButtonClicked( editor_root, "btn_words", function( sender, eventType )
        self:ToggleShowShorts()
    end )

    -- 表情按钮绑定
    self.btn_faces = g_methods:ButtonClicked( editor_root, "btn_faces", function( sender, eventType )
        self:ToggleShowFaces()
    end )

   --聊天框的list向上滚动
    self.btn_jump_up = g_methods:ButtonClicked(self.chat_root, "btn_jump_up", function( sender, eventType )
        local fPercent = self.chat_view:getPercentVertical()
        fPercent = fPercent - 10 
        if fPercent <  0  then
            fPercent = 0
        end
        self.chat_view:jumpToPercentVertical( fPercent )
    end )
    --聊天框的list向下滚动
    self.btn_jump_dn = g_methods:ButtonClicked(self.chat_root, "btn_jump_dn", function( sender, eventType )
        local fPercent = self.chat_view:getPercentVertical()
         fPercent = fPercent + 10 
        if fPercent > 100 then
            fPercent = 100
        end
        self.chat_view:jumpToPercentVertical( fPercent )
    end )

    --聊天框的list跳到底部
    self.btn_jump_bottom = g_methods:ButtonClicked(self.chat_root, "btn_jump_bottom", function( sender, eventType )
     
         self.chat_view:jumpToBottom( )
    end )
    
    
    
    --隐藏
    self.btn_show = g_methods:ButtonClicked(self.chat_root, "btn_show", function( sender, eventType )
        self.chat_root:setVisible( false )
        self.faces_view:setVisible( false )
        self.short_view:setVisible( false )
        self.btn_hide:setVisible( true )
    end )
    
    self.btn_hide = g_methods:ButtonClicked(self.pan_chat, "btn_hide", function( sender, eventType )
        self.chat_root:setVisible( true )
        self.faces_view:setVisible( false )
        self.short_view:setVisible( false )
         self.btn_hide:setVisible( false )
     end )
    
    
    -- 快捷语面板
     self.short_view = g_methods:WidgetVisible( self.pan_chat, "pan_shorts", false )
     self.short_temp = g_methods:WidgetVisible( self.short_view, "stext", false )

    -- 刷新快捷语
     self:FreshShortWords()

    -- 表情面板
  --  self.faces_view = g_methods:WidgetVisible( self.root_ui, "faces", false )
    
    -- 添加表情面板
   -- self:FreshFaces()

   
    -- 键盘监听
    self.listen_keyboard = cc.EventListenerKeyboard:create()
    self.listen_keyboard:registerScriptHandler( handler( self, self.OnKeyboardReleased ), cc.Handler.EVENT_KEYBOARD_RELEASED )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority( self.listen_keyboard, 1 )

    -- 消息监听列表
    self.msg_hookers = {       
        { E_HALL_HTMLCHAT,          handler( self, self.OnRecHallChat ) },
        { E_CLIENT_SYSCHAT,         handler( self, self.OnRecSysChat ) },
        { E_CLIENT_DCLICKPLAYER,    handler( self, self.OnInsertPlayerName ) },
        { E_HALL_MSGBOX,            handler( self, self.OnRecMsgBox ) }, 
        { E_CLIENT_SETCHATEDIT,     handler( self, self.OnRecSetEditBox ) } 
    }
    g_event:AddListeners( self.msg_hookers, "compchat_events" )

    -- 将缓存的系统日志输入
    if jav_systemlogs and #jav_systemlogs > 0 then
        for index = 1, #jav_systemlogs do
            self:AddChat( jav_systemlogs[index], index == #jav_systemlogs )
        end        
    end
    -- 默认提示输入
    self.default_text = ""
    self.edt_content:setString( self.default_text )
    self.edt_content:setMaxLength( 100 )

    --self:AddChat( "玩家<c=FFFF00FF>[┘一▽/☆═●□卍◆]<c=w>进入房间,旁观玩家tthhds")
    if jav_room_type(ROOM_MATCH) == true then
        g_methods:warn("禁止聊天框")
        g_methods:WidgetDisable(self.btn_faces, true)
        g_methods:WidgetDisable(self.btn_shorts, true)
        g_methods:WidgetDisable(self.btn_send, true)
        g_methods:WidgetDisable(self.edt_content, true)

    end    
end


-- 反激活
function CompChat:InActived()

    -- 键盘监听移除
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:removeEventListener( self.listen_keyboard )
    self.listen_keyboard = nil
    
    -- 关闭sprite_grib的鼠标监听事假
    self.face_panels["tape"]:SetMouseEnabled( false )

    -- 事件监听注销
    g_event:DelListenersByTag( "compchat_events" )
    CompChat.super.InActived( self )
end

-- 添加新聊天
function CompChat:AddChat( content, reload )

    local size = self.chat_view:getContentSize()
    local item = ccui.Widget:create()
    local RichLabel = require("kernels.node.nodeRichLabel" )
    local ricLab = RichLabel.new( { text = content, font="gfont.ttf", fontSize=16, rowWidth=size.width } )
    --ricLab:align( display.LEFT_TOP )
    item:addChild( ricLab )
    item:setContentSize( size.width, ricLab:GetHeight() )
    self.chat_view:addChild( item )
    reload = reload or false
    if reload == true then
        self.chat_view:refreshView() 
        self.chat_view:jumpToBottom()
        --self.chat_view.scrollNode:setPosition( cc.p(0, 0) )
    end  

end

-- 聊天消息到
function CompChat:OnRecHallChat( event_id, event_args )

    -- 系统消息
    if event_args.type == CHAT_SYSTEM then
        local text =  jav_bg2312_utf8( event_args.info ) 
        self:AddChat( text, true )
        return
    end

    -- 玩家消息
    if event_args.type == CHAT_USER  then

        local player = jav_queryplayer_byUID( event_args.uid )
        local content = ""
        if player then
            local txt_fmt = ""
            local sname = jav_format_richname( event_args.uid  )   
            local text =  jav_bg2312_utf8( event_args.info ) 
            if event_args.uid == jav_self_uid then 
                txt_fmt = g_library:QueryConfig( "text.i_say" )
                content = string.format( txt_fmt, text ) 
            else
                txt_fmt = g_library:QueryConfig( "text.user_say" )
                -- 前缀判断是否为机器人语言"rot_say"
                if string.find( text, "rob_say" ) then
                    local text = self.short_words[text]
                    content = string.format( text, sname ) 
                else
                    content = string.format( txt_fmt, sname, text ) 
                end
            end

            self:AddChat( content, true )
        else
            local content = ""
            local content =  jav_bg2312_utf8( event_args.info )  
            self:AddChat( content, true )  
        end
        
        return
    end

end

-- 系统消息到
function CompChat:OnRecSysChat( event_id, event_args )    
    if event_args ~= nil then 
        self:AddChat( event_args.info, true )    
    end
end

-- 插入双击玩家名字
function CompChat:OnInsertPlayerName( event_id, event_args )

    local player = jav_queryplayer_byUID( event_args.uid )
    if player then
        local name = jav_bg2312_utf8( player.nickname )
        self.edt_content:insertString( name .. "，" )
    end

end

-- 设置编辑框内容
function CompChat:OnRecSetEditBox( event_id, event_args )
    self.edt_content:setString( event_args.text )
end

-- 大厅提示框消息到
function CompChat:OnRecMsgBox( event_id, event_args )    
 --   "sdfsdf{http:"
 
    local fidx,lidx = string.find(event_args.msg,"http:",1)    -- 从字符串第一个位置开始查找
    if fidx == nil then
    else
        fidx,lidx = string.find(event_args.msg,"{",1)
        event_args.msg = string.sub(event_args.msg,1,fidx-1)
    end

    self:AddChat( jav_bg2312_utf8( event_args.msg ), true )    
end

--判断所选元素是否在快捷短语列表中
function JundgeArray(msgstr,uselist)
    --   g_methods:log("!!!!!!!!trutyrhdfhdfghdfghdghdghdfghdfghe")
    if not uselist then
        return false
    end
    if uselist then
        for k,v in pairs(uselist) do
            if v == msgstr then
                --             g_methods:log("!!!!!!!!true")
                return true
            end
        end
        --     g_methods:log("!!!!!!!!false")
        return false
    end
end

-- 刷新快捷语
function CompChat:FreshShortWords()

    local short_list = self.short_view:getChildByName( "list" )

    --如果需要增加快捷短语，需要更新此列表
    local uselists={"hello","hurry","winagain","tryagain","baldian","lose","lose1"}
    short_list:removeAllItems()

    for k, text in pairs( self.short_words ) do    
        local tmp = self.short_temp:clone()
        tmp.key = k
        --    g_methods:log("!!!!!!!!text=%s",text)


        local hasflag= JundgeArray(k,uselists)
        --   g_methods:log("!!!!!!!!!!hasflag=%d",hasflag)
        --    g_methods:log("!!!!!!!!k11=%s",k)
        repeat
            if hasflag == true then
                --        g_methods:log("!!!!!!!!gsdfgsgfsfgk=%s",k)
                tmp:setString( text )
                tmp:setVisible( true )
                short_list:pushBackCustomItem( tmp )   

                tmp:setTouchEnabled( true )
                tmp:addTouchEventListener( function( sender, eventType )
                    if eventType == ccui.TouchEventType.ended then
                        --self:AddChat( sender:getString(), true )
                        local content = sender:getString()
                        jav_userchat( jav_utf8_bg2312(content) )
               
                        self:ToggleShowShorts()
                    end
                end ) 
                break 
            else
                break
            end
        until true        
    end
    short_list:refreshView()
end

-- 命令发布
function CompChat:SendCmd()

    local cmd_str = self.edt_content:getString()
    if cmd_str == "" or cmd_str == self.default_text then
        return
    end

    -- 调试模式下"/"号开头的文本定为命令
    local fidx,ladx = string.find( cmd_str, "/" ,1)
    --if jav_is_debugmode() == true and pos == 1 then
    if fidx == 1 then
        local msgArgs = { chair = jav_get_mychairid(), args = string.sub( cmd_str, 2 ) }
        jav_send_message( "cmd_line", msgArgs )
    else

        -- 发布模式下为聊天
        jav_userchat( jav_utf8_bg2312(cmd_str))

        -- 自己显示
--        local txt_fmt = g_library:QueryConfig( "text.i_say" )
--        local content = string.format( txt_fmt, cmd_str ) 
--        self:AddChat( content, true )
    end

    self.edt_content:setString( "" )

end

-- 显示快捷语面板
function CompChat:ToggleShowShorts()

    if self.short_view:isVisible() then
        self.short_view:setVisible( false )
    else
        self.short_view:setVisible( true )
        self.faces_view:setVisible( false )
    end
    local short_list = self.short_view:getChildByName( "list" )
    short_list:jumpToTop()
end

-- 监听按键
function CompChat:OnKeyboardReleased( keycode, event )

    if keycode == cc.KeyCode.KEY_KP_ENTER then

        local text = self.edt_content:getString()
        if text ~= "" then
            self:SendCmd()
        end
    end
    
    if keycode == cc.KeyCode.KEY_1 then

    end

end

-- 鼠标移动
function CompChat:OnMouseMove( posx,posy,isget )
    local template = self.faces_view:getChildByName( "mark" )
    if isget == false then
        template:setVisible(false)
        return
    end
    
    -- 如果移动在在表情动画面板
    if  self.faces_view and 
        self.faces_view:isVisible() == true then
        template:setVisible(true)
        local size = self.faces_view:getContentSize()
        template:setPosition( cc.p( posx-1, posy+size.height) ) -- 修正选中框显示的坐标位置
    end
end


-- 鼠标弹起
function CompChat:onMouseTouchUp( scrx, scry, idx )
    if self.faces_view:isVisible() then
        self:OnInsertfaceEdiotr(idx) 
    end
    
    -- 如果点击在聊天框上不处理
    if  self.chat_root and 
        self.chat_root:hitTest( cc.p( scrx, scry ) )then
        return
    end



end

-- 显示表情动画面板
function CompChat:ToggleShowFaces()

    if self.faces_view:isVisible() then 
        self.faces_view:setVisible( false )
    else
        self.faces_view:setVisible( true )
        self.short_view:setVisible( false )  
    end

end

-- 刷新表情面板
function CompChat:FreshFaces()
    local tape_class = require( "kernels.node.nodeSpriteGrid" )
    local face_node = self.faces_view   

    local new_tape = tape_class.new( "facetape" )
    face_node:addChild( new_tape )

    new_tape:SetMouseEnabled( true )                     -- 开启鼠标监听事件

    new_tape.Item_dim       = FACE_DIMENSION
    new_tape.offset         = FACE_OFFSET
    new_tape.item_perline   = FACE_ROWCOUNT
    new_tape.align_type     = { new_tape.ALIGN_LEFT, new_tape.ALIGN_TOP }
    
    -- 批量添加表情，用于表格精灵通用使用
    local facemap = {}
    local itemidx = 0
    for row = 1, 5 do
        for col = 1, 3 do
            local item = display.newSprite()
            local ani = g_library:CreateAnimation( string.format( "faces.sf_%03d", itemidx ) )    -- 资源
            item:playAnimationForever( ani )
            table.insert( facemap,{sprite = item, tag = itemidx }  )   
            itemidx = itemidx + 1
        end
    end    
    
    new_tape:AddBatItems(facemap)
    
    new_tape:SetCallback( handler( self, self.OnFaceGridEvent ) ) 

    self.face_panels = { tape = new_tape }

end

-- 添加点击的表情到输入框中
function CompChat:OnInsertfaceEdiotr(faceidx)
--    local text = self.edt_content:getString()    -- 得到当前输入框中的所有值    
--    text = text .. "#" .. tostring(faceidx)
    local text = "#" .. tostring(faceidx)
    
    g_methods:log( "插入的字符串是[%s]", text )
    self.faces_view:setVisible( false )
    self.edt_content:insertString(text)
end

--
function CompChat:OnFaceGridEvent( grid, event_args )    
    if event_args.type == "mousemove" then
        self:OnMouseMove( event_args.posx,event_args.posy,event_args.isget)    
        return
    end
    
    if event_args.type == "clicked" then
        g_methods:log( "点击了表情[%s]", tostring(event_args.spt.tag) )           -- 此处添加一个事件处理机制，让其可以添加到输入框中
        self:onMouseTouchUp( event_args.posx, event_args.posy, event_args.spt.tag) 
        return
    end
end

return CompChat

 