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
