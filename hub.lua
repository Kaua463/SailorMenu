task.wait(3)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

local RequestHit = RS.CombatSystem.Remotes.RequestHit
local RequestAbility = RS.AbilitySystem.Remotes.RequestAbility

local S = {
    autoAttack=false, attackDelay=0.05,
    spamSkills=false, skills={false,false,false,false},
    antiFreeze=false, removeFX=false,
    hitbox=false, hitboxSize=15,
    spy=false,
}

local hitboxCache, spyLogs, spyHooked = {}, {}, false
local currentTab = "combat"
local minimized = false
local pages = {combat={}, hitbox={}, spy={}}

local gui = Instance.new("ScreenGui")
gui.Name = "SailorHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local W, FULL_H = 250, 360

local main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, FULL_H)
main.Position = UDim2.new(0, 10, 0, 10)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", main)
ms.Thickness = 1
ms.Color = Color3.fromRGB(40, 60, 120)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(14, 18, 38)
header.BorderSizePixel = 0
header.Parent = main

local htitle = Instance.new("TextLabel")
htitle.Size = UDim2.new(1, -45, 1, 0)
htitle.Position = UDim2.new(0, 10, 0, 0)
htitle.BackgroundTransparency = 1
htitle.Text = "SAILOR PIECE HUB"
htitle.TextColor3 = Color3.fromRGB(120, 170, 255)
htitle.Font = Enum.Font.GothamBold
htitle.TextSize = 12
htitle.TextXAlignment = Enum.TextXAlignment.Left
htitle.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 22)
minBtn.Position = UDim2.new(1, -34, 0, 8)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 70)
minBtn.TextColor3 = Color3.fromRGB(180, 200, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.BorderSizePixel = 0
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.Position = UDim2.new(0, 0, 0, 38)
tabBar.BackgroundColor3 = Color3.fromRGB(12, 14, 26)
tabBar.BorderSizePixel = 0
tabBar.Parent = main

local tL = Instance.new("UIListLayout", tabBar)
tL.FillDirection = Enum.FillDirection.Horizontal
tL.HorizontalAlignment = Enum.HorizontalAlignment.Center
tL.VerticalAlignment = Enum.VerticalAlignment.Center
tL.Padding = UDim.new(0, 3)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -68)
scroll.Position = UDim2.new(0, 0, 0, 68)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 200)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ElasticBehavior = Enum.ElasticBehavior.Never
scroll.Parent = main

local sLL = Instance.new("UIListLayout", scroll)
sLL.Padding = UDim.new(0, 4)
sLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
sLL.SortOrder = Enum.SortOrder.LayoutOrder

local sPad = Instance.new("UIPadding", scroll)
sPad.PaddingTop = UDim.new(0, 6)
sPad.PaddingBottom = UDim.new(0, 6)

sLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, sLL.AbsoluteContentSize.Y + 14)
end)

local function reg(item, page)
    table.insert(pages[page], item)
    item.Visible = (page == currentTab)
    return item
end

local function setTab(name)
    currentTab = name
    scroll.CanvasPosition = Vector2.new(0, 0)
    for n, items in pairs(pages) do
        for _, v in ipairs(items) do
            v.Visible = (n == name)
        end
    end
end

local function makeRow(h, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -12, 0, h)
    f.BackgroundColor3 = Color3.fromRGB(18, 20, 34)
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke", f)
    s.Thickness = 1
    s.Color = Color3.fromRGB(28, 36, 70)
    return f
end

local function makeSep(text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -12, 0, 16)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order
    f.Parent = scroll
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(70, 100, 180)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    return f
end

local function makeToggle(ico, label, cb, order)
    local row = makeRow(36, order)

    local iL = Instance.new("TextLabel")
    iL.Size = UDim2.new(0, 24, 0, 24)
    iL.Position = UDim2.new(0, 6, 0.5, -12)
    iL.BackgroundColor3 = Color3.fromRGB(22, 32, 72)
    iL.Text = ico
    iL.TextSize = 13
    iL.Font = Enum.Font.GothamBold
    iL.TextColor3 = Color3.fromRGB(100, 150, 255)
    iL.BorderSizePixel = 0
    iL.Parent = row
    Instance.new("UICorner", iL).CornerRadius = UDim.new(0, 5)

    local lL = Instance.new("TextLabel")
    lL.Size = UDim2.new(1, -82, 1, 0)
    lL.Position = UDim2.new(0, 36, 0, 0)
    lL.BackgroundTransparency = 1
    lL.Text = label
    lL.TextColor3 = Color3.fromRGB(180, 185, 210)
    lL.Font = Enum.Font.Gotham
    lL.TextSize = 10
    lL.TextXAlignment = Enum.TextXAlignment.Left
    lL.TextWrapped = true
    lL.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 36, 0, 18)
    pill.Position = UDim2.new(1, -42, 0.5, -9)
    pill.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    pill.BorderSizePixel = 0
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 13, 0, 13)
    dot.Position = UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
    dot.BorderSizePixel = 0
    dot.Parent = pill
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            pill.BackgroundColor3 = Color3.fromRGB(25, 65, 160)
            dot.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
            dot.Position = UDim2.new(1, -16, 0.5, -6)
            row.BackgroundColor3 = Color3.fromRGB(14, 20, 40)
        else
            pill.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
            dot.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
            dot.Position = UDim2.new(0, 3, 0.5, -6)
            row.BackgroundColor3 = Color3.fromRGB(18, 20, 34)
        end
        cb(active)
    end)

    return row
