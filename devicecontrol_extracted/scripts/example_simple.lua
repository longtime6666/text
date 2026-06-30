--[[
    简单压枪脚本示例
    持续往下拉，速度由 recoil_speed 控制
    
    可用 API:
    - move(x, y): 移动鼠标
    - sleep(ms): 延迟执行
    - isButtonDown(button): 检查按键 (1=左键, 2=右键, 3=中键, 4=侧键1, 5=侧键2)
    - getElapsedTime(): 获取按键按下后经过的时间(毫秒)
    - getShotCount(): 获取当前射击次数
    - log(msg): 输出日志
    
    全局变量:
    - recoil_speed: 基础下拉速度（从UI设置）
    - shot_interval: 射击间隔(毫秒)
]]

-- 初始化时调用
function on_start()
    log("压枪开始")
end

-- 每帧调用
function on_update()
    -- 简单的持续下拉
    move(0, recoil_speed)
    sleep(16) -- 约60fps
end

-- 结束时调用
function on_stop()
    log("压枪结束")
end
