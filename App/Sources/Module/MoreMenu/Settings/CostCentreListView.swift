//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import SwiftUI

/// View for listing and managing cost centres.
@MainActor
struct CostCentreListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddView = false
    @State private var selectedCostCentre: CostCentre?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var fetchedCostCentres: FetchedResults<CostCentre>
    @AppStorage("management_inactive_costcentre_ids")
    private var inactiveCostCentreIDsRaw: String = ""

    var body: some View {
        List {
            Section {
                ForEach(activeCostCentres, id: \.self) { costCentre in
                    activeRow(for: costCentre)
                }
                .listRowBackground(Color.aListBackground)
            } header: {
                Text(L10n.managementCostCentreSectionActive)
                    .textStyle(.title3)
                    .accessibilityAddTraits(.isHeader)
            } footer: {
                Text("Nutze Kostenstellen, um Zeiten später in Reports und Exporten sinnvoll zu gruppieren.")
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }

            if inactiveCostCentres.isEmpty == false {
                Section {
                    ForEach(inactiveCostCentres, id: \.self) { costCentre in
                        inactiveRow(for: costCentre)
                    }
                    .listRowBackground(Color.aListBackground)
                } header: {
                    Text(L10n.managementCostCentreSectionInactive)
                        .textStyle(.title3)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text(L10n.managementCostCentreSectionInactiveFooter)
                        .textStyle(.body3)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.aBackground)
        .navigationTitle(L10n.generalManagementCostCentres)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddView = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.accessibilityAddCostCentre)
            }
        }
        .sheet(isPresented: $showingAddView) {
            CostCentreEditView()
                .presentationDetents([.medium])
                .presentationBackground(Color.aBackground)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedCostCentre) { costCentre in
            CostCentreEditView(costCentre: costCentre)
                .presentationDetents([.medium])
                .presentationBackground(Color.aBackground)
                .presentationDragIndicator(.visible)
        }
    }

    private var sortedCostCentres: [CostCentre] {
        fetchedCostCentres.sorted { lhs, rhs in
            let lhsName = lhs.name ?? ""
            let rhsName = rhs.name ?? ""
            return lhsName < rhsName
        }
    }

    /// Returns the active cost centres currently visible in the first section.
    private var activeCostCentres: [CostCentre] {
        sortedCostCentres.filter { inactiveCostCentreIdentifiers.contains($0.objectID.uriRepresentation().absoluteString) == false }
    }

    /// Returns the inactive cost centres currently visible in the second section.
    private var inactiveCostCentres: [CostCentre] {
        sortedCostCentres.filter { inactiveCostCentreIdentifiers.contains($0.objectID.uriRepresentation().absoluteString) }
    }

    /// Parses persisted inactive identifiers into a lookup set.
    private var inactiveCostCentreIdentifiers: Set<String> {
        Set(inactiveCostCentreIDsRaw.split(separator: "|").map(String.init))
    }

    /// Renders one active row with context-aware swipe actions.
    ///
    /// - Parameter costCentre: The cost centre shown in the row.
    /// - Returns: One row including swipe actions.
    private func activeRow(for costCentre: CostCentre) -> some View {
        CostCentreRowView(costCentre: costCentre)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedCostCentre = costCentre
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if isCostCentreInUse(costCentre) {
                    Button {
                        deactivate(costCentre)
                    } label: {
                        Text(L10n.generalInactive)
                    }
                    .tint(.orange)
                } else {
                    Button(role: .destructive) {
                        delete(costCentre)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
    }

    /// Renders one inactive row with reactivation swipe action.
    ///
    /// - Parameter costCentre: The cost centre shown in the row.
    /// - Returns: One row including activation swipe action.
    private func inactiveRow(for costCentre: CostCentre) -> some View {
        CostCentreRowView(costCentre: costCentre)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    activate(costCentre)
                } label: {
                    Text(L10n.generalActive)
                }
                .tint(.green)
            }
    }

    /// Persists a cost centre as inactive in local settings.
    ///
    /// - Parameter costCentre: The cost centre to deactivate.
    private func deactivate(_ costCentre: CostCentre) {
        let identifier = costCentre.objectID.uriRepresentation().absoluteString
        var identifiers = inactiveCostCentreIdentifiers
        identifiers.insert(identifier)
        storeInactiveIdentifiers(identifiers)
    }

    /// Removes a cost centre from local inactive settings.
    ///
    /// - Parameter costCentre: The cost centre to reactivate.
    private func activate(_ costCentre: CostCentre) {
        let identifier = costCentre.objectID.uriRepresentation().absoluteString
        var identifiers = inactiveCostCentreIdentifiers
        identifiers.remove(identifier)
        storeInactiveIdentifiers(identifiers)
    }

    /// Indicates whether a cost centre is already used by existing records.
    ///
    /// - Parameter costCentre: The cost centre to evaluate.
    /// - Returns: `true` when linked records already exist.
    private func isCostCentreInUse(_ costCentre: CostCentre) -> Bool {
        let hasAssignedTimeRecords = costCentre.timerecords?.isEmpty == false
        let hasAssignedOrders = costCentre.orders?.isEmpty == false
        return hasAssignedTimeRecords || hasAssignedOrders
    }

    /// Permanently deletes a cost centre that is not in active use.
    ///
    /// - Parameter costCentre: The cost centre to delete.
    private func delete(_ costCentre: CostCentre) {
        guard isCostCentreInUse(costCentre) == false else {
            deactivate(costCentre)
            return
        }

        let identifier = costCentre.objectID.uriRepresentation().absoluteString
        viewContext.delete(costCentre)
        do {
            try viewContext.save()
            var identifiers = inactiveCostCentreIdentifiers
            identifiers.remove(identifier)
            storeInactiveIdentifiers(identifiers)
        } catch {
            print("Error deleting cost centre: \(error)")
        }
    }

    /// Persists the inactive cost-centre identifier list.
    ///
    /// - Parameter identifiers: The identifiers that should be stored as inactive.
    private func storeInactiveIdentifiers(_ identifiers: Set<String>) {
        inactiveCostCentreIDsRaw = identifiers.sorted().joined(separator: "|")
    }
}

