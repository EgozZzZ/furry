package dev.furry.client.module.combat;

import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.DoubleSetting;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.player.PlayerInventory;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.screen.slot.SlotActionType;

public class AutoTotem extends Module {
    public final DoubleSetting health = add(new DoubleSetting("Health", "Swap below this HP", 14.0, 1.0, 20.0));
    public final BooleanSetting always = add(new BooleanSetting("Always", "Swap regardless of HP", false));

    private long lastSwap = 0L;

    public AutoTotem() {
        super("AutoTotem", "Move totems to offhand automatically", Category.COMBAT);
    }

    @Override
    public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.interactionManager == null) return;

        long now = System.currentTimeMillis();
        if (now - lastSwap < 200L) return;

        if (!always.get() && mc.player.getHealth() > health.get()) return;

        ItemStack off = mc.player.getOffHandStack();
        if (off.getItem() == Items.TOTEM_OF_UNDYING) return;

        PlayerInventory inv = mc.player.getInventory();
        int totemSlot = -1;
        for (int i = 0; i < 36; i++) {
            ItemStack s = inv.getStack(i);
            if (s.getItem() == Items.TOTEM_OF_UNDYING) { totemSlot = i; break; }
        }
        if (totemSlot == -1) return;

        int screenSlot = totemSlot < 9 ? totemSlot + 36 : totemSlot;
        mc.interactionManager.clickSlot(
                mc.player.playerScreenHandler.syncId,
                screenSlot,
                40,
                SlotActionType.SWAP,
                mc.player
        );
        lastSwap = now;
    }
}
