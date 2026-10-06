#!/usr/bin/env bash
set -e
BASE="src/main/java/dev/furry/client"
mkdir -p "$BASE/gui/render" "$BASE/gui/theme" "$BASE/gui/panel" "$BASE/gui/widget" "$BASE/gui/hud"

cat > "$BASE/gui/render/Render2D.java" << 'EOF'
package dev.furry.client.gui.render;

import net.minecraft.client.gui.DrawContext;

public final class Render2D {
    private Render2D() {}

    public static void rect(DrawContext ctx, int x, int y, int w, int h, int color) {
        ctx.fill(x, y, x + w, y + h, color);
    }

    public static void vGradient(DrawContext ctx, int x, int y, int w, int h, int top, int bottom) {
        ctx.fillGradient(x, y, x + w, y + h, top, bottom);
    }

    public static void roundedRect(DrawContext ctx, int x, int y, int w, int h, int r, int color) {
        r = Math.min(r, Math.min(w / 2, h / 2));
        if (r <= 0) { ctx.fill(x, y, x + w, y + h, color); return; }
        ctx.fill(x + r, y, x + w - r, y + h, color);
        ctx.fill(x, y + r, x + r, y + h - r, color);
        ctx.fill(x + w - r, y + r, x + w, y + h - r, color);
        circleQuadrant(ctx, x + r, y + r, r, color, 0, 0);
        circleQuadrant(ctx, x + w - r, y + r, r, color, 1, 0);
        circleQuadrant(ctx, x + r, y + h - r, r, color, 0, 1);
        circleQuadrant(ctx, x + w - r, y + h - r, r, color, 1, 1);
    }

    private static void circleQuadrant(DrawContext ctx, int cx, int cy, int r, int color, int qx, int qy) {
        for (int dy = -r; dy <= 0; dy++) {
            int dx = (int) Math.sqrt(r * r - dy * dy);
            int px = qx == 0 ? cx - dx : cx;
            int py = qy == 0 ? cy + dy : cy - dy;
            ctx.fill(px, py, px + dx, py + 1, color);
        }
    }

    public static void outline(DrawContext ctx, int x, int y, int w, int h, int thickness, int color) {
        ctx.fill(x, y, x + w, y + thickness, color);
        ctx.fill(x, y + h - thickness, x + w, y + h, color);
        ctx.fill(x, y + thickness, x + thickness, y + h - thickness, color);
        ctx.fill(x + w - thickness, y + thickness, x + w, y + h - thickness, color);
    }

    public static void shadow(DrawContext ctx, int x, int y, int w, int h, int r, int spread, int color) {
        for (int i = spread; i > 0; i--) {
            int a = (color >>> 24) * (spread - i + 1) / spread / 3;
            int c = (a << 24) | (color & 0xFFFFFF);
            roundedRect(ctx, x - i, y - i, w + i * 2, h + i * 2, r + i, c);
        }
    }
}
EOF

cat > "$BASE/gui/render/Animator.java" << 'EOF'
package dev.furry.client.gui.render;

public final class Animator {
    private float value, target, speed;
    private long lastMs;

    public Animator(float initial, float speed) {
        this.value = initial;
        this.target = initial;
        this.speed = speed;
        this.lastMs = System.currentTimeMillis();
    }

    public void setTarget(float t) { this.target = t; }
    public void setImmediate(float v) { this.value = v; this.target = v; }
    public float get() { return value; }

    public float update() {
        long now = System.currentTimeMillis();
        float dt = Math.min(100, now - lastMs) / 1000f;
        lastMs = now;
        float diff = target - value;
        value += diff * Math.min(1f, speed * dt * 20f);
        if (Math.abs(diff) < 0.001f) value = target;
        return value;
    }

    public boolean isAnimating() { return Math.abs(target - value) > 0.001f; }
}
EOF

cat > "$BASE/gui/theme/Theme.java" << 'EOF'
package dev.furry.client.gui.theme;

import com.google.gson.JsonObject;

public final class Theme {
    public final String name;
    public int background, backgroundAlt, headerBar, accent, accentDim;
    public int text, textDim, border, enabled, disabled, hoverOverlay;

    public Theme(String name) { this.name = name; }

    public JsonObject toJson() {
        JsonObject o = new JsonObject();
        o.addProperty("name", name);
        o.addProperty("background", background);
        o.addProperty("backgroundAlt", backgroundAlt);
        o.addProperty("headerBar", headerBar);
        o.addProperty("accent", accent);
        o.addProperty("accentDim", accentDim);
        o.addProperty("text", text);
        o.addProperty("textDim", textDim);
        o.addProperty("border", border);
        o.addProperty("enabled", enabled);
        o.addProperty("disabled", disabled);
        o.addProperty("hoverOverlay", hoverOverlay);
        return o;
    }

