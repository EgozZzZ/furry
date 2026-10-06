package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class EnumSetting<E extends Enum<E>> extends Setting<E> {
    public final E[] values;
    public EnumSetting(String name, String desc, E def) {
        super(name, desc, def);
        this.values = def.getDeclaringClass().getEnumConstants();
    }
    public void cycle() { int i = (value.ordinal() + 1) % values.length; this.value = values[i]; }
    @Override public JsonElement toJson() { return new JsonPrimitive(value.name()); }
    @Override public void fromJson(JsonElement j) { this.value = Enum.valueOf(value.getDeclaringClass(), j.getAsString()); }
}