end

local function makeCycle(ico, label, opts, cb, order)
    local row = makeRow(36, order)
    local idx = 1

    local iL = Instance.new("TextLabel")
    iL.Size = UDim2.new(0, 24, 0, 24)
    iL.Position = UDim2.new(0, 6, 0.5, -12)
    iL.BackgroundColor3 = Color3.fromRGB(22, 32, 72)
    iL.Text = ico
    iL.TextSize = 13
    iL.Font = Enum.Font.GothamBold
    iL.TextColor3 = Color3.fromRGB(100, 150, 255)
    iL.BorderSizePixel = 0
    iL.Parent = row
    Instance.new("UICorner", iL).CornerRadius = UDim.new(0, 5)

    local lL = Instance.new("TextLabel")
    lL.Size = UDim2.new(1, -44, 1, 0)
    lL.Position = UDim2.new(0, 36, 0, 0)
    lL.BackgroundTransparency = 1
    lL.Text = label..": "..opts[1][1]
    lL.TextColor3 = Color3.fromRGB(100, 160, 255)
    lL.Font = Enum.Font.GothamBold
    lL.TextSize = 10
    lL.TextXAlignment = Enum.TextXAlignment.Left
    lL.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        idx = idx % #opts + 1
        lL.Text = label..": "..opts[idx][1]
        cb(opts[idx][2])
    end)

    return row
end

-- TABS
local tabBtns = {}
local tabDefs = {
    {name="combat", label="Combat"},
    {name="hitbox", label="Hitbox"},
    {name="spy",    label="Spy"},
}

for _, t in ipairs(tabDefs) do
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(0, 72, 0, 22)
    tb.Text = t.label
    tb.BackgroundColor3 = Color3.fromRGB(18, 20, 38)
    tb.TextColor3 = Color3.fromRGB(80, 90, 130)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 10
    tb.BorderSizePixel = 0
    tb.Parent = tabBar
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 5)
    tabBtns[t.name] = tb

    tb.MouseButton1Click:Connect(function()
        setTab(t.name)
        for n, b in pairs(tabBtns) do
            b.BackgroundColor3 = n == t.name
                and Color3.fromRGB(25, 50, 120)
                or Color3.fromRGB(18, 20, 38)
            b.TextColor3 = n == t.name
                and Color3.fromRGB(120, 180, 255)
                or Color3.fromRGB(80, 90, 130)
        end
    end)
end

-- COMBAT
reg(makeSep("  ATAQUE", 10), "combat")
reg(makeToggle("A", "Auto Attack", function(v) S.autoAttack = v end, 11), "combat")
reg(makeCycle("V", "Velocidade",
    {{"MAXIMA",0.05},{"ALTA",0.1},{"MEDIA",0.2},{"BAIXA",0.35}},
    function(v) S.attackDelay = v end, 12), "combat")

reg(makeSep("  HABILIDADES", 20), "combat")

local skillCard = makeRow(88, 21)
reg(skillCard, "combat")

local sgrid = Instance.new("Frame")
sgrid.Size = UDim2.new(1, -10, 0, 44)
sgrid.Position = UDim2.new(0, 5, 0, 5)
sgrid.BackgroundTransparency = 1
sgrid.Parent = skillCard

local sgL = Instance.new("UIListLayout", sgrid)
sgL.FillDirection = Enum.FillDirection.Horizontal
sgL.Padding = UDim.new(0, 4)
sgL.HorizontalAlignment = Enum.HorizontalAlignment.Center

for i = 1, 4 do
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(0, 48, 0, 40)
    sb.Text = "S"..i
    sb.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    sb.TextColor3 = Color3.fromRGB(90, 100, 150)
    sb.Font = Enum.Font.GothamBold
    sb.TextSize = 13
    sb.BorderSizePixel = 0
    sb.Parent = sgrid
    Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 6)
    local sk = Instance.new("UIStroke", sb)
    sk.Color = Color3.fromRGB(32, 42, 80)
    sk.Thickness = 1
    local on = false
    sb.MouseButton1Click:Connect(function()
        on = not on
        S.skills[i] = on
        sb.BackgroundColor3 = on and Color3.fromRGB(20,50,130) or Color3.fromRGB(18,22,42)
        sb.TextColor3 = on and Color3.fromRGB(100,170,255) or Color3.fromRGB(90,100,150)
        sk.Color = on and Color3.fromRGB(50,90,200) or Color3.fromRGB(32,42,80)
    end)
