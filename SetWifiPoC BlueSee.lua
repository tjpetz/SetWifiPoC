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

    -- Create a label widget
    local ssid_input = bluesee.new_widget(bluesee.textfield)
    ssid_input.title = "SSID"
    ssid_input.value = ""

    -- Add the label widget to the service panel
    span:add_widget(ssid_input)

    -- Add a divider
    span:add_widget(bluesee.new_widget(bluesee.hr))

    local wifipwd_input = bluesee.new_widget(bluesee.textfield)
    wifipwd_input.title = "Password"
    wifipwd_input.value = ""

    span:add_widget(wifipwd_input)

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