#pragma once

#define WLR_USE_UNSTABLE

#include <chrono>
#include <hyprland/src/render/Texture.hpp>
#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>

// A cozy, cartoony snow cap sitting on a window's top edge: a thick flat-white
// pillow with a few soft mounds and frosting drips that grow over time.
// It reserves no space (the layout is untouched). The shape is rasterized with
// cairo into a texture that is only rebuilt when width/scale/growth step change.
class CSnowCap : public IHyprWindowDecoration {
  public:
    CSnowCap(PHLWINDOW);
    virtual ~CSnowCap();

    virtual SDecorationPositioningInfo getPositioningInfo() override;
    virtual void                       onPositioningReply(const SDecorationPositioningReply& reply) override;
    virtual void                       draw(Render::CRenderContext& ctx, PHLMONITOR pMonitor, float const& a, const Render::SWindowRenderPresentation& presentation) override;
    virtual eDecorationType            getDecorationType() override;
    virtual void                       updateWindow(PHLWINDOW) override;
    virtual void                       damageEntire() override;
    virtual uint64_t                   getDecorationFlags() override;
    virtual eDecorationLayer           getDecorationLayer() override;
    virtual std::string                getDisplayName() override;

    // 0..1 growth, from creation time
    double growth() const;
    // the growth step moved on since the cap was last drawn
    bool needsRedraw() const;

  private:
    void                                  drawPass(Render::CRenderContext& ctx, PHLMONITOR pMonitor, float a);
    void                                  rebuildTexture(double widthLogical, double scale, int step, double cornerR);
    CBox                                  globalDamageBox() const;

    PHLWINDOWREF                          m_window;
    std::chrono::steady_clock::time_point m_born;
    uint32_t                              m_seed = 0;

    Vector2D                              m_lastPos;
    Vector2D                              m_lastSize;

    // texture cache
    SP<Render::ITexture>                  m_tex;
    int                                   m_texW = 0, m_texStep = -1, m_texMaxH = 0;
    double                                m_texScale = 0, m_texCorner = -1;
    uint64_t                              m_texColor = 0;

    friend class CSnowCapPassElement;
};
