namespace Valash {
    public string format_value (double input) {
        const string[] units = { "B", "KB", "MB", "GB", "TB" };
        size_t index = 0;
        double speed = input;
        while (speed > 1000) {
            index += 1;
            speed /= 1000;
        }
        return "%.1f %s".printf (speed, units[index]);
    }

    /* format_value for data binding */
    public bool format_value_transform (GLib.Binding binding, GLib.Value from_value, ref GLib.Value to_value) {
        to_value = format_value ((int) from_value.get_int ());
        return true;
    }

    public string camel_to_kebab (string camel_case) {
        StringBuilder result = new StringBuilder ();
        for (int i = 0; i < camel_case.length; i += 1) {
            char c = camel_case[i];
            if (c.isupper ()) {
                result.append_unichar ('-');
            }
            result.append_unichar (c.tolower ());
        }
        return result.str;
    }
}
