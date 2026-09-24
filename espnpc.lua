-- ============================================
-- ESP JUGADORES + MOBS/NPCs v5.0 ULTRA DIOS PRO MAX (2025)
-- ============================================

-- === CONFIGURACIÓN ===
local defaultHighlightColor = Color3.fromRGB(255, 255, 255)
local outlineColor          = Color3.fromRGB(0, 0, 0)
local fillTransparency      = 0.5
local outlineTransparency   = 0
local maxDistance           = 3000   -- 🔥 Más distancia
local updateSpeed           = 0.3    -- 🔥 Balance entre fluidez y rendimiento

-- 🎨 Colores
local NPC_COLOR        = Color3.fromRGB(255, 80, 80)
local NPC_OUTLINE      = Color3.fromRGB(255, 0, 0)
local BOSS_COLOR       = Color3.fromRGB(180, 0, 255)
local BOSS_OUTLINE     = Color3.fromRGB(120, 0, 200)

-- 📏 Tamaño mínimo
local MIN_MOB_SIZE = 1.5

-- 🔥 Límite de Highlights (Roblox solo renderiza 31)
local MAX_HIGHLIGHTS = 30
local highlightCount = 0

-- Tablas
local playerDistances = {}
local npcDistances = {}
local activeHighlights = {}  -- 🔥 Para controlar el límite

-- ============================================
-- 🎨 COLORES POR EQUIPO
-- ============================================
local function getHighlightColor(player)
    local team = player.Team
    if team then
        return team.TeamColor.Color
    else
        return defaultHighlightColor
    end
end

-- ============================================
-- 🔥 SISTEMA DE PRIORIDAD DE HIGHLIGHTS
-- ============================================
local function canAddHighlight()
    return highlightCount < MAX_HIGHLIGHTS
end

local function registerHighlight(obj)
    if activeHighlights[obj] then return true end
    if not canAddHighlight() then return false end
    activeHighlights[obj] = true
    highlightCount = highlightCount + 1
    return true
end

local function unregisterHighlight(obj)
    if activeHighlights[obj] then
        activeHighlights[obj] = nil
        highlightCount = math.max(0, highlightCount - 1)
    end
end

-- ============================================
-- 👤 HIGHLIGHT DE JUGADORES
-- ============================================
local function createHighlight(player)
    local character = player.Character
    if not character then return end
    if character:FindFirstChild("PlayerHighlight") then return end

    if not registerHighlight(character) then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerHighlight"
    highlight.Adornee = character
    highlight.FillColor = getHighlightColor(player)
    highlight.OutlineColor = outlineColor
    highlight.FillTransparency = fillTransparency
    highlight.OutlineTransparency = outlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
end

local function removeHighlight(player)
    local character = player.Character
    if character then
        local highlight = character:FindFirstChild("PlayerHighlight")
        if highlight then
            highlight:Destroy()
            unregisterHighlight(character)
        end
    end
end

-- ============================================
-- 👹 DETECCIÓN DE MOBS (MEJORADA Y FLEXIBLE)
-- ============================================
local function esMob(obj)
    if not (obj:IsA("Model") or obj:IsA("Folder")) then return false end
    if game.Players:GetPlayerFromCharacter(obj) then return false end

    -- 🔥 Filtro de blacklist básico
    local nombre = string.lower(obj.Name)
    if string.find(nombre, "tool") or string.find(nombre, "handle")
       or string.find(nombre, "bullet") or string.find(nombre, "projectile")
       or string.find(nombre, "effect") or string.find(nombre, "particle") then
        return false
    end

    -- 🔥 Humanoid opcional
    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end

    -- 🔥 Buscar raíz flexible
    local root = obj:FindFirstChild("HumanoidRootPart")
        or obj.PrimaryPart
        or obj:FindFirstChildOfClass("Part")
        or obj:FindFirstChildOfClass("BasePart")

    if not root then
        for _, v in ipairs(obj:GetChildren()) do
            if v:IsA("BasePart") then
                root = v
                break
            end
        end
    end

    if not root then return false end
    if root:IsA("BasePart") and root.Size.Magnitude < MIN_MOB_SIZE then
        return false
    end

    return true, root
end

