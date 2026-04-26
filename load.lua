--[[
    ╔══════════════════════════════════════════╗
    ║         INFYIFF BACKUP - LOADER          ║
    ║      Universal Script Menu Loader        ║
    ╚══════════════════════════════════════════╝
    
    Cara pakai:
    1. Jalankan script ini di exploit executor
    2. Pilih tool yang ingin dijalankan dari menu
    3. Tool akan otomatis diload dan dijalankan
    
    Note: Pastikan executor mendukung HttpGet / request
--]]

-- ══════════════════════════════════════
--  KONFIGURASI
-- ══════════════════════════════════════

local BASE_URL = "https://raw.githubusercontent.com/prisma-ui/backup/refs/heads/main/"

local TOOLS = {
    -- [ KATEGORI: EXPLOITS & UTILITIES ]
    {
        name     = "Infinite Yield FE",
        desc     = "Admin command executor lengkap",
        category = "Exploits",
        url      = BASE_URL .. "iyfd.lua",
        icon     = "⚡",
    },
    {
        name     = "WallWalker",
        desc     = "Berjalan menembus dinding",
        category = "Exploits",
        url      = BASE_URL .. "wallwalker.lua",
        icon     = "🧱",
    },
    {
        name     = "VR Script",
        desc     = "Script pendukung mode VR",
        category = "Exploits",
        url      = BASE_URL .. "vr.lua",
        icon     = "🥽",
    },
    {
        name     = "Misc Bypasses",
        desc     = "Bypass anti-cheat umum (gcinfo, dll)",
        category = "Exploits",
        url      = BASE_URL .. "misc/bypasses.lua",
        icon     = "🛡️",
    },
    {
        name     = "Process Bypass",
        desc     = "Hook & bypass detection process",
        category = "Exploits",
        url      = BASE_URL .. "misc/process.lua",
        icon     = "🔧",
    },
    {
        name     = "Gravity Controller",
        desc     = "Kontrol gravitasi karakter",
        category = "Exploits",
        url      = BASE_URL .. "misc/gravityController.lua",
        icon     = "🌍",
    },

    -- [ KATEGORI: INSPECTOR & DECOMPILER ]
    {
        name     = "Advanced Decompiler V3 + Dex",
        desc     = "Load AdvDecompiler lalu Dex (decompile otomatis terhubung)",
        category = "Inspector",
        url      = nil, -- special: multi-load
        icon     = "🔍",
        _multi   = {
            BASE_URL .. "AdvancedDecompilerV3/init.lua",
            BASE_URL .. "dex.lua",
        },
    },
    {
        name     = "Dex Explorer (standalone)",
        desc     = "Browser & inspector object Roblox (tanpa decompiler override)",
        category = "Inspector",
        url      = BASE_URL .. "dex.lua",
        icon     = "🗂️",
    },
    {
        name     = "SimpleSpy V3",
        desc     = "Remote spy & interceptor",
        category = "Inspector",
        url      = BASE_URL .. "SimpleSpyV3/main.lua",
        icon     = "👁️",
    },
    {
        name     = "Advanced Decompiler V3",
        desc     = "Decompiler bytecode Luau (standalone, tanpa Dex)",
        category = "Inspector",
        url      = BASE_URL .. "AdvancedDecompilerV3/init.lua",
        icon     = "📦",
    },
    {
        name     = "Konstant Decompiler",
        desc     = "Decompile/disassemble via API eksternal",
        category = "Inspector",
        url      = BASE_URL .. "konstant.lua",
        icon     = "🔓",
    },

    -- [ KATEGORI: BUILDER & TOOLS ]
    {
        name     = "F3X Building Tools",
        desc     = "Tool building & manipulasi objek",
        category = "Builder",
        url      = BASE_URL .. "f3x.lua",
        icon     = "🏗️",
    },

    -- [ KATEGORI: UI & LOGGER ]
    {
        name     = "Developer Console",
        desc     = "Console log & debug Roblox",
        category = "UI & Logger",
        url      = BASE_URL .. "console.lua",
        icon     = "🖥️",
    },
    {
        name     = "Audio Logger",
        desc     = "Logger & scanner audio/sound",
        category = "UI & Logger",
        url      = BASE_URL .. "audiologger.lua",
        icon     = "🎵",
    },
}

-- ══════════════════════════════════════
--  HELPER: HTTP GET
-- ══════════════════════════════════════

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and result and #result > 0 then
        return result
    end
    -- fallback untuk executor lain
    local req = (syn and syn.request)
             or (http and http.request)
             or http_request
             or request
    if req then
        local res = req({ Url = url, Method = "GET" })
        if res and res.StatusCode == 200 then
            return res.Body
        end
    end
    return nil
