local Teleporter = require("components/teleporter")


------------------------------------------------------------
--本文件复制自: 单人传送塔(3389031461) :: 最终来源貌似来自 巨兽掉落加强(2788995386)
------------------------------------------------------------
local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function NoPlayersOrHoles(pt)
    return not (IsAnyPlayerInRange(pt.x, 0, pt.z, 2) or TheWorld.Map:IsPointNearHole(pt))
end

function Teleporter:TravelTeleport(obj, targetTeleporter)
    if targetTeleporter ~= nil then
        local target_x, target_y, target_z = targetTeleporter.Transform:GetWorldPosition()
        local offset = targetTeleporter.components.teleporter ~= nil and targetTeleporter.components.teleporter.offset or 0

        local is_aquatic = obj.components.locomotor ~= nil and obj.components.locomotor:IsAquatic()
        local allow_ocean = is_aquatic or obj.components.amphibiouscreature ~= nil or obj.components.drownable ~= nil

        if targetTeleporter.components.teleporter ~= nil and targetTeleporter.components.teleporter.trynooffset then
            local pt = Vector3(target_x, target_y, target_z)
            if FindWalkableOffset(pt, 0, 0, 1, true, false, NoPlayersOrHoles, allow_ocean) ~= nil then
                offset = 0
            end
        end

        if offset ~= 0 then
            local pt = Vector3(target_x, target_y, target_z)
            local angle = math.random() * 2 * PI

            if not is_aquatic then
                offset = FindWalkableOffset(pt, angle, offset, 8, true, false, NoPlayersOrHoles, allow_ocean) or
                        FindWalkableOffset(pt, angle, offset * .5, 6, true, false, NoPlayersOrHoles, allow_ocean) or
                        FindWalkableOffset(pt, angle, offset, 8, true, false, NoHoles, allow_ocean) or
                        FindWalkableOffset(pt, angle, offset * .5, 6, true, false, NoHoles, allow_ocean)
            else
                offset = FindSwimmableOffset(pt, angle, offset, 8, true, false, NoPlayersOrHoles) or
                        FindSwimmableOffset(pt, angle, offset * .5, 6, true, false, NoPlayersOrHoles) or
                        FindSwimmableOffset(pt, angle, offset, 8, true, false, NoHoles) or
                        FindSwimmableOffset(pt, angle, offset * .5, 6, true, false, NoHoles)
            end

            if offset ~= nil then
                target_x = target_x + offset.x
                target_z = target_z + offset.z
            end
        end

        local ocean_at_point = TheWorld.Map:IsOceanAtPoint(target_x, target_y, target_z, false)
        if ocean_at_point then
            if not allow_ocean then
                local terrestrial = obj.components.locomotor ~= nil and obj.components.locomotor:IsTerrestrial()
                if terrestrial then
                    return
                end
            end
        else
            if is_aquatic then
                return
            end
        end

        if obj.Physics ~= nil then
            obj.Physics:Teleport(target_x, target_y, target_z)
        elseif obj.Transform ~= nil then
            obj.Transform:SetPosition(target_x, target_y, target_z)
        end
    end
end

function Teleporter:Travel(doer, target)
    if self.onActivate ~= nil then
        self.onActivate(self.inst, doer, self.migration_data)
    end

    self:TravelTeleport(doer, target)

    if target ~= nil and target.components.teleporter ~= nil then
        if doer:HasTag("player") then
            target.components.teleporter:ReceivePlayer(doer, self.inst)
        elseif doer.components.inventoryitem ~= nil then
            target.components.teleporter:ReceiveItem(doer, self.inst)
        end
    end

    if doer.components.leader ~= nil then
        for follower, v in pairs(doer.components.leader.followers) do
            self:TravelTeleport(follower, target)
        end
    end

    --special case for the chester_eyebone: look for inventory items with followers
    if doer.components.inventory ~= nil then
        for k, item in pairs(doer.components.inventory.itemslots) do
            if item.components.leader ~= nil then
                for follower, v in pairs(item.components.leader.followers) do
                    self:TravelTeleport(follower, target)
                end
            end
        end
        -- special special case, look inside equipped containers
        for k, equipped in pairs(doer.components.inventory.equipslots) do
            if equipped.components.container ~= nil then
                for j, item in pairs(equipped.components.container.slots) do
                    if item.components.leader ~= nil then
                        for follower, v in pairs(item.components.leader.followers) do
                            self:TravelTeleport(follower, target)
                        end
                    end
                end
            end
        end
    end

    target = nil
    return true
end

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end
local solo_townportal = State {
    name     = "solo_townportal",
    tags     = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

    onenter  = function(inst, data)
        ToggleOffPhysics(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Stop()

        inst.sg.statemem.target = data.teleporter
        inst.sg.statemem.teleportarrivestate = "exittownportal_pre"

        inst.AnimState:PlayAnimation("townportal_enter_pre")

        inst.sg.statemem.fx = SpawnPrefab("townportalsandcoffin_fx")
        inst.sg.statemem.fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end,

    timeline = {
        TimeEvent(8 * FRAMES, function(inst)
            inst.sg.statemem.isteleporting = true
            inst.components.health:SetInvincible(true)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.DynamicShadow:Enable(false)
        end),
        TimeEvent(18 * FRAMES, function(inst)
            inst:Hide()
        end),
        TimeEvent(26 * FRAMES, function(inst)
            if inst.sg.statemem.target ~= nil and
                    inst.sg.statemem.target.components.teleporter ~= nil and
                    inst.sg.statemem.target.components.teleporter:Travel(inst, inst.sg.statemem.target) then
                inst:Hide()
                inst.sg.statemem.fx:KillFX()
            else
                inst.sg:GoToState("exittownportal")
            end
        end),
    },

    onexit   = function(inst)
        inst.sg.statemem.fx:KillFX()

        if inst.sg.statemem.isphysicstoggle then
            ToggleOnPhysics(inst)
        end

        if inst.sg.statemem.isteleporting then
            inst.components.health:SetInvincible(false)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst:Show()
            inst.DynamicShadow:Enable(true)
        end
    end,
}

return solo_townportal
