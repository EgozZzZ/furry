package dev.furry.client.setting.settings;
import com.google.gson.JsonElement;
import com.google.gson.JsonPrimitive;
import dev.furry.client.setting.Setting;
public class DoubleSetting extends Setting<Double> {
    public final double min, max;
    public DoubleSetting(String name, String desc, double def, double min, double max) {
        super(name, desc, def);
        this.min = min; this.max = max;
    }
    @Override public JsonElement toJson() { return new JsonPrimitive(value); }
    @Override public void fromJson(JsonElement j) { this.value = j.getAsDouble(); }
}