end

-- ══════════════════════════════════════
--  HELPER: JALANKAN TOOL
-- ══════════════════════════════════════

local loaded = {} -- track tool yang sudah diload

local function runSingleUrl(url, label)
    local source = httpGet(url)
    if not source then
        warn("[Loader] Gagal mengunduh: " .. label)
        return false
    end
    local fn, err = loadstring(source, label)
    if not fn then
        warn("[Loader] Gagal compile " .. label .. ": " .. tostring(err))
        return false
    end
    local ok, runErr = pcall(fn)
    if not ok then
        warn("[Loader] Error " .. label .. ": " .. tostring(runErr))
        return false
    end
    return true
end

local function runTool(tool)
    -- Cek apakah sudah pernah diload
    if loaded[tool.name] then
        warn("[Loader] " .. tool.name .. " sudah dijalankan sebelumnya, skip.")
        return
    end

    -- Multi-load (misal: AdvancedDecompiler + Dex secara berurutan)
    if tool._multi then
        print("[Loader] Multi-load: " .. tool.name)
        for i, url in ipairs(tool._multi) do
            print("[Loader] Step " .. i .. ": " .. url:match("[^/]+$"))
            local ok = runSingleUrl(url, url:match("[^/]+$"))
            if not ok and i < #tool._multi then
                warn("[Loader] Step " .. i .. " gagal, melanjutkan ke step berikutnya...")
            end
            if i < #tool._multi then task.wait(0.3) end
        end
        loaded[tool.name] = true
        print("[Loader] ✓ " .. tool.name .. " selesai!")
        return
    end

    print("[Loader] Mengunduh: " .. tool.name .. " ...")

    local source = httpGet(tool.url)

    if not source then
        warn("[Loader] Gagal mengunduh: " .. tool.name)
        return
    end

    local fn, err = loadstring(source, tool.name)
    if not fn then
        warn("[Loader] Gagal compile " .. tool.name .. ": " .. tostring(err))
        return
    end

    local ok, runErr = pcall(fn)
    if not ok then
        warn("[Loader] Error saat menjalankan " .. tool.name .. ": " .. tostring(runErr))
        return
    end

    loaded[tool.name] = true
    print("[Loader] ✓ " .. tool.name .. " berhasil dijalankan!")
end

-- ══════════════════════════════════════
--  UI: BUAT MENU
-- ══════════════════════════════════════

-- Hapus loader lama jika ada
local existingGui = game:GetService("CoreGui"):FindFirstChild("InfyiffLoader")
if existingGui then existingGui:Destroy() end

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- ── Root ScreenGui ──────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "InfyiffLoader"
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn    = false
ScreenGui.DisplayOrder    = 999
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = lp.PlayerGui end

-- ── Warna & konstanta ────────────────
local C = {
    BG        = Color3.fromRGB(18, 18, 24),
    PANEL     = Color3.fromRGB(26, 26, 34),
    CARD      = Color3.fromRGB(34, 34, 46),
    CARD_HOV  = Color3.fromRGB(44, 44, 60),
    ACCENT    = Color3.fromRGB(120, 80, 255),
    ACCENT2   = Color3.fromRGB(80, 180, 255),
    TEXT      = Color3.fromRGB(220, 220, 235),
    TEXT_DIM  = Color3.fromRGB(130, 130, 155),
    SUCCESS   = Color3.fromRGB(80, 210, 130),
    WARNING   = Color3.fromRGB(255, 170, 60),
    CLOSE     = Color3.fromRGB(255, 75, 75),
}

local CARD_H    = 62
local CARD_PAD  = 7
local MENU_W    = 380
local MENU_H    = 500

