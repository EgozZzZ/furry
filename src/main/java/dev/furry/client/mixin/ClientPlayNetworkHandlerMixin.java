package dev.furry.client.mixin;

import dev.furry.client.FurryClient;
import dev.furry.client.module.combat.Velocity;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.network.ClientPlayNetworkHandler;
import net.minecraft.entity.Entity;
import net.minecraft.network.packet.s2c.play.EntityVelocityUpdateS2CPacket;
import net.minecraft.util.math.Vec3d;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayNetworkHandler.class)
public class ClientPlayNetworkHandlerMixin {

    // Velocity — let vanilla apply first, then overwrite the entity velocity with multipliers.
    // Using RETURN (not HEAD+cancel) so the entity lookup and other packet side effects still run.
    @Inject(method = "onEntityVelocityUpdate", at = @At("RETURN"))
    private void furryclient$velocity(EntityVelocityUpdateS2CPacket packet, CallbackInfo ci) {
        FurryClient fc = FurryClient.INSTANCE;
        if (fc == null || fc.modules == null) return;
        Velocity vel = fc.modules.get(Velocity.class);
        if (vel == null || !vel.isEnabled()) return;

        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.player == null) return;
        if (packet.getEntityId() != mc.player.getId()) return;

        Vec3d raw = packet.getVelocity();
        double h = vel.horizontal.get();
        double v = vel.vertical.get();

        Entity self = mc.player;
        self.setVelocity(raw.x * h, raw.y * v, raw.z * h);
    }
}
