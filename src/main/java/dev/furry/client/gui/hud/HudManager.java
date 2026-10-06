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
