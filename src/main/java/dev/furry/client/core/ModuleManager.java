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
