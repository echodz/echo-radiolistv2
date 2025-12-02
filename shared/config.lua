Config = {}

Config.UseRPName = true

Config.LetPlayersChangeVisibilityOfRadioList = true
Config.RadioListVisibilityCommand = "radiolist"
Config.HideRadioListVisibilityByDefault = false

Config.LetPlayersSetTheirOwnNameInRadio = true
Config.RadioListChangeNameCommand = "nameinradio"
Config.ResetPlayersCustomizedNameOnExit = true

Config.LetPlayersChangeRadioChannelsName = true
Config.ModifyRadioChannelNameCommand = "nameofradio"

Config.ShowPlayersServerIdNextToTheirName = false
Config.PlayerServerIdPosition = "right"

Config.RadioListOnlyShowsToGroupsWithAccess = false
Config.GroupsWithAccessToTheRadioList = {
    ["police"] = true,
    ["ambulance"] = true,
}

Config.JobsWithCallsign = {
    ["police"] = true,
    ["trooper"] = true,
    ["ambulance"] = true,
}

Config.LetPlayersOverrideRadioChannelsWithName = false

Config.RadioChannelsWithName = {
    ["0"] = "Admin",
    ["1"] = "Police",
    ["2"] = "Ambulance",
}

Config.Notification = function(source, message, type)
    TriggerClientEvent("QBCore:Notify", source, message, type or "primary", 5000)
end