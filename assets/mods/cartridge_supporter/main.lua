---@type ModReference
CartridgeSupporter = RegisterMod("CartridgeSupporter", 1)

local mod = CartridgeSupporter

local BOSSES = {
	["blueBaby"] = "102.1.0",
	["theLamb"] = "273.0.0",
	["megaSatan"] = "275.0.0",
	["mother"] = "912.10.0",
	["theBeast"] = "951.0.0",
	["delirium"] = "412.0.0",
}

mod:AddCallback(
    ModCallbacks.MC_POST_NEW_LEVEL,
    function(_)
        Isaac.DebugString("[Cartridge]StageEntered:" .. tostring(Game():GetLevel():GetStage()) .. "." .. tostring(Game():GetLevel():GetStageType()))
    end
)

mod:AddCallback(
    ModCallbacks.MC_POST_NEW_ROOM,
    function(_)
        local level = Game():GetLevel()
        local room = level:GetCurrentRoom()
        local roomDesc = level:GetCurrentRoomDesc()
        local roomType = room:GetType()

        if level:GetAbsoluteStage() == LevelStage.STAGE8 then
            if roomDesc.Data.Name == "Living Room" and level:GetStageType() == StageType.STAGETYPE_WOTL then
                Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(1000 + 8) .. "." .. tostring(false)) -- Dogma
            elseif roomDesc.Data.Name == "Beast Room" then
                Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(1000 + 9) .. "." .. tostring(false))
            else
                Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(roomType) .. "." .. tostring(room:IsClear()))
            end
            return
        end

        if roomType == RoomType.ROOM_BOSS then
            local bossId = room:GetBossID()
            local bossDartId = nil
            
            if bossId == 63 then
                bossDartId = 0 -- Hush
            elseif bossId == 39 then
                bossDartId = 1 -- Isaac
            elseif bossId == 24 then
                bossDartId = 2 -- Satan
            elseif bossId == 40 then
                bossDartId = 3 -- Blue Baby
            elseif bossId == 54 then
                bossDartId = 4 -- The Lamb
            elseif bossId == 55 then
                bossDartId = 5 -- Mega Satan
            elseif bossId == 70 then
                bossDartId = 6 -- Delirium
            elseif bossId == 88 then
                bossDartId = 7 -- Mother
            end

            if bossDartId ~= nil then
                Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(1000 + bossDartId) .. "." .. tostring(room:IsClear()))
                return
            end
        end

        Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(roomType) .. "." .. tostring(room:IsClear()))
    end
)

-- mod:AddCallback(
--     ModCallbacks.MC_POST_NPC_INIT,
--     ---@param entityNPC EntityNPC
--     function(_, entityNPC)
--         local room = Game():GetLevel():GetCurrentRoom()

--         if entityNPC.Type == EntityType.ENTITY_DOGMA and entityNPC.Variant == 1 then
--             Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(1000 + 9) .. "." .. tostring(room:IsClear())) -- Dogma
--         end
--     end
-- )

mod:AddCallback(
    ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,
    ---@param rng RNG
    ---@param spawnPos Vector
    function(_, rng, spawnPos)
        local level = Game():GetLevel()
        local room = level:GetCurrentRoom()
        local roomDesc = level:GetCurrentRoomDesc()
        local roomType = room:GetType()

        if roomDesc.Data.Name == "Dogma Test" then
            Isaac.DebugString("[Cartridge]RoomCleared:" .. tostring(1000 + 8) .. "." .. tostring(Game():GetRoom():IsClear())) -- Dogma
            return
        end

        if roomType == RoomType.ROOM_BOSS then
            local bossId = room:GetBossID()
            local bossDartId = nil
            
            if bossId == 63 then
                bossDartId = 0 -- Hush
            elseif bossId == 39 then
                bossDartId = 1 -- Isaac
            elseif bossId == 24 then
                bossDartId = 2 -- Satan
            elseif bossId == 40 then
                bossDartId = 3 -- Blue Baby
            elseif bossId == 54 then
                bossDartId = 4 -- The Lamb
            elseif bossId == 55 then
                bossDartId = 5 -- Mega Satan
            elseif bossId == 70 then
                bossDartId = 6 -- Delirium
            elseif bossId == 88 then
                bossDartId = 7 -- Mother
            end

            if bossDartId ~= nil then
                Isaac.DebugString("[Cartridge]RoomCleared:" .. tostring(1000 + bossDartId))
                return
            end
        end

        Isaac.DebugString("[Cartridge]RoomCleared:" .. tostring(Game():GetRoom():GetType()))
    end
)

mod:AddCallback(
	ModCallbacks.MC_POST_NPC_DEATH,
	---@param npc EntityNPC
	function(_, npc)
		local room = Game():GetRoom()

		if room:GetType() == RoomType.ROOM_BOSS and npc:IsBoss() then
            for bossName, data in pairs(BOSSES) do
                if (npc.Type .. "." .. npc.Variant .. "." .. npc.SubType) == data then
                    Isaac.DebugString("[Cartridge]BossCleared:" .. bossName)
                    break
                end
            end
		end
	end
)

