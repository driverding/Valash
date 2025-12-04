namespace Valash {
    public string format_value (double input) {
        const string[] units = { "B", "KB", "MB", "GB", "TB" };
        size_t index = 0;
        double speed = input;

        while (speed > 1000) {
            index += 1;
            speed /= 1000;
        }

        return "%.1f %s".printf(speed, units[index]);
    }

    public static string camel_to_snake (string camel_case) {
        StringBuilder result = new StringBuilder ();
        for (int i = 0; i < camel_case.length; i += 1) {
            char c = camel_case[i];
            if (c.isupper ()) {
                result.append_unichar ('_');
            }
            result.append_unichar (c.tolower ());
        }

        return result.str;
    }

}
