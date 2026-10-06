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
