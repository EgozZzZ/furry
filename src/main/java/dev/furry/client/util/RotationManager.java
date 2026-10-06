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

    public static void clear() { active = false; }
    public static boolean isActive() { return active; }
    public static float getYaw() { return spoofYaw; }
    public static float getPitch() { return spoofPitch; }
}
