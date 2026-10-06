package dev.furry.client.gui;

import dev.furry.client.gui.panel.CategoryPanel;
import dev.furry.client.gui.theme.Theme;
import dev.furry.client.gui.theme.ThemeManager;
import dev.furry.client.module.Module;
import net.minecraft.client.gui.Click;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.input.CharInput;
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
    public boolean mouseClicked(Click click, boolean doubled) {
        double mx = click.x();
        double my = click.y();
        int button = click.button();
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
        return super.mouseClicked(click, doubled);
    }

    @Override
    public boolean mouseReleased(Click click) {
        draggingCategory = null;
        return super.mouseReleased(click);
    }

    @Override
    public boolean mouseDragged(Click click, double dx, double dy) {
        if (draggingCategory != null) {
            for (CategoryPanel p : panels) {
                if (p.category == draggingCategory) {
                    p.x = (int) click.x() - dragOffsetX;
                    p.y = (int) click.y() - dragOffsetY;
                }
            }
            return true;
        }
        return super.mouseDragged(click, dx, dy);
    }

    @Override
    public boolean charTyped(CharInput input) {
        char c = (char) input.codepoint();
        if (c == 't' || c == 'T') { THEMES.cycle(); return true; }
        return super.charTyped(input);
    }

    @Override
    public boolean shouldPause() { return false; }
}
