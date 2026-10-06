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
