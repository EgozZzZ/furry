#!/usr/bin/env bash
set -e
BASE="src/main/java/dev/furry/client"
mkdir -p "$BASE/module/combat" "$BASE/util"

cat > "$BASE/module/Aggression.java" << 'EOF'
package dev.furry.client.module;

public enum Aggression {
    SUBTLE,
    NORMAL,
    ANARCHY
}
EOF

cat > "$BASE/util/CombatUtil.java" << 'EOF'
package dev.furry.client.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.Vec3d;

import java.util.Comparator;
import java.util.List;

public final class CombatUtil {
    private CombatUtil() {}

    public static List<Entity> entitiesAround(double range) {
        MinecraftClient mc = MinecraftClient.getInstance();
        ClientPlayerEntity me = mc.player;
        if (me == null || mc.world == null) return List.of();
        Vec3d eye = me.getEyePos();
        return mc.world.getEntities().stream()
                .filter(e -> e != me)
                .filter(e -> e instanceof LivingEntity && ((LivingEntity) e).isAlive())
                .filter(e -> e.squaredDistanceTo(eye) <= range * range)
                .sorted(Comparator.comparingDouble(e -> e.squaredDistanceTo(eye)))
                .toList();
    }

    public static Entity nearestTarget(double range) {
        List<Entity> list = entitiesAround(range);
        return list.isEmpty() ? null : list.get(0);
    }

    public static float[] rotationsTo(Vec3d from, Vec3d to) {
        double dx = to.x - from.x;
        double dy = to.y - from.y;
        double dz = to.z - from.z;
        double dist = Math.sqrt(dx * dx + dz * dz);
        float yaw = (float) Math.toDegrees(Math.atan2(dz, dx)) - 90f;
        float pitch = (float) -Math.toDegrees(Math.atan2(dy, dist));
        return new float[] { yaw, pitch };
    }

    public static boolean isFriend(Entity e) {
        if (!(e instanceof PlayerEntity p)) return false;
        String n = p.getGameProfile().name();
        return n != null && n.equalsIgnoreCase("placeholder");
    }

    public static float cooldownProgress() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return 0f;
        return mc.player.getAttackCooldownProgress(0.5f);
    }
}
EOF

cat > "$BASE/module/combat/KillAura.java" << 'EOF'
package dev.furry.client.module.combat;

import dev.furry.client.module.Aggression;
import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.DoubleSetting;
import dev.furry.client.setting.settings.EnumSetting;
import dev.furry.client.util.CombatUtil;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.util.Hand;
import net.minecraft.util.math.Vec3d;

public class KillAura extends Module {
    public final DoubleSetting range = add(new DoubleSetting("Range", "Reach distance", 3.0, 1.0, 6.0));
    public final DoubleSetting cps = add(new DoubleSetting("CPS", "Clicks per second", 12.0, 1.0, 20.0));
    public final BooleanSetting rotate = add(new BooleanSetting("Rotate", "Turn toward target", true));
    public final BooleanSetting swing = add(new BooleanSetting("Swing", "Arm swing animation", true));
    public final BooleanSetting playersOnly = add(new BooleanSetting("Players Only", "Only target players", false));
    public final BooleanSetting mobsOnly = add(new BooleanSetting("Mobs Only", "Only target hostile mobs", false));
    public final EnumSetting<Aggression> aggression = add(new EnumSetting<>("Aggression", "Timing profile", Aggression.NORMAL));

    private long lastHit = 0L;

    public KillAura() {
        super("KillAura", "Automatically attacks nearby entities", Category.COMBAT);
    }

    private long intervalMs() {
        double c = cps.get();
        if (aggression.get() == Aggression.SUBTLE) c *= 0.7;
        if (aggression.get() == Aggression.ANARCHY) c *= 1.4;
        return (long) (1000.0 / c);
    }

    @Override
    public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;

        long now = System.currentTimeMillis();
        if (now - lastHit < intervalMs()) return;

        Entity target = CombatUtil.nearestTarget(range.get());
        if (target == null) return;
        if (playersOnly.get() && !(target instanceof net.minecraft.entity.player.PlayerEntity)) return;
        if (mobsOnly.get() && target instanceof net.minecraft.entity.player.PlayerEntity) return;
        if (CombatUtil.isFriend(target)) return;
        if (!(target instanceof LivingEntity le) || !le.isAlive()) return;

        if (rotate.get()) {
            Vec3d eye = mc.player.getEyePos();
            Vec3d tp = target.getBoundingBox().getCenter();
            float[] r = CombatUtil.rotationsTo(eye, tp);
            mc.player.setYaw(r[0]);
            mc.player.setPitch(r[1]);
        }

        float cd = CombatUtil.cooldownProgress();
        if (cd < 0.9f && aggression.get() != Aggression.ANARCHY) return;

        mc.interactionManager.attackEntity(mc.player, target);
        if (swing.get()) mc.player.swingHand(Hand.MAIN_HAND);
        lastHit = now;
    }
}
EOF

cat > "$BASE/module/combat/Velocity.java" << 'EOF'
package dev.furry.client.module.combat;

import dev.furry.client.module.Aggression;
import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.DoubleSetting;
import dev.furry.client.setting.settings.EnumSetting;

public class Velocity extends Module {
    public final DoubleSetting horizontal = add(new DoubleSetting("Horizontal", "Knockback multiplier", 0.0, 0.0, 1.0));
    public final DoubleSetting vertical = add(new DoubleSetting("Vertical", "Vertical knockback multiplier", 0.0, 0.0, 1.0));
    public final EnumSetting<Aggression> aggression = add(new EnumSetting<>("Aggression", "Timing profile", Aggression.NORMAL));

    public Velocity() {
        super("Velocity", "Reduce or cancel knockback", Category.COMBAT);
    }
}
EOF

cat > "$BASE/module/combat/Criticals.java" << 'EOF'
package dev.furry.client.module.combat;

import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.EnumSetting;

public class Criticals extends Module {
    public enum Mode { PACKET, JUMP, MINI }

    public final EnumSetting<Mode> mode = add(new EnumSetting<>("Mode", "Crit technique", Mode.PACKET));

    public Criticals() {
        super("Criticals", "Force critical hits", Category.COMBAT);
    }
}
EOF

cat > "$BASE/module/combat/AutoTotem.java" << 'EOF'
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
EOF

cat > "$BASE/core/ModuleManager.java" << 'EOF'
package dev.furry.client.core;

import dev.furry.client.module.Module;
import dev.furry.client.module.combat.AutoTotem;
import dev.furry.client.module.combat.Criticals;
import dev.furry.client.module.combat.KillAura;
import dev.furry.client.module.combat.Velocity;

import java.util.*;

public final class ModuleManager {
    private final List<Module> modules = new ArrayList<>();
    private final Map<Class<?>, Module> byClass = new HashMap<>();

    public void registerAll() {
        register(new KillAura());
        register(new Velocity());
        register(new Criticals());
        register(new AutoTotem());
    }

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

echo "Turn 3A written."
