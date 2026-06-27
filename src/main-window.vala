[GtkTemplate (ui = "/com/github/driverding/Valash/main-window.ui")]
public class Valash.MainWindow: Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ViewStack stack;
    [GtkChild]
    private unowned Valash.OverviewPage overview_page;
    [GtkChild]
    private unowned Valash.ProxiesPage proxies_page;
    [GtkChild]
    private unowned Valash.ConnectionPage connection_page;
    [GtkChild]
    private unowned Adw.ToastOverlay overlay;

    private Clash clash;
    private Settings settings;

    private GLib.Cancellable connections_cancellable;
    public signal void connections_received (ConnectionsData data);

    public MainWindow (Adw.Application app, Clash clash, Settings settings) {
        typeof (Valash.Graph).ensure ();
        typeof (Valash.OverviewPage).ensure ();
        typeof (Valash.ProxiesPage).ensure ();
        typeof (Valash.ConnectionPage).ensure ();

        Object (application: app);

        this.clash = clash;
        this.settings = settings;
        overview_page.setup (clash);
        proxies_page.setup (clash);
    }

    construct {
        this.connections_cancellable = new GLib.Cancellable ();

        connections_received.connect (overview_page.on_connections_received);
        connections_received.connect (connection_page.on_connections_received);
        GLib.Timeout.add (1000, () => {
            request_connections.begin ();
            return true;
        });
    }

    private async void request_connections () {
        ConnectionsData response = yield clash.request_connections (connections_cancellable);
        connections_received (response);
    }

    [GtkCallback]
    private void on_stack_notify_visible_child (GLib.Object sender, GLib.ParamSpec pspec) {
        if (stack.visible_child == proxies_page) {
            proxies_page.refresh ();
        }
    }
}

