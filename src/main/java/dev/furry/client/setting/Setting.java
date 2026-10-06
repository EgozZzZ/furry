package dev.furry.client.setting;

import com.google.gson.JsonElement;

public abstract class Setting<T> {
    public final String name;
    public final String description;
    protected T value;
    protected T defaultValue;

    public Setting(String name, String description, T defaultValue) {
        this.name = name;
        this.description = description;
        this.value = defaultValue;
        this.defaultValue = defaultValue;
    }

    public T get() { return value; }
    public void set(T v) { this.value = v; }
    public T getDefault() { return defaultValue; }
    public void reset() { this.value = defaultValue; }

    public abstract JsonElement toJson();
    public abstract void fromJson(JsonElement json);
}
