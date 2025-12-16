[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxies-page.ui")]
class Valash.ProxiesPage : Gtk.Box {
    [GtkChild]
    private unowned Adw.PreferencesGroup proxy_provider_group;
    [GtkChild]
    private unowned Adw.PreferencesGroup proxy_group_group;

    private Clash instance;
    private Gee.HashMap<string, ProxyGroupRow> group_rows;
    private Gee.HashMap<string, ProxyProviderRow> provider_rows;

    construct {
        this.instance = Clash.get_instance ();
        group_rows = new Gee.HashMap<string, ProxyGroupRow> ();
        provider_rows = new Gee.HashMap<string, ProxyProviderRow> ();
    }


    /* Database */

    public async void healthcheck (string provider) {
        yield instance.request_proxy_providers_healthcheck (provider, null);
        stderr.printf ("Checked");
        refresh ();
    }

    // public async double refresh_delay_individual (string proxy) {
    //     int delay = yield instance.request_proxy_delay (proxy, null);
    //     HealthHistory history = new HealthHistory () { delay = delay, time = new GLib.DateTime.now_local () };
    //     proxies.get (proxy).history.add (history);
    //     return delay;
    // }

    // public async void refresh_group_delay (string group) {

        // Use a better way of handling instead of reconstruct UI
    // }

    public void refresh () { // having "all" means selectable
        refresh_proxy_groups.begin ();
        refresh_proxy_providers.begin ();
    }


    private async void refresh_proxy_groups () {
        var data = yield instance.request_proxies (null);

        // Diff
        var seen = new Gee.HashSet<string> ();

        foreach (ProxyData proxy in data.values) {
            if (proxy.all == null) continue;
            seen.add (proxy.name);
            if (group_rows.has_key (proxy.name)) {
                group_rows[proxy.name].refresh (data);
            } else {
                var new_row = new ProxyGroupRow.from_data (proxy.name, data);
                proxy_group_group.add (new_row);
                group_rows.set (proxy.name, new_row);
            }
        }

        foreach (string name in group_rows.keys) {
            if (!seen.contains (name)) {
                var row_to_remove = group_rows[name];
                proxy_group_group.remove (row_to_remove);
                group_rows.unset (name);
            }
        }
    }

    private async void refresh_proxy_providers () {
        var data = yield instance.request_proxy_providers (null);

        // Diff
        var seen = new Gee.HashSet<string> ();

        foreach (ProxyProviderData provider in data.values) {
            if (provider.vehicle_type == "Compatible") continue;
            seen.add (provider.name);
            if (provider_rows.has_key (provider.name)) {
                provider_rows[provider.name].refresh (provider);
            } else {
                var new_row = new ProxyProviderRow.from_data (provider);
                proxy_provider_group.add (new_row);
                provider_rows.set (provider.name, new_row);
            }
        }

        foreach (string name in provider_rows.keys) {
            if (!seen.contains (name)) {
                var row_to_remove = provider_rows[name];
                proxy_provider_group.remove (row_to_remove);
                provider_rows.unset (name);
            }
        }

    }
}
