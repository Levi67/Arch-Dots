// Snow cap for Quickshell popups (Launcher, wallpaper picker): the same cartoony pillow + drips
// the hypr-snowcaps plugin draws on windows (ported from SnowCap.cpp), which can't reach layer surfaces.
// Snow stacks up while the popup is open, is kept between opens and slowly melts while it's closed.
//
// Place it as a sibling of the card (not inside a clipping item):
//   PopupSnowCap { target: card; open: win.visible }
import QtQuick
import "../../theme"

Item {
    id: root

    required property Item target          // the card the snow sits on (same parent as this item)
    property bool open: false               // popup currently shown?
    property real cornerRadius: target?.radius ?? 0
    property color snow: "white"

    readonly property bool on: Winter.capsOn
    readonly property real maxH: Winter.capMaxHeight
    readonly property real above: 1.3 * maxH + 6
    readonly property real below: 1.35 * maxH + 6

    // growth 0..1 (starts a bit grown so a quick glance already shows some snow)
    property real growth: 0.15
    readonly property int steps: 40
    readonly property int step: Math.round(Math.max(0, Math.min(1, growth)) * steps)
    readonly property real seed: Math.random() * 1000

    visible: on && (target?.visible ?? false)
    x: target ? target.x : 0
    y: target ? target.y - above : 0
    z: (target?.z ?? 0) + 1
    width: target ? target.width : 0
    height: above + below
    opacity: target?.opacity ?? 1
    scale: target?.scale ?? 1
    transformOrigin: Item.Bottom

    // ---- growth bookkeeping (cheap: every 2 s, only while winter caps are on) ----
    property real last: Date.now()
    Timer {
        interval: 2000
        repeat: true
        running: root.on && (root.open || root.growth > 0.15)
        onTriggered: {
            const now = Date.now(), dt = now - root.last;
            root.last = now;
            if (root.open)
                root.growth = Math.min(1, root.growth + dt / Winter.popupCapGrowMs);
            else
                root.growth = Math.max(0.15, root.growth - dt / Winter.popupCapMeltMs);
        }
    }
    onOpenChanged: last = Date.now()

    onStepChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onMaxHChanged: canvas.requestPaint()
    onCornerRadiusChanged: canvas.requestPaint()

    function rnd(i) {
        const v = Math.sin(seed * 12.9898 + i * 78.233) * 43758.5453;
        return v - Math.floor(v);
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.visible
        renderTarget: Canvas.Image
        onVisibleChanged: if (visible)
            requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const W = width;
            if (W <= 0)
                return;

            const MAXH = root.maxH;
            const g = root.step / root.steps;
            const eased = 1 - Math.pow(1 - g, 2);
            const H = MAXH * (0.3 + 0.7 * eased);

            ctx.save();
            ctx.translate(0, root.above);   // y = 0: the card's top edge
            ctx.fillStyle = root.snow;
            ctx.beginPath();

            // ---- pillow: slab + soft mounds, draped over the rounded corners ----
            const base = 4.0;
            const slabH = base + H * 0.5;
            const N = W < 350 ? 2 : W < 1000 ? 3 : 4;
            const slot = W / N;
            const mounds = [];
            for (let i = 0; i < N; ++i) {
                const hw = slot * 0.5 * (0.7 + 0.28 * root.rnd(i * 4));
                const c = slot * (i + 0.5) + (slot * 0.5 - hw) * (root.rnd(i * 4 + 1) * 2 - 1);
                mounds.push({
                    c: c,
                    hw: hw,
                    amp: H * (0.35 + 0.4 * root.rnd(i * 4 + 2))
                });
            }
            const heightAt = x => {
                let h = slabH;
                for (const m of mounds) {
                    const t = (x - m.c) / m.hw;
                    if (Math.abs(t) < 1)
                        h += m.amp * (1 - t * t) * (1 - t * t);
                }
                return h;
            };
            const R = Math.max(0, root.cornerRadius);
            const edgeY = x => {
                const d = Math.min(x, W - x);
                if (R <= 0 || d >= R)
                    return 0;
                const dd = Math.max(0, d);
                return R - Math.sqrt(R * R - (R - dd) * (R - dd));
            };
            const thick = x => {
                const d = Math.min(x, W - x);
                const t = Math.max(0, Math.min(1, d / (R + slabH)));
                return heightAt(x) * (0.45 + 0.55 * t * t * (3 - 2 * t));
            };
            const tEnd = thick(0);
            const rcTop = tEnd * 0.7, rcBot = tEnd * 0.3;
            const round = (r, d) => d < r ? r - Math.sqrt(r * r - (r - d) * (r - d)) : 0;

            ctx.moveTo(0, edgeY(0) + base - rcBot);
            for (let x = 0; x <= W; x += 1)
                ctx.lineTo(x, edgeY(x) + base - round(rcBot, Math.min(x, W - x)));
            for (let x = W; x >= 0; x -= 1)
                ctx.lineTo(x, edgeY(x) + base - thick(x) + round(rcTop, Math.min(x, W - x)));
            ctx.closePath();

            // ---- frosting drips: appear one by one, grow longer and fatter ----
            for (let i = 0; i < N; ++i) {
                const appear = 0.1 + 0.6 * root.rnd(100 + i * 4);
                if (g <= appear)
                    continue;
                const t = (g - appear) / (1 - appear);
                const br = MAXH * (0.3 + 0.12 * root.rnd(101 + i * 4)) * (0.55 + 0.45 * t);
                const sw = br * 0.9, fil = br * 0.8;
                const minL = 2.1 * br;
                const len = minL + Math.max(0, MAXH * 1.25 - minL) * t * (0.5 + 0.5 * root.rnd(102 + i * 4));
                const cx = R + 16 + br + Math.max(0, W - 2 * R - 32 - 2 * br) * ((i + 0.2 + 0.6 * root.rnd(103 + i * 4)) / N);
                const by = base + len - br;
                const k = Math.sqrt(br * br - sw * sw);

                ctx.moveTo(cx - sw - fil, base - 1);
                ctx.bezierCurveTo(cx - sw, base - 1, cx - sw, base, cx - sw, base + fil);
                ctx.lineTo(cx - sw, by - k);
                ctx.arc(cx, by, br, Math.atan2(-k, -sw), Math.atan2(-k, sw), true);
                ctx.lineTo(cx + sw, base + fil);
                ctx.bezierCurveTo(cx + sw, base, cx + sw, base - 1, cx + sw + fil, base - 1);
                ctx.closePath();
            }

            ctx.fill();   // nonzero winding, like the plugin
            ctx.restore();
        }
    }
}
