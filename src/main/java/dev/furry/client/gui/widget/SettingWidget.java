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
