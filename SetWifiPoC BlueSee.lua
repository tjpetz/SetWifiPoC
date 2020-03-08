local bluesee = require "bluesee"

-- Config service definition
local config_service_uuid = bluesee.UUID.new('2de598db-ae66-4942-9106-490c3f5e5687')
bluesee.set_display_name(config_service_uuid, 'SetWifiPoC')
bluesee.set_display_category(config_service_uuid, bluesee.ui)

local wifiSSID_uuid = bluesee.UUID.new('15bc7004-c6c0-4d1e-a390-af4a6ee643db')
local wifiPassword_uuid = bluesee.UUID.new('01510af0-bdbc-4549-aef8-ef724bba2265')
local configurationLock_uuid = bluesee.UUID.new('5a622576-7f47-49d7-83fb-6a96ecea03e8')
local configurationUnlock_uuid = bluesee.UUID.new('50ee954b-12b8-4a41-875e-11b8bf1a3506')
local configurationIsLocked_uuid = bluesee.UUID.new('e5add166-af0e-4c54-9121-4a34371c638b')

-- Ping service definition
local ping_service_uuid = bluesee.UUID.new('6e1de8ff-a379-4cbc-b4aa-8bb627c9a2af')
bluesee.set_display_name(ping_service_uuid, 'Wifi Ping')
bluesee.set_display_category(ping_service_uuid, bluesee.ui)

local pingTarget_uuid = bluesee.UUID.new('680e23d1-4214-4ab1-b20f-0e0c85528284')
local pingRTT_uuid = bluesee.UUID.new('6d8d89cb-e5cd-4f18-8ae3-282b7bb8e58a')

-- Register the Config service
bluesee.register_service(config_service_uuid, function(span)

    local ssid_display = bluesee.new_widget(bluesee.label)
    ssid_display.title = "Current SSID"
    ssid_display.value = ""
    span:add_widget(ssid_display)

    -- Field to enter the ssid and update button
    local ssid_input = bluesee.new_widget(bluesee.textfield)
    ssid_input.title = "SSID"
    ssid_input.value = ""
    span:add_widget(ssid_input)

    local ssid_button = bluesee.new_widget(bluesee.button)
    ssid_button.title = "Update SSID"

    local ssid_ch = nil
    ssid_button.on_click = function()
        if ssid_ch ~= nil then
            ssid_ch:write_binary(ssid_input.value)
            ssid_display.value = ssid_input.value
        end
    end
    span:add_widget(ssid_button)
 
    -- Field to enter the password and an update button
    local wifipwd_input = bluesee.new_widget(bluesee.textfield)
    wifipwd_input.title = "Password"
    wifipwd_input.value = ""
    span:add_widget(wifipwd_input)

    local password_button = bluesee.new_widget(bluesee.button)
    password_button.title = "Update Password"

    local password_ch = nil

    password_button.on_click = function()
        if password_ch ~= nil then
            password_ch:write_binary(wifipwd_input.value)
        end
    end
    span:add_widget(password_button)

    -- Add a divider
    span:add_widget(bluesee.new_widget(bluesee.hr))

    -- lock management fields and buttons
    local isunlocked_ch = nil

    local isLocked_label = bluesee.new_widget(bluesee.label)
    isLocked_label.title = "Is Locked: "
    span:add_widget(isLocked_label)

    local lock_input = bluesee.new_widget(bluesee.textfield)
    lock_input.title = "Lock Password"
    lock_input.value = ""
    span:add_widget(lock_input)

    local lock_button = bluesee.new_widget(bluesee.button)
    lock_button.title = "Lock"

    local lock_ch = nil

    lock_button.on_click = function()
        if lock_ch ~= nil then
            lock_ch:write_binary(lock_input.value)
        end
    end
    span:add_widget(lock_button)

    local unlock_input = bluesee.new_widget(bluesee.textfield)
    unlock_input.title = "Unlock Password"
    unlock_input.value = ""
    span:add_widget(unlock_input)

    local unlock_button = bluesee.new_widget(bluesee.button)
    unlock_button.title = "Unlock"

    local unlock_ch = nil

    unlock_button.on_click = function()
        if unlock_ch ~= nil then
            unlock_ch:write_binary(unlock_input.value)
        end
    end
    span:add_widget(unlock_button)
    
    -- Add handlers for the characteristics
    span.on_ch_discovered = function(ch)
        if ch.uuid == wifiSSID_uuid then
            ssid_ch = ch
            local update_function = function()
                ssid_display.value = ch.value:as_raw_string()
            end
            ch:add_read_callback(update_function)
            ch:read()
        elseif ch.uuid == wifiPassword_uuid then
            password_ch = ch
        elseif ch.uuid == configurationLock_uuid then
            lock_ch = ch
        elseif ch.uuid == configurationUnlock_uuid then
            unlock_ch = ch
        elseif ch.uuid == configurationIsLocked_uuid then
            isunlocked_ch = ch
            local update_function = function()
                local isLocked = ch.value:unsigned_integer()
                isLocked_label.value = string.format('%d', isLocked)
            end
            ch:add_read_callback(update_function)
            ch:read()
        end
    end

 end)

 -- Register the Ping service
 bluesee.register_service(ping_service_uuid, function(span)

    local rtt_label = bluesee.new_widget(bluesee.label)
    rtt_label.title = "RTT"
    rtt_label.value = ""
    span:add_widget(rtt_label) 

    local host_label = bluesee.new_widget(bluesee.label)
    host_label.title = "host"
    host_label.value = ""
    span:add_widget(host_label)

    local hostname_input = bluesee.new_widget(bluesee.textfield)
    hostname_input.title = "hostname"
    hostname_input.value = ""
    span:add_widget(hostname_input)

    local ping_ch = nil

    local ping_button = bluesee.new_widget(bluesee.button)
    ping_button.title = "Ping"

    ping_button.on_click = function()
        if ping_ch ~= nill then
            ping_ch:write_binary(hostname_input.value)
        end
    end

    span:add_widget(ping_button)
 
    -- listen for and configure the characteristics
    span.on_ch_discovered = function(ch)
        if ch.uuid == pingTarget_uuid then
            ping_ch = ch
            local update_function = function()
                local hostname = ch.value
                host_label.value = hostname:as_raw_string()
            end
            ch:add_read_callback(update_function)
            ch:read()
        elseif ch.uuid == pingRTT_uuid then
            local update_function = function()
                local rtt = ch.value:signed_integer()
                rtt_label.value = string.format("%d mS", rtt)
            end  
            ch:add_read_callback(update_function)
            ch:read()
         end
    end

 end)