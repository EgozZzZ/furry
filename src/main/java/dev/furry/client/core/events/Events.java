package dev.furry.client.core.events;

import net.minecraft.client.gui.DrawContext;
import net.minecraft.network.packet.Packet;

public final class Events {
    private Events() {}
    public record Tick() {}
    public record Render2D(DrawContext ctx, float tickDelta) {}
    public record Render3D(DrawContext ctx, float tickDelta) {}
    public record KeyPress(int key, int scancode, int action, int mods) {}
    public record PacketSend(Packet<?> packet, boolean cancelable) {}
    public record PacketReceive(Packet<?> packet, boolean cancelable) {}
}
