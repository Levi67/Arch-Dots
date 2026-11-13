#include "SnowCap.hpp"
#include "SnowCapPass.hpp"
#include "globals.hpp"

#include <algorithm>
#include <cmath>

#include <cairo/cairo.h>
#include <drm_fourcc.h>

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>

using namespace Render::GL;

// cheap deterministic per-window randomness so a cap keeps its shape
static double rnd(uint32_t seed, uint32_t i) {
    uint64_t z = (uint64_t(seed) << 32) + i * 0x9E3779B97F4A7C15ULL;
    z          = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z          = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    z ^= z >> 31;
    return double(z & 0xFFFFFF) / double(0xFFFFFF);
}

static constexpr double OVERHANG_MAX = 8.0;
static constexpr int    GROW_STEPS   = 40; // texture is rebuilt at most this many times while growing

// room above/below the window's top border line, relative to max_height
static double above(double maxH) {
    return 1.3 * maxH + 6.0;
}
static double below(double maxH) {
    return 1.35 * maxH + 6.0;
}
static double easeOut(double g) {
    return 1.0 - std::pow(1.0 - g, 2.0);
}
static double overhang(double eased) {
    return 1.0; // the cap drapes over the rounded corners instead of sticking out
}

CSnowCap::CSnowCap(PHLWINDOW w) : IHyprWindowDecoration(w), m_window(w), m_born(std::chrono::steady_clock::now()) {
    m_seed     = uint32_t(reinterpret_cast<uintptr_t>(w.get()) >> 4) ^ uint32_t(m_born.time_since_epoch().count());
    m_lastPos  = w->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    m_lastSize = w->size(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
}

CSnowCap::~CSnowCap() {
    damageEntire();
}

bool CSnowCap::needsRedraw() const {
    return std::clamp(int(growth() * GROW_STEPS), 0, GROW_STEPS) != m_texStep;
}

double CSnowCap::growth() const {
    const double minutes = std::max<double>(0.1, snowVars.growMinutes->value());
    const double elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - m_born).count() / 60.0;
    return std::clamp(elapsed / minutes, 0.0, 1.0);
}

SDecorationPositioningInfo CSnowCap::getPositioningInfo() {
    SDecorationPositioningInfo info;
    info.policy         = DECORATION_POSITION_ABSOLUTE;
    info.edges          = DECORATION_EDGE_TOP;
    info.reserved       = false; // never push the layout around
    info.priority       = 5;
    info.desiredExtents = {Vector2D{OVERHANG_MAX, above(snowVars.maxHeight->value())}, Vector2D{OVERHANG_MAX, 0.0}};
    return info;
}

void CSnowCap::onPositioningReply(const SDecorationPositioningReply& reply) {
    ;
}

uint64_t CSnowCap::getDecorationFlags() {
    return DECORATION_NON_SOLID;
}

eDecorationLayer CSnowCap::getDecorationLayer() {
    return DECORATION_LAYER_OVER;
}

eDecorationType CSnowCap::getDecorationType() {
    return DECORATION_CUSTOM;
}

std::string CSnowCap::getDisplayName() {
    return "SnowCap";
}

void CSnowCap::draw(Render::CRenderContext& ctx, PHLMONITOR pMonitor, float const& a, const Render::SWindowRenderPresentation& presentation) {
    if (!validMapped(m_window))
        return;

    const auto PWINDOW = m_window.lock();

    if (!PWINDOW->m_ruleApplicator->decorate().valueOrDefault() || Fullscreen::controller()->isFullscreen(PWINDOW))
        return;

    g_pHyprRenderer->addPassElement(ctx, makeUnique<CSnowCapPassElement>(this, a));
}

