AddCSLuaFile()

-- ConVar
if !ConVarExists("ph_rotation_support") then
    local ph_rotation_support = CreateConVar(
        "ph_rotation_support",
        "1",
        {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}
    )
end

if SERVER then

    -- Player spawns
    local function PROPHUNTROTHOOK_PlayerSpawn(pl)
        if GetConVar("ph_rotation_support"):GetBool() && pl:Team() == TEAM_PROPS then
            pl.lockRotation = false
            pl.usesNewRotation = false
            
            timer.Simple(0.1, function() 
                if IsValid(pl) then 
                    PROPHUNTROT_PostPlayerSpawn(pl) 
                end 
            end)
        end
    end
    hook.Add("PlayerSpawn", "PROPHUNTROTHOOK_PlayerSpawn", PROPHUNTROTHOOK_PlayerSpawn)

    -- Think hook for updating prop angles/position
    local function PROPHUNTROTHOOK_Think()
        if !GetConVar("ph_rotation_support"):GetBool() then return end

        for _, pl in pairs(team.GetPlayers(TEAM_PROPS)) do
            if not pl:IsValid() or not pl:Alive() or not pl.usesNewRotation then continue end
            local prop = pl.ph_prop
            if not prop or not prop:IsValid() then continue end

            -- Update position
            if prop:GetModel() == "models/player/kleiner.mdl" then
                prop:SetPos(pl:GetPos())
            else
                prop:SetPos(pl:GetPos() - Vector(0,0,prop:OBBMins().z))
            end

            -- Update angles (always upright)
            local ang = prop:GetAngles()
            ang.pitch = 0
            ang.roll = 0

            if not pl.lockRotation then
                ang.yaw = pl:EyeAngles().yaw -- update yaw only when unlocked
            end

            prop:SetAngles(ang)

            -- Check R key for toggling lock
            if pl:KeyPressed(IN_RELOAD) then
                pl.lockRotation = not pl.lockRotation
                pl:ChatPrint("Locked Rotation: "..string.upper(tostring(pl.lockRotation)))
            end
        end
    end
    hook.Add("Think", "PROPHUNTROTHOOK_Think", PROPHUNTROTHOOK_Think)

    -- Post player spawn setup
    function PROPHUNTROT_PostPlayerSpawn(pl)
        local prop = pl.ph_prop
        if not pl:Alive() or not prop or not prop:IsValid() then return end

        if prop:GetParent() and prop:GetParent():IsValid() then
            prop:SetParent(nil)
        end

        pl.usesNewRotation = true
        pl:ChatPrint("Press the reload button to lock your rotation.")
    end

    -- ConVar change callback
    local function PROPHUNTROT_RotationSupportChanged(name, old, new)
        PrintMessage(HUD_PRINTTALK, "Warning: ph_rotation_support changed. Bugs may occur!")

        for _, pl in pairs(team.GetPlayers(TEAM_PROPS)) do
            local prop = pl.ph_prop
            if not pl:IsValid() or not pl:Alive() or not prop or not prop:IsValid() then continue end

            if pl.usesNewRotation then
                pl.lockRotation = false
                pl.usesNewRotation = false
                prop:SetParent(pl)
            else
                if prop:GetParent() and prop:GetParent():IsValid() then
                    prop:SetParent(nil)
                end
                pl.usesNewRotation = true
                pl:ChatPrint("Press the reload button to lock your rotation.")
            end
        end
    end
    cvars.AddChangeCallback("ph_rotation_support", PROPHUNTROT_RotationSupportChanged)
end