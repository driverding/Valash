[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxies-page.ui")]
class Valash.ProxiesPage : Gtk.Box {
    [GtkChild]
    private unowned Adw.PreferencesGroup proxies_group;
    [GtkChild]
    private unowned Adw.PreferencesGroup proxy_providers_group;

    private Clash instance;


    public ProxiesPage () {
        Object ();
    }

    construct {
        this.instance = Clash.get_instance ();
    }

    public void refresh () {
        // Remove all objects
        while (proxy_providers_group.get_row (0) != null) {
            proxy_providers_group.remove (proxy_providers_group.get_row (0));
        }
        while (proxies_group.get_row (0) != null) {
            proxies_group.remove (proxies_group.get_row (0));
        }
        refresh_proxies_group.begin ();
        refresh_proxy_providers_group.begin ();
    }

    private async void refresh_proxies_group () {
        Gee.HashMap<string, ProxyData> proxies = yield instance.request_proxies (null);
    }

    private async void refresh_proxy_providers_group () {
        Gee.HashMap<string, ProxyProviderData> providers = yield instance.request_proxy_providers (null);
        foreach (var provider in providers.values) {
            switch (provider.vehicle_type) {
                case "Compatible":
                    break;
                case "HTTP":
                    proxy_providers_group.add (new ProxyProviderRow.from_data (provider));
                    break;
                // TODO: Implement More
            }
        }
    }
}
