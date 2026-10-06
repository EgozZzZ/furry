package dev.furry.client.mixin;

import dev.furry.client.util.RotationManager;
import net.minecraft.client.network.ClientPlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayerEntity.class)
public class ClientPlayerEntityMixin {

    // Silent rotation — set the network yaw/pitch AFTER movement input is processed
    // but BEFORE sendMovementPackets reads them. Render fields (renderYaw/renderPitch)
    // stay untouched, so the camera doesn't move.
    @Inject(method = "tickMovement", at = @At("TAIL"))
    private void furryclient$silentRotate(CallbackInfo ci) {
        if (!RotationManager.isActive()) return;
        ClientPlayerEntity self = (ClientPlayerEntity) (Object) this;
        self.setYaw(RotationManager.getYaw());
        self.setPitch(RotationManager.getPitch());
    }
}
