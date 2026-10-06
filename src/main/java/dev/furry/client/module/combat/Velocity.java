package dev.furry.client.module.combat;

import dev.furry.client.module.Aggression;
import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.DoubleSetting;
import dev.furry.client.setting.settings.EnumSetting;

public class Velocity extends Module {
    public final DoubleSetting horizontal = add(new DoubleSetting("Horizontal", "Knockback multiplier", 0.0, 0.0, 1.0));
    public final DoubleSetting vertical = add(new DoubleSetting("Vertical", "Vertical multiplier", 0.0, 0.0, 1.0));
    public final BooleanSetting explosionsOnly = add(new BooleanSetting("Explosions Only", "Only explosion knockback", false));
    public final EnumSetting<Aggression> aggression = add(new EnumSetting<>("Aggression", "Timing profile", Aggression.NORMAL));

    public Velocity() {
        super("Velocity", "Reduce or cancel knockback", Category.COMBAT);
    }
}
