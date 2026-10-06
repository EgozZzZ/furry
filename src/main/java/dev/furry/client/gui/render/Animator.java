package dev.furry.client.gui.render;

public final class Animator {
    private float value, target, speed;
    private long lastMs;

    public Animator(float initial, float speed) {
        this.value = initial;
        this.target = initial;
        this.speed = speed;
        this.lastMs = System.currentTimeMillis();
    }

    public void setTarget(float t) { this.target = t; }
    public void setImmediate(float v) { this.value = v; this.target = v; }
    public float get() { return value; }

    public float update() {
        long now = System.currentTimeMillis();
        float dt = Math.min(100, now - lastMs) / 1000f;
        lastMs = now;
        float diff = target - value;
        value += diff * Math.min(1f, speed * dt * 20f);
        if (Math.abs(diff) < 0.001f) value = target;
        return value;
    }

    public boolean isAnimating() { return Math.abs(target - value) > 0.001f; }
}
