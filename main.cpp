#define WLR_USE_UNSTABLE

#include <algorithm>
#include <chrono>

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopTimer.hpp>
#include <hyprland/src/render/Renderer.hpp>

#include "SnowCap.hpp"
#include "globals.hpp"

// Do NOT change this function.
APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static Hyprutils::Signal::CHyprSignalListener g_openListener;
static SP<CEventLoopTimer>                    g_growTimer;

static constexpr auto                         GROW_TICK = std::chrono::seconds(20);

static bool hasCap(PHLWINDOW w) {
    return std::ranges::any_of(w->presentation().decorations(), [](const auto& d) { return d->getDisplayName() == "SnowCap"; });
}

static void addCap(PHLWINDOW w) {
    if (!hasCap(w))
        HyprlandAPI::addWindowDecoration(PHANDLE, w, makeShared<CSnowCap>(w));
}

// caps grow slowly; repaint them whenever their growth step moved on
static void onGrowTick(SP<CEventLoopTimer> self, void*) {
    for (auto& w : Desktop::windowState()->windows()) {
        if (!validMapped(w) || w->isHidden())
            continue;
        for (auto& d : w->presentation().decorations()) {
            if (d->getDisplayName() != "SnowCap")
                continue;
            auto* cap = dynamic_cast<CSnowCap*>(d.get());
            if (cap && cap->needsRedraw())
                cap->damageEntire();
        }
    }
    self->updateTimeout(GROW_TICK);
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const std::string HASH        = __hyprland_api_get_hash();
    const std::string CLIENT_HASH = __hyprland_api_get_client_hash();

    if (HASH != CLIENT_HASH) {
        HyprlandAPI::addNotification(PHANDLE, "[snowcaps] Version mismatch with running Hyprland — rebuild the plugin", CHyprColor{1.0, 0.2, 0.2, 1.0}, 8000);
        throw std::runtime_error("[snowcaps] Version mismatch");
    }

    snowVars.growMinutes = makeShared<Config::Values::CIntValue>("plugin:snowcaps:grow_minutes", "Minutes until a snow cap is fully grown", 30,
                                                                 Config::Values::SIntValueOptions{.min = 1, .max = 1440});
    snowVars.maxHeight   = makeShared<Config::Values::CIntValue>("plugin:snowcaps:max_height", "Full snow cap height in px", 32,
                                                                 Config::Values::SIntValueOptions{.min = 4, .max = 64});
    snowVars.color       = makeShared<Config::Values::CColorValue>("plugin:snowcaps:col.snow", "Snow color", 0xFFFFFFFF);

    HyprlandAPI::addConfigValueV2(PHANDLE, snowVars.growMinutes);
    HyprlandAPI::addConfigValueV2(PHANDLE, snowVars.maxHeight);
    HyprlandAPI::addConfigValueV2(PHANDLE, snowVars.color);
    HyprlandAPI::reloadConfig();

    g_openListener = Event::bus()->m_events.window.open.listen([](PHLWINDOW w) { addCap(w); });

    for (auto& w : Desktop::windowState()->windows()) {
        if (w->isHidden() || !validMapped(w))
            continue;
        addCap(w);
    }

    g_growTimer = makeShared<CEventLoopTimer>(GROW_TICK, onGrowTick, nullptr);
    g_pEventLoopManager->addTimer(g_growTimer);

    return {"snowcaps", "Snow piling up on top of your windows.", "levi", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_openListener.reset();
    if (g_growTimer) {
        g_pEventLoopManager->removeTimer(g_growTimer);
        g_growTimer.reset();
    }
    g_pHyprRenderer->context().m_pass.removeAllOfType("CSnowCapPassElement");
}
