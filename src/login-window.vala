/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

[GtkTemplate (ui = "/com/github/driverding/Valash/login-window.ui")]
public class Valash.LoginWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.EntryRow address_entry;
    [GtkChild]
    private unowned Adw.PasswordEntryRow secret_entry;
    [GtkChild]
    private unowned Gtk.Button connect_button;
    [GtkChild]
    private unowned Adw.ToastOverlay overlay;

    private Clash clash;
    private Settings settings;

    public signal void login_success (Gtk.ApplicationWindow source);

    public LoginWindow (Adw.Application app, Clash clash, Settings settings) {
        Object (application: app);
        this.clash = clash;
        this.settings = settings;
    }

    [GtkCallback]
    private void on_connect_button_clicked (Gtk.Button source) {
        string address = address_entry.text;
        string secret = secret_entry.text;
        if (address == "") {
            overlay.add_toast (new Adw.Toast (_("Empty URL!")));
            return;
        }
        address = address.has_prefix ("http://") ? address : "http://" + address;
        test_validity.begin (address, secret);
    }
    
    private async void test_validity (string address, string secret) {
        connect_button.sensitive = false;
        string error;
        bool validity = yield clash.test_validity (address, secret, out error);
        if (validity) {
            settings.set_string ("address", address);
            settings.set_string ("secret", secret);
            login_success (this);
        } else {
            overlay.add_toast (new Adw.Toast (error));
            connect_button.sensitive = true;
        }
    }
}