end

local spamPill = Instance.new("Frame")
spamPill.Size = UDim2.new(0, 36, 0, 18)
spamPill.Position = UDim2.new(1, -42, 0, 56)
spamPill.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
spamPill.BorderSizePixel = 0
spamPill.Parent = skillCard
Instance.new("UICorner", spamPill).CornerRadius = UDim.new(1, 0)

local spamDot = Instance.new("Frame")
spamDot.Size = UDim2.new(0, 13, 0, 13)
spamDot.Position = UDim2.new(0, 3, 0.5, -6)
spamDot.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
spamDot.BorderSizePixel = 0
spamDot.Parent = spamPill
Instance.new("UICorner", spamDot).CornerRadius = UDim.new(1, 0)

local spamLbl = Instance.new("TextLabel")
spamLbl.Size = UDim2.new(1, -55, 0, 22)
spamLbl.Position = UDim2.new(0, 8, 0, 54)
spamLbl.BackgroundTransparency = 1
spamLbl.Text = "Spam skills ativas"
spamLbl.TextColor3 = Color3.fromRGB(180, 185, 210)
spamLbl.Font = Enum.Font.Gotham
spamLbl.TextSize = 10
spamLbl.TextXAlignment = Enum.TextXAlignment.Left
spamLbl.Parent = skillCard

local spamBtn = Instance.new("TextButton")
spamBtn.Size = UDim2.new(1, 0, 0, 26)
spamBtn.Position = UDim2.new(0, 0, 0, 54)
spamBtn.BackgroundTransparency = 1
spamBtn.Text = ""
spamBtn.Parent = skillCard

local spamOn = false
spamBtn.MouseButton1Click:Connect(function()
    spamOn = not spamOn
    S.spamSkills = spamOn
    spamPill.BackgroundColor3 = spamOn and Color3.fromRGB(25,65,160) or Color3.fromRGB(35,35,55)
    spamDot.BackgroundColor3 = spamOn and Color3.fromRGB(100,170,255) or Color3.fromRGB(70,70,100)
    spamDot.Position = spamOn and UDim2.new(1,-16,0.5,-6) or UDim2.new(0,3,0.5,-6)
end)

reg(makeSep("  UTILIDADES", 30), "combat")
reg(makeToggle("F", "Anti-Freeze", function(v) S.antiFreeze = v end, 31), "combat")
reg(makeToggle("X", "Remover FX", function(v) S.removeFX = v end, 32), "combat")

-- HITBOX
reg(makeSep("  HITBOX EXPANDER", 40), "hitbox")
reg(makeToggle("H", "Expandir hitbox NPCs", function(v)
    S.hitbox = v
    if not v then
        for part, orig in pairs(hitboxCache) do
            pcall(function()
                if part and part.Parent then
                    part.Size = orig.s
                    part.Transparency = orig.t
                    part.CanCollide = orig.c
                end
            end)
        end
        hitboxCache = {}
    end
end, 41), "hitbox")

reg(makeCycle("T", "Tamanho",
    {{"P(5)",5},{"M(10)",10},{"G(15)",15},{"XL(20)",20},{"XXL(30)",30},{"MAX(50)",50}},
    function(v)
        S.hitboxSize = v
        if S.hitbox then
            for part, _ in pairs(hitboxCache) do
                pcall(function()
                    if part and part.Parent then
                        part.Size = Vector3.new(v,v,v)
                    end
                end)
            end
        end
    end, 42), "hitbox")

reg(makeToggle("V", "Mostrar hitboxes", function(v)
    for part, _ in pairs(hitboxCache) do
        pcall(function()
            if part and part.Parent then
                part.Transparency = v and 0.6 or 1
            end
        end)
    end
end, 43), "hitbox")

-- SPY
reg(makeSep("  REMOTE SPY", 50), "spy")
reg(makeToggle("S", "Ativar Remote Spy", function(v)
    S.spy = v
    if v and not spyHooked then
        spyHooked = true
        local mt = getrawmetatable(game)
        local oldNC = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if S.spy and typeof(self) == "Instance" then
                if method == "FireServer" or method == "InvokeServer" then
                    local e = string.format("[%s] %s > %s",
                        os.date("%H:%M:%S"), method, self.Name)
                    for i, a in ipairs(args) do
                        e = e..string.format(" | A%d:%s", i, tostring(a):sub(1,20))
                    end
                    table.insert(spyLogs, e)
                    if #spyLogs > 100 then table.remove(spyLogs, 1) end
                end
            end
            return oldNC(self, ...)
        end)
        setreadonly(mt, true)
    end
end, 51), "spy")

