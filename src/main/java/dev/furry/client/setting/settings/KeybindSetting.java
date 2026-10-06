package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class KeybindSetting extends Setting<Integer> {
    public KeybindSetting(String name, String desc, int def) { super(name, desc, def); }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsInt(); }
}
