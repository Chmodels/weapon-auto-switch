```lua
return {
    {
        name = "switch_auto",
        label = "Automatic Switch",
        description = "Converts a semi-automatic weapon to fire automatically. Use while holding a weapon.",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = false,
        buttons = {
            {
                label = "Install",
                action = function(slot)
                    TriggerEvent("autoSwitch:useItem", "install")
                end
            }
        }
    },
    {
        name = "remove_switch",
        label = "Switch Remover",
        description = "Removes the automatic switch from a weapon. Use while holding a weapon.",
        weight = 100,
        stack = false,
        close = true,
        allowArmed = false,
        buttons = {
            {
                label = "Remove",
                action = function(slot)
                    TriggerEvent("autoSwitch:useItem", "remove")
                end
            }
        }
    }
}