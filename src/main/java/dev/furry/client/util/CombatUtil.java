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
