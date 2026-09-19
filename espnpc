-- ============================================
-- ESP JUGADORES + MOBS/NPCs (Bots) 2025
-- ============================================

-- === CONFIGURACIÓN ===
local defaultHighlightColor = Color3.fromRGB(255, 255, 255) -- blanco para jugadores sin team
local outlineColor          = Color3.fromRGB(0, 0, 0)
local fillTransparency      = 0.5
local outlineTransparency   = 0
local maxDistance           = 500

-- 🎨 Colores para mobs/NPCs (puedes cambiarlos)
local NPC_COLOR        = Color3.fromRGB(255, 80, 80)   -- rojo (enemigos)
local NPC_OUTLINE      = Color3.fromRGB(255, 0, 0)
local BOSS_COLOR       = Color3.fromRGB(180, 0, 255)   -- morado (jefes)
local BOSS_OUTLINE     = Color3.fromRGB(120, 0, 200)

-- 📏 Tamaño mínimo para considerar algo como "mob" (evita basura)
local MIN_MOB_SIZE = 2

-- Tabla para guardar distancias (optimización)
local playerDistances = {}
local npcDistances = {}

-- ============================================
-- 🎨 COLORES POR EQUIPO (JUGADORES)
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
-- 👤 HIGHLIGHT DE JUGADORES
-- ============================================
local function createHighlight(player)
    local character = player.Character or player.CharacterAdded:Wait()
    if character and not character:FindFirstChild("PlayerHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerHighlight"
        highlight.Adornee = character
        highlight.FillColor = getHighlightColor(player)
        highlight.OutlineColor = outlineColor
        highlight.FillTransparency = fillTransparency
        highlight.OutlineTransparency = outlineTransparency
        highlight.Parent = character
    end
end

local function removeHighlight(player)
    local character = player.Character
    if character then
        local highlight = character:FindFirstChild("PlayerHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

-- ============================================
-- 👹 DETECCIÓN DE MOBS / NPCs
-- ============================================
-- Función que decide si un objeto es un "mob" válido
local function esMob(obj)
    -- Tiene que ser Model o Folder
    if not (obj:IsA("Model") or obj:IsA("Folder")) then return false end

    -- No debe ser un jugador (ya los manejamos aparte)
    if game.Players:GetPlayerFromCharacter(obj) then return false end

    -- Debe tener un Humanoid (esto filtra armas, partes, decoraciones)
    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    -- Debe tener vida (algunos Humanoid están muertos)
    if humanoid.Health <= 0 then return false end

    -- Debe tener una parte principal para calcular distancia
    local root = obj:FindFirstChild("HumanoidRootPart")
        or obj.PrimaryPart
        or obj:FindFirstChildOfClass("Part")
    if not root then return false end

    return true
end

-- Detecta si un mob es "jefe" (por nombre o tamaño)
local function esJefe(obj)
    -- Por nombre
    local nombre = string.lower(obj.Name)
    if string.find(nombre, "boss") or string.find(nombre, "jefe") 
       or string.find(nombre, "king") or string.find(nombre, "lord")
       or string.find(nombre, "elite") or string.find(nombre, "champion") then
        return true
    end
    -- Por tamaño (si su PrimaryPart es enorme)
    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
    if root and root.Size.Magnitude > 15 then
        return true
    end
    return false
end

-- Crea highlight en un mob
local function createNpcHighlight(obj)
    if obj:FindFirstChild("NpcHighlight") then return end

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

-- Quita highlight de un mob
local function removeNpcHighlight(obj)
    local h = obj:FindFirstChild("NpcHighlight")
    if h then h:Destroy() end
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

    -- Recorremos TODO el Workspace buscando mobs
    for _, obj in ipairs(workspace:GetDescendants()) do
        if esMob(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart") 
                      or obj.PrimaryPart 
                      or obj:FindFirstChildOfClass("Part")
            if root then
                local distance = (localPosition - root.Position).Magnitude
                npcDistances[obj] = distance

                if distance <= maxDistance then
                    createNpcHighlight(obj)
                    actuales[obj] = true
                end
            end
        end
    end

    -- Limpiamos highlights de mobs que ya no están o están lejos
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
        task.wait()
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
spawn(function()
    while task.wait(0.5) do
        updatePlayerHighlights()
        updateNpcHighlights()
    end
end)
