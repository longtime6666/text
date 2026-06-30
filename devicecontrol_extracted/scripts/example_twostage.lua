--[[
    两段式压枪脚本示例
    第一阶段：快速下拉
    第二阶段：持续慢速下拉
    
    可用 API:
    - move(x, y): 移动鼠标
    - sleep(ms): 延迟执行
    - isButtonDown(button): 检查按键
    - getElapsedTime(): 获取按键按下后经过的时间(毫秒)
    - getShotCount(): 获取当前射击次数
    - log(msg): 输出日志
]]

-- 配置
local first_stage_duration = 150  -- 第一阶段持续时间(毫秒)
local first_stage_speed = 4.0     -- 第一阶段速度倍率
local second_stage_speed = 1.0    -- 第二阶段速度倍率

function on_start()
    log("两段式压枪开始")
end

function on_update()
    local elapsed = getElapsedTime()
    local speed
    
    if elapsed < first_stage_duration then
        -- 第一阶段：快速下拉
        speed = recoil_speed * first_stage_speed
    else
        -- 第二阶段：持续慢速下拉
        speed = recoil_speed * second_stage_speed
    end
    
    move(0, speed)
    sleep(16)
end

function on_stop()
    log("两段式压枪结束")
end
