#!/usr/bin/env bash
set -e

BASE="src/main/java/dev/furry/client"
mkdir -p "$BASE/core/events" "$BASE/module" "$BASE/setting/settings" "$BASE/gui" "$BASE/mixin" src/main/resources

cat > .gitignore <<'EOF'
.gradle/
build/
out/
*.iml
.idea/
run/
EOF

cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2G
org.gradle.parallel=true

minecraft_version=1.21.11
yarn_mappings=1.21.11+build.1
loader_version=0.16.9

mod_version=1.0.0
maven_group=dev.furry
archives_base_name=furryclient

fabric_version=0.115.0+1.21.11
EOF

cat > settings.gradle <<'EOF'
pluginManagement {
    repositories {
        maven { url = 'https://maven.fabricmc.net/' }
        gradlePluginPortal()
    }
}
rootProject.name = 'furryclient'
EOF

cat > build.gradle <<'EOF'
plugins {
    id 'fabric-loom' version '1.9-SNAPSHOT'
    id 'maven-publish'
}

version = project.mod_version
group = project.maven_group

base { archivesName = project.archives_base_name }

repositories {
    mavenCentral()
    maven { url = "https://maven.fabricmc.net/" }
}

dependencies {
    minecraft "com.mojang:minecraft:${project.minecraft_version}"
    mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"
    modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_version}"
}

processResources {
    inputs.property "version", project.version
    filesMatching("fabric.mod.json") {
        expand "version": project.version
    }
}

tasks.withType(JavaCompile).configureEach {
    it.options.release = 21
}

java {
    withSourcesJar()
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}
EOF

cat > src/main/resources/fabric.mod.json <<'EOF'
{
  "schemaVersion": 1,
  "id": "furryclient",
  "version": "${version}",
  "name": "FurryClient",
  "description": "Anarchy & PvP client for Minecraft 1.21.11",
  "authors": ["AN0nYMouS-ViP"],
  "license": "MIT",
  "environment": "client",
  "entrypoints": {
    "client": ["dev.furry.client.FurryClient"]
  },
  "mixins": ["furryclient.mixins.json"],
  "depends": {
    "fabricloader": ">=0.16.0",
    "minecraft": "~1.21.11",
    "java": ">=21",
    "fabric-api": "*"
  }
}
EOF

cat > src/main/resources/furryclient.mixins.json <<'EOF'
{
  "required": true,
  "package": "dev.furry.client.mixin",
  "compatibilityLevel": "JAVA_21",
  "client": [
    "ClientPlayerEntityMixin",
    "ClientPlayNetworkHandlerMixin"
  ],
  "injectors": { "defaultRequire": 1 }
}
EOF

cat > "$BASE/FurryClient.java" <<'EOF'
package dev.furry.client;

import dev.furry.client.core.EventBus;
import dev.furry.client.core.ModuleManager;
import dev.furry.client.core.ConfigManager;
import dev.furry.client.core.KeybindManager;
import dev.furry.client.gui.ClickGui;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.minecraft.client.MinecraftClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FurryClient implements ClientModInitializer {
    public static final String MOD_ID = "furryclient";
    public static final String NAME = "FurryClient";
    public static final String VERSION = "1.0.0";
    public static final Logger LOG = LoggerFactory.getLogger(NAME);

    public static FurryClient INSTANCE;
    public static MinecraftClient MC;

    public EventBus events;
    public ModuleManager modules;
    public ConfigManager config;
    public KeybindManager keybinds;
    public ClickGui clickGui;

    @Override
    public void onInitializeClient() {
        INSTANCE = this;
        MC = MinecraftClient.getInstance();

        LOG.info("[FurryClient] booting v{}", VERSION);

        this.events   = new EventBus();
        this.modules  = new ModuleManager();
        this.config   = new ConfigManager();
        this.keybinds = new KeybindManager();
        this.clickGui = new ClickGui();

        this.modules.registerAll();
        this.config.load();
        this.keybinds.register();

        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            if (client.player == null) return;
            this.keybinds.tick();
            this.modules.tick();
        });

        LOG.info("[FurryClient] {} modules loaded", this.modules.size());
    }
}
EOF

cat > "$BASE/core/EventBus.java" <<'EOF'
package dev.furry.client.core;

import java.util.*;
import java.util.function.Consumer;

public final class EventBus {
    private final Map<Class<?>, List<Consumer<?>>> listeners = new HashMap<>();