-- Detectar jefe
local function esJefe(obj)
    local nombre = string.lower(obj.Name)
    local palabras = {
        "boss", "jefe", "king", "lord", "elite", "champion",
        "titan", "giant", "demon", "dragon", "god", "legend",
        "mythic", "epic", "ancient", "elder", "guardian"
    }
    for _, palabra in ipairs(palabras) do
        if string.find(nombre, palabra) then
            return true
        end
    end

    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
    if root and root.Size.Magnitude > 15 then
        return true
    end
    return false
end

-- ============================================
-- 🎯 CREAR HIGHLIGHT DE NPC
-- ============================================
local function createNpcHighlight(obj)
    if obj:FindFirstChild("NpcHighlight") then return end
    if not registerHighlight(obj) then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "NpcHighlight"
    highlight.Adornee = obj
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    if esJefe(obj) then
        highlight.FillColor = BOSS_COLOR
        highlight.OutlineColor = BOSS_OUTLINE
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
    else
        highlight.FillColor = NPC_COLOR
        highlight.OutlineColor = NPC_OUTLINE
        highlight.FillTransparency = fillTransparency
        highlight.OutlineTransparency = outlineTransparency
    end

    highlight.Parent = obj
end

local function removeNpcHighlight(obj)
    local h = obj:FindFirstChild("NpcHighlight")
    if h then
        h:Destroy()
        unregisterHighlight(obj)
    end
end

-- ============================================
-- 🔄 ACTUALIZAR HIGHLIGHTS DE JUGADORES
-- ============================================
local function updatePlayerHighlights()
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter or not localCharacter.PrimaryPart then return end

    local localPosition = localCharacter.PrimaryPart.Position

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            if character and character.PrimaryPart then
                local distance = (localPosition - character.PrimaryPart.Position).Magnitude
                playerDistances[player] = distance

                if distance <= maxDistance then
                    createHighlight(player)
                else
                    removeHighlight(player)
                end
            end
        end
    end
end

-- ============================================
-- 🔄 ACTUALIZAR HIGHLIGHTS DE MOBS / NPCs
-- ============================================
local function updateNpcHighlights()
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter or not localCharacter.PrimaryPart then return end

    local localPosition = localCharacter.PrimaryPart.Position
    local actuales = {}
    local candidatos = {}

    -- 🔥 FASE 1: Recoger todos los mobs candidatos con su distancia
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local valido, root = esMob(obj)
            if valido and root then
                local distance = (localPosition - root.Position).Magnitude
                if distance <= maxDistance then
                    table.insert(candidatos, {obj = obj, dist = distance, root = root})
                end
            end
        end
    end

    -- 🔥 FASE 2: Ordenar por distancia (más cercanos primero)
    table.sort(candidatos, function(a, b) return a.dist < b.dist end)

    -- 🔥 FASE 3: Aplicar highlight a los más cercanos
    for _, data in ipairs(candidatos) do
        local obj = data.obj
        if not obj:FindFirstChild("NpcHighlight") then
            if canAddHighlight() then
                createNpcHighlight(obj)
            else
                -- 🔥 Si no hay espacio, al menos no crashea
                break
            end
        end
        actuales[obj] = true
        npcDistances[obj] = data.dist
    end

    -- 🔥 FASE 4: Limpiar los que ya no están
    for obj, _ in pairs(npcDistances) do
        if not actuales[obj] or not obj.Parent then
            if obj and obj.Parent then
                removeNpcHighlight(obj)
            end
            npcDistances[obj] = nil
        end
    end
end

-- ============================================
-- 📡 EVENTOS DE JUGADORES
-- ============================================
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createHighlight(player)
    end)
    player.CharacterRemoving:Connect(function()
        removeHighlight(player)
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
    playerDistances[player] = nil
end)

-- ============================================
-- 🔁 BUCLE PRINCIPAL
-- ============================================
task.spawn(function()
    while task.wait(updateSpeed) do
        pcall(updatePlayerHighlights)
        pcall(updateNpcHighlights)
    end
end)

print("[m6c ESP v5.0 ULTRA DIOS PRO MAX] Cargado ✅ | Distancia: " .. maxDistance .. " | Update: " .. updateSpeed .. "s")
