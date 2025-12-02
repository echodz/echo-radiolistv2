local playerServerID = GetPlayerServerId(PlayerId())
local playersInRadio, currentRadioChannel, currentRadioChannelName = {}, nil, nil
local allowedToSeeRadioList, radioListVisibility = true, true
local temporaryName = "temporaryPlayerNameAsAWorkaroundForABugInPMA-VOICEWhichEventsGetCalledTwiceWhileThePlayerConnectsToTheRadioForFirstTime"
local radioListPosition = { x = 0, y = 0 }
local isInDragMode = false

local function closeTheRadioList()
    playersInRadio, currentRadioChannel, currentRadioChannelName = {}, nil, nil
    SendNUIMessage({ clearRadioList = true })
end

local function modifyTheRadioListVisibility(state)
    SendNUIMessage({ changeVisibility = true, visible = (allowedToSeeRadioList and state) or false })
end

local function loadSavedPosition()
    local screenWidth, screenHeight = GetScreenResolution()
    radioListPosition.x = screenWidth * 0.99 - 120
    radioListPosition.y = screenHeight * 0.12
end

local function savePositionToFile()
end

local function sendPositionToNUI()
    SendNUIMessage({ loadPosition = radioListPosition })
end

local function enableDragMode()
    isInDragMode = true
    SendNUIMessage({ enableDragMode = true })
    SetNuiFocus(true, true)
    
    DisableControlAction(0, 1, true)
    DisableControlAction(0, 2, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 257, true)
    DisableControlAction(0, 322, true)
    DisableControlAction(0, 200, true)
end

local function disableDragMode()
    isInDragMode = false
    SendNUIMessage({ disableDragMode = true })
    SetNuiFocus(false, false)
    
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 24, true)
    EnableControlAction(0, 25, true)
    EnableControlAction(0, 257, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 200, true)
end

RegisterNUICallback("savePosition", function(data, cb)
    if isInDragMode and data and data.x and data.y then
        radioListPosition.x = data.x
        radioListPosition.y = data.y
        savePositionToFile()
    end
    cb("ok")
end)

RegisterNUICallback("focusNUIB", function(data, cb)
    if data.focused then
        SetNuiFocus(true, true)
    else
        SetNuiFocus(false, false)
        isInDragMode = false
    end
    cb("ok")
end)

RegisterNetEvent("x-radiolist:getPositionFromStorage", function(position)
    if position then
        radioListPosition.x = position.x or 0
        radioListPosition.y = position.y or 0
    end
end)

RegisterNUICallback("updateRadioName", function(data, cb)
    if data.name and data.name ~= "" then
        local customizedName = data.name:match("^%s*(.-)%s*$")
        if customizedName ~= "" and customizedName ~= " " and customizedName ~= nil then
            if Config.LetPlayersSetTheirOwnNameInRadio then
                if isPlayerAllowedToChangeName(PlayerId(), true) then
                    ExecuteCommand(Config.RadioListChangeNameCommand .. " " .. customizedName)
                end
            end
        end
    end
    cb("ok")
end)

RegisterNUICallback("getCurrentName", function(data, cb)
    local playerName = Player(playerServerID).state[Shared.State.nameInRadio] or GetPlayerName(PlayerId())
    SendNUIMessage({ currentName = playerName })
    cb("ok")
end)

CreateThread(function()
    while true do
        Wait(0)
        if isInDragMode then
            if IsControlJustPressed(0, 322) then
                disableDragMode()
            end
        end
    end
end)

local function addServerIdToPlayerName(serverId, playerName)
    if Config.ShowPlayersServerIdNextToTheirName then
        if Config.PlayerServerIdPosition == "left" then playerName = ("%s) %s"):format(serverId, playerName)
        elseif Config.PlayerServerIdPosition == "right" then playerName = ("%s (%s"):format(playerName, serverId) end
    end
    return playerName
end

local function addPlayerToTheRadioList(playerId, playerName, overrideMemberCount)
    if playersInRadio[playerId] then return end
    playersInRadio[playerId] = temporaryName
    playersInRadio[playerId] = addServerIdToPlayerName(playerId, playerName or Player(playerId).state[Shared.State.nameInRadio] or callback.await(Shared.Callback.getPlayerName, false, playerId))
    
    local memberCount = overrideMemberCount or 0
    if not overrideMemberCount then
        for _ in pairs(playersInRadio) do
            memberCount = memberCount + 1
        end
    end
    
    SendNUIMessage({ self = playerId == playerServerID, radioId = playerId, radioName = playersInRadio[playerId], channel = currentRadioChannelName, memberCount = memberCount })
