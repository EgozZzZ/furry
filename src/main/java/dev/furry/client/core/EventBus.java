package dev.furry.client.core;

import java.util.*;
import java.util.function.Consumer;

public final class EventBus {
    private final Map<Class<?>, List<Consumer<?>>> listeners = new HashMap<>();

    public <T> void on(Class<T> type, Consumer<T> handler) {
        listeners.computeIfAbsent(type, k -> new ArrayList<>()).add(handler);
    }

    @SuppressWarnings("unchecked")
    public <T> void fire(T event) {
        List<Consumer<?>> list = listeners.get(event.getClass());
        if (list == null) return;
        for (Consumer<?> c : list) {
            try { ((Consumer<T>) c).accept(event); }
            catch (Throwable t) { dev.furry.client.FurryClient.LOG.error("listener threw on {}", event.getClass().getSimpleName(), t); }
        }
    }
}