    public static Theme fromJson(JsonObject o) {
        Theme t = new Theme(o.get("name").getAsString());
        t.background = o.get("background").getAsInt();
        t.backgroundAlt = o.get("backgroundAlt").getAsInt();
        t.headerBar = o.get("headerBar").getAsInt();
        t.accent = o.get("accent").getAsInt();
        t.accentDim = o.get("accentDim").getAsInt();
        t.text = o.get("text").getAsInt();
        t.textDim = o.get("textDim").getAsInt();
        t.border = o.get("border").getAsInt();
        t.enabled = o.get("enabled").getAsInt();
        t.disabled = o.get("disabled").getAsInt();
        t.hoverOverlay = o.get("hoverOverlay").getAsInt();
        return t;
    }
}
EOF

cat > "$BASE/gui/theme/Themes.java" << 'EOF'
package dev.furry.client.gui.theme;

import java.util.List;

public final class Themes {
    private Themes() {}

    public static Theme darkGlassNeon() {
        Theme t = new Theme("Dark Glass Neon");
        t.background = 0xE6101418;
        t.backgroundAlt = 0xF0181C22;
        t.headerBar = 0xFF1E2430;
        t.accent = 0xFF00E5FF;
        t.accentDim = 0x4000E5FF;
        t.text = 0xFFE8ECF2;
        t.textDim = 0xFF7A8595;
        t.border = 0x30FFFFFF;
        t.enabled = 0xFF00E5FF;
        t.disabled = 0xFF404650;
        t.hoverOverlay = 0x18FFFFFF;
        return t;
    }

    public static Theme softPastel() {
        Theme t = new Theme("Soft Pastel");
        t.background = 0xE61C1820;
        t.backgroundAlt = 0xF0241F2A;
        t.headerBar = 0xFF2E2838;
        t.accent = 0xFFC8A8FF;
        t.accentDim = 0x40C8A8FF;
        t.text = 0xFFF0E8F5;
        t.textDim = 0xFF9A8AA8;
        t.border = 0x30FFFFFF;
        t.enabled = 0xFFB0FFD8;
        t.disabled = 0xFF4A4055;
        t.hoverOverlay = 0x18FFFFFF;
        return t;
    }

    public static Theme midnightBlue() {
        Theme t = new Theme("Midnight Blue");
        t.background = 0xE6080C1A;
        t.backgroundAlt = 0xF00C1226;
        t.headerBar = 0xFF141C36;
        t.accent = 0xFF4A7CFF;
        t.accentDim = 0x404A7CFF;
        t.text = 0xFFE0E8FF;
        t.textDim = 0xFF6E7BA0;
        t.border = 0x30FFFFFF;
        t.enabled = 0xFF4A7CFF;
        t.disabled = 0xFF2A3350;
        t.hoverOverlay = 0x18FFFFFF;
        return t;
    }

    public static List<Theme> all() {
        return List.of(darkGlassNeon(), softPastel(), midnightBlue());
    }
}
EOF

cat > "$BASE/gui/theme/ThemeManager.java" << 'EOF'
package dev.furry.client.gui.theme;

import dev.furry.client.FurryClient;
import java.util.List;

public final class ThemeManager {
    private final List<Theme> themes = Themes.all();
    private Theme active = themes.get(0);

    public Theme active() { return active; }

    public void cycle() {
        int i = themes.indexOf(active);
        active = themes.get((i + 1) % themes.size());
        FurryClient.LOG.info("[FurryClient] theme -> {}", active.name);
    }

    public void set(Theme t) { this.active = t; }
}
EOF

cat > "$BASE/gui/widget/SettingWidget.java" << 'EOF'
package dev.furry.client.gui.widget;

import dev.furry.client.gui.render.Render2D;
import dev.furry.client.gui.theme.Theme;
import dev.furry.client.setting.Setting;
import dev.furry.client.setting.settings.*;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;

public final class SettingWidget {
    public static final int HEIGHT = 16;
    private SettingWidget() {}

    public static void draw(DrawContext ctx, Setting<?> s, int x, int y, int w, int mx, int my, Theme t) {
        MinecraftClient mc = MinecraftClient.getInstance();
        ctx.drawTextWithShadow(mc.textRenderer, s.name, x, y + 4, t.textDim);

        if (s instanceof BooleanSetting bs) {
            int boxW = 20, boxH = 10;
            int bx = x + w - boxW - 2;
            int by = y + 3;
            Render2D.roundedRect(ctx, bx, by, boxW, boxH, 5, bs.get() ? t.enabled : t.disabled);
            int knobX = bs.get() ? bx + boxW - 9 : bx + 1;
            Render2D.roundedRect(ctx, knobX, by + 1, 8, 8, 4, 0xFFFFFFFF);
        } else if (s instanceof IntSetting is) {
            drawSlider(ctx, x, y, w, is.get(), is.min, is.max, t);
            String val = String.valueOf(is.get());
            ctx.drawTextWithShadow(mc.textRenderer, val, x + w - mc.textRenderer.getWidth(val) - 2, y + 4, t.text);
        } else if (s instanceof DoubleSetting ds) {
            drawSlider(ctx, x, y, w, ds.get(), ds.min, ds.max, t);
            String val = String.format("%.2f", ds.get());
            ctx.drawTextWithShadow(mc.textRenderer, val, x + w - mc.textRenderer.getWidth(val) - 2, y + 4, t.text);
        } else if (s instanceof EnumSetting<?> es) {
            String val = es.get().name();
            int tw = mc.textRenderer.getWidth(val);
            ctx.drawTextWithShadow(mc.textRenderer, val, x + w - tw - 2, y + 4, t.accent);
        } else if (s instanceof KeybindSetting ks) {
            String val = ks.get() <= 0 ? "none" : "key " + ks.get();
            int tw = mc.textRenderer.getWidth(val);
            ctx.drawTextWithShadow(mc.textRenderer, val, x + w - tw - 2, y + 4, t.accent);
        }
    }

    private static void drawSlider(DrawContext ctx, int x, int y, int w, double val, double min, double max, Theme t) {
        int barX = x + w / 2 + 4;
        int barY = y + 6;
        int barW = w / 2 - 8;
        Render2D.roundedRect(ctx, barX, barY, barW, 4, 2, t.disabled);
        double frac = (val - min) / (max - min);
        int fillW = (int) (barW * frac);
        Render2D.roundedRect(ctx, barX, barY, fillW, 4, 2, t.accent);
        Render2D.roundedRect(ctx, barX + fillW - 2, barY - 2, 4, 8, 2, t.accent);
    }

    public static boolean click(Setting<?> s, int x, int y, int w, double mx, double my, int button) {
        if (mx < x || mx > x + w || my < y || my > y + HEIGHT) return false;
        if (s instanceof BooleanSetting bs) {
            if (button == 0) { bs.set(!bs.get()); return true; }
        } else if (s instanceof IntSetting is) {
            int barX = x + w / 2 + 4;
            int barW = w / 2 - 8;
            double frac = Math.max(0, Math.min(1, (mx - barX) / barW));
            is.set((int) Math.round(is.min + frac * (is.max - is.min)));
            return true;
        } else if (s instanceof DoubleSetting ds) {
            int barX = x + w / 2 + 4;
            int barW = w / 2 - 8;
            double frac = Math.max(0, Math.min(1, (mx - barX) / barW));
            ds.set(ds.min + frac * (ds.max - ds.min));
            return true;
        } else if (s instanceof EnumSetting<?> es) {
            if (button == 0) { es.cycle(); return true; }
        }
        return false;
    }
}
EOF

cat > "$BASE/gui/panel/CategoryPanel.java" << 'EOF'
package dev.furry.client.gui.panel;

import dev.furry.client.FurryClient;
import dev.furry.client.gui.render.Animator;
import dev.furry.client.gui.render.Render2D;
import dev.furry.client.gui.theme.Theme;
import dev.furry.client.gui.widget.SettingWidget;
import dev.furry.client.module.Module;
import dev.furry.client.setting.Setting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;

import java.util.*;

public class CategoryPanel {
    public static final int HEADER_H = 22;
    public static final int ROW_H = 18;
    public static final int PAD = 4;

    public final Module.Category category;
    public int x, y;
    private final int w = 160;

    private final List<Module> modules;
    private final Map<Module, Boolean> expanded = new HashMap<>();
    private final Map<Module, Animator> rowAnims = new HashMap<>();
    private final Map<Module, Animator> expandAnims = new HashMap<>();

    public CategoryPanel(Module.Category cat, int x, int y) {
        this.category = cat;
        this.x = x;
        this.y = y;
        this.modules = FurryClient.INSTANCE.modules.byCategory(cat);
        for (Module m : modules) {
            rowAnims.put(m, new Animator(0f, 8f));
            expandAnims.put(m, new Animator(0f, 10f));
        }
    }

    public int width() { return w; }

    public void render(DrawContext ctx, int mouseX, int mouseY, float delta, Theme t, int slide) {
        MinecraftClient mc = MinecraftClient.getInstance();

        int bodyH = HEADER_H;
        for (Module m : modules) {
            bodyH += ROW_H;
            if (expanded.getOrDefault(m, false)) {
                int sc = Math.max(1, m.settings.size());
                bodyH += sc * SettingWidget.HEIGHT + PAD;
            }
        }

        int py = y + slide;
        Render2D.shadow(ctx, x, py, w, bodyH, 6, 6, 0x80000000);
        Render2D.roundedRect(ctx, x, py, w, bodyH, 6, t.backgroundAlt);
        Render2D.outline(ctx, x, py, w, bodyH, 1, t.border);

        Render2D.roundedRect(ctx, x, py, w, HEADER_H, 6, t.headerBar);
        ctx.fill(x, py + HEADER_H - 4, x + w, py + HEADER_H, t.headerBar);
        ctx.drawTextWithShadow(mc.textRenderer, category.display, x + 8, py + 7, t.text);

        int rowY = py + HEADER_H;
        for (Module m : modules) {
            boolean hovered = mouseX >= x && mouseX <= x + w
                    && mouseY >= rowY && mouseY <= rowY + ROW_H;
            Animator hover = rowAnims.get(m);
            hover.setTarget(hovered ? 1f : 0f);
            float hv = hover.update();
            if (hv > 0.01f) {
                int a = (int) (((t.hoverOverlay >>> 24) & 0xFF) * hv);
                int overlay = (a << 24) | (t.hoverOverlay & 0xFFFFFF);
                ctx.fill(x + 2, rowY, x + w - 2, rowY + ROW_H, overlay);
            }

            int dotX = x + 8;
            int dotY = rowY + ROW_H / 2;
            if (m.isEnabled()) Render2D.roundedRect(ctx, dotX - 1, dotY - 4, 8, 8, 4, t.accentDim);
            Render2D.roundedRect(ctx, dotX, dotY - 3, 6, 6, 3, m.isEnabled() ? t.enabled : t.disabled);

            ctx.drawTextWithShadow(mc.textRenderer, m.getName(), x + 22, rowY + 5, t.text);

            if (!m.settings.isEmpty()) {
                Animator ea = expandAnims.get(m);
                ea.setTarget(expanded.getOrDefault(m, false) ? 1f : 0f);
                String arrow = ea.update() > 0.5f ? "v" : ">";
                ctx.drawTextWithShadow(mc.textRenderer, arrow, x + w - 14, rowY + 5, t.textDim);
            }

            rowY += ROW_H;

            if (expanded.getOrDefault(m, false)) {
                int startY = rowY;
                int idx = 0;
                for (Setting<?> s : m.settings) {
                    SettingWidget.draw(ctx, s, x + 8, startY + idx * SettingWidget.HEIGHT, w - 16, mouseX, mouseY, t);
                    idx++;
                }
                if (m.settings.isEmpty()) {
                    ctx.drawTextWithShadow(mc.textRenderer, "no settings", x + 12, startY + 4, t.textDim);
                }
                rowY += Math.max(1, idx) * SettingWidget.HEIGHT + PAD;
            }
        }
    }

    public boolean mouseClicked(double mx, double my, int button) {
        int rowY = y + HEADER_H;
        for (Module m : modules) {
            if (mx >= x && mx <= x + w && my >= rowY && my <= rowY + ROW_H) {
                if (button == 0) { m.toggle(); return true; }
                else if (button == 1 && !m.settings.isEmpty()) {
                    expanded.put(m, !expanded.getOrDefault(m, false));
                    return true;
                }
            }
            rowY += ROW_H;
            if (expanded.getOrDefault(m, false)) {
                int startY = rowY;
                int idx = 0;
                for (Setting<?> s : m.settings) {
                    int sy = startY + idx * SettingWidget.HEIGHT;
                    if (SettingWidget.click(s, x + 8, sy, w - 16, mx, my, button)) return true;
                    idx++;
                }
                rowY += Math.max(1, idx) * SettingWidget.HEIGHT + PAD;
            }
        }
        return false;
    }

    public boolean mouseScrolled(double mx, double my, double v) { return false; }
}
EOF

cat > "$BASE/gui/ClickGui.java" << 'EOF'
package dev.furry.client.gui;

import dev.furry.client.gui.panel.CategoryPanel;
import dev.furry.client.gui.theme.Theme;
import dev.furry.client.gui.theme.ThemeManager;
import dev.furry.client.module.Module;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;

import java.util.*;

public class ClickGui extends Screen {
    public static final ThemeManager THEMES = new ThemeManager();

    private final List<CategoryPanel> panels = new ArrayList<>();
    private Module.Category draggingCategory = null;
    private int dragOffsetX, dragOffsetY;
    private long openedAt;
    private float openAnim;

    public ClickGui() {
        super(Text.literal("FurryClient"));
        int x = 20;
        for (Module.Category cat : Module.Category.values()) {
            CategoryPanel p = new CategoryPanel(cat, x, 40);
            panels.add(p);
            x += p.width() + 10;
        }
    }

    @Override
    protected void init() {
        openedAt = System.currentTimeMillis();
        super.init();
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        long elapsed = System.currentTimeMillis() - openedAt;
        openAnim = Math.min(1f, elapsed / 220f);

        Theme t = THEMES.active();
        ctx.fill(0, 0, width, height, (int) (0xB0000000 * openAnim));

        int slide = (int) ((1f - openAnim) * 20);
        for (CategoryPanel p : panels) {
            p.render(ctx, mouseX, mouseY, delta, t, slide);
        }

        ctx.drawTextWithShadow(textRenderer, "FurryClient", 12, 12, t.text);
        ctx.drawTextWithShadow(textRenderer, "Theme: " + t.name + "  ·  T to cycle  ·  RShift to close", 12, 24, t.textDim);

        super.render(ctx, mouseX, mouseY, delta);
    }

    @Override
    public boolean mouseClicked(double mx, double my, int button) {
        for (CategoryPanel p : panels) {
            if (p.mouseClicked(mx, my, button)) return true;
            if (mx >= p.x && mx <= p.x + p.width() && my >= p.y && my <= p.y + CategoryPanel.HEADER_H) {
                if (button == 0) {
                    draggingCategory = p.category;
                    dragOffsetX = (int) mx - p.x;
                    dragOffsetY = (int) my - p.y;
                    return true;
                }
            }
        }
        return super.mouseClicked(mx, my, button);
    }

    @Override
    public boolean mouseReleased(double mx, double my, int button) {
        draggingCategory = null;
        return super.mouseReleased(mx, my, button);
    }

    @Override
    public boolean mouseDragged(double mx, double my, int button, double dx, double dy) {
        if (draggingCategory != null) {
            for (CategoryPanel p : panels) {
                if (p.category == draggingCategory) {
                    p.x = (int) mx - dragOffsetX;
                    p.y = (int) my - dragOffsetY;
                }
            }
            return true;
        }
        return super.mouseDragged(mx, my, button, dx, dy);
    }

    @Override
    public boolean charTyped(char c, int mods) {
        if (c == 't' || c == 'T') { THEMES.cycle(); return true; }
        return super.charTyped(c, mods);
    }

    @Override
    public boolean shouldPause() { return false; }
}
EOF

cat > "$BASE/gui/hud/HudManager.java" << 'EOF'
package dev.furry.client.gui.hud;

import net.minecraft.client.gui.DrawContext;
import java.util.*;

public final class HudManager {
    private final List<HudElement> elements = new ArrayList<>();
    public void register(HudElement e) { elements.add(e); }
    public List<HudElement> all() { return elements; }

    public void render(DrawContext ctx, float tickDelta) {
        for (HudElement e : elements) if (e.visible()) e.render(ctx, tickDelta);
    }

    public static abstract class HudElement {
        public int x, y;
        public boolean dragging;
        public int dragOffX, dragOffY;
        public abstract int width();
        public abstract int height();
        public abstract void render(DrawContext ctx, float delta);
        public boolean visible() { return true; }
    }
}
EOF

if ! grep -q "HudManager" src/main/java/dev/furry/client/FurryClient.java; then
  sed -i 's|import dev.furry.client.gui.ClickGui;|import dev.furry.client.gui.ClickGui;\nimport dev.furry.client.gui.hud.HudManager;|' src/main/java/dev/furry/client/FurryClient.java
  sed -i 's|public ClickGui clickGui;|public ClickGui clickGui;\n    public HudManager hud;|' src/main/java/dev/furry/client/FurryClient.java
  sed -i 's|this.clickGui = new ClickGui();|this.clickGui = new ClickGui();\n        this.hud = new HudManager();|' src/main/java/dev/furry/client/FurryClient.java
fi

echo "Turn 2 files written."