    public <T> void on(Class<T> type, Consumer<T> handler) {
        listeners.computeIfAbsent(type, k -> new ArrayList<>()).add(handler);
    }

    @SuppressWarnings("unchecked")
    public <T> void fire(T event) {
        List<Consumer<?>> list = listeners.get(event.getClass());
        if (list == null) return;
        for (Consumer<?> c : list) {
            try { ((Consumer<T>) c).accept(event); }
            catch (Throwable t) { dev.furry.client.FurryClient.LOG.error("listener threw on {}", event.getClass().getSimpleName(), t); }
        }
    }
}
EOF

cat > "$BASE/core/events/Events.java" <<'EOF'
package dev.furry.client.core.events;

import net.minecraft.client.gui.DrawContext;
import net.minecraft.network.packet.Packet;

public final class Events {
    private Events() {}
    public record Tick() {}
    public record Render2D(DrawContext ctx, float tickDelta) {}
    public record Render3D(DrawContext ctx, float tickDelta) {}
    public record KeyPress(int key, int scancode, int action, int mods) {}
    public record PacketSend(Packet<?> packet, boolean cancelable) {}
    public record PacketReceive(Packet<?> packet, boolean cancelable) {}
}
EOF

cat > "$BASE/module/Module.java" <<'EOF'
package dev.furry.client.module;

import dev.furry.client.setting.Setting;
import java.util.ArrayList;
import java.util.List;

public abstract class Module {
    private final String name;
    private final String description;
    private final Category category;
    private boolean enabled;
    private int keybind = -1;

    public final List<Setting<?>> settings = new ArrayList<>();

    public Module(String name, String description, Category category) {
        this.name = name;
        this.description = description;
        this.category = category;
    }

    protected <T extends Setting<?>> T add(T setting) { settings.add(setting); return setting; }

    public void onEnable() {}
    public void onDisable() {}
    public void onTick() {}

    public void toggle() { setEnabled(!enabled); }

    public void setEnabled(boolean value) {
        if (this.enabled == value) return;
        this.enabled = value;
        if (value) onEnable(); else onDisable();
    }

    public String getName() { return name; }
    public String getDescription() { return description; }
    public Category getCategory() { return category; }
    public boolean isEnabled() { return enabled; }
    public int getKeybind() { return keybind; }
    public void setKeybind(int k) { this.keybind = k; }

    public enum Category {
        COMBAT("Combat"),
        MOVEMENT("Movement"),
        VISUALS("Visuals"),
        COSMETICS("Cosmetics"),
        WORLD("World"),
        MISC("Misc");
        public final String display;
        Category(String d) { this.display = d; }
    }
}
EOF

cat > "$BASE/setting/Setting.java" <<'EOF'
package dev.furry.client.setting;

import com.google.gson.JsonElement;

public abstract class Setting<T> {
    public final String name;
    public final String description;
    protected T value;
    protected T defaultValue;

    public Setting(String name, String description, T defaultValue) {
        this.name = name;
        this.description = description;
        this.value = defaultValue;
        this.defaultValue = defaultValue;
    }

    public T get() { return value; }
    public void set(T v) { this.value = v; }
    public T getDefault() { return defaultValue; }
    public void reset() { this.value = defaultValue; }

    public abstract JsonElement toJson();
    public abstract void fromJson(JsonElement json);
}
EOF

cat > "$BASE/setting/settings/BooleanSetting.java" <<'EOF'
package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class BooleanSetting extends Setting<Boolean> {
    public BooleanSetting(String name, String desc, boolean def) { super(name, desc, def); }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsBoolean(); }
}
EOF

cat > "$BASE/setting/settings/IntSetting.java" <<'EOF'
package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class IntSetting extends Setting<Integer> {
    public final int min, max;
    public IntSetting(String name, String desc, int def, int min, int max) {
        super(name, desc, def);
        this.min = min; this.max = max;
    }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsInt(); }
}
EOF

cat > "$BASE/setting/settings/DoubleSetting.java" <<'EOF'
package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class DoubleSetting extends Setting<Double> {
    public final double min, max;
    public DoubleSetting(String name, String desc, double def, double min, double max) {
        super(name, desc, def);
        this.min = min; this.max = max;
    }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsDouble(); }
}
EOF