void CSnowCap::rebuildTexture(double winW, double scale, int step, double cornerR) {
    const double MAXH  = snowVars.maxHeight->value();
    const double g     = double(step) / GROW_STEPS;
    const double eased = easeOut(g);
    const double H     = MAXH * (0.3 + 0.7 * eased); // current cap height
    const double ov    = overhang(eased);
    const double W     = winW + 2 * ov;
    const double ABOVE = above(MAXH);

    const int    texW = std::ceil(W * scale);
    const int    texH = std::ceil((ABOVE + below(MAXH)) * scale);

    auto*        surf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, texW, texH);
    auto*        cr   = cairo_create(surf);
    cairo_scale(cr, scale, scale);
    cairo_translate(cr, 0, ABOVE); // y = 0 is the window's outer top edge, x = 0 the cap's left end

    // ---- the pillow: slab + a few soft mounds, one smooth outline ----
    const double base   = 4.0;           // pillow bottom, slightly over the border
    const double slabH  = base + H * 0.5; // pillow thickness without mounds
    const int    N      = W < 350 ? 2 : W < 1000 ? 3 : 4;
    const double slot   = W / N;

    struct SMound {
        double c, hw, amp;
    };
    std::vector<SMound> mounds;
    for (int i = 0; i < N; ++i) {
        const double hw = slot * 0.5 * (0.7 + 0.28 * rnd(m_seed, i * 4));
        const double c  = slot * (i + 0.5) + (slot * 0.5 - hw) * (rnd(m_seed, i * 4 + 1) * 2.0 - 1.0);
        mounds.push_back({c, hw, H * (0.35 + 0.4 * rnd(m_seed, i * 4 + 2))});
    }

    const auto height = [&](double x) {
        double h = slabH;
        for (auto& m : mounds) {
            const double t = (x - m.c) / m.hw;
            if (std::abs(t) < 1.0)
                h += m.amp * (1.0 - t * t) * (1.0 - t * t); // smooth bump, flat tangents at its feet
        }
        return h;
    };

    // The window's outer top outline, including its rounded corners: the snow sits on
    // this line and drapes down over the corners, thinning towards the sides.
    const double R     = std::max(0.0, cornerR);
    const auto   edgeY = [&](double x) {
        const double d = std::min(x, W - x) - ov; // distance from the window's side
        if (R <= 0 || d >= R)
            return 0.0;
        const double dd = std::max(0.0, d);
        return R - std::sqrt(R * R - (R - dd) * (R - dd));
    };
    const auto thick = [&](double x) {
        const double d    = std::min(x, W - x);
        const double span = R + slabH;
        const double t    = std::clamp(d / span, 0.0, 1.0);
        return height(x) * (0.45 + 0.55 * t * t * (3.0 - 2.0 * t)); // smoothstep taper
    };

    const double tEnd  = thick(0);
    const double rcTop = tEnd * 0.7; // rounded tips at both ends
    const double rcBot = tEnd * 0.3;
    const auto   round = [](double r, double d) { return d < r ? r - std::sqrt(r * r - (r - d) * (r - d)) : 0.0; };

    cairo_new_sub_path(cr);
    cairo_move_to(cr, 0, edgeY(0) + base - rcBot);
    for (double x = 0; x <= W; x += 1.0) // underside, left -> right, following the window outline
        cairo_line_to(cr, x, edgeY(x) + base - round(rcBot, std::min(x, W - x)));
    for (double x = W; x >= 0; x -= 1.0) // top, right -> left
        cairo_line_to(cr, x, edgeY(x) + base - thick(x) + round(rcTop, std::min(x, W - x)));
    cairo_close_path(cr);

    // ---- frosting drips: appear one by one, grow longer and fatter ----
    const int DRIPS = N;
    for (int i = 0; i < DRIPS; ++i) {
        const double appear = 0.1 + 0.6 * rnd(m_seed, 100 + i * 4);
        if (g <= appear)
            continue;
        const double t    = (g - appear) / (1.0 - appear);
        const double br   = MAXH * (0.3 + 0.12 * rnd(m_seed, 101 + i * 4)) * (0.55 + 0.45 * t); // bulb radius
        const double sw   = br * 0.9;                                                               // stem half width
        const double fil  = br * 0.8;                                                               // fillet into the pillow
        const double minL = 2.1 * br;
        const double len  = minL + std::max(0.0, MAXH * 1.25 - minL) * t * (0.5 + 0.5 * rnd(m_seed, 102 + i * 4));
        const double cx   = ov + R + 16 + br + std::max(0.0, W - 2 * (ov + R) - 32 - 2 * br) * ((i + 0.2 + 0.6 * rnd(m_seed, 103 + i * 4)) / DRIPS);
        const double by   = base + len - br;
        const double k    = std::sqrt(br * br - sw * sw);

        cairo_new_sub_path(cr);
        cairo_move_to(cr, cx - sw - fil, base - 1);
        cairo_curve_to(cr, cx - sw, base - 1, cx - sw, base, cx - sw, base + fil);
        cairo_line_to(cr, cx - sw, by - k);
        cairo_arc_negative(cr, cx, by, br, std::atan2(-k, -sw), std::atan2(-k, sw));
        cairo_line_to(cr, cx + sw, base + fil);
        cairo_curve_to(cr, cx + sw, base, cx + sw, base - 1, cx + sw + fil, base - 1);
        cairo_close_path(cr);
    }

    const CHyprColor col = CHyprColor(uint64_t(snowVars.color->value()));
    cairo_set_source_rgba(cr, col.r, col.g, col.b, col.a);
    cairo_set_fill_rule(cr, CAIRO_FILL_RULE_WINDING);
    cairo_fill(cr);
    cairo_surface_flush(surf);

    m_tex = g_pHyprRenderer->createTexture(DRM_FORMAT_ARGB8888, cairo_image_surface_get_data(surf), cairo_image_surface_get_stride(surf), Vector2D{double(texW), double(texH)});

    cairo_destroy(cr);
    cairo_surface_destroy(surf);

    m_texW     = texW;
    m_texScale = scale;
    m_texCorner = cornerR;
    m_texStep  = step;
    m_texMaxH  = MAXH;
    m_texColor = snowVars.color->value();
}

