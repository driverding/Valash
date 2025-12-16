[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxies-page.ui")]
class Valash.ProxiesPage : Gtk.Box {
    [GtkChild]
    private unowned Adw.PreferencesGroup proxy_provider_group;

    private Clash instance;
    // private Gee.HashMap<string, ProxyGroupRow> group_rows;
    private Gee.HashMap<string, ProxyProviderRow> provider_rows;

    construct {
        this.instance = Clash.get_instance ();
        provider_rows = new Gee.HashMap<string, ProxyProviderRow> ();
    }


    /* Database */

    public async void healthcheck (string provider) {
        yield instance.request_proxy_providers_healthcheck (provider, null);
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
        refresh_proxies_group.begin ();
        refresh_proxy_providers_group.begin ();
    }


    private async void refresh_proxies_group () {
        // var data = yield instance.request_proxies (null);
    }

    private async void refresh_proxy_providers_group () {
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