cat > "$BASE/setting/settings/EnumSetting.java" <<'EOF'
package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class EnumSetting<E extends Enum<E>> extends Setting<E> {
    public final E[] values;
    public EnumSetting(String name, String desc, E def) {
        super(name, desc, def);
        this.values = def.getDeclaringClass().getEnumConstants();
    }
    public void cycle() { int i = (value.ordinal() + 1) % values.length; this.value = values[i]; }
    @Override public JsonElement toJson() { return new JsonPrimitive(value.name()); }
    @Override public void fromJson(JsonElement j) { this.value = Enum.valueOf(value.getDeclaringClass(), j.getAsString()); }
}
EOF

cat > "$BASE/setting/settings/KeybindSetting.java" <<'EOF'
package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class KeybindSetting extends Setting<Integer> {
    public KeybindSetting(String name, String desc, int def) { super(name, desc, def); }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsInt(); }
}
EOF

cat > "$BASE/core/ModuleManager.java" <<'EOF'
package dev.furry.client.core;

import dev.furry.client.module.Module;
import java.util.*;

public final class ModuleManager {
    private final List<Module> modules = new ArrayList<>();
    private final Map<Class<?>, Module> byClass = new HashMap<>();

    public void registerAll() {}

    public void register(Module m) { modules.add(m); byClass.put(m.getClass(), m); }

    @SuppressWarnings("unchecked")
    public <T extends Module> T get(Class<T> type) { return (T) byClass.get(type); }

    public List<Module> all() { return modules; }
    public int size() { return modules.size(); }

    public List<Module> byCategory(Module.Category cat) {
        List<Module> out = new ArrayList<>();
        for (Module m : modules) if (m.getCategory() == cat) out.add(m);
        return out;
    }

    public void tick() {
        for (Module m : modules) {
            if (m.isEnabled()) {
                try { m.onTick(); }
                catch (Throwable t) { dev.furry.client.FurryClient.LOG.error("module {} tick failed", m.getName(), t); }
            }
        }
    }
}
EOF

cat > "$BASE/core/ConfigManager.java" <<'EOF'
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
EOF

cat > "$BASE/core/KeybindManager.java" <<'EOF'
package dev.furry.client.core;

import dev.furry.client.FurryClient;
import dev.furry.client.module.Module;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;

public final class KeybindManager {
    private KeyBinding openGui;
    private final java.util.Map<Module, Boolean> wasDown = new java.util.HashMap<>();

    public void register() {
        openGui = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                "key.furryclient.gui",
                InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_RIGHT_SHIFT,
                "category.furryclient"
        ));
    }

    public void tick() {
        while (openGui.wasPressed()) {
            FurryClient.MC.setScreen(FurryClient.INSTANCE.clickGui);
        }
        for (Module m : FurryClient.INSTANCE.modules.all()) {
            int k = m.getKeybind();
            if (k <= 0) continue;
            boolean down = InputUtil.isKeyPressed(FurryClient.MC.getWindow().getHandle(), k);
            if (down && !wasDown.getOrDefault(m, false)) m.toggle();
            wasDown.put(m, down);
        }
    }
}
EOF

cat > "$BASE/gui/ClickGui.java" <<'EOF'
package dev.furry.client.gui;

import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;

public class ClickGui extends Screen {
    public ClickGui() { super(Text.literal("FurryClient")); }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        super.render(ctx, mouseX, mouseY, delta);
    }

    @Override
    public boolean shouldPause() { return false; }
}
EOF

cat > "$BASE/mixin/ClientPlayNetworkHandlerMixin.java" <<'EOF'
package dev.furry.client.mixin;

import dev.furry.client.FurryClient;
import dev.furry.client.core.events.Events;
import net.minecraft.client.network.ClientPlayNetworkHandler;
import net.minecraft.network.packet.Packet;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayNetworkHandler.class)
public class ClientPlayNetworkHandlerMixin {
    @Inject(method = "sendPacket", at = @At("HEAD"), cancellable = true)
    private void furryclient$sendPacket(Packet<?> packet, CallbackInfo ci) {
        FurryClient.INSTANCE.events.fire(new Events.PacketSend(packet, true));
    }
}
EOF

cat > "$BASE/mixin/ClientPlayerEntityMixin.java" <<'EOF'
package dev.furry.client.mixin;

import net.minecraft.client.network.ClientPlayerEntity;
import org.spongepowered.asm.mixin.Mixin;

@Mixin(ClientPlayerEntity.class)
public class ClientPlayerEntityMixin {
}
EOF

echo "FurryClient scaffold written."
find . -type f -not -path './.git/*' -not -path './.gradle/*' | sort