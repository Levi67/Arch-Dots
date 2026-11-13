#pragma once

#include <hyprland/src/config/values/types/ColorValue.hpp>
#include <hyprland/src/config/values/types/IntValue.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>

inline HANDLE PHANDLE = nullptr;

struct SSnowVars {
    SP<Config::Values::CIntValue>   growMinutes; // minutes until a cap reaches full size
    SP<Config::Values::CIntValue>   maxHeight;   // full cap height in logical px
    SP<Config::Values::CColorValue> color;       // snow color
};

inline SSnowVars snowVars = {};
