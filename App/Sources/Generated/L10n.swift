//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen
// swiftlint:disable type_body_length identifier_name
// swiftformat:disable wrapPropertyBodies

import Foundation

// MARK: - Strings

public enum L10n {
    /// Kunde hinzufügen
    public static var accessibilityAddClient: String { L10n.tr("accessibility_add_client") }
    /// Kostenstelle hinzufügen
    public static var accessibilityAddCostCentre: String { L10n.tr("accessibility_add_cost_centre") }
    /// Kunde bearbeiten
    public static var accessibilityEditClient: String { L10n.tr("accessibility_edit_client") }
    /// Kostenstelle bearbeiten
    public static var accessibilityEditCostCentre: String { L10n.tr("accessibility_edit_cost_centre") }
    /// Schwarz-Weiß-Druck aktivieren
    public static var accessibilityExportBlackAndWhitePrint: String { L10n.tr("accessibility_export_black_and_white_print") }
    /// Enddatum wählen
    public static var accessibilityExportEndDate: String { L10n.tr("accessibility_export_end_date") }
    /// Kommentare in Export einbeziehen
    public static var accessibilityExportIncludeComments: String { L10n.tr("accessibility_export_include_comments") }
    /// Pulsdruck in Export einbeziehen
    public static var accessibilityExportIncludePulsePressure: String { L10n.tr("accessibility_export_include_pulse_pressure") }
    /// Startdatum wählen
    public static var accessibilityExportStartDate: String { L10n.tr("accessibility_export_start_date") }
    /// Öffnet die Mail-App
    public static var accessibilityImprintContactHint: String { L10n.tr("accessibility_imprint_contact_hint") }
    /// E-Mail senden
    public static var accessibilityImprintContactLabel: String { L10n.tr("accessibility_imprint_contact_label") }
    /// Karte letzte Buchung
    public static var accessibilityOverviewLatestCard: String { L10n.tr("accessibility_overview_latest_card") }
    /// Öffnet die gefilterte Liste
    public static var accessibilityOverviewOpenItemHint: String { L10n.tr("accessibility_overview_open_item_hint") }
    /// %@ %@
    public static func accessibilityOverviewOpenItemValue(
        _ pronounce1: Any,
        _ pronounce2: Any
    ) -> String {
        L10n.tr(
            "accessibility_overview_open_item_value",
            String(describing: pronounce1),
            String(describing: pronounce2)
        )
    }

