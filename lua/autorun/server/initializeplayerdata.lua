local function LoadAllPlayerData()
    OFPLAYERS = {}
    local data = file.Read("of_npcp/playerdata.txt", "DATA")
    if data then
        local playerData = util.JSONToTable(data)
        for steamID, pdata in pairs(playerData) do
            OFPLAYERS[steamID] = {deck = pdata.deck}
        end
    end
end

local function SyncPlayerDeckToClient(ply)
    if OFPLAYERS[ply:SteamID()] then
        net.Start("UpdatePlayerDeck")
        net.WriteString(ply:SteamID())
        net.WriteString(OFPLAYERS[ply:SteamID()].deck)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end
end

hook.Add("Initialize", "LoadAllPlayerData", LoadAllPlayerData)

hook.Add("PlayerInitialSpawn", "SyncPlayerDeck", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            SyncPlayerDeckToClient(ply)
        end
    end)
end)