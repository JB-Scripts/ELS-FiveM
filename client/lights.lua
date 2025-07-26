RegisterNetEvent("kjELS:resetExtras")
AddEventHandler("kjELS:resetExtras", function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end
    
    -- Only process if the local player is in the vehicle
    local ped = GetPlayerPed(-1)
    if GetVehiclePedIsIn(ped, false) ~= vehicle then
        return
    end

    if setContains(kjxmlData, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) then
        for i = 1, 9 do
            SetVehicleExtra(vehicle, i, 1)
        end
    end
end)

for _, v in ipairs(Config.AudioBanks) do
    RequestScriptAudioBank(v, false)
end

RegisterNetEvent("kjELS:toggleLights")
AddEventHandler("kjELS:toggleLights", function(playerid, type, status)
    local serverId = GetPlayerServerId(PlayerId())
    if playerid ~= serverId then
        return -- Only process for the local player
    end

    local vehicle = GetVehiclePedIsUsing(GetPlayerPed(-1))
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end

    if kjEnabledVehicles[vehicle] == nil then 
        kjEnabledVehicles[vehicle] = {
            primary = false,
            secondary = false,
            warning = false,
            light_sound = nil
        }
    end

    -- Stop any existing light sound before toggling
    if kjEnabledVehicles[vehicle]["light_sound"] ~= nil then
        StopSound(kjEnabledVehicles[vehicle]["light_sound"])
        ReleaseSoundId(kjEnabledVehicles[vehicle]["light_sound"])
        kjEnabledVehicles[vehicle]["light_sound"] = nil
    end

    kjEnabledVehicles[vehicle][type] = status
    
    -- Play sound only when turning lights on (status == true)
    local modelHash = getCarHash(vehicle)
    if status and kjxmlData[modelHash] and kjxmlData[modelHash].sounds and kjxmlData[modelHash].sounds.lightToggle then
        kjEnabledVehicles[vehicle]["light_sound"] = GetSoundId()
        PlaySoundFromEntity(
            kjEnabledVehicles[vehicle]["light_sound"],
            kjxmlData[modelHash].sounds.lightToggle.audioString,
            vehicle,
            kjxmlData[modelHash].sounds.lightToggle.soundSet or 0,
            0,
            0
        )
    end

    if type == "primary" then
        TriggerEvent("kjELS:primaryLights", NetworkGetNetworkIdFromEntity(vehicle))
    elseif type == "secondary" then
        TriggerEvent("kjELS:secondaryLights", NetworkGetNetworkIdFromEntity(vehicle))
    elseif type == "warning" then
        TriggerEvent("kjELS:warningLights", NetworkGetNetworkIdFromEntity(vehicle))
    end
end)

