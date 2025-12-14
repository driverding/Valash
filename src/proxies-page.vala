[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxies-page.ui")]
class Valash.ProxiesPage : Gtk.Box {
    [GtkChild]
    private unowned Adw.PreferencesGroup proxies_group;
    [GtkChild]
    private unowned Adw.PreferencesGroup proxy_providers_group;

    private Clash instance;
    private Gee.HashMap<string, ProxyData> proxies;
    private Gee.HashMap<string, ProxyProviderData> providers;

    construct {
        this.instance = Clash.get_instance ();
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
        proxies = yield instance.request_proxies (null);
        // while (proxies_group.get_row (0) != null) {
        //     proxies_group.remove (proxies_group.get_row (0));
        // }

    }

    private async void refresh_proxy_providers_group () {
        providers = yield instance.request_proxy_providers (null);

        foreach (var provider in providers.values) {
            switch (provider.vehicle_type) {
                case "Compatible":
                    break;
                case "HTTP":
                    proxy_providers_group.add (new ProxyProviderRow.from_data (provider));
                    break;
            }
        }
    }
}
