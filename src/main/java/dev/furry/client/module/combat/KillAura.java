package dev.furry.client.module.combat;

import dev.furry.client.module.Aggression;
import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.DoubleSetting;
import dev.furry.client.setting.settings.EnumSetting;
import dev.furry.client.setting.settings.IntSetting;
import dev.furry.client.util.CombatUtil;
import dev.furry.client.util.RotationManager;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.registry.Registries;
import net.minecraft.util.Hand;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;

public class KillAura extends Module {
    public enum Mode { COOLDOWN, SPAM, LEGIT }
    public enum RotationMode { SILENT, CLIENT, BOTH }

    public final DoubleSetting range = add(new DoubleSetting("Range", "Reach distance", 3.0, 1.0, 6.0));
    public final EnumSetting<Mode> mode = add(new EnumSetting<>("Mode", "Attack timing", Mode.COOLDOWN));
    public final EnumSetting<RotationMode> rotationMode = add(new EnumSetting<>("Rotation", "SILENT/CLIENT/BOTH", RotationMode.SILENT));
    public final DoubleSetting cooldownThreshold = add(new DoubleSetting("Cooldown", "Min cooldown before swing", 0.95, 0.5, 1.0));
    public final DoubleSetting rotationSpeed = add(new DoubleSetting("Rot Speed", "Max degrees per tick", 180.0, 30.0, 360.0));
    public final BooleanSetting swing = add(new BooleanSetting("Swing", "Arm swing animation", true));
    public final BooleanSetting playersOnly = add(new BooleanSetting("Players Only", "Only target players", false));
    public final BooleanSetting mobsOnly = add(new BooleanSetting("Mobs Only", "Only target hostile mobs", false));
    public final BooleanSetting weaponCycle = add(new BooleanSetting("Weapon Cycle", "Swap hotbar slots between hits", false));
    public final IntSetting cycleSlots = add(new IntSetting("Cycle Slots", "Number of slots to rotate", 3, 2, 9));
    public final BooleanSetting autoCrit = add(new BooleanSetting("AutoCrit", "Force crit flag on swing", false));
    public final BooleanSetting axeOnShield = add(new BooleanSetting("Axe On Shield", "Swap to axe if blocking", false));
    public final EnumSetting<Aggression> aggression = add(new EnumSetting<>("Aggression", "Timing profile", Aggression.NORMAL));

    private int cycleIndex = 0;
    private long lastHit = 0L;
    private float lastYaw = 0f;

    public KillAura() {
        super("KillAura", "Cooldown-aware auto attack for 1.9+ PvP", Category.COMBAT);
    }

    @Override
    public void onDisable() {
        RotationManager.clear();
    }

    @Override
    public void onTick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null || mc.world == null) return;

        Entity target = CombatUtil.bestTarget(range.get());
        if (target == null) {
            RotationManager.clear();
            return;
        }
        if (playersOnly.get() && !(target instanceof PlayerEntity)) return;
        if (mobsOnly.get() && target instanceof PlayerEntity) return;
        if (CombatUtil.isFriend(target)) return;
        if (!(target instanceof LivingEntity le) || !le.isAlive()) return;

        Vec3d eye = mc.player.getEyePos();
        Vec3d aim = aimPoint(target);
        float[] r = CombatUtil.rotationsTo(eye, aim);

        // Smooth rotation — cap degrees per tick so server doesn't flag snap
        float targetYaw = r[0];
        float targetPitch = r[1];
        float maxStep = rotationSpeed.get().floatValue();

        float currentYaw = RotationManager.isActive() ? RotationManager.getYaw() : mc.player.getYaw();
        float currentPitch = RotationManager.isActive() ? RotationManager.getPitch() : mc.player.getPitch();

        float newYaw = approachAngle(currentYaw, targetYaw, maxStep);
        float newPitch = approachAngle(currentPitch, targetPitch, maxStep);

        RotationMode rm = rotationMode.get();
        if (rm == RotationMode.SILENT || rm == RotationMode.BOTH) {
            RotationManager.set(newYaw, newPitch);
        }
        if (rm == RotationMode.CLIENT || rm == RotationMode.BOTH) {
            mc.player.setYaw(newYaw);
            mc.player.setPitch(newPitch);
        }

        if (axeOnShield.get() && target instanceof PlayerEntity pe && pe.isBlocking()) {
            int axeSlot = findAxeSlot(mc);
            if (axeSlot != -1) mc.player.getInventory().setSelectedSlot(axeSlot);
        }

        long now = System.currentTimeMillis();
        float cd = CombatUtil.cooldownProgress();
        Mode m = mode.get();

        if (m == Mode.COOLDOWN && cd < cooldownThreshold.get()) return;
        if (m == Mode.LEGIT && cd < 0.95f) return;
        if (m == Mode.SPAM && now - lastHit < (long) (1000.0 / 16.0)) return;

        if (eye.distanceTo(CombatUtil.closestPointOnBox(eye, target.getBoundingBox())) > range.get() + 0.5) return;

        mc.interactionManager.attackEntity(mc.player, target);
        if (swing.get()) mc.player.swingHand(Hand.MAIN_HAND);
        lastHit = now;

        if (weaponCycle.get()) {
            cycleIndex = (cycleIndex + 1) % cycleSlots.get();
            mc.player.getInventory().setSelectedSlot(cycleIndex);
        }
    }

    private Vec3d aimPoint(Entity target) {
        Box b = target.getBoundingBox();
        Vec3d c = b.getCenter();
        return new Vec3d(c.x, c.y + 0.15, c.z);
    }

    private static float approachAngle(float from, float to, float maxDelta) {
        float diff = wrapDegrees(to - from);
        if (Math.abs(diff) <= maxDelta) return to;
        return from + Math.signum(diff) * maxDelta;
    }

    private static float wrapDegrees(float d) {
        d = d % 360f;
        if (d >= 180f) d -= 360f;
        if (d < -180f) d += 360f;
        return d;
    }

    private int findAxeSlot(MinecraftClient mc) {
        for (int i = 0; i < 9; i++) {
            ItemStack s = mc.player.getInventory().getStack(i);
            String id = Registries.ITEM.getId(s.getItem()).getPath();
            if (id.endsWith("_axe")) return i;
        }
        return -1;
    }
}
