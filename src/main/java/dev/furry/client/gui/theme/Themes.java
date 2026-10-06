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