RegisterNetEvent("kjELS:primaryLights")
AddEventHandler("kjELS:primaryLights", function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end

    -- Only process if the local player is in the vehicle
    local ped = GetPlayerPed(-1)
    if GetVehiclePedIsIn(ped, false) ~= vehicle then
        return
    end

    local modelHash = getCarHash(vehicle)
    if not kjxmlData[modelHash] or not kjxmlData[modelHash].extras then
        return
    end

    for ex, _ in pairs(kjxmlData[modelHash].extras) do
        SetVehicleExtra(vehicle, ex, 1) -- Off
    end

    SetVehicleAutoRepairDisabled(vehicle, true)

    while kjEnabledVehicles[vehicle] and kjEnabledVehicles[vehicle]["primary"] do
        SetVehicleEngineOn(vehicle, true, true, false)
        local lastFlash = {}
        for _, flash in pairs(kjxmlData[modelHash].patterns.primary) do
            if kjEnabledVehicles[vehicle]["primary"] then
                for _, extra in pairs(flash['extras']) do
                    SetVehicleExtra(vehicle, extra, 0)
                    table.insert(lastFlash, extra)
                end
                Citizen.Wait(flash['duration'])
            end

            for _, v in pairs(lastFlash) do
                SetVehicleExtra(vehicle, v, 1)
            end
            lastFlash = {}
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("kjELS:secondaryLights")
AddEventHandler("kjELS:secondaryLights", function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end

    -- Only process if the local player is in the vehicle
    local ped = GetPlayerPed(-1)
    if GetVehiclePedIsIn(ped, false) ~= vehicle then
        return
    end

    local modelHash = getCarHash(vehicle)
    if not kjxmlData[modelHash] or not kjxmlData[modelHash].patterns.rearreds then
        return
    end

    if not kjEnabledVehicles[vehicle]["secondary"] then
        for _, flash in pairs(kjxmlData[modelHash].patterns.rearreds) do
            for _, extra in pairs(flash['extras']) do
                SetVehicleExtra(vehicle, extra, 1)
            end
        end
    end

    while kjEnabledVehicles[vehicle] and kjEnabledVehicles[vehicle]["secondary"] do
        SetVehicleEngineOn(vehicle, true, true, false)
        local lastFlash = {}
        for _, flash in pairs(kjxmlData[modelHash].patterns.rearreds) do
            if kjEnabledVehicles[vehicle]["secondary"] then
                for _, extra in pairs(flash['extras']) do
                    table.insert(lastFlash, extra)
                    SetVehicleExtra(vehicle, extra, 0)
                end
                Citizen.Wait(flash['duration'])
            end

            for _, v in pairs(lastFlash) do
                SetVehicleExtra(vehicle, v, 1)
            end
            lastFlash = {}
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("kjELS:warningLights")
AddEventHandler("kjELS:warningLights", function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end

    -- Only process if the local player is in the vehicle
    local ped = GetPlayerPed(-1)
    if GetVehiclePedIsIn(ped, false) ~= vehicle then
        return
    end

    local modelHash = getCarHash(vehicle)
    if not kjxmlData[modelHash] or not kjxmlData[modelHash].patterns.secondary then
        return
    end

    if not kjEnabledVehicles[vehicle]["warning"] then
        for _, flash in pairs(kjxmlData[modelHash].patterns.secondary) do
            for _, extra in pairs(flash['extras']) do
                SetVehicleExtra(vehicle, extra, 1)
            end
        end
    end

    while kjEnabledVehicles[vehicle] and kjEnabledVehicles[vehicle]["warning"] do
        SetVehicleEngineOn(vehicle, true, true, false)
        local lastFlash = {}
        for _, flash in pairs(kjxmlData[modelHash].patterns.secondary) do
            if kjEnabledVehicles[vehicle]["warning"] then
                for _, extra in pairs(flash['extras']) do
                    table.insert(lastFlash, extra)
                    SetVehicleExtra(vehicle, extra, 0)
                end
                Citizen.Wait(flash['duration'])
            end

            for _, v in pairs(lastFlash) do
                SetVehicleExtra(vehicle, v, 1)
            end
            lastFlash = {}
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("kjELS:updateHorn")
AddEventHandler("kjELS:updateHorn", function(playerid, status)
    local serverId = GetPlayerServerId(PlayerId())
    if playerid ~= serverId then
        return
    end

    local vehicle = GetVehiclePedIsUsing(GetPlayerPed(-1))
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end
	    
    if kjEnabledVehicles[vehicle] == nil then
        addVehicleToTable(vehicle)
    end
    kjEnabledVehicles[vehicle]["horn"] = status
	    
    if kjEnabledVehicles[vehicle]["horn_sound"] ~= nil then
        StopSound(kjEnabledVehicles[vehicle]["horn_sound"])
        ReleaseSoundId(kjEnabledVehicles[vehicle]["horn_sound"])
        kjEnabledVehicles[vehicle]["horn_sound"] = nil
    end
    
    if status == 1 then
        kjEnabledVehicles[vehicle]["horn_sound"] = GetSoundId()
        PlaySoundFromEntity(kjEnabledVehicles[vehicle]["horn_sound"], "SIRENS_AIRHORN", vehicle, 0, 0, 0)
    end
end)

RegisterNetEvent("kjELS:updateSiren")
AddEventHandler("kjELS:updateSiren", function(vehNetId, status)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        CancelEvent()
        return
    end

    if kjEnabledVehicles[vehicle] == nil then
        addVehicleToTable(vehicle)
    end

    -- Only process if siren state has changed
    if kjEnabledVehicles[vehicle]["siren"] == status then
        return -- Prevent retriggering the same state
    end

    -- Determine which tone (0 = off, 1-4 = tones)
    local newTone = status
    local currentTone = kjEnabledVehicles[vehicle]["currentSirenTone"] or 0

    -- Only stop/start sound if tone is changing or turning off
    if newTone ~= currentTone then
        -- Stop any existing siren sound
        if kjEnabledVehicles[vehicle]["sound"] ~= nil then
            StopSound(kjEnabledVehicles[vehicle]["sound"])
            ReleaseSoundId(kjEnabledVehicles[vehicle]["sound"])
            kjEnabledVehicles[vehicle]["sound"] = nil
        end

        local modelHash = getCarHash(vehicle)
        if not kjxmlData[modelHash] or not kjxmlData[modelHash].sounds then
            kjEnabledVehicles[vehicle]["siren"] = status
            kjEnabledVehicles[vehicle]["currentSirenTone"] = newTone
            return
        end
        local vehicleSounds = kjxmlData[modelHash].sounds

        -- Play siren sound based on status
        if newTone == 1 then
            kjEnabledVehicles[vehicle]["sound"] = GetSoundId()
            PlaySoundFromEntity(
                kjEnabledVehicles[vehicle]["sound"],
                vehicleSounds.srnTone1.audioString,
                vehicle,
                vehicleSounds.srnTone1.soundSet,
                0,
                0
            )
            DisableVehicleImpactExplosionActivation(vehicle, true)
        elseif newTone == 2 then
            kjEnabledVehicles[vehicle]["sound"] = GetSoundId()
            PlaySoundFromEntity(
                kjEnabledVehicles[vehicle]["sound"],
                vehicleSounds.srnTone2.audioString,
                vehicle,
                vehicleSounds.srnTone2.soundSet,
                0,
                0
            )
            DisableVehicleImpactExplosionActivation(vehicle, true)
        elseif newTone == 3 then
            kjEnabledVehicles[vehicle]["sound"] = GetSoundId()
            PlaySoundFromEntity(
                kjEnabledVehicles[vehicle]["sound"],
                vehicleSounds.srnTone3.audioString,
                vehicle,
                vehicleSounds.srnTone3.soundSet,
                0,
                0
            )
            DisableVehicleImpactExplosionActivation(vehicle, true)
        elseif newTone == 4 then
            kjEnabledVehicles[vehicle]["sound"] = GetSoundId()
            PlaySoundFromEntity(
                kjEnabledVehicles[vehicle]["sound"],
                vehicleSounds.srnTone4.audioString,
                vehicle,
                vehicleSounds.srnTone4.soundSet,
                0,
                0
            )
            DisableVehicleImpactExplosionActivation(vehicle, true)
        else
            -- Siren off, nothing to play
            DisableVehicleImpactExplosionActivation(vehicle, true)
        end
    end

    kjEnabledVehicles[vehicle]["siren"] = status
    kjEnabledVehicles[vehicle]["currentSirenTone"] = newTone
end)

Citizen.CreateThread(function()
    while true do
        if kjxmlData then
            for vehicle, _ in pairs(kjEnabledVehicles) do
                if DoesEntityExist(vehicle) and kjxmlData[getCarHash(vehicle)] then
                    -- Only process for the local player's vehicle
                    local ped = GetPlayerPed(-1)
                    if GetVehiclePedIsIn(ped, false) == vehicle then
                        for ex, det in pairs(kjxmlData[getCarHash(vehicle)].extras) do
                            if IsVehicleExtraTurnedOn(vehicle, ex) and det.enabled then
                                local ExtraInfo = kjxmlData[getCarHash(vehicle)].extras[ex]
                                createEnviromentLight(vehicle, ex, ExtraInfo.env_pos.x, ExtraInfo.env_pos.y, ExtraInfo.env_pos.z, ExtraInfo.env_pos.color)
                            end
                        end
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)