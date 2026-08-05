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
        to_value = format_value (from_value.get_double ());
        return true;
    }

    /*  */
    public bool format_delay_transform (GLib.Binding binding, GLib.Value from_value, ref GLib.Value to_value) {
        double delay = from_value.get_double ();
        to_value = delay == 0 ? "-" : "%.2f ms".printf (delay);
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

    /* Delegates for diff_list_store */
    public delegate K ListStoreKeyFunc<K> (GLib.Object item);
    public delegate GLib.Object ListStoreModelFactory<V> (V data);
    public delegate void ListStoreSyncFunc<V> (GLib.Object item, V data);

    /**
     * Diff a GLib.ListStore against a map of new data.
     *
     * Removes items whose key is absent from the map, syncs existing items
     * in-place, and appends new items constructed from remaining map entries.
     *
     * @param store    The ListStore to mutate.
     * @param data     A map from key to data object with the desired state.
     * @param get_key  Extracts the identifying key from a store item.
     * @param factory  Constructs a new store item from a data object.
     * @param sync     Updates an existing store item in-place from a data object.
     */
    public static void diff_list_store<K, V> (
        GLib.ListStore store,
        Gee.Map<K, V> data,
        owned ListStoreKeyFunc<K> get_key,
        owned ListStoreModelFactory<V> factory,
        owned ListStoreSyncFunc<V> sync
    ) {
        var to_append = new Gee.HashSet<K> ();
        foreach (var key in data.keys) {
            to_append.add (key);
        }

        for (int i = (int) store.get_n_items () - 1; i >= 0; i--) {
            var item = store.get_item (i);
            K key = get_key (item);
            if (!data.has_key (key)) {
                store.remove (i);
            } else {
                sync (item, data[key]);
                to_append.remove (key);
            }
        }

        foreach (var key in to_append) {
            store.append (factory (data[key]));
        }
    }
}