    /// Karte offene Punkte
    public static var accessibilityOverviewOpenItemsCard: String { L10n.tr("accessibility_overview_open_items_card") }
    /// Profilauswahl Übersicht
    public static var accessibilityOverviewProfilePicker: String { L10n.tr("accessibility_overview_profile_picker") }
    /// Karte Schnellaktionen
    public static var accessibilityOverviewQuickActionsCard: String { L10n.tr("accessibility_overview_quick_actions_card") }
    /// Karte letzte Einträge
    public static var accessibilityOverviewRecentCard: String { L10n.tr("accessibility_overview_recent_card") }
    /// Karte aktiver Timer
    public static var accessibilityOverviewRunningCard: String { L10n.tr("accessibility_overview_running_card") }
    /// Karte Tageswerte
    public static var accessibilityOverviewTodayCard: String { L10n.tr("accessibility_overview_today_card") }
    /// Öffnet den App Store zur iOS-App.
    public static var accessibilityPeerSyncShowIosAppHint: String { L10n.tr("accessibility_peer_sync_show_ios_app_hint") }
    /// Verwaltung
    public static var activityAdmin: String { L10n.tr("activity_admin") }
    /// Pause
    public static var activityBreak: String { L10n.tr("activity_break") }
    /// Meeting
    public static var activityMeeting: String { L10n.tr("activity_meeting") }
    /// Reise
    public static var activityTravel: String { L10n.tr("activity_travel") }
    /// Arbeit
    public static var activityWork: String { L10n.tr("activity_work") }
    /// Adresse
    public static var clientAddress: String { L10n.tr("client_address") }
    /// Ländercode
    public static var clientCountryCode: String { L10n.tr("client_country_code") }
    /// E-Mail
    public static var clientEmail: String { L10n.tr("client_email") }
    /// Externe Referenz
    public static var clientExternalRef: String { L10n.tr("client_external_ref") }
    /// Rechnungsadresse
    public static var clientInvoiceAddress: String { L10n.tr("client_invoice_address") }
    /// Rechnungsdetails
    public static var clientInvoiceDetails: String { L10n.tr("client_invoice_details") }
    /// Rechnungs-E-Mail
    public static var clientInvoiceEmail: String { L10n.tr("client_invoice_email") }
    /// Name
    public static var clientName: String { L10n.tr("client_name") }
    /// Zugehörige Aufträge
    public static var clientRelatedOrders: String { L10n.tr("client_related_orders") }
    /// Umsatzsteuerbefreit
    public static var clientSalesTaxExempt: String { L10n.tr("client_sales_tax_exempt") }
    /// Umsatzsteuer-ID
    public static var clientSalesTaxId: String { L10n.tr("client_sales_tax_id") }
    /// Gemeinsames Profil
    public static var clientSharedProfile: String { L10n.tr("client_shared_profile") }
    /// Steuer-ID
    public static var clientTaxId: String { L10n.tr("client_tax_id") }
    /// USt-ID
    public static var clientVatId: String { L10n.tr("client_vat_id") }
    /// Abwesenheit
    public static var costCentreAbsence: String { L10n.tr("cost_centre_absence") }
    /// Administration
    public static var costCentreAdmin: String { L10n.tr("cost_centre_admin") }
    /// Externe Referenz
    public static var costCentreExternalRef: String { L10n.tr("cost_centre_external_ref") }
    /// Tätigkeit
    public static var costCentreGeneral: String { L10n.tr("cost_centre_general") }
    /// Intern
    public static var costCentreInternal: String { L10n.tr("cost_centre_internal") }
    /// Meeting
    public static var costCentreMeeting: String { L10n.tr("cost_centre_meeting") }
    /// Kostenstellenname
    public static var costCentreName: String { L10n.tr("cost_centre_name") }
    /// Kostenstellen-Bereich
    public static var costCentreScope: String { L10n.tr("cost_centre_scope") }
    /// Client
    public static var costCentreScopeClient: String { L10n.tr("cost_centre_scope_client") }
    /// Global
    public static var costCentreScopeGlobal: String { L10n.tr("cost_centre_scope_global") }
    /// Client auswählen
    public static var costCentreSelectClient: String { L10n.tr("cost_centre_select_client") }
    /// Fortbildung
    public static var costCentreTraining: String { L10n.tr("cost_centre_training") }
    /// Reisezeit
    public static var costCentreTravel: String { L10n.tr("cost_centre_travel") }
    /// Die Sicherungsdatei konnte nicht erstellt oder geteilt werden.
    public static var errorBackupExportMessage: String { L10n.tr("error_backup_export_message") }
    /// Export fehlgeschlagen
    public static var errorBackupExportTitle: String { L10n.tr("error_backup_export_title") }
    /// E-Mail konnte nicht geöffnet werden. Bitte kopieren Sie die Adresse manuell.
    public static var errorImprintMailUnavailableMessage: String { L10n.tr("error_imprint_mail_unavailable_message") }
    /// Mail nicht verfügbar
    public static var errorImprintMailUnavailableTitle: String { L10n.tr("error_imprint_mail_unavailable_title") }
    /// Von
    public static var exportDateRangeFrom: String { L10n.tr("export_date_range_from") }
    /// Export vorbereiten
    public static var exportDateRangePreview: String { L10n.tr("export_date_range_preview") }
    /// Zeitraum
    public static var exportDateRangeTitle: String { L10n.tr("export_date_range_title") }
    /// Bis
    public static var exportDateRangeTo: String { L10n.tr("export_date_range_to") }
    /// CSV (Textdatei)
    public static var exportFormatCsv: String { L10n.tr("export_format_csv") }
    /// PDF (Dokument)
    public static var exportFormatPdf: String { L10n.tr("export_format_pdf") }
    /// PDF Erstellen
    public static var exportPdfCreateButton: String { L10n.tr("export_pdf_create_button") }
    /// Keine Daten
    public static var exportPdfNoDataTitle: String { L10n.tr("export_pdf_no_data_title") }
    /// Drucken
    public static var exportPreparedPrintButton: String { L10n.tr("export_prepared_print_button") }
    /// Speichern
    public static var exportPreparedSaveButton: String { L10n.tr("export_prepared_save_button") }
    /// Schwarz-Weiß-Druck
    public static var exportPreviewBlackAndWhitePrint: String { L10n.tr("export_preview_black_and_white_print") }
    /// Exportieren
    public static var exportPreviewExportButton: String { L10n.tr("export_preview_export_button") }
    /// Format
    public static var exportPreviewFormatTitle: String { L10n.tr("export_preview_format_title") }
    /// Kommentare einbeziehen
    public static var exportPreviewIncludeComments: String { L10n.tr("export_preview_include_comments") }
    /// %d Messungen
    public static func exportPreviewMeasurementCount(
        _ pronounce1: Int
    ) -> String {
        L10n.tr(
            "export_preview_measurement_count",
            pronounce1
        )
    }

