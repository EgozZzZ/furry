package dev.furry.client.core;

import dev.furry.client.FurryClient;
import dev.furry.client.module.Module;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import net.minecraft.util.Identifier;
import org.lwjgl.glfw.GLFW;

public final class KeybindManager {
    private static final KeyBinding.Category CATEGORY =
            KeyBinding.Category.create(Identifier.of("furryclient", "main"));

    private KeyBinding openGui;
    private final java.util.Map<Module, Boolean> wasDown = new java.util.HashMap<>();

    public void register() {
        openGui = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                "key.furryclient.gui",
                InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_RIGHT_SHIFT,
                CATEGORY
        ));
    }

    public void tick() {
        while (openGui.wasPressed()) {
            FurryClient.MC.setScreen(FurryClient.INSTANCE.clickGui);
        }
        net.minecraft.client.util.Window win = FurryClient.MC.getWindow();
        for (Module m : FurryClient.INSTANCE.modules.all()) {
            int k = m.getKeybind();
            if (k <= 0) continue;
            boolean down = InputUtil.isKeyPressed(win, k);
            if (down && !wasDown.getOrDefault(m, false)) m.toggle();
            wasDown.put(m, down);
        }
    }
}
