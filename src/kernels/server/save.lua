-- save.lua
-- 2015-01-04
-- KevinYuen
-- 存档数据

local BaseObject = require( "kernels.object" )
local SaveData = class( "SaveData", BaseObject )

-- 初始化
function SaveData:OnCreate( args )

    SaveData.super.OnCreate( self, args )    

    local fileUtils = cc.FileUtils:getInstance()

    -- 默认路径配置
    self.raw_path = "savedata.json";
    self.save_path = fileUtils:getWritablePath() .. "drmj-save.json"
--    if device.platform == "windows" then
--        local path = fileUtils:fullPathForFilename( "config.json" )
--        local pos = string.find( path, "config.json" )
--        local folder = string.sub( path, 0, pos - 1 )
--        self.save_path = folder .. "save.json"
--    end

    -- 如果没有存档,则读取原型
    local load_file = self.save_path
    if false == fileUtils:isFileExist( load_file ) then
        load_file = self.raw_path
        g_methods:debug( "首次创建存档,原型:%s...", load_file )
    end

    -- 读取
    local import_path = self.save_path
    if device.platform == "windows" then
        --import_path = jav_utf8_bg2312( import_path )
    end
    
    self.configs = g_methods:ImportJson( import_path )
    if not self.configs then

        import_path = self.raw_path
        if device.platform == "windows" then
            --import_path = jav_utf8_bg2312( import_path )
        end
        
        self.configs = g_methods:ImportJson( import_path ) 
        if not self.configs then
            g_methods:warn( "存档读取失败:%s...", self.raw_path )            
        end
        
    end
    
    g_methods:debug( "存档读取成功:%s...", load_file )

    -- 记录游戏启动时间
    local launch_time = os.time()
    self.configs.system.launch_time = launch_time
    g_methods:debug( "游戏启动日期:%s...", os.date( "%c", launch_time ) )

    return true

end

-- 销毁
function SaveData:OnDestroy()
    SaveData.super.OnDestroy( self ) 
end

-- 文档化保存
function SaveData:SaveAll( save_path )
    
    -- 主角数据导入
    if g_mainrole ~= nil then
        self.configs.role = g_mainrole:Export() 
    end
    
    save_path = save_path or self.save_path    
    if device.platform == "windows" then
	   --save_path = jav_utf8_bg2312( save_path )
	end
    if g_methods:ExportJson( save_path, self.configs ) == false then
        g_methods:error( "存档失败:%s...", save_path )
        return false
    end    

    g_methods:debug( "存档成功:%s...", save_path )
    return true
end

-- 存档后关闭
function SaveData:Shutdown( save_path )

    local shutdown_time = os.time()
    self.configs.system.shutdown_time = shutdown_time
    g_methods:debug( "\t游戏关闭日期:%s...", os.date( "%c", shutdown_time ) )
    local launch_time = self.configs.system.launch_time
    local dif_time = os.difftime( shutdown_time, launch_time )
    g_methods:debug( "\t游戏时长:%d秒...", dif_time )    
    self:SaveAll()

end

return SaveData