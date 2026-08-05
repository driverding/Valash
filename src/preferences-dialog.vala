/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

[GtkTemplate (ui = "/com/github/driverding/Valash/preferences-dialog.ui")]
public class Valash.PreferencesDialog : Adw.PreferencesDialog {
    [GtkChild]
    private unowned Adw.SpinRow record_length_row;
    [GtkChild]
    private unowned Adw.SpinRow update_period_row;
    [GtkChild]
    private unowned Adw.EntryRow test_url_row;
    [GtkChild]
    private unowned Adw.SpinRow test_timeout_row;

    public PreferencesDialog (Settings settings) {
        Object ();
        this.bind_settings (settings);
    }

    public void bind_settings (Settings settings) {
        settings.bind ("test-url", test_url_row, "text", SettingsBindFlags.DEFAULT);
        settings.bind ("test-timeout", test_timeout_row, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("record-length", record_length_row, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("update-period", update_period_row, "value", SettingsBindFlags.DEFAULT);
    }
}
