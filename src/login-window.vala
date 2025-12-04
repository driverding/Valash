[GtkTemplate (ui = "/com/github/driverding/Valash/ui/login-window.ui")]
public class Valash.LoginWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.EntryRow addressEntry;

    [GtkChild]
    private unowned Adw.PasswordEntryRow passwordEntry;

    [GtkChild]
    private unowned Gtk.Button connectButton;

    [GtkChild]
    private unowned Adw.ToastOverlay overlay;

    public LoginWindow (Adw.Application app) {
        Object (application: app);
    }

    [GtkCallback]
    private void on_connect_button_clicked (Gtk.Button source) {

    }
}
