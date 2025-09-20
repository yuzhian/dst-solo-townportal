GLOBAL.setmetatable(env, { __index = function(t, k)
  return GLOBAL.rawget(GLOBAL, k)
end })

local solo_townportal = require("stategraphs/SGsolo_townportal")

local auto_open_map = GetModConfigData("auto_open_map") -- 是否自动打开地图
local open_map_delay = GetModConfigData("open_map_delay") -- 延迟多少秒打开地图
local cost_sanity = GetModConfigData("cost_sanity") -- 消耗理智
local cost_type = GetModConfigData("cost_type") -- 消耗物品
local cost_count = GetModConfigData("cost_count") -- 消耗物品数量

local TOWNPORTAL_CHANNEL_TAG = "townportal_channeler"
local SOLO_TOWNPORTAL_ID = "SOLO_TOWNPORTAL"
local SOLO_TOWNPORTAL_STRING = "传送"
local TOWNPORTAL_DETECTION_RADIUS = 10

local function FindTownportal(pos)
  local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, TOWNPORTAL_DETECTION_RADIUS, { "townportal", "structure" })
  if #ents == 0 then
    return nil
  end
  local nearest, mindistsq = nil, math.huge
  for _, v in ipairs(ents) do
    local distsq = v:GetDistanceSqToPoint(pos)
    if distsq < mindistsq then
      nearest = v
      mindistsq = distsq
    end
  end

  return nearest
end

local function CanTeleport(player, position)
  --检查玩家是否在触摸懒人传送塔
  if not player.inst:HasTag(TOWNPORTAL_CHANNEL_TAG) then
    return false
  end

  --检查物品栏是否有足够的消耗品
  if cost_type ~= "none" and not player.inst.replica.inventory:Has(cost_type, cost_count) then
    return false
  end

  --检查鼠标附近是否有懒人传送塔
  local target = FindTownportal(position)
  if not target then
    return false
  end
  return true
end

local function OnStartChanneling(self, channeler)
  channeler:AddTag(TOWNPORTAL_CHANNEL_TAG)
  channeler.townportal = self
  if auto_open_map then
    channeler:DoStaticTaskInTime(open_map_delay, function()
      if channeler:HasTag(TOWNPORTAL_CHANNEL_TAG) then
        if channeler.player_classified then
          local x, y, z = channeler.Transform:GetWorldPosition()
          channeler.player_classified.revealmapspot_worldx:set(x)
          channeler.player_classified.revealmapspot_worldz:set(z)
          channeler.player_classified.revealmapspotevent:push()
        end
      end
    end)
  end
end

local function OnStopChanneling(self, aborted)
  if _onstopchannelingfn then
    _onstopchannelingfn(self, aborted)
  end
  self.channeler:RemoveTag(TOWNPORTAL_CHANNEL_TAG)
  self.channeler.townportal = nil
end

local function OnActivate(inst, doer)
  if doer:HasTag("player") then
    if doer.components.talker ~= nil then
      doer.components.talker:ShutUp()
    end
    if doer.components.sanity ~= nil then
      doer.components.sanity:DoDelta(-cost_sanity)
    end
    if cost_type ~= "none" and doer.components.inventory ~= nil then
      doer.components.inventory:ConsumeByName(cost_type, cost_count)
    end
  end
end

------------------------------------------------------------
--地图传送动作
------------------------------------------------------------
AddStategraphState("wilson", solo_townportal)
AddAction(SOLO_TOWNPORTAL_ID, SOLO_TOWNPORTAL_STRING, function(act)
  if act.doer ~= nil and act.doer:HasTag("player") and act.target ~= nil and act.target:HasTag("townportal") then
    act.doer:CloseMinimap()
    act.doer.sg:GoToState("solo_townportal", { teleporter = act.target })
  end
end)
ACTIONS.SOLO_TOWNPORTAL.map_action = true
ACTIONS.SOLO_TOWNPORTAL.rmb = true
ACTIONS.SOLO_TOWNPORTAL.instant = true
ACTIONS_MAP_REMAP[ACTIONS.SOLO_TOWNPORTAL.code] = function(act, ...)
  return BufferedAction(act.doer, act.target, ACTIONS.SOLO_TOWNPORTAL)
end

------------------------------------------------------------
--地图中替换鼠标交互
------------------------------------------------------------
AddComponentPostInit("playercontroller", function(self)
  local getMapActions = self.GetMapActions
  function self:GetMapActions(position, ...)
    local LMBaction, RMBaction = getMapActions(self, position, ...)

    print("playercontroller CanTeleport", CanTeleport(self, position))
    if not CanTeleport(self, position) then
      return LMBaction, RMBaction
    end

    local act = BufferedAction(self.inst, FindTownportal(position), ACTIONS.SOLO_TOWNPORTAL)
    RMBaction = self:RemapMapAction(act, position)
    return LMBaction, RMBaction
  end
end)

------------------------------------------------------------
--懒人传送塔替换交互逻辑
--0. 允许传送塔在渲染范围外保持加载状态
--1. 触摸时, 标记触摸者标签, 根据配置弹出地图
--2. 传送后, 根据配置消耗理智和物品
------------------------------------------------------------
AddPrefabPostInit("townportal", function(inst)
  inst.entity:SetCanSleep(false)
  local channelable = inst.components.channelable
  local teleporter = inst.components.teleporter
  if not channelable or not teleporter then
    return inst
  end
  local _onchannelingfn = channelable.onchannelingfn
  local _onstopchannelingfn = channelable.onstopchannelingfn
  channelable:SetChannelingFn(
          function(self, channeler)
            _onchannelingfn(self, channeler)
            OnStartChanneling(self, channeler)
          end,
          function(self, aborted)
            _onstopchannelingfn(self, aborted)
            OnStopChanneling(self, aborted)
          end
  )
  teleporter.onActivate = OnActivate
  return inst
end)

