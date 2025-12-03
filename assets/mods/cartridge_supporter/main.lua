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
        Isaac.DebugString("[Cartridge]RoomEntered:" .. tostring(Game():GetRoom():GetType()) .. "." .. tostring(Game():GetRoom():IsClear()))
    end
)

mod:AddCallback(
    ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,
    ---@param rng RNG
    ---@param spawnPos Vector
    function(_, rng, spawnPos)
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

