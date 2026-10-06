package dev.furry.client.core;

import com.google.gson.*;
import dev.furry.client.FurryClient;
import dev.furry.client.module.Module;
import dev.furry.client.setting.Setting;

import java.nio.file.*;

public final class ConfigManager {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static final Path DIR = Paths.get("furryclient");

    public void load() {
        try {
            Files.createDirectories(DIR);
            Path file = DIR.resolve("default.json");
            if (!Files.exists(file)) { save(); return; }

            JsonObject root = JsonParser.parseString(Files.readString(file)).getAsJsonObject();
            for (Module m : FurryClient.INSTANCE.modules.all()) {
                if (!root.has(m.getName())) continue;
                JsonObject mo = root.getAsJsonObject(m.getName());
                if (mo.has("enabled")) m.setEnabled(mo.get("enabled").getAsBoolean());
                if (mo.has("keybind")) m.setKeybind(mo.get("keybind").getAsInt());
                if (mo.has("settings")) {
                    JsonObject so = mo.getAsJsonObject("settings");
                    for (Setting<?> s : m.settings) {
                        if (so.has(s.name)) {
                            try { s.fromJson(so.get(s.name)); }
                            catch (Throwable t) { FurryClient.LOG.warn("bad setting {}.{}", m.getName(), s.name); }
                        }
                    }
                }
            }
            FurryClient.LOG.info("[FurryClient] config loaded");
        } catch (Throwable t) { FurryClient.LOG.error("[FurryClient] config load failed", t); }
    }

    public void save() {
        try {
            Files.createDirectories(DIR);
            JsonObject root = new JsonObject();
            for (Module m : FurryClient.INSTANCE.modules.all()) {
                JsonObject mo = new JsonObject();
                mo.addProperty("enabled", m.isEnabled());
                mo.addProperty("keybind", m.getKeybind());
                JsonObject so = new JsonObject();
                for (Setting<?> s : m.settings) so.add(s.name, s.toJson());
                mo.add("settings", so);
                root.add(m.getName(), mo);
            }
            Files.writeString(DIR.resolve("default.json"), GSON.toJson(root));
        } catch (Throwable t) { FurryClient.LOG.error("[FurryClient] config save failed", t); }
    }
}