    /// Optionen
    public static var exportPreviewOptionsTitle: String { L10n.tr("export_preview_options_title") }
    /// Zusammenfassung
    public static var exportPreviewSummaryTitle: String { L10n.tr("export_preview_summary_title") }
    /// Export-Vorschau
    public static var exportPreviewTitle: String { L10n.tr("export_preview_title") }
    /// Aktiv
    public static var generalActive: String { L10n.tr("general_active") }
    /// Zusätzlich
    public static var generalAdditional: String { L10n.tr("general_additional") }
    /// Alle
    public static var generalAll: String { L10n.tr("general_all") }
    /// Bereits vergeben
    public static var generalAlreadyTaken: String { L10n.tr("general_already_taken") }
    /// Abbrechen
    public static var generalCancel: String { L10n.tr("general_cancel") }
    /// Kunde
    public static var generalClient: String { L10n.tr("general_client") }
    /// Kommentar
    public static var generalComment: String { L10n.tr("general_comment") }
    /// E-Mail kopieren
    public static var generalCopyEmail: String { L10n.tr("general_copy_email") }
    /// E-Mail kopiert
    public static var generalCopyEmailToast: String { L10n.tr("general_copy_email_toast") }
    /// Details
    public static var generalDetails: String { L10n.tr("general_details") }
    /// Onboarding
    public static var generalDeveloperOnboarding: String { L10n.tr("general_developer_onboarding") }
    /// Auf Standardwerte zurücksetzen
    public static var generalDeveloperResetDefaults: String { L10n.tr("general_developer_reset_defaults") }
    /// Zurücksetzen
    public static var generalDeveloperResetDefaultsConfirm: String { L10n.tr("general_developer_reset_defaults_confirm") }
    /// Alle gespeicherten Werte werden zurückgesetzt. Die App wird danach geschlossen.
    public static var generalDeveloperResetDefaultsMessage: String { L10n.tr("general_developer_reset_defaults_message") }
    /// Standardwerte zurücksetzen?
    public static var generalDeveloperResetDefaultsTitle: String { L10n.tr("general_developer_reset_defaults_title") }
    /// Bearbeiten
    public static var generalEdit: String { L10n.tr("general_edit") }
    /// Filtern
    public static var generalFilter: String { L10n.tr("general_filter") }
    /// Import starten
    public static var generalImportButton: String { L10n.tr("general_import_button") }
    /// Nicht zuordnen
    public static var generalImportColumnNone: String { L10n.tr("general_import_column_none") }
    /// Spalte %@
    public static func generalImportColumnNumber(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_import_column_number",
            String(describing: pronounce1)
        )
    }

    /// Importierbare Daten
    public static var generalImportDataSection: String { L10n.tr("general_import_data_section") }
    /// Automatisch
    public static var generalImportDelimiterAuto: String { L10n.tr("general_import_delimiter_auto") }
    /// Komma
    public static var generalImportDelimiterComma: String { L10n.tr("general_import_delimiter_comma") }
    /// Semikolon
    public static var generalImportDelimiterSemicolon: String { L10n.tr("general_import_delimiter_semicolon") }
    /// Tabulator
    public static var generalImportDelimiterTab: String { L10n.tr("general_import_delimiter_tab") }
    /// Trennzeichen
    public static var generalImportDelimiterTitle: String { L10n.tr("general_import_delimiter_title") }
    /// Keine importierbaren Zeilen gefunden
    public static var generalImportErrorNoRows: String { L10n.tr("general_import_error_no_rows") }
    /// Datei konnte nicht gelesen werden
    public static var generalImportErrorRead: String { L10n.tr("general_import_error_read") }
    /// Import konnte nicht gespeichert werden
    public static var generalImportErrorSave: String { L10n.tr("general_import_error_save") }
    /// Datum
    public static var generalImportFieldDate: String { L10n.tr("general_import_field_date") }
    /// Datei
    public static var generalImportFileSection: String { L10n.tr("general_import_file_section") }
    /// Erste Zeile sind Spaltennamen
    public static var generalImportHeaderRow: String { L10n.tr("general_import_header_row") }
    /// Importiere CSV-Dateien und ordne die Spalten zu, bevor die Messungen gespeichert werden.
    public static var generalImportIntroDescription: String { L10n.tr("general_import_intro_description") }
    /// Spalten zuordnen
    public static var generalImportMappingTitle: String { L10n.tr("general_import_mapping_title") }
    /// Importiert: %@
    public static func generalImportResult(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_import_result",
            String(describing: pronounce1)
        )
    }

    /// Importierbare Zeilen: %@
    public static func generalImportRowCount(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_import_row_count",
            String(describing: pronounce1)
        )
    }

    /// CSV-Datei auswählen
    public static var generalImportSelectFile: String { L10n.tr("general_import_select_file") }
    /// Ausgewählte Datei: %@
    public static func generalImportSelectedFile(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_import_selected_file",
            String(describing: pronounce1)
        )
    }

    /// Inaktiv
    public static var generalInactive: String { L10n.tr("general_inactive") }
    /// %@ Einträge
    public static func generalListEntryCount(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_list_entry_count",
            String(describing: pronounce1)
        )
    }

    /// Zurücksetzen
    public static var generalListFilterReset: String { L10n.tr("general_list_filter_reset") }
    /// Tätigkeiten
    public static var generalManagementActivities: String { L10n.tr("general_management_activities") }
    /// Kunden
    public static var generalManagementClients: String { L10n.tr("general_management_clients") }
    /// Kostenstellen
    public static var generalManagementCostCentres: String { L10n.tr("general_management_cost_centres") }
    /// Aufträge
    public static var generalManagementOrders: String { L10n.tr("general_management_orders") }
    /// Tarife
    public static var generalManagementRates: String { L10n.tr("general_management_rates") }
    /// Eintragen
    public static var generalMeasurementAdd: String { L10n.tr("general_measurement_add") }
    /// Über %@
    public static func generalMenuAboutApp(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_menu_about_app",
            String(describing: pronounce1)
        )
    }

    /// %@ ausblenden
    public static func generalMenuHideApp(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_menu_hide_app",
            String(describing: pronounce1)
        )
    }

    /// Andere ausblenden
    public static var generalMenuHideOthers: String { L10n.tr("general_menu_hide_others") }
    /// Menü
    public static var generalMenuMain: String { L10n.tr("general_menu_main") }
    /// Einstellungen…
    public static var generalMenuPreferences: String { L10n.tr("general_menu_preferences") }
    /// %@ beenden
    public static func generalMenuQuit(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_menu_quit",
            String(describing: pronounce1)
        )
    }

    /// Alle einblenden
    public static var generalMenuShowAll: String { L10n.tr("general_menu_show_all") }
    /// Automatisch
    public static var generalMoreAppearanceAutomatic: String { L10n.tr("general_more_appearance_automatic") }
    /// Dunkel
    public static var generalMoreAppearanceDark: String { L10n.tr("general_more_appearance_dark") }
    /// Hell
    public static var generalMoreAppearanceLight: String { L10n.tr("general_more_appearance_light") }
    /// Erscheinungsbild
    public static var generalMoreAppearanceTitle: String { L10n.tr("general_more_appearance_title") }
    /// Daten exportieren
    public static var generalMoreExportTitle: String { L10n.tr("general_more_export_title") }
    /// Daten importieren
    public static var generalMoreImportTitle: String { L10n.tr("general_more_import_title") }
    /// Impressum
    public static var generalMoreImprint: String { L10n.tr("general_more_imprint") }
    /// Datenschutz
    public static var generalMorePrivacy: String { L10n.tr("general_more_privacy") }
    /// App bewerten
    public static var generalMoreRateApp: String { L10n.tr("general_more_rate_app") }
    /// Developer
    public static var generalMoreSectionDeveloper: String { L10n.tr("general_more_section_developer") }
    /// Export
    public static var generalMoreSectionExport: String { L10n.tr("general_more_section_export") }
    /// Informationen
    public static var generalMoreSectionInfo: String { L10n.tr("general_more_section_info") }
    /// Einstellungen
    public static var generalMoreSectionSettings: String { L10n.tr("general_more_section_settings") }
    /// Tags
    public static var generalMoreTags: String { L10n.tr("general_more_tags") }
    /// Auf iOS übertragen
    public static var generalMoreTransferToIos: String { L10n.tr("general_more_transfer_to_ios") }
    /// Mac Synchronisation
    public static var generalMoreTransferToMac: String { L10n.tr("general_more_transfer_to_mac") }
    /// Keine Daten
    public static var generalNoData: String { L10n.tr("general_no_data") }
    /// Keine
    public static var generalNone: String { L10n.tr("general_none") }
    /// OK
    public static var generalOk: String { L10n.tr("general_ok") }
    /// Notiz
    public static var generalOverviewActionAddNote: String { L10n.tr("general_overview_action_add_note") }
    /// Duplizieren
    public static var generalOverviewActionDuplicate: String { L10n.tr("general_overview_action_duplicate") }
    /// Neue Buchung
    public static var generalOverviewActionNewEntry: String { L10n.tr("general_overview_action_new_entry") }
    /// Öffnen
    public static var generalOverviewActionOpenRecord: String { L10n.tr("general_overview_action_open_record") }
    /// Zur Liste
    public static var generalOverviewActionOpenRecordsList: String { L10n.tr("general_overview_action_open_records_list") }
    /// Speichern
    public static var generalOverviewActionSaveNote: String { L10n.tr("general_overview_action_save_note") }
    /// Starten
    public static var generalOverviewActionStart: String { L10n.tr("general_overview_action_start") }
    /// Stoppen
    public static var generalOverviewActionStop: String { L10n.tr("general_overview_action_stop") }
    /// Dauer %@
    public static func generalOverviewElapsed(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "general_overview_elapsed",
            String(describing: pronounce1)
        )
    }

    /// %@ bis %@
    public static func generalOverviewLatestTime(
        _ pronounce1: Any,
        _ pronounce2: Any
    ) -> String {
        L10n.tr(
            "general_overview_latest_time",
            String(describing: pronounce1),
            String(describing: pronounce2)
        )
    }

    /// Letzte Buchung
    public static var generalOverviewLatestTitle: String { L10n.tr("general_overview_latest_title") }
    /// Übersicht wird geladen
    public static var generalOverviewLoading: String { L10n.tr("general_overview_loading") }
    /// %@: %@
    public static func generalOverviewMetaLine(
        _ pronounce1: Any,
        _ pronounce2: Any
    ) -> String {
        L10n.tr(
            "general_overview_meta_line",
            String(describing: pronounce1),
            String(describing: pronounce2)
        )
    }

    /// Keine Buchung vorhanden
    public static var generalOverviewNoLatestRecord: String { L10n.tr("general_overview_no_latest_record") }
    /// Notiz eingeben
    public static var generalOverviewNotePlaceholder: String { L10n.tr("general_overview_note_placeholder") }
    /// Notiz bearbeiten
    public static var generalOverviewNoteTitle: String { L10n.tr("general_overview_note_title") }
    /// Freigabe ausstehend
    public static var generalOverviewOpenItemsApproval: String { L10n.tr("general_overview_open_items_approval") }
    /// Abrechnung offen
    public static var generalOverviewOpenItemsBilling: String { L10n.tr("general_overview_open_items_billing") }
    /// Diesen Monat fakturiert
    public static var generalOverviewOpenItemsInvoicedPeriod: String { L10n.tr("general_overview_open_items_invoiced_period") }
    /// Offene Punkte
    public static var generalOverviewOpenItemsTitle: String { L10n.tr("general_overview_open_items_title") }
    /// Alle Profile
    public static var generalOverviewProfileAll: String { L10n.tr("general_overview_profile_all") }
    /// Profil
    public static var generalOverviewProfileScope: String { L10n.tr("general_overview_profile_scope") }
    /// Schnellaktionen
    public static var generalOverviewQuickActionsTitle: String { L10n.tr("general_overview_quick_actions_title") }
    /// Keine Einträge vorhanden
    public static var generalOverviewRecentEmpty: String { L10n.tr("general_overview_recent_empty") }
    /// Letzte Einträge
    public static var generalOverviewRecentTitle: String { L10n.tr("general_overview_recent_title") }
    /// Aktivität
    public static var generalOverviewRunningActivity: String { L10n.tr("general_overview_running_activity") }
    /// Auftrag
    public static var generalOverviewRunningOrder: String { L10n.tr("general_overview_running_order") }
    /// Aktiver Timer
    public static var generalOverviewRunningTitle: String { L10n.tr("general_overview_running_title") }
    /// Läuft
    public static var generalOverviewStatusRunning: String { L10n.tr("general_overview_status_running") }
    /// Nicht aktiv
    public static var generalOverviewStatusStopped: String { L10n.tr("general_overview_status_stopped") }
    /// Pausenzeit
    public static var generalOverviewTodayBreak: String { L10n.tr("general_overview_today_break") }
    /// Einträge
    public static var generalOverviewTodayEntries: String { L10n.tr("general_overview_today_entries") }
    /// Nettozeit
    public static var generalOverviewTodayNet: String { L10n.tr("general_overview_today_net") }
    /// Heute
    public static var generalOverviewTodayTitle: String { L10n.tr("general_overview_today_title") }
    /// Unbekannt
    public static var generalOverviewValueUnknown: String { L10n.tr("general_overview_value_unknown") }
    /// Kunden suchen
    public static var generalPlaceholderSearchClients: String { L10n.tr("general_placeholder_search_clients") }
    /// Eingabe
    public static var generalSave: String { L10n.tr("general_save") }
    /// Bereich
    public static var generalScope: String { L10n.tr("general_scope") }
    /// Suchen
    public static var generalSearch: String { L10n.tr("general_search") }
    /// Auswählen...
    public static var generalSelectPlaceholder: String { L10n.tr("general_select_placeholder") }
    /// Einstellungen
    public static var generalSettings: String { L10n.tr("general_settings") }
    /// Gemeinsames Profil
    public static var generalSharedProfile: String { L10n.tr("general_shared_profile") }
    /// Status
    public static var generalStatus: String { L10n.tr("general_status") }
    /// Daten
    public static var generalTabData: String { L10n.tr("general_tab_data") }
    /// Mehr
    public static var generalTabExport: String { L10n.tr("general_tab_export") }
    /// Verwaltung
    public static var generalTabManagement: String { L10n.tr("general_tab_management") }
    /// Übersicht
    public static var generalTabOverview: String { L10n.tr("general_tab_overview") }
    /// Unbekannt
    public static var generalUnknown: String { L10n.tr("general_unknown") }
    /// Lege hier eine neue Kostenstelle an, indem du einen Namen eingibst. Die externe Referenz kann z. B. ein Buchungscode sein, und der Kommentar ist für deine eigenen Notizen.
    public static var managementCostCentreEditFooter: String { L10n.tr("management_cost_centre_edit_footer") }
    /// Aktive Kostenstellen
    public static var managementCostCentreSectionActive: String { L10n.tr("management_cost_centre_section_active") }
    /// Inaktive Kostenstellen
    public static var managementCostCentreSectionInactive: String { L10n.tr("management_cost_centre_section_inactive") }
    /// Deaktivierte Kostenstellen können in der App nicht ausgewählt werden. Sie bleiben erhalten, weil sie bereits in bestehenden Daten und Reports verwendet werden.
    public static var managementCostCentreSectionInactiveFooter: String { L10n.tr("management_cost_centre_section_inactive_footer") }
    /// Schau kurz über die möglichen Kostenstellen. Wenn alles passt, geh weiter. Du kannst sie später auch noch bearbeiten.
    public static var managementOnboardingCostCentreHint: String { L10n.tr("management_onboarding_cost_centre_hint") }
    /// Neuen Begriff hinzufügen
    public static var managementTerminologyAccessibilityAddTerm: String { L10n.tr("management_terminology_accessibility_add_term") }
    /// Hinzufügen
    public static var managementTerminologyAddButton: String { L10n.tr("management_terminology_add_button") }
    /// Hinweis
    public static var managementTerminologyAlertInfoTitle: String { L10n.tr("management_terminology_alert_info_title") }
    /// Singular und Plural müssen ausgefüllt sein, bevor du den Bildschirm verlässt.
    public static var managementTerminologyErrorBothRequired: String { L10n.tr("management_terminology_error_both_required") }
    /// Bitte einen Namen eingeben.
    public static var managementTerminologyErrorEnterName: String { L10n.tr("management_terminology_error_enter_name") }
    /// Der Auftraggeber-Name darf nicht leer sein.
    public static var managementTerminologyErrorNameRequired: String { L10n.tr("management_terminology_error_name_required") }
    /// Einstellung konnte nicht gespeichert werden.
    public static var managementTerminologyErrorSaveFailed: String { L10n.tr("management_terminology_error_save_failed") }
    /// Aktueller Name
    public static var managementTerminologyFieldCurrentName: String { L10n.tr("management_terminology_field_current_name") }
    /// Neuer Name
    public static var managementTerminologyFieldNewName: String { L10n.tr("management_terminology_field_new_name") }
    /// Mehrzahl
    public static var managementTerminologyFieldPluralName: String { L10n.tr("management_terminology_field_plural_name") }
    /// Plural
    public static var managementTerminologyFieldPluralTitle: String { L10n.tr("management_terminology_field_plural_title") }
    /// Singular
    public static var managementTerminologyFieldSingularTitle: String { L10n.tr("management_terminology_field_singular_title") }
    /// Bestimme, wie die App die Person oder Organisation bezeichnet, für wen du Leistungen erbringst. Beispiele: Selbständig → „Auftraggeber“, Kanzlei → „Mandant“, Angestellt → „Arbeitgeber“. Du kannst die Einstellung später anpassen.
    public static var managementTerminologyFooterCounterparty: String { L10n.tr("management_terminology_footer_counterparty") }
    /// Kunden
    public static var managementTerminologyOptionClientPlural: String { L10n.tr("management_terminology_option_client_plural") }
    /// Kunde
    public static var managementTerminologyOptionClientSingular: String { L10n.tr("management_terminology_option_client_singular") }
    /// Arbeitgeber
    public static var managementTerminologyOptionEmployerPlural: String { L10n.tr("management_terminology_option_employer_plural") }
    /// Arbeitgeber
    public static var managementTerminologyOptionEmployerSingular: String { L10n.tr("management_terminology_option_employer_singular") }
    /// Freitext
    public static var managementTerminologyOptionFreeTextPlural: String { L10n.tr("management_terminology_option_free_text_plural") }
    /// Freitext
    public static var managementTerminologyOptionFreeTextSingular: String { L10n.tr("management_terminology_option_free_text_singular") }
    /// Mandanten
    public static var managementTerminologyOptionMandatePlural: String { L10n.tr("management_terminology_option_mandate_plural") }
    /// Mandant
    public static var managementTerminologyOptionMandateSingular: String { L10n.tr("management_terminology_option_mandate_singular") }
    /// Auftraggeber
    public static var managementTerminologyOptionPrincipalPlural: String { L10n.tr("management_terminology_option_principal_plural") }
    /// Auftraggeber
    public static var managementTerminologyOptionPrincipalSingular: String { L10n.tr("management_terminology_option_principal_singular") }
    /// Vorauswahl
    public static var managementTerminologyPickerTerm: String { L10n.tr("management_terminology_picker_term") }
    /// Terminologie gespeichert.
    public static var managementTerminologySaved: String { L10n.tr("management_terminology_saved") }
    /// Bitte wähle deine Konfiguration
    public static var managementTerminologySectionCounterparty: String { L10n.tr("management_terminology_section_counterparty") }
    /// Neuen Namen
    public static var managementTerminologySheetNewNameTitle: String { L10n.tr("management_terminology_sheet_new_name_title") }
    /// Terminologie
    public static var managementTerminologyTitle: String { L10n.tr("management_terminology_title") }
    /// Verwerfen
    public static var managementTerminologyUnsavedDiscard: String { L10n.tr("management_terminology_unsaved_discard") }
    /// Du hast ungespeicherte Freitext-Änderungen. Möchtest du speichern, verwerfen oder abbrechen?
    public static var managementTerminologyUnsavedMessage: String { L10n.tr("management_terminology_unsaved_message") }
    /// Speichern und verlassen
    public static var managementTerminologyUnsavedSaveAndLeave: String { L10n.tr("management_terminology_unsaved_save_and_leave") }
    /// Ungespeicherte Änderungen
    public static var managementTerminologyUnsavedTitle: String { L10n.tr("management_terminology_unsaved_title") }
    /// Bearbeiten
    public static var measurementDetailEdit: String { L10n.tr("measurement_detail_edit") }
    /// Abbrechen
    public static var measurementInputCancel: String { L10n.tr("measurement_input_cancel") }
    /// Kommentar
    public static var measurementInputComment: String { L10n.tr("measurement_input_comment") }
    /// Datum
    public static var measurementInputDate: String { L10n.tr("measurement_input_date") }
    /// Diastolisch
    public static var measurementInputDiastolic: String { L10n.tr("measurement_input_diastolic") }
    /// Direkt
    public static var measurementInputModeDirect: String { L10n.tr("measurement_input_mode_direct") }
    /// Native
    public static var measurementInputModeNative: String { L10n.tr("measurement_input_mode_native") }
    /// Puls
    public static var measurementInputPulse: String { L10n.tr("measurement_input_pulse") }
    /// Speichern
    public static var measurementInputSave: String { L10n.tr("measurement_input_save") }
    /// Systolisch
    public static var measurementInputSystolic: String { L10n.tr("measurement_input_systolic") }
    /// Tags
    public static var measurementInputTags: String { L10n.tr("measurement_input_tags") }
    /// Pulsdruck
    public static var measurementListPulsePressure: String { L10n.tr("measurement_list_pulse_pressure") }
    /// Hochnormal
    public static var measurementResultHighNormal: String { L10n.tr("measurement_result_high_normal") }
    /// Hypertonie Grad 1
    public static var measurementResultHypertensionGrade1: String { L10n.tr("measurement_result_hypertension_grade1") }
    /// Hypertonie Grad 2
    public static var measurementResultHypertensionGrade2: String { L10n.tr("measurement_result_hypertension_grade2") }
    /// Hypertonie Grad 3
    public static var measurementResultHypertensionGrade3: String { L10n.tr("measurement_result_hypertension_grade3") }
    /// Niedriger Blutdruck
    public static var measurementResultLow: String { L10n.tr("measurement_result_low") }
    /// Normal
    public static var measurementResultNormal: String { L10n.tr("measurement_result_normal") }
    /// Optimal
    public static var measurementResultOptimal: String { L10n.tr("measurement_result_optimal") }
    /// Nachmittags gemessen
    public static var measurementTimePeriodAfternoonMeasured: String { L10n.tr("measurement_time_period_afternoon_measured") }
    /// Abends gemessen
    public static var measurementTimePeriodEveningMeasured: String { L10n.tr("measurement_time_period_evening_measured") }
    /// Vormittags gemessen
    public static var measurementTimePeriodMorningMeasured: String { L10n.tr("measurement_time_period_morning_measured") }
    /// Nachts gemessen
    public static var measurementTimePeriodNightMeasured: String { L10n.tr("measurement_time_period_night_measured") }
    /// Ein Jahr Premium mit allen Funktionen & Berichten
    public static var purchaseAnnualDescription: String { L10n.tr("purchase_annual_description") }
    /// Jahresabo Premium
    public static var purchaseAnnualName: String { L10n.tr("purchase_annual_name") }
    /// Lebenslanger Zugriff auf alle Premium-Funktionen
    public static var purchaseLifetimeDescription: String { L10n.tr("purchase_lifetime_description") }
    /// Einmaliger Kauf Premium
    public static var purchaseLifetimeName: String { L10n.tr("purchase_lifetime_name") }
    /// Voller Zugriff auf alle Premium-Funktionen
    public static var purchaseMonthlyDescription: String { L10n.tr("purchase_monthly_description") }
    /// Monatsabo Premium
    public static var purchaseMonthlyName: String { L10n.tr("purchase_monthly_name") }
    /// Überspringen
    public static var purchaseSkip: String { L10n.tr("purchase_skip") }
    /// Datenbank leeren
    public static var settingsDeveloperClearDatabase: String { L10n.tr("settings_developer_clear_database") }
    /// Datenbank leeren
    public static var settingsDeveloperClearDatabaseConfirm: String { L10n.tr("settings_developer_clear_database_confirm") }
    /// Datenbank wirklich leeren?
    public static var settingsDeveloperClearDatabaseTitle: String { L10n.tr("settings_developer_clear_database_title") }
    /// Harter Werksreset (alles löschen)
    public static var settingsDeveloperFactoryReset: String { L10n.tr("settings_developer_factory_reset") }
    /// Alles löschen und beenden
    public static var settingsDeveloperFactoryResetConfirm: String { L10n.tr("settings_developer_factory_reset_confirm") }
    /// Die gesamte lokale Datenbank inklusive Quarantäne- und Backup-Dateien wird gelöscht. Die App beendet sich danach sofort.
    public static var settingsDeveloperFactoryResetMessage: String { L10n.tr("settings_developer_factory_reset_message") }
    /// Harten Werksreset ausführen?
    public static var settingsDeveloperFactoryResetTitle: String { L10n.tr("settings_developer_factory_reset_title") }
    /// Seed Data
    public static var settingsDeveloperSeedData: String { L10n.tr("settings_developer_seed_data") }
    /// Kontakt
    public static var settingsImprintContactButton: String { L10n.tr("settings_imprint_contact_button") }
    /// app@jandamerau.com
    public static var settingsImprintContactEmail: String { L10n.tr("settings_imprint_contact_email") }
    /// mailto:app@jandamerau.com
    public static var settingsImprintContactMailto: String { L10n.tr("settings_imprint_contact_mailto") }
    /// Impressum
    public static var settingsImprintHeadingTitle: String { L10n.tr("settings_imprint_heading_title") }
    /// Verantwortlicher gemäß § 55 Abs. 2 RStV
    public static var settingsImprintResponsibleHeadline: String { L10n.tr("settings_imprint_responsible_headline") }
    /// Impressum
    public static var settingsImprintTitle: String { L10n.tr("settings_imprint_title") }
    /// Haptisches Feedback
    public static var settingsMoreHapticFeedbackTitle: String { L10n.tr("settings_more_haptic_feedback_title") }
    /// Sprache
    public static var settingsMoreLanguageTitle: String { L10n.tr("settings_more_language_title") }
    /// Abo verwalten
    public static var settingsMorePurchasesTitle: String { L10n.tr("settings_more_purchases_title") }
    /// Käufe wiederherstellen
    public static var settingsMoreRestorePurchases: String { L10n.tr("settings_more_restore_purchases") }
    /// Einstellungen
    public static var settingsMoreTitle: String { L10n.tr("settings_more_title") }
    /// Jetzt verbinden
    public static var settingsPeerSyncConnectNow: String { L10n.tr("settings_peer_sync_connect_now") }
    /// Du bist erfolgreich mit deinem Mac %@ verbunden. Synchronisiere jetzt deine Daten, wenn beide Apps geöffnet und im gleichen Netzwerk sind.
    public static func settingsPeerSyncConnectedHint(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "settings_peer_sync_connected_hint",
            String(describing: pronounce1)
        )
    }

    /// Synchronisierung erlauben
    public static var settingsPeerSyncIncomingSyncAllow: String { L10n.tr("settings_peer_sync_incoming_sync_allow") }
    /// %@ möchte Daten synchronisieren. Möchtest du das jetzt erlauben?
    public static func settingsPeerSyncIncomingSyncMessage(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "settings_peer_sync_incoming_sync_message",
            String(describing: pronounce1)
        )
    }

    /// Eingehende Synchronisierung
    public static var settingsPeerSyncIncomingSyncTitle: String { L10n.tr("settings_peer_sync_incoming_sync_title") }
    /// Scanne den QR-Code von deinem Mac, um die lokale Synchronisierung zu starten.
    public static var settingsPeerSyncIntroHint: String { L10n.tr("settings_peer_sync_intro_hint") }
    /// Dein Gerät ist bereits gekoppelt. Tippe auf Jetzt mit iOS synchronisieren, wenn beide Apps geöffnet und im gleichen Netzwerk sind.
    public static var settingsPeerSyncReconnectHint: String { L10n.tr("settings_peer_sync_reconnect_hint") }
    /// Jetzt mit iOS synchronisieren
    public static var settingsPeerSyncReconnectNow: String { L10n.tr("settings_peer_sync_reconnect_now") }
    /// Das erwartete iOS-Gerät mit geöffneter App wurde im lokalen Netzwerk nicht gefunden.
    public static var settingsPeerSyncReconnectPeerNotFoundMessage: String { L10n.tr("settings_peer_sync_reconnect_peer_not_found_message") }
    /// iOS App anzeigen
    public static var settingsPeerSyncShowIosApp: String { L10n.tr("settings_peer_sync_show_ios_app") }
    /// Letzter Transfer
    public static var settingsPeerSyncStatusLastTransfer: String { L10n.tr("settings_peer_sync_status_last_transfer") }
    /// Noch nie
    public static var settingsPeerSyncStatusNever: String { L10n.tr("settings_peer_sync_status_never") }
    /// Noch kein Peer verbunden
    public static var settingsPeerSyncStatusNoPeer: String { L10n.tr("settings_peer_sync_status_no_peer") }
    /// Peer vorhanden
    public static var settingsPeerSyncStatusPeerAvailable: String { L10n.tr("settings_peer_sync_status_peer_available") }
    /// Synchronisierte Daten
    public static var settingsPeerSyncStatusSyncedData: String { L10n.tr("settings_peer_sync_status_synced_data") }
    /// Sync-Status
    public static var settingsPeerSyncStatusTitle: String { L10n.tr("settings_peer_sync_status_title") }
    /// Jetzt synchronisieren
    public static var settingsPeerSyncSyncNow: String { L10n.tr("settings_peer_sync_sync_now") }
    /// Synchronisierung mit %@ läuft gerade. Bitte halte beide Apps geöffnet und im gleichen Netzwerk.
    public static func settingsPeerSyncSyncingHint(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "settings_peer_sync_syncing_hint",
            String(describing: pronounce1)
        )
    }

    /// Datenschutz
    public static var settingsPrivacyPolicyTitle: String { L10n.tr("settings_privacy_policy_title") }
    /// Abos werden automatisch verlängert. Jederzeit kündbar.
    public static var settingsPurchasesFooter: String { L10n.tr("settings_purchases_footer") }
    /// Unterstütze die Entwicklung und erhalte Zugriff auf Premium-Funktionen.
    public static var settingsPurchasesIntro: String { L10n.tr("settings_purchases_intro") }
    /// Abos verwalten
    public static var settingsPurchasesManage: String { L10n.tr("settings_purchases_manage") }
    /// Monatlich kündbar
    public static var settingsPurchasesMonthlyCancelable: String { L10n.tr("settings_purchases_monthly_cancelable") }
    /// Beliebt
    public static var settingsPurchasesPopular: String { L10n.tr("settings_purchases_popular") }
    /// 2 Monate Gratis
    public static var settingsPurchasesSaveTwoMonths: String { L10n.tr("settings_purchases_save_two_months") }
    /// Account
    public static var timerecordInputAccount: String { L10n.tr("timerecord_input_account") }
    /// BVB-2
    public static var timerecordInputAccountDefault: String { L10n.tr("timerecord_input_account_default") }
    /// Konten suchen...
    public static var timerecordInputAccountSearchPlaceholder: String { L10n.tr("timerecord_input_account_search_placeholder") }
    /// Tätigkeit
    public static var timerecordInputActivity: String { L10n.tr("timerecord_input_activity") }
    /// Tätigkeit wählen
    public static var timerecordInputActivityPlaceholder: String { L10n.tr("timerecord_input_activity_placeholder") }
    /// Zuletzt verwendet
    public static var timerecordInputActivityRecent: String { L10n.tr("timerecord_input_activity_recent") }
    /// Eingabe löschen
    public static var timerecordInputClear: String { L10n.tr("timerecord_input_clear") }
    /// Client
    public static var timerecordInputClient: String { L10n.tr("timerecord_input_client") }
    /// Client entfernen
    public static var timerecordInputClientClear: String { L10n.tr("timerecord_input_client_clear") }
    /// Client wählen
    public static var timerecordInputClientPlaceholder: String { L10n.tr("timerecord_input_client_placeholder") }
    /// Arbeitskontext
    public static var timerecordInputContext: String { L10n.tr("timerecord_input_context") }
    /// BVB-2 - Arbeitszeiten
    public static var timerecordInputContextPlaceholder: String { L10n.tr("timerecord_input_context_placeholder") }
    /// Datum
    public static var timerecordInputDate: String { L10n.tr("timerecord_input_date") }
    /// Beschreibung
    public static var timerecordInputDescription: String { L10n.tr("timerecord_input_description") }
    /// Dauer
    public static var timerecordInputDuration: String { L10n.tr("timerecord_input_duration") }
    /// %@m
    public static func timerecordInputDurationMinutes(
        _ pronounce1: Any
    ) -> String {
        L10n.tr(
            "timerecord_input_duration_minutes",
            String(describing: pronounce1)
        )
    }

    /// h
    public static var timerecordInputDurationPlaceholder: String { L10n.tr("timerecord_input_duration_placeholder") }
    /// Endzeit
    public static var timerecordInputEndTime: String { L10n.tr("timerecord_input_end_time") }
    /// Auftrag
    public static var timerecordInputOrder: String { L10n.tr("timerecord_input_order") }
    /// Keine Treffer
    public static var timerecordInputOrderNoResults: String { L10n.tr("timerecord_input_order_no_results") }
    /// Zuerst Client wählen...
    public static var timerecordInputOrderSearchDisabled: String { L10n.tr("timerecord_input_order_search_disabled") }
    /// Auftrag suchen...
    public static var timerecordInputOrderSearchPlaceholder: String { L10n.tr("timerecord_input_order_search_placeholder") }
    /// Startzeit
    public static var timerecordInputStartTime: String { L10n.tr("timerecord_input_start_time") }
    /// Unbekannt
    public static var timerecordInputUnknownValue: String { L10n.tr("timerecord_input_unknown_value") }
}