-- ── Fungsi bantu UI ─────────────────
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function newLabel(parent, text, size, color, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text      = text
    l.TextSize  = size
    l.TextColor3 = color
    l.Font      = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent    = parent
    if props then for k,v in pairs(props) do l[k] = v end end
    return l
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- ── Main Frame ──────────────────────
local Main = Instance.new("Frame")
Main.Name               = "Main"
Main.Size               = UDim2.new(0, MENU_W, 0, MENU_H)
Main.Position           = UDim2.new(0.5, -MENU_W/2, 0.5, -MENU_H/2)
Main.BackgroundColor3   = C.BG
Main.BorderSizePixel    = 0
Main.Parent             = ScreenGui
corner(Main, 12)

-- Shadow/stroke
local stroke = Instance.new("UIStroke")
stroke.Color     = C.ACCENT
stroke.Thickness = 1.5
stroke.Transparency = 0.5
stroke.Parent = Main

-- ── Header ──────────────────────────
local Header = Instance.new("Frame")
Header.Name             = "Header"
Header.Size             = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = C.PANEL
Header.BorderSizePixel  = 0
Header.Parent           = Main
corner(Header, 12)

-- Fix corner bawah header
local HeaderFix = Instance.new("Frame")
HeaderFix.Size              = UDim2.new(1, 0, 0, 12)
HeaderFix.Position          = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3  = C.PANEL
HeaderFix.BorderSizePixel   = 0
HeaderFix.Parent            = Header

-- Accent bar kiri
local AccentBar = Instance.new("Frame")
AccentBar.Size              = UDim2.new(0, 4, 0, 28)
AccentBar.Position          = UDim2.new(0, 14, 0.5, -14)
AccentBar.BackgroundColor3  = C.ACCENT
AccentBar.BorderSizePixel   = 0
AccentBar.Parent            = Header
corner(AccentBar, 2)

local TitleLabel = newLabel(Header, "INFYIFF LOADER", 15, C.TEXT, {
    Size     = UDim2.new(1, -120, 1, 0),
    Position = UDim2.new(0, 28, 0, 0),
    TextYAlignment = Enum.TextYAlignment.Center,
})

local SubLabel = newLabel(Header, "Script Menu", 11, C.TEXT_DIM, {
    Size     = UDim2.new(1, -120, 0, 14),
    Position = UDim2.new(0, 28, 0, 32),
})

-- Badge jumlah tool
local Badge = Instance.new("TextLabel")
Badge.Size               = UDim2.new(0, 38, 0, 20)
Badge.Position           = UDim2.new(0, 28 + 130, 0.5, -10)
Badge.BackgroundColor3   = C.ACCENT
Badge.TextColor3         = Color3.new(1,1,1)
Badge.Text               = tostring(#TOOLS) .. " tools"
Badge.TextSize           = 10
Badge.Font               = Enum.Font.GothamBold
Badge.BorderSizePixel    = 0
Badge.Parent             = Header
corner(Badge, 10)

-- Tombol minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Size               = UDim2.new(0, 28, 0, 28)
MinBtn.Position           = UDim2.new(1, -66, 0.5, -14)
MinBtn.BackgroundColor3   = C.CARD
MinBtn.Text               = "─"
MinBtn.TextColor3         = C.TEXT_DIM
MinBtn.TextSize           = 14
MinBtn.Font               = Enum.Font.GothamBold
MinBtn.BorderSizePixel    = 0
MinBtn.Parent             = Header
corner(MinBtn, 6)

-- Tombol close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size               = UDim2.new(0, 28, 0, 28)
CloseBtn.Position           = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3   = C.CLOSE
CloseBtn.Text               = "✕"
CloseBtn.TextColor3         = Color3.new(1,1,1)
CloseBtn.TextSize           = 13
CloseBtn.Font               = Enum.Font.GothamBold
CloseBtn.BorderSizePixel    = 0
CloseBtn.Parent             = Header
corner(CloseBtn, 6)

-- ── Status bar ──────────────────────
local StatusBar = Instance.new("Frame")
StatusBar.Name             = "StatusBar"
StatusBar.Size             = UDim2.new(1, -20, 0, 28)
StatusBar.Position         = UDim2.new(0, 10, 0, 58)
StatusBar.BackgroundColor3 = C.PANEL
StatusBar.BorderSizePixel  = 0
StatusBar.Parent           = Main
corner(StatusBar, 6)

local StatusDot = Instance.new("Frame")
StatusDot.Size              = UDim2.new(0, 8, 0, 8)
StatusDot.Position          = UDim2.new(0, 10, 0.5, -4)
StatusDot.BackgroundColor3  = C.SUCCESS
StatusDot.BorderSizePixel   = 0
StatusDot.Parent            = StatusBar
corner(StatusDot, 4)

local StatusLabel = newLabel(StatusBar, "Siap • Pilih tool dari daftar di bawah", 11, C.TEXT_DIM, {
    Size     = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 26, 0, 0),
    TextYAlignment = Enum.TextYAlignment.Center,
    Font     = Enum.Font.Gotham,
})

local function setStatus(msg, color)
    StatusLabel.Text = msg
    StatusDot.BackgroundColor3 = color or C.SUCCESS
end

-- ── Category tabs ───────────────────
local categories = {}
for _, t in ipairs(TOOLS) do
    if not table.find(categories, t.category) then
        table.insert(categories, t.category)
    end
end
table.insert(categories, 1, "Semua")

local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -20, 0, 30)
TabBar.Position         = UDim2.new(0, 10, 0, 94)
TabBar.BackgroundTransparency = 1
TabBar.Parent           = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding       = UDim.new(0, 6)
TabLayout.Parent        = TabBar

