#include "SnowCapPass.hpp"
#include "SnowCap.hpp"

#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>

CSnowCapPassElement::CSnowCapPassElement(CSnowCap* deco, float a) : m_deco(deco), m_a(a) {
    ;
}

std::vector<UP<IPassElement>> CSnowCapPassElement::draw(Render::CRenderContext& ctx) {
    m_deco->drawPass(ctx, ctx.m_data.pMonitor.lock(), m_a);
    return {};
}
