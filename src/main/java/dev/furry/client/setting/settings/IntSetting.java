package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class IntSetting extends Setting<Integer> {
    public final int min, max;
    public IntSetting(String name, String desc, int def, int min, int max) {
        super(name, desc, def);
        this.min = min; this.max = max;
    }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsInt(); }
}