local activeCategory = "Semua"
local tabButtons     = {}

-- ── Scroll area ─────────────────────
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name                = "ToolList"
ScrollFrame.Size                = UDim2.new(1, -20, 1, -138)
ScrollFrame.Position            = UDim2.new(0, 10, 0, 132)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel     = 0
ScrollFrame.ScrollBarThickness  = 4
ScrollFrame.ScrollBarImageColor3 = C.ACCENT
ScrollFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent              = Main

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding      = UDim.new(0, CARD_PAD)
ListLayout.SortOrder    = Enum.SortOrder.LayoutOrder
ListLayout.Parent       = ScrollFrame

-- ── Fungsi: render ulang daftar tool ─
local toolCards = {}

local function renderTools(categoryFilter)
    -- Bersihkan cards lama
    for _, c in ipairs(toolCards) do c:Destroy() end
    toolCards = {}

    local order = 0
    local prevCat = nil

    for _, tool in ipairs(TOOLS) do
        if categoryFilter == "Semua" or tool.category == categoryFilter then

            -- Category separator
            if tool.category ~= prevCat then
                prevCat = tool.category
                local sep = Instance.new("Frame")
                sep.Size              = UDim2.new(1, 0, 0, 22)
                sep.BackgroundTransparency = 1
                sep.LayoutOrder       = order
                sep.Parent            = ScrollFrame
                table.insert(toolCards, sep)
                order += 1

                local sepLabel = newLabel(sep, "▸  " .. tool.category:upper(), 10, C.ACCENT, {
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            end

            -- Card tool
            local Card = Instance.new("TextButton")
            Card.Name               = tool.name
            Card.Size               = UDim2.new(1, 0, 0, CARD_H)
            Card.BackgroundColor3   = C.CARD
            Card.Text               = ""
            Card.BorderSizePixel    = 0
            Card.LayoutOrder        = order
            Card.AutoButtonColor    = false
            Card.Parent             = ScrollFrame
            corner(Card, 8)
            table.insert(toolCards, Card)
            order += 1

            -- Icon bubble
            local IconBg = Instance.new("Frame")
            IconBg.Size              = UDim2.new(0, 38, 0, 38)
            IconBg.Position          = UDim2.new(0, 10, 0.5, -19)
            IconBg.BackgroundColor3  = C.BG
            IconBg.BorderSizePixel   = 0
            IconBg.Parent            = Card
            corner(IconBg, 8)

            local IconLabel = Instance.new("TextLabel")
            IconLabel.Size               = UDim2.new(1, 0, 1, 0)
            IconLabel.BackgroundTransparency = 1
            IconLabel.Text               = tool.icon
            IconLabel.TextSize           = 18
            IconLabel.Font               = Enum.Font.Gotham
            IconLabel.TextColor3         = C.TEXT
            IconLabel.TextXAlignment     = Enum.TextXAlignment.Center
            IconLabel.TextYAlignment     = Enum.TextYAlignment.Center
            IconLabel.Parent             = IconBg

            -- Nama tool
            local NameLabel = newLabel(Card, tool.name, 13, C.TEXT, {
                Size     = UDim2.new(1, -120, 0, 18),
                Position = UDim2.new(0, 58, 0, 12),
            })

            -- Deskripsi
            local DescLabel = newLabel(Card, tool.desc, 11, C.TEXT_DIM, {
                Size     = UDim2.new(1, -120, 0, 14),
                Position = UDim2.new(0, 58, 0, 32),
                Font     = Enum.Font.Gotham,
            })

            -- Run button
            local RunBtn = Instance.new("TextButton")
            RunBtn.Size              = UDim2.new(0, 60, 0, 26)
            RunBtn.Position          = UDim2.new(1, -72, 0.5, -13)
            RunBtn.BackgroundColor3  = C.ACCENT
            RunBtn.Text              = "Run"
            RunBtn.TextColor3        = Color3.new(1,1,1)
            RunBtn.TextSize          = 12
            RunBtn.Font              = Enum.Font.GothamBold
            RunBtn.BorderSizePixel   = 0
            RunBtn.Parent            = Card
            corner(RunBtn, 6)

            -- Tandai jika sudah diload
            if loaded[tool.name] then
                RunBtn.BackgroundColor3 = C.SUCCESS
                RunBtn.Text = "✓ Done"
            end

            -- Hover efek card
            Card.MouseEnter:Connect(function()
                tween(Card, { BackgroundColor3 = C.CARD_HOV })
            end)
            Card.MouseLeave:Connect(function()
                tween(Card, { BackgroundColor3 = loaded[tool.name] and C.CARD or C.CARD })
            end)

            -- Hover efek run btn
            RunBtn.MouseEnter:Connect(function()
                if not loaded[tool.name] then
                    tween(RunBtn, { BackgroundColor3 = C.ACCENT2 })
                end
            end)
            RunBtn.MouseLeave:Connect(function()
                if not loaded[tool.name] then
                    tween(RunBtn, { BackgroundColor3 = C.ACCENT })
                end
            end)

            -- Klik run
            local function doRun()
                if loaded[tool.name] then
                    setStatus("⚠  " .. tool.name .. " sudah dijalankan", C.WARNING)
                    return
                end

                RunBtn.Text = "..."
                RunBtn.BackgroundColor3 = C.WARNING
                setStatus("⏳  Mengunduh " .. tool.name .. " ...", C.WARNING)
                StatusDot.BackgroundColor3 = C.WARNING

                task.spawn(function()
                    runTool(tool)
                    if loaded[tool.name] then
                        RunBtn.Text             = "✓ Done"
                        RunBtn.BackgroundColor3 = C.SUCCESS
                        setStatus("✓  " .. tool.name .. " berhasil dijalankan!", C.SUCCESS)
                    else
                        RunBtn.Text             = "✗ Gagal"
                        RunBtn.BackgroundColor3 = C.CLOSE
                        setStatus("✗  Gagal menjalankan " .. tool.name, C.CLOSE)
                    end
                end)
            end

            Card.MouseButton1Click:Connect(doRun)
            RunBtn.MouseButton1Click:Connect(doRun)
        end
    end

    -- Update canvas height
    ListLayout:ApplyLayout()
    task.defer(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end)
end

-- ── Buat tab buttons ─────────────────
for _, cat in ipairs(categories) do
    local tab = Instance.new("TextButton")
    tab.Size               = UDim2.new(0, 0, 1, 0)
    tab.AutomaticSize      = Enum.AutomaticSize.X
    tab.BackgroundColor3   = cat == "Semua" and C.ACCENT or C.CARD
    tab.Text               = "  " .. cat .. "  "
    tab.TextColor3         = cat == "Semua" and Color3.new(1,1,1) or C.TEXT_DIM
    tab.TextSize           = 11
    tab.Font               = Enum.Font.GothamBold
    tab.BorderSizePixel    = 0
    tab.Parent             = TabBar
    corner(tab, 6)
    tabButtons[cat] = tab

    tab.MouseButton1Click:Connect(function()
        activeCategory = cat
        -- Update semua tab
        for c, btn in pairs(tabButtons) do
            if c == cat then
                tween(btn, { BackgroundColor3 = C.ACCENT })
                btn.TextColor3 = Color3.new(1,1,1)
            else
                tween(btn, { BackgroundColor3 = C.CARD })
                btn.TextColor3 = C.TEXT_DIM
            end
        end
        renderTools(cat)
    end)
end

-- ── Tombol close & minimize ──────────
CloseBtn.MouseButton1Click:Connect(function()
    tween(Main, { Size = UDim2.new(0, MENU_W, 0, 0), Position = UDim2.new(0.5, -MENU_W/2, 0.5, 0) }, 0.2)
    task.delay(0.22, function() ScreenGui:Destroy() end)
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(Main, { Size = UDim2.new(0, MENU_W, 0, 52) }, 0.2)
    else
        tween(Main, { Size = UDim2.new(0, MENU_W, 0, MENU_H) }, 0.2)
    end
end)

-- ── Drag ─────────────────────────────
do
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Render awal ──────────────────────
renderTools("Semua")

-- ── Animasi masuk ────────────────────
Main.Size = UDim2.new(0, MENU_W, 0, 0)
tween(Main, { Size = UDim2.new(0, MENU_W, 0, MENU_H) }, 0.25)

print([[
╔══════════════════════════════════╗
║    INFYIFF LOADER - Aktif!       ║
║    ]] .. #TOOLS .. [[ tools tersedia           ║
╚══════════════════════════════════╝
]])