void CSnowCap::drawPass(Render::CRenderContext& ctx, PHLMONITOR pMonitor, float a) {
    const auto PWINDOW = m_window.lock();
    if (!PWINDOW || !pMonitor)
        return;

    const auto   PWORKSPACE = PWINDOW->m_workspace;
    const auto   WSOFFSET   = PWORKSPACE && !(PWINDOW->m_state & Desktop::View::WINDOW_STATE_PINNED) ? PWORKSPACE->m_renderOffset->value() : Vector2D();
    const auto   POS        = PWINDOW->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    const auto   SIZE       = PWINDOW->size(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    const double BS         = PWINDOW->presentation().borderSize();
    const auto   OFFSET     = PWINDOW->presentation().floatingOffset() - pMonitor->m_position + WSOFFSET;
    const double SCALE      = pMonitor->m_scale;

    if (SIZE.x < 40 || SIZE.y < 40)
        return;

    const double MAXH  = snowVars.maxHeight->value();
    const int    step  = std::clamp(int(growth() * GROW_STEPS), 0, GROW_STEPS);
    const double ov    = overhang(easeOut(double(step) / GROW_STEPS));
    const double winW  = SIZE.x + 2 * BS;
    const int    wantW = std::ceil((winW + 2 * ov) * SCALE);
    const double ROUND  = PWINDOW->presentation().rounding();
    const double CORNER = ROUND > 0 ? ROUND + BS : 0.0;

    if (!m_tex || wantW != m_texW || SCALE != m_texScale || CORNER != m_texCorner || step != m_texStep || int(MAXH) != m_texMaxH || uint64_t(snowVars.color->value()) != m_texColor)
        rebuildTexture(winW, SCALE, step, CORNER);

    if (!m_tex)
        return;

    CBox box = {POS.x - BS - ov, POS.y - BS - above(MAXH), 0, 0};
    box.translate(OFFSET).scale(SCALE).round();
    box.w = m_texW;
    box.h = std::ceil((above(MAXH) + below(MAXH)) * SCALE);

    g_pHyprOpenGL->renderTexture(ctx, m_tex, box, {.a = a});
}

void CSnowCap::updateWindow(PHLWINDOW pWindow) {
    damageEntire();
    m_lastPos  = pWindow->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    m_lastSize = pWindow->size(Desktop::View::IGeometric::GEOMETRIC_CURRENT);
    damageEntire();
}

CBox CSnowCap::globalDamageBox() const {
    const double MAXH = snowVars.maxHeight->value();
    const double PAD  = OVERHANG_MAX + 8; // border + overhang
    return CBox{m_lastPos.x - PAD, m_lastPos.y - PAD - above(MAXH), m_lastSize.x + 2 * PAD, above(MAXH) + PAD + below(MAXH)};
}

void CSnowCap::damageEntire() {
    g_pHyprRenderer->damageBox(globalDamageBox());
}