/// Row view for displaying a cost centre in the list.
@MainActor
struct CostCentreRowView: View {
    let costCentre: CostCentre

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            HStack {
                Text(costCentre.name ?? L10n.generalUnknown)
                    .textStyle(.body1)
                    .foregroundStyle(Color.aPrimary)
                Spacer()
                Text(L10n.costCentreScopeGlobal)
                    .textStyle(.tabbar)
                    .foregroundStyle(Color.aAccentColorBlue)
                    .padding(.horizontal, .spacingXS)
                    .padding(.vertical, 2)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.aAccentColorBlue.opacity(0.14))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.aAccentColorBlue.opacity(0.35), lineWidth: 1)
                    )
            }

            if let externalReferenceText, externalReferenceText.isEmpty == false {
                HStack(spacing: .spacingXS) {
                    Image(systemName: "number")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.aAccentColorBlue)
                        .frame(width: .spacingXS)
                        .accessibilityHidden(true)
                    Text(externalReferenceText)
                        .textStyle(.body3)
                        .foregroundStyle(Color.aPrimary)
                }
            }

            // Note: Client display removed as client relationship doesn't exist in current data model

            if let commentText, commentText.isEmpty == false {
                Text(commentText)
                    .textStyle(.body3)
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// The formatted external reference text rendered in prominent style.
    private var externalReferenceText: String? {
        let trimmedReference = costCentre.external_ref?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard trimmedReference.isEmpty == false else {
            return nil
        }
        return "\(L10n.costCentreExternalRef): \(trimmedReference)"
    }

    /// The optional comment text rendered as secondary helper text.
    private var commentText: String? {
        let trimmedComment = costCentre.notice?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard trimmedComment.isEmpty == false else {
            return nil
        }
        return trimmedComment
    }
}
