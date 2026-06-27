[GtkTemplate (ui = "/com/github/driverding/Valash/login-window.ui")]
public class Valash.LoginWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.EntryRow address_entry;
    [GtkChild]
    private unowned Adw.PasswordEntryRow password_entry;
    [GtkChild]
    private unowned Gtk.Button connect_button;
    [GtkChild]
    private unowned Adw.ToastOverlay overlay;

    private Clash clash;
    private Settings settings;

    public LoginWindow (Adw.Application app, Clash clash, Settings settings) {
        Object (application: app);
        this.clash = clash;
        this.settings = settings;
    }

    [GtkCallback]
    private void on_connect_button_clicked (Gtk.Button source) {
        unowned string input_url = address_entry.get_text ();
        unowned string secret = password_entry.get_text ();
        if (input_url == "") {
            raise_failure_toast (_("Empty URL!"));
            return;
        }
        string url = input_url.has_prefix ("http://") ? input_url : "http://" + input_url;
        connect_button.sensitive = false;
        test_validity.begin (url, secret);
    }
    
    private async void test_validity (string url, string secret) {
        string error;
        bool validity = yield clash.test_validity (url, secret, out error);
        if (validity) {
            record_login_info (url, secret);
            login_success ();
        } else {
            raise_failure_toast (error);
            connect_button.sensitive = true;
        }
    }
    
    private void record_login_info (string url, string secret) {
        settings.set_string ("url", url);
        settings.set_string ("secret", secret);
    }
    
    public signal void login_success ();
    
    private void raise_failure_toast (string content) {
        overlay.add_toast (new Adw.Toast (content));
    }
}
