#pragma once

#include <hyprland/src/render/pass/PassElement.hpp>

class CSnowCap;

class CSnowCapPassElement : public IPassElement {
  public:
    CSnowCapPassElement(CSnowCap* deco, float a);
    virtual ~CSnowCapPassElement() = default;

    virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override;
    virtual bool                          needsLiveBlur(Render::CRenderContext& ctx) override {
        return false;
    }
    virtual bool needsPrecomputeBlur(Render::CRenderContext& ctx) override {
        return false;
    }
    virtual const char* passName() override {
        return "CSnowCapPassElement";
    }
    virtual ePassElementType type() override {
        return EK_CUSTOM;
    }

  private:
    CSnowCap* m_deco = nullptr;
    float     m_a    = 1.F;
};