end

local function removePlayerFromTheRadioList(playerId)
    if not playersInRadio[playerId] then return end
    if playersInRadio[playerId] == temporaryName then return end
    if playerId == playerServerID then closeTheRadioList() return end
    playersInRadio[playerId] = nil
    
    local memberCount = 0
    for _ in pairs(playersInRadio) do
        memberCount = memberCount + 1
    end
    
    SendNUIMessage({ radioId = playerId, memberCount = memberCount, channel = currentRadioChannelName })
end

RegisterNetEvent("pma-voice:addPlayerToRadio", function(playerId)
    if not currentRadioChannel or not (currentRadioChannel > 0) then return end
    addPlayerToTheRadioList(playerId)
end)

RegisterNetEvent("pma-voice:removePlayerFromRadio", function(playerId)
    if not currentRadioChannel or not (currentRadioChannel > 0) then return end
    removePlayerFromTheRadioList(playerId)
end)

RegisterNetEvent("pma-voice:syncRadioData", function()
    closeTheRadioList()
    local _playersInRadio
    _playersInRadio, currentRadioChannel, currentRadioChannelName = callback.await(Shared.Callback.getPlayersInRadio, false)
    
    local memberCount = 0
    for _ in pairs(_playersInRadio) do
        memberCount = memberCount + 1
    end
    
    for playerId, playerName in pairs(_playersInRadio) do
        addPlayerToTheRadioList(playerId, playerName, memberCount)
    end
    _playersInRadio = nil
end)

RegisterNetEvent("pma-voice:radioActive")
AddEventHandler("pma-voice:radioActive", function(talkingState)
    SendNUIMessage({ radioId = playerServerID, radioTalking = talkingState })
end)

RegisterNetEvent("pma-voice:setTalkingOnRadio")
AddEventHandler("pma-voice:setTalkingOnRadio", function(source, talkingState)
    SendNUIMessage({ radioId = source, radioTalking = talkingState })
end)

AddStateBagChangeHandler(Shared.State.allowedToSeeRadioList, ("player:%s"):format(playerServerID), function(bagName, key, value)
    local receivedPlayerServerId = tonumber(bagName:gsub('player:', ''), 10)
    if not receivedPlayerServerId or receivedPlayerServerId ~= playerServerID then return end
    allowedToSeeRadioList = (value == nil and false) or value
    modifyTheRadioListVisibility(radioListVisibility)
end)

if Config.LetPlayersChangeVisibilityOfRadioList then
    RegisterCommand(Config.RadioListVisibilityCommand,function()
        radioListVisibility = not radioListVisibility
        modifyTheRadioListVisibility(radioListVisibility)
    end)
    TriggerEvent("chat:addSuggestion", "/"..Config.RadioListVisibilityCommand, "Show/Hide Radio List")
end

if Config.LetPlayersSetTheirOwnNameInRadio then
    TriggerEvent("chat:addSuggestion", "/"..Config.RadioListChangeNameCommand, "Customize your name to be shown in radio list", { { name = "customized name", help = "Enter your desired name to be shown in radio list" } })
end

if Config.HideRadioListVisibilityByDefault then
    SetTimeout(1000, function()
        radioListVisibility = false
        modifyTheRadioListVisibility(radioListVisibility)
    end)
end

if Config.LetPlayersChangeRadioChannelsName then
    TriggerEvent("chat:addSuggestion", "/"..Config.ModifyRadioChannelNameCommand, "Modify the name of the radio channel you are currently in", { { name = "customized name", help = "Enter your desired name to set it as you current radio channel's name" } })
end

RegisterCommand("radiolistdrag", function()
    if isInDragMode then
        disableDragMode()
    else
        enableDragMode()
    end
end)
TriggerEvent("chat:addSuggestion", "/radiolistdrag", "Toggle radio list drag mode")

local function isPlayerAllowedToChangeName(source, notify)
    if not Config.LetPlayersSetTheirOwnNameInRadio then
        return false
    end
    
    local response = true
    if Framework.Initial == "qb" then
        local xPlayer = Framework.GetPlayer and Framework.GetPlayer(source)
        if xPlayer then
            if Config.JobsWithCallsign[xPlayer.PlayerData?.job?.name] and xPlayer.PlayerData?.job?.onduty then
                response = false
                if notify then
                    Config.Notification(source, "You cannot change your name on radio while on duty!", "error")
                end
            end
        end
    end
    return response
end

CreateThread(function()
    loadSavedPosition()
    sendPositionToNUI()
end)