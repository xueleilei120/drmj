-- nodeModal.lua
-- 2014-10-20
-- KevinYuen
-- 模板面板
-- 位于场景最上层

-- 模态LayerOrder计数器
ModalZOrderTracker = 8000

local ModalPanel = class( "ModalPanel" )

-- 加载并绑定PANEL
function ModalPanel:BindUIJSON( json_file )

    -- 读取界面文件
    local node = ccs.GUIReader:getInstance():widgetFromJsonFile( json_file )
    if not node then 
        g_methods:error( "UI界面[%s]模态化失败...", json_file )
        return false
    end

    -- 已经绑定过不能再次绑定
    if self.node_name and self.node_name ~= "" then
        g_methods:error( "UI界面[%s]模态化失败,不支持二次绑定...", json_file )
        return false
    end
    
    -- 绑定
    ModalZOrderTracker = ModalZOrderTracker + 1
    local scene = cc.Director:getInstance():getRunningScene()
    scene:FindRoot():addChild( node, ModalZOrderTracker )
    self.node_name = "root_ui_modal_" .. ModalZOrderTracker
    node:setName( self.node_name )
    node:setContentSize( display.width, display.height )
    node:setTouchEnabled( true )
    return true
    
end

-- 关闭
function ModalPanel:Close()
    
    local modal_ui = self:GetRoot()
    if modal_ui then
        modal_ui:removeFromParent()
    end
end

-- 获取界面节点
function ModalPanel:GetRoot()
    local scene = cc.Director:getInstance():getRunningScene()
    return scene:FindRoot():getChildByName( self.node_name )
end
return ModalPanel