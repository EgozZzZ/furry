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
            rowAnims.put(m, new Animator(0f, 12f));
            expandAnims.put(m, new Animator(0f, 14f));
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
