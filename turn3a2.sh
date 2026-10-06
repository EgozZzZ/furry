#!/usr/bin/env bash
set -e
BASE="src/main/java/dev/furry/client"
MIXIN="$BASE/mixin"

# --- RotationManager ---
cat > "$BASE/util/RotationManager.java" << 'EOF'
package dev.furry.client.util;

public final class RotationManager {
    private static float spoofYaw = 0f;
    private static float spoofPitch = 0f;
    private static boolean active = false;

    public static void set(float yaw, float pitch) {
        spoofYaw = yaw;
        spoofPitch = pitch;
        active = true;
    }

    public static void clear() {
        active = false;
    }

    public static boolean isActive() { return active; }
    public static float getYaw() { return spoofYaw; }
    public static float getPitch() { return spoofPitch; }
}
EOF

# --- CombatUtil v2 ---
cat > "$BASE/util/CombatUtil.java" << 'EOF'
package dev.furry.client.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public final class CombatUtil {
    private CombatUtil() {}

    public static List<Entity> entitiesAround(double range) {
        MinecraftClient mc = MinecraftClient.getInstance();
        ClientPlayerEntity me = mc.player;
        if (me == null || mc.world == null) return List.of();

        Vec3d eye = me.getEyePos();
        double r2 = range * range;
        List<Entity> out = new ArrayList<>();

        for (Entity e : mc.world.getEntities()) {
            if (e == me) continue;
            if (!(e instanceof LivingEntity le) || !le.isAlive()) continue;
            if (eye.squaredDistanceTo(closestPointOnBox(eye, e.getBoundingBox())) <= r2) out.add(e);
        }

        return out;
    }

    // sort by threat: shield up > low health > nearest
    public static Entity bestTarget(double range) {
        List<Entity> list = entitiesAround(range);
        if (list.isEmpty()) return null;
        MinecraftClient mc = MinecraftClient.getInstance();
        Vec3d eye = mc.player.getEyePos();
        list.sort(Comparator
                .comparingInt((Entity e) -> (e instanceof PlayerEntity p && p.isBlocking()) ? 0 : 1)
                .thenComparingDouble(e -> e instanceof LivingEntity le ? le.getHealth() : 1000)
                .thenComparingDouble(e -> e.squaredDistanceTo(eye)));
        return list.get(0);
    }

    public static Entity nearestTarget(double range) {
        List<Entity> list = entitiesAround(range);
        if (list.isEmpty()) return null;
        MinecraftClient mc = MinecraftClient.getInstance();
        Vec3d eye = mc.player.getEyePos();
        list.sort(Comparator.comparingDouble(e -> e.squaredDistanceTo(eye)));
        return list.get(0);
    }

    public static Vec3d closestPointOnBox(Vec3d p, Box b) {
        return new Vec3d(
                Math.max(b.minX, Math.min(p.x, b.maxX)),
                Math.max(b.minY, Math.min(p.y, b.maxY)),
                Math.max(b.minZ, Math.min(p.z, b.maxZ))
        );
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

# --- KillAura v2 ---
cat > "$BASE/module/combat/KillAura.java" << 'EOF'
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
    public final EnumSetting<RotationMode> rotationMode = add(new EnumSetting<>("Rotation", "SILENT=spoof only, CLIENT=camera, BOTH", RotationMode.SILENT));
    public final DoubleSetting cooldownThreshold = add(new DoubleSetting("Cooldown", "Min cooldown before swing", 0.95, 0.5, 1.0));
    public final BooleanSetting swing = add(new BooleanSetting("Swing", "Arm swing animation", true));
    public final BooleanSetting playersOnly = add(new BooleanSetting("Players Only", "Only target players", false));
    public final BooleanSetting mobsOnly = add(new BooleanSetting("Mobs Only", "Only target hostile mobs", false));
    public final BooleanSetting weaponCycle = add(new BooleanSetting("Weapon Cycle", "Swap hotbar slots between hits", false));
    public final IntSetting cycleSlots = add(new IntSetting("Cycle Slots", "Number of hotbar slots to rotate", 3, 2, 9));
    public final BooleanSetting autoCrit = add(new BooleanSetting("AutoCrit", "Jump for crits mid-cooldown", false));
    public final BooleanSetting axeOnShield = add(new BooleanSetting("Axe On Shield", "Swap to axe if target blocking", false));
    public final EnumSetting<Aggression> aggression = add(new EnumSetting<>("Aggression", "Timing profile", Aggression.NORMAL));

    private int cycleIndex = 0;
    private long lastHit = 0L;

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
        Vec3d aim = aimPoint(target, eye);
        float[] r = CombatUtil.rotationsTo(eye, aim);

        RotationMode rm = rotationMode.get();
        if (rm == RotationMode.SILENT || rm == RotationMode.BOTH) {
            RotationManager.set(r[0], r[1]);
        }
        if (rm == RotationMode.CLIENT || rm == RotationMode.BOTH) {
            mc.player.setYaw(r[0]);
            mc.player.setPitch(r[1]);
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

        if (autoCrit.get() && mc.player.isOnGround() && cd > 0.9f && cd < 0.99f) {
            mc.player.jump();
        }

        // reach validation — must be within eye-to-hitbox distance
        if (eye.distanceTo(CombatUtil.closestPointOnBox(eye, target.getBoundingBox())) > range.get() + 0.5) return;

        mc.interactionManager.attackEntity(mc.player, target);
        if (swing.get()) mc.player.swingHand(Hand.MAIN_HAND);
        lastHit = now;

        if (weaponCycle.get()) {
            cycleIndex = (cycleIndex + 1) % cycleSlots.get();
            mc.player.getInventory().setSelectedSlot(cycleIndex);
        }
    }

    private Vec3d aimPoint(Entity target, Vec3d eye) {
        Box b = target.getBoundingBox();
        Vec3d center = b.getCenter();
        // aim slightly above center for head-height hits
        return new Vec3d(center.x, center.y + 0.15, center.z);
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
EOF

# --- Velocity v2 ---
cat > "$BASE/module/combat/Velocity.java" << 'EOF'
package dev.furry.client.module.combat;

import dev.furry.client.module.Aggression;
import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.DoubleSetting;
import dev.furry.client.setting.settings.EnumSetting;

public class Velocity extends Module {
    public final DoubleSetting horizontal = add(new DoubleSetting("Horizontal", "Knockback multiplier (0=cancel)", 0.0, 0.0, 1.0));
    public final DoubleSetting vertical = add(new DoubleSetting("Vertical", "Vertical knockback multiplier", 0.0, 0.0, 1.0));
    public final BooleanSetting onlyExplosions = add(new BooleanSetting("Explosions Only", "Only reduce explosion knockback", false));
    public final EnumSetting<Aggression> aggression = add(new EnumSetting<>("Aggression", "Timing profile", Aggression.NORMAL));

    public Velocity() {
        super("Velocity", "Reduce or cancel knockback", Category.COMBAT);
    }
}
EOF

# --- Criticals v2 ---
cat > "$BASE/module/combat/Criticals.java" << 'EOF'
package dev.furry.client.module.combat;

import dev.furry.client.module.Module;
import dev.furry.client.setting.settings.BooleanSetting;
import dev.furry.client.setting.settings.EnumSetting;

public class Criticals extends Module {
    public enum Mode { PACKET, JUMP, MINI }

    public final EnumSetting<Mode> mode = add(new EnumSetting<>("Mode", "Crit technique", Mode.PACKET));
    public final BooleanSetting onlyOnGround = add(new BooleanSetting("Ground Only", "Only fire when grounded", true));

    public Criticals() {
        super("Criticals", "Force critical hits via packet injection", Category.COMBAT);
    }
}
EOF

# --- ClientPlayerEntityMixin — silent rotation + criticals ---
cat > "$MIXIN/ClientPlayerEntityMixin.java" << 'EOF'
package dev.furry.client.mixin;

import dev.furry.client.FurryClient;
import dev.furry.client.module.combat.Criticals;
import dev.furry.client.util.RotationManager;
import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.ModifyVariable;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayerEntity.class)
public class ClientPlayerEntityMixin {

    // Silent rotation — intercept the yaw/pitch about to be sent in the movement packet
    @ModifyVariable(method = "sendMovementPackets", at = @At("HEAD"), ordinal = 0)
    private float furryclient$spoofYaw(float yaw) {
        if (RotationManager.isActive()) return RotationManager.getYaw();
        return yaw;
    }

    // Criticals — inject the classic pre-jump packet before the movement packet fires
    @Inject(method = "sendMovementPackets", at = @At("HEAD"))
    private void furryclient$criticals(CallbackInfo ci) {
        FurryClient fc = FurryClient.INSTANCE;
        if (fc == null || fc.modules == null) return;
        Criticals crit = fc.modules.get(Criticals.class);
        if (crit == null || !crit.isEnabled()) return;

        ClientPlayerEntity self = (ClientPlayerEntity) (Object) this;
        if (!self.isOnGround()) return;
        if (crit.mode.get() != Criticals.Mode.PACKET) return;

        double x = self.getX();
        double y = self.getY();
        double z = self.getZ();

        // classic crit chain: tiny upward offset, tiny return offset, then real position
        self.networkHandler.sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(
                x, y + 0.0625, z, false, self.horizontalCollision));
        self.networkHandler.sendPacket(new PlayerMoveC2SPacket.PositionAndOnGround(
                x, y, z, false, self.horizontalCollision));
    }
}
EOF

# --- ClientPlayNetworkHandlerMixin — Velocity ---
cat > "$MIXIN/ClientPlayNetworkHandlerMixin.java" << 'EOF'
package dev.furry.client.mixin;

import dev.furry.client.FurryClient;
import dev.furry.client.module.combat.Velocity;
import net.minecraft.client.network.ClientPlayNetworkHandler;
import net.minecraft.entity.Entity;
import net.minecraft.network.packet.s2c.play.EntityVelocityUpdateS2CPacket;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayNetworkHandler.class)
public class ClientPlayNetworkHandlerMixin {

    @Inject(method = "onEntityVelocityUpdate", at = @At("HEAD"), cancellable = true)
    private void furryclient$velocity(EntityVelocityUpdateS2CPacket packet, CallbackInfo ci) {
        FurryClient fc = FurryClient.INSTANCE;
        if (fc == null || fc.modules == null) return;
        Velocity vel = fc.modules.get(Velocity.class);
        if (vel == null || !vel.isEnabled()) return;

        net.minecraft.client.MinecraftClient mc = net.minecraft.client.MinecraftClient.getInstance();
        if (mc.player == null) return;
        int selfId = mc.player.getId();
        if (packet.getEntityId() != selfId) return;

        double h = vel.horizontal.get();
        double v = vel.vertical.get();

        // cancel and re-apply with the module multipliers
        ci.cancel();
        Entity self = mc.player;
        net.minecraft.util.math.Vec3d cur = self.getVelocity();
        double vx = packet.getVelocityX() * h;
        double vy = packet.getVelocityY() * v;
        double vz = packet.getVelocityZ() * h;
        self.setVelocity(vx, vy, vz);
    }
}
EOF

# --- mixins.json — register both mixins ---
cat > src/main/resources/furryclient.mixins.json << 'EOF'
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

echo "Turn 3A-2 written."
