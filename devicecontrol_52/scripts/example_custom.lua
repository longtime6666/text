--[[
    自定义压枪脚本模板
    
    ========== 可用 API ==========
    
    move(x, y)          - 移动鼠标 (x=水平, y=垂直, 正数=右/下)
    sleep(ms)           - 延迟执行 (毫秒)
    isButtonDown(btn)   - 检查按键是否按下
                          btn: 1=左键, 2=右键, 3=中键, 4=侧键1, 5=侧键2
    getElapsedTime()    - 获取按键按下后经过的时间 (毫秒)
    getShotCount()      - 获取当前射击次数 (基于 shot_interval 计算)
    log(msg)            - 输出日志到状态栏
    
    ========== 全局变量 ==========
    
    recoil_speed        - 基础下拉速度 (从UI设置读取)
    shot_interval       - 射击间隔 (毫秒, 从UI设置读取)
    
    ========== 回调函数 ==========
    
    on_start()          - 按下触发键时调用 (可选)
    on_update()         - 每帧调用，在这里实现压枪逻辑 (必须)
    on_stop()           - 释放触发键时调用 (可选)
    
    ========== 示例 ==========
]]

-- 自定义压枪数据表
-- 格式: { y偏移, x偏移 } 每发一个
local pattern = {
    { 2.0, 0.0 },   -- 第1发
    { 2.5, 0.0 },   -- 第2发
    { 3.0, 0.2 },   -- 第3发
    { 3.5, 0.3 },   -- 第4发
    { 3.0, -0.2 },  -- 第5发
    { 2.5, -0.3 },  -- 第6发
    { 2.0, 0.1 },   -- 第7发
    { 1.8, 0.0 },   -- 第8发
    { 1.5, -0.1 },  -- 第9发
    { 1.2, 0.0 },   -- 第10发及以后
}

local last_shot = 0
local accumulator_x = 0
local accumulator_y = 0

function on_start()
    last_shot = 0
    accumulator_x = 0
    accumulator_y = 0
    log("自定义压枪开始")
end

function on_update()
    local shot = getShotCount()
    
    -- 只在新的一发时处理
    if shot > last_shot then
        last_shot = shot
        
        -- 获取当前发数的压枪数据
        local index = math.min(shot, #pattern)
        local data = pattern[index]
        
        -- 应用速度倍率
        local pull_y = data[1] * recoil_speed
        local pull_x = data[2] * recoil_speed
        
        -- 亚像素累积
        accumulator_y = accumulator_y + pull_y
        accumulator_x = accumulator_x + pull_x
        
        local move_y = math.floor(accumulator_y)
        local move_x = math.floor(accumulator_x)
        
        if move_y ~= 0 or move_x ~= 0 then
            accumulator_y = accumulator_y - move_y
            accumulator_x = accumulator_x - move_x
            move(move_x, move_y)
        end
    end
    
    sleep(5) -- 高频检测
end

function on_stop()
    log("自定义压枪结束, 共 " .. last_shot .. " 发")
end
