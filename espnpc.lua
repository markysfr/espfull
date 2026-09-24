-- ============================================
-- ESP v7.0 AUTO-DETECT | Detección Universal | Sin lag
-- ============================================

-- === CONFIGURACIÓN ===
local defaultHighlightColor = Color3.fromRGB(255, 255, 255)
local outlineColor          = Color3.fromRGB(0, 0, 0)
local fillTransparency      = 0.5
local outlineTransparency   = 0
local maxDistance           = 5000
local updateSpeed           = 0.3

-- 🎨 Colores
local NPC_COLOR        = Color3.fromRGB(255, 80, 80)
local NPC_OUTLINE      = Color3.fromRGB(255, 0, 0)
local BOSS_COLOR       = Color3.fromRGB(180, 0, 255)
local BOSS_OUTLINE     = Color3.fromRGB(120, 0, 200)

-- 🔥 Límite de Highlights
local MAX_HIGHLIGHTS = 30
local highlightCount = 0

-- Tablas
local playerDistances = {}
local npcDistances = {}
local activeHighlights = {}
local nombresDetectados = {}  -- 🔥 Para auto-aprender qué nombres son mobs

-- ============================================
-- 🎨 COLORES POR EQUIPO
-- ============================================
local function getHighlightColor(player)
    local team = player.Team
    if team then return team.TeamColor.Color end
    return defaultHighlightColor
end

-- ============================================
-- 🔥 SISTEMA DE PRIORIDAD
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
        local h = character:FindFirstChild("PlayerHighlight")
        if h then h:Destroy(); unregisterHighlight(character) end
    end
end

-- ============================================
-- 🧠 AUTO-DETECT: SISTEMA DE APRENDIZAJE
-- ============================================
-- 🔥 Blacklist universal
local BLACKLIST = {
    "tool", "handle", "bullet", "projectile", "effect", "particle",
    "debris", "hitbox", "weapon", "gun", "sword", "knife", "ammo",
    "base", "spawn", "checkpoint", "trigger", "zone", "region",
    "sound", "music", "light", "beam", "trail", "smoke", "fire",
    "camera", "terrain", "water", "grass", "tree", "rock", "bush",
    "house", "building", "wall", "floor", "door", "window", "prop",
    "decoration", "furniture", "sign", "flag", "banner", "statue"
}

local function enBlacklist(nombre)
    local n = string.lower(nombre)
    for _, palabra in ipairs(BLACKLIST) do
        if string.find(n, palabra) then return true end
    end
    return false
end

-- 🔥 Comprobar si un objeto es un mob por ESTRUCTURA (no por nombre)
local function esMobPorEstructura(obj)
    -- Debe ser Model
    if not obj:IsA("Model") then return false end
    if game.Players:GetPlayerFromCharacter(obj) then return false end
    if enBlacklist(obj.Name) then return false end

    -- 🔥 CRITERIO 1: Tiene Humanoid vivo (el más fiable)
    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
        if root then return true, root end
    end

    -- 🔥 CRITERIO 2: Tiene HumanoidRootPart y al menos 2 partes más
    local hrp = obj:FindFirstChild("HumanoidRootPart")
    if hrp then
        local partes = 0
        for _, v in ipairs(obj:GetChildren()) do
            if v:IsA("BasePart") then partes = partes + 1 end
        end
        if partes >= 2 then return true, hrp end
    end

    -- 🔥 CRITERIO 3: Tiene Health (NumberValue) y una raíz
    local health = obj:FindFirstChild("Health")
    if health and health:IsA("NumberValue") and health.Value > 0 then
        local root = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
        if not root then
            for _, v in ipairs(obj:GetChildren()) do
                if v:IsA("BasePart") then root = v; break end
            end
        end
        if root then return true, root end
    end

    -- 🔥 CRITERIO 4: Modelo con >3 partes, PrimaryPart, y que NO sea estático
    local primary = obj.PrimaryPart
    if primary then
        local partes = 0
        for _, v in ipairs(obj:GetChildren()) do
            if v:IsA("BasePart") then partes = partes + 1 end
        end
        -- Si tiene PrimaryPart, >3 partes, y al menos una parte NO está anclada
        if partes >= 3 then
            local tieneNoAnclada = false
            for _, v in ipairs(obj:GetChildren()) do
                if v:IsA("BasePart") and not v.Anchored then
                    tieneNoAnclada = true
                    break
                end
            end
            if tieneNoAnclada then return true, primary end
        end
    end

    return false
end

-- 🔥 Comprobar si un objeto ya ha sido detectado antes (auto-aprendizaje)
local function esNombreConocido(nombre)
    return nombresDetectados[nombre] == true
end

local function registrarNombre(nombre)
    if not nombresDetectados[nombre] then
        nombresDetectados[nombre] = true
        print("[m6c ESP] 🆕 Nuevo mob detectado: " .. nombre)
    end
end

-- 🔥 Detección principal (combina estructura + auto-aprendizaje)
local function esMob(obj)
    if not (obj:IsA("Model") or obj:IsA("Folder")) then return false end
    if game.Players:GetPlayerFromCharacter(obj) then return false end
    if enBlacklist(obj.Name) then return false end

    -- 🔥 Si ya sabemos que este nombre es un mob, lo aceptamos directo
    if esNombreConocido(obj.Name) then
        local root = obj:FindFirstChild("HumanoidRootPart")
            or obj.PrimaryPart
            or obj:FindFirstChildOfClass("BasePart")
        if root then return true, root end
    end

    -- 🔥 Si no, comprobamos por estructura
    local valido, root = esMobPorEstructura(obj)
    if valido then
        registrarNombre(obj.Name)
        return true, root
    end

    return false
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
        if string.find(nombre, palabra) then return true end
    end

    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MaxHealth > 500 then return true end

    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
    if root and root.Size.Magnitude > 15 then return true end
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
    if h then h:Destroy(); unregisterHighlight(obj) end
end

-- ============================================
-- 🔄 ACTUALIZAR JUGADORES
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
-- 🔄 ACTUALIZAR MOBS (con prioridad)
-- ============================================
local function updateNpcHighlights()
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter or not localCharacter.PrimaryPart then return end

    local localPosition = localCharacter.PrimaryPart.Position
    local actuales = {}
    local candidatos = {}

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

    table.sort(candidatos, function(a, b) return a.dist < b.dist end)

    for _, data in ipairs(candidatos) do
        local obj = data.obj
        if not obj:FindFirstChild("NpcHighlight") then
            if canAddHighlight() then
                createNpcHighlight(obj)
            end
        end
        actuales[obj] = true
        npcDistances[obj] = data.dist
    end

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
-- 📡 EVENTOS
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

print("[m6c ESP v7.0 AUTO-DETECT] Cargado ✅ | Distancia: " .. maxDistance)
