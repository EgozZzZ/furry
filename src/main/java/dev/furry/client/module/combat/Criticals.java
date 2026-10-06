package dev.furry.client.module.combat;

import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.EnumSetting;

public class Criticals extends Module {
    public enum Mode { PACKET, ATTACK_FLAG }

    public final EnumSetting<Mode> mode = add(new EnumSetting<>("Mode", "Crit technique", Mode.ATTACK_FLAG));
    public final BooleanSetting onlyOnGround = add(new BooleanSetting("Ground Only", "Only fire when grounded", true));

    public Criticals() {
        super("Criticals", "Force critical hits", Category.COMBAT);
    }
}
