local dummy = script.Parent
local humanoid = dummy:WaitForChild("Humanoid")
local rootPart = dummy:WaitForChild("HumanoidRootPart")

-- ==========================================
-- CONFIGURAÇÕES DA IA
-- ==========================================
local DetectionRange = 40
local AttackRange = 5
local Damage = 15

local canAttack = true
local isFollowing = false

-- ==========================================
-- FUNÇÕES AUXILIARES
-- ==========================================

-- Busca o jogador vivo mais próximo no servidor
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (rootPart.Position - targetRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player.Character
                end
            end
        end
    end
    
    return closestPlayer, shortestDistance
end

-- Pisca o Dummy de vermelho para dar feedback visual do ataque
local function flashRed()
    local originalColors = {}
    
    -- Salva as cores e pinta de vermelho
    for _, part in ipairs(dummy:GetChildren()) do
        if part:IsA("BasePart") then
            originalColors[part] = part.Color
            part.Color = Color3.fromRGB(255, 0, 0) -- Vermelho
        end
    end
    
    -- Volta as cores normais depois de 0.3 segundos
    task.delay(0.3, function()
        for part, color in pairs(originalColors) do
            if part and part.Parent then
                part.Color = color
            end
        end
    end)
end

-- ==========================================
-- LOOP PRINCIPAL DE INTELIGÊNCIA
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.1) -- Roda 10x por segundo para não sobrecarregar o servidor
        
        -- Se o Dummy morrer, desliga a IA
        if humanoid.Health <= 0 then break end 
        
        local target, distance = getClosestPlayer()
        
        if target and distance <= DetectionRange then
            local targetRoot = target:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = target:FindFirstChild("Humanoid")
            
            -- Verifica se está perto o suficiente para atacar
            if distance <= AttackRange then
                -- Para de andar para atacar
                humanoid:MoveTo(rootPart.Position) 
                
                if canAttack then
                    canAttack = false
                    print("Dummy acertou um ataque no jogador!")
                    
                    -- Feedback Visual e Dano
                    flashRed()
                    targetHumanoid:TakeDamage(Damage)
                    
                    -- Tempo de recarga do ataque
                    task.wait(1.5)
                    canAttack = true
                end
                
            else
                -- Está no alcance de visão, mas não de ataque: Seguir!
                if not isFollowing then
                    isFollowing = true
                    print("Dummy começou a seguir o jogador!")
                end
                
                -- Se não estiver no meio do tempo de ataque, anda em direção ao jogador
                if canAttack then
                    humanoid:MoveTo(targetRoot.Position)
                end
            end
            
        else
            -- Jogador saiu do alcance de detecção ou morreu
            if isFollowing then
                isFollowing = false
                print("Dummy perdeu o alvo e parou.")
                humanoid:MoveTo(rootPart.Position) -- Para o Dummy onde ele está
            end
        end
    end
end)
