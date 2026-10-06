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