local logCard = makeRow(185, 52)
reg(logCard, "spy")

local logBox = Instance.new("ScrollingFrame")
logBox.Size = UDim2.new(1, -10, 1, -38)
logBox.Position = UDim2.new(0, 5, 0, 5)
logBox.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
logBox.BorderSizePixel = 0
logBox.ScrollBarThickness = 2
logBox.ScrollBarImageColor3 = Color3.fromRGB(50, 80, 180)
logBox.Parent = logCard
Instance.new("UICorner", logBox).CornerRadius = UDim.new(0, 6)

local logLL = Instance.new("UIListLayout", logBox)
logLL.Padding = UDim.new(0, 1)
local logPad = Instance.new("UIPadding", logBox)
logPad.PaddingLeft = UDim.new(0, 4)
logPad.PaddingTop = UDim.new(0, 3)

logLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    logBox.CanvasSize = UDim2.new(0, 0, 0, logLL.AbsoluteContentSize.Y + 8)
    logBox.CanvasPosition = Vector2.new(0, logBox.CanvasSize.Y.Offset)
end)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.47, 0, 0, 26)
copyBtn.Position = UDim2.new(0, 5, 1, -31)
copyBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 130)
copyBtn.Text = "Copiar"
copyBtn.TextColor3 = Color3.fromRGB(140, 180, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 10
copyBtn.BorderSizePixel = 0
copyBtn.Parent = logCard
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.47, 0, 0, 26)
clearBtn.Position = UDim2.new(0.53, -5, 1, -31)
clearBtn.BackgroundColor3 = Color3.fromRGB(80, 18, 18)
clearBtn.Text = "Limpar"
clearBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 10
clearBtn.BorderSizePixel = 0
clearBtn.Parent = logCard
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

copyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard(table.concat(spyLogs, "\n"))
        copyBtn.Text = "OK!"
        task.wait(2)
        copyBtn.Text = "Copiar"
    end)
end)

clearBtn.MouseButton1Click:Connect(function()
    spyLogs = {}
    for _, c in ipairs(logBox:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
end)

-- MINIMIZAR
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    tabBar.Visible = not minimized
    scroll.Visible = not minimized
    main.Size = minimized
        and UDim2.new(0, W, 0, 38)
        or UDim2.new(0, W, 0, FULL_H)
    minBtn.Text = minimized and "+" or "-"
end)

setTab("combat")
tabBtns["combat"].BackgroundColor3 = Color3.fromRGB(25, 50, 120)
tabBtns["combat"].TextColor3 = Color3.fromRGB(120, 180, 255)

-- LOOPS
task.spawn(function()
    while true do
        task.wait(S.attackDelay)
        if S.autoAttack then
            pcall(function() RequestHit:FireServer() end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if S.spamSkills then
            for i = 1, 4 do
                if S.skills[i] then
                    pcall(function() RequestAbility:FireServer(i) end)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if S.antiFreeze then
            local char = player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if hum.WalkSpeed < 8 then hum.WalkSpeed = 16 end
                    if hum:GetState() == Enum.HumanoidStateType.None then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                    end
                end
            end
        end
    end
end)

local lastSpyCount = 0

local function isPlrChar(m)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == m then return true end
    end
    return false
end

RunService.Heartbeat:Connect(function()
    if S.removeFX then
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") then
                pcall(function() if o.Enabled then o.Enabled = false end end)
            end
        end
    end

    if S.hitbox then
        for _, m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") and m ~= player.Character and not isPlrChar(m) then
                if m:FindFirstChild("Humanoid") then
                    for _, p in ipairs(m:GetDescendants()) do
                        if p:IsA("BasePart") and not hitboxCache[p] then
                            hitboxCache[p] = {s=p.Size, t=p.Transparency, c=p.CanCollide}
                            pcall(function()
                                p.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                                p.Transparency = 1
                                p.CanCollide = false
                            end)
                        end
                    end
                end
            end
        end
    end

    if S.spy and #spyLogs ~= lastSpyCount then
        lastSpyCount = #spyLogs
        local last = spyLogs[#spyLogs]
        if last then
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -4, 0, 13)
            lbl.BackgroundTransparency = 1
            lbl.Text = last
            lbl.TextColor3 = last:find("FireServer")
                and Color3.fromRGB(255, 100, 100)
                or Color3.fromRGB(100, 255, 100)
            lbl.Font = Enum.Font.Code
            lbl.TextSize = 9
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.Parent = logBox
        end
    end
end)

print("Sailor Piece Hub carregado!")
