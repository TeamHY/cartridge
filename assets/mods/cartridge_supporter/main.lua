---@type ModReference
CartridgeSupporter = RegisterMod("CartridgeSupporter", 1)

local mod = CartridgeSupporter

mod:AddCallback(
    ModCallbacks.MC_POST_NEW_LEVEL,
    function(_)
        print("[Cartridge]StageEntered:" .. tostring(Game():GetLevel():GetStage()) .. "." .. tostring(Game():GetLevel():GetStageType()))
    end
)

mod:AddCallback(
    ModCallbacks.MC_POST_NEW_ROOM,
    function(_)
        print("[Cartridge]RoomEntered:" .. tostring(Game():GetRoom():GetType()))
    end
)