// MARK: - Implementation Details

extension L10n {
    private static func tr(_ key: String, _ args: CVarArg...) -> String {
        // Default Setup
        //
        // This project supports an in-app language override (macOS Preferences).
        // We resolve translations from a language-specific .lproj bundle when an override is active,
        // instead of relying on `AppleLanguages` which may require an app restart on some platforms.
        let bundle = resolvedLocalizationBundle()
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, locale: resolvedFormattingLocale(), arguments: args)
    }

    private static func resolvedLocalizationBundle() -> Bundle {
        let overrideCode = UserDefaults.standard.string(forKey: "appLanguageOverrideCode")
        guard let overrideCode, overrideCode != "system" else {
            // Resolve the system language explicitly from the global domain, so the UI can switch
            // back reliably even if the app had previously overridden its own `AppleLanguages`.
            guard let systemCode = resolvedSystemLanguageCode(),
                  let path = BundleToken.bundle.path(forResource: systemCode, ofType: "lproj"),
                  let languageBundle = Bundle(path: path)
            else {
                return BundleToken.bundle
            }
            return languageBundle
        }
        guard let path = BundleToken.bundle.path(forResource: overrideCode, ofType: "lproj"),
              let languageBundle = Bundle(path: path)
        else {
            return BundleToken.bundle
        }
        return languageBundle
    }

    private static func resolvedFormattingLocale() -> Locale {
        let overrideCode = UserDefaults.standard.string(forKey: "appLanguageOverrideCode")
        guard let overrideCode, overrideCode != "system" else {
            if let systemCode = resolvedSystemLanguageCode() {
                return Locale(identifier: systemCode)
            }
            return Locale.current
        }
        return Locale(identifier: overrideCode)
    }

    private static func resolvedSystemLanguageCode() -> String? {
        if let languages = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String],
           let first = languages.first,
           let code = normalizeLanguageCode(from: first)
        {
            return code
        }

        if let firstPreferred = Locale.preferredLanguages.first,
           let code = normalizeLanguageCode(from: firstPreferred)
        {
            return code
        }

        return nil
    }

    private static func normalizeLanguageCode(from identifier: String) -> String? {
        let parts = identifier.split(whereSeparator: { $0 == "-" || $0 == "_" })
        guard let primary = parts.first, primary.isEmpty == false else {
            return nil
        }
        return String(primary)
    }
}

private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

// swiftlint:enable type_body_length identifier_name
// swiftformat:enable wrapPropertyBodies
