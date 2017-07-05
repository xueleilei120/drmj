-- main.lua
-- 2014-12-14
-- KevinYuen
-- 启动脚本

-- 错误追踪
function __G__TRACKBACK__(errorMessage)

    release_print("----------------------------------------")
    release_print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    release_print(debug.traceback("", 2))
    release_print("----------------------------------------")
    
    if jav_is_debugmode() == true then
        device.showAlert( "LUA ERROR", tostring( errorMessage ), { "OK" } )
    end
     
end

-- 脚本require路径追加
package.path = package.path .. ";src/"

-- 文件加载失败是否弹框
cc.FileUtils:getInstance():setPopupNotify(false)

-- 游戏主脚本启动
require("game").new():run()
