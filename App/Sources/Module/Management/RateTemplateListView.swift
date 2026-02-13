//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Lists reusable rate templates for creation, maintenance, and deactivation.
@MainActor
struct RateTemplateListView: View {
    /// Available template filter tabs.
    enum ActivityFilter: String, CaseIterable, Identifiable {
        case active
        case inactive
        case all

        var id: String { rawValue }
    }

    /// The managed object context used for updates.
    @Environment(\.managedObjectContext) private var viewContext

    /// Fetches all templates sorted by name.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedTemplates: FetchedResults<RateTemplate>

    /// Stores the search string used to filter by name.
    @State private var searchText: String = ""

    /// Stores the active filter segment.
    @State private var filter: ActivityFilter = .active

    /// Controls add-sheet presentation.
    @State private var showsAddSheet = false

    /// Stores currently selected template for edit mode.
    @State private var selectedTemplate: RateTemplate?

    /// Renders the template list.
    var body: some View {
        List {
            Section {
                Picker(L10n.generalFilter, selection: $filter) {
                    Text(L10n.generalActive).tag(ActivityFilter.active)
                    Text(L10n.generalInactive).tag(ActivityFilter.inactive)
                    Text("All").tag(ActivityFilter.all)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(filteredTemplates, id: \.objectID) { template in
                    templateRow(template)
                        .listRowBackground(Color.aListBackground)
                }
            } header: {
                Text("Rate Templates")
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .searchable(text: $searchText, prompt: L10n.generalSearch)
        .navigationTitle("Rate Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showsAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create template")
            }
        }
        .sheet(isPresented: $showsAddSheet) {
            RateTemplateEditView()
        }
        .sheet(item: $selectedTemplate) { template in
            RateTemplateEditView(template: template)
        }
    }
}

private extension RateTemplateListView {
    /// Returns the currently selected profile object if persisted in settings.
    var selectedProfile: Profile? {
        let profileURIString = SettingsStorageService.shared.activeProfileObjectURI
        guard profileURIString.isEmpty == false,
              let uri = URL(string: profileURIString),
              let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri),
              let object = try? viewContext.existingObject(with: objectID),
              let profile = object as? Profile
        else {
            return nil
        }
        return profile
    }

    /// Returns templates filtered by search and active-state segment.
    var filteredTemplates: [RateTemplate] {
        let scopedTemplates = fetchedTemplates.filter { template in
            guard let selectedProfile else {
                return true
            }
            let belongsToProfile = template.profile?.objectID == selectedProfile.objectID
            let isShared = template.shared_profile?.boolValue ?? true
            return belongsToProfile || isShared
        }

        return scopedTemplates.filter { template in
            let matchesSearch = matchesSearchText(template)
            let matchesState = matchesStateFilter(template)
            return matchesSearch && matchesState
        }
    }

    /// Renders one template row with edit and activate/deactivate actions.
    ///
    /// - Parameter template: The template to display.
    /// - Returns: One list row.
    func templateRow(_ template: RateTemplate) -> some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            HStack {
                Text(displayName(template))
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)
                Spacer()
                Text(displayBillingType(template))
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
            }
            if let amount = displayAmount(template) {
                Text(amount)
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTemplate = template
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if template.is_active?.boolValue ?? true {
                Button {
                    setActive(false, for: template)
                } label: {
                    Text(L10n.generalInactive)
                }
                .tint(.orange)
            } else {
                Button {
                    setActive(true, for: template)
                } label: {
                    Text(L10n.generalActive)
                }
                .tint(.green)
            }
        }
    }

    /// Applies the selected active-state filter to one template.
    ///
    /// - Parameter template: The candidate template.
    /// - Returns: `true` when the template passes the active-state filter.
    func matchesStateFilter(_ template: RateTemplate) -> Bool {
        let isActive = template.is_active?.boolValue ?? true
        switch filter {
        case .active:
            return isActive
        case .inactive:
            return isActive == false
        case .all:
            return true
        }
    }

    /// Applies the search filter to one template name.
    ///
    /// - Parameter template: The candidate template.
    /// - Returns: `true` when the template name matches the query.
    func matchesSearchText(_ template: RateTemplate) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return true }
        return displayName(template).localizedCaseInsensitiveContains(query)
    }

    /// Returns one safe display name for a template.
    func displayName(_ template: RateTemplate) -> String {
        let trimmed = template.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalUnknown : trimmed
    }

    /// Returns one short label for billing type.
    func displayBillingType(_ template: RateTemplate) -> String {
        guard let billingType = BillingType(coreDataValue: template.billing_type) else {
            return "-"
        }
        switch billingType {
        case .hourly:
            return "Hourly"
        case .fixed:
            return "Fixed"
        case .none:
            return "None"
        }
    }

    /// Returns one amount text depending on billing type.
    func displayAmount(_ template: RateTemplate) -> String? {
        guard let billingType = BillingType(coreDataValue: template.billing_type) else {
            return nil
        }
        switch billingType {
        case .hourly:
            guard let value = template.hourly_rate?.doubleValue else { return nil }
            return String(format: "%.2f", value)
        case .fixed:
            guard let value = template.fixed_amount?.doubleValue else { return nil }
            return String(format: "%.2f", value)
        case .none:
            return nil
        }
    }

    /// Updates the `is_active` flag for one template.
    func setActive(_ isActive: Bool, for template: RateTemplate) {
        template.is_active = NSNumber(value: isActive)
        template.updated_at = Date()
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
    }
}
