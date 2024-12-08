class RecorderMod {
  static const modMain = """
---

local DAILY_SEED = "%SEED%"
local DAILY_BOSS = "%BOSS%"

local BOSSES = {
  ["blue_baby"] = "102.1.0",
  ["the_lamb"] = "273.0.0",
  ["mega_satan"] = "275.0.0",
  ["mother"] = "912.10.0",
  ["the_beast"] = "951.0.0",
  ["delirium"] = "412.0.0"
}

---

CartridgeRecorder = RegisterMod("CartridgeRecorder", 1)

local mod = CartridgeRecorder

local game = Game()

mod:AddCallback(
	ModCallbacks.MC_POST_GAME_STARTED,
	function(_, isContinue)
		Isaac.ExecuteCommand("seed " .. DAILY_SEED)

		local seed = game:GetSeeds():GetStartSeedString():gsub(" ", "")
		local player = Isaac.GetPlayer()

		Isaac.DebugString("[CR]START:" .. game.Difficulty .. "." .. player:GetPlayerType() .. "." .. seed)
	end
)

mod:AddCallback(
	ModCallbacks.MC_POST_GAME_END,
	function(_, isGameOver)
		if not isGameOver then
			local seed = game:GetSeeds():GetStartSeedString():gsub(" ", "")
			local player = Isaac.GetPlayer()

			Isaac.DebugString("[CR]END:" .. game.Difficulty .. ":" .. player:GetPlayerType() .. ":" .. seed)
		end
	end
)

mod:AddCallback(
	ModCallbacks.MC_POST_NEW_LEVEL,
	function(_)
		local stage = game:GetLevel():GetStage()

		Isaac.DebugString("[CR]STAGE:" .. stage)
	end
)

mod:AddCallback(
	ModCallbacks.MC_POST_NPC_DEATH,
	---@param npc EntityNPC
	function(_, npc)
		local room = Game():GetRoom()

		if room:GetType() == RoomType.ROOM_BOSS and npc:IsBoss() and BOSSES[DAILY_BOSS] == (npc.Type .. "." .. npc.Variant .. "." .. npc.SubType) then
			Isaac.DebugString("[CR]BOSS:Killed")
		end
	end
)
""";

  static const modMetadata = """
<metadata>
	<name>CartridgeRecorder</name>
	<directory>cartridge-recorder</directory>
	<description/>
	<version>1.0</version>
	<visibility/>
</metadata>
""";

  static String getModMain(String seed, String boss) {
    return modMain.replaceFirst('%SEED%', seed).replaceFirst('%BOSS%', boss);
  }
}
