//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Renders the root overview dashboard.
struct OverviewView: View {
    /// Provides access to the managed object context.
    @Environment(\.managedObjectContext) private var context

    /// Stores the view model once the view appears.
    @State private var viewModel: OverviewViewModel?

    /// Stores the record currently edited in the note sheet.
    @State private var noteRecord: TimeRecords?

    /// Stores the note draft text.
    @State private var noteDraft: String = ""

    /// The main dashboard content.
    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
                    .accessibilityLabel(L10n.generalOverviewLoading)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .navigationTitle(L10n.generalTabOverview)
        .onAppear {
            guard viewModel == nil else {
                return
            }
            viewModel = OverviewViewModel(context: context)
        }
        .sheet(item: $noteRecord) { record in
            noteSheet(record: record)
        }
    }
}

private extension OverviewView {
    /// Builds the scrollable dashboard content.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The complete dashboard view.
    func content(viewModel: OverviewViewModel) -> some View {
        ScrollView {
            VStack(spacing: .spacingM) {
                profileCard(viewModel: viewModel)
                runningCard(viewModel: viewModel)
                latestRecordCard(viewModel: viewModel)
                todayMetricsCard(viewModel: viewModel)
                openItemsCard(viewModel: viewModel)
                recentRecordsCard(viewModel: viewModel)
                quickActionsCard(viewModel: viewModel)
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
        }
    }

    /// Builds the profile selection card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The profile scope card.
    @ViewBuilder
    func profileCard(viewModel: OverviewViewModel) -> some View {
        if viewModel.isProfileSelectionVisible {
            dashboardCard(title: L10n.generalOverviewProfileScope, accessibilityLabel: L10n.accessibilityOverviewProfilePicker) {
                Picker(L10n.generalOverviewProfileScope, selection: Binding(
                    get: { viewModel.selectedProfileObjectURI },
                    set: { viewModel.selectProfile($0) }
                )) {
                    ForEach(viewModel.availableProfiles, id: \.objectID) { profile in
                        Text(normalizedValue(profile.name))
                            .tag(profile.objectID.uriRepresentation().absoluteString)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel(L10n.accessibilityOverviewProfilePicker)
            }
        }
    }

    /// Builds the running timer card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The running timer card.
    func runningCard(viewModel: OverviewViewModel) -> some View {
        dashboardCard(title: L10n.generalOverviewRunningTitle, accessibilityLabel: L10n.accessibilityOverviewRunningCard) {
            if let record = viewModel.runningRecord {
                VStack(alignment: .leading, spacing: .spacingS) {
                    HStack {
                        Text(L10n.generalOverviewStatusRunning)
                            .textStyle(.body2)
                        Spacer()
                        runningElapsedText(viewModel: viewModel, record: record)
                            .textStyle(.body2)
                    }

                    recordMetaLine(label: L10n.generalOverviewRunningOrder, value: record.order?.name)
                    recordMetaLine(label: L10n.generalOverviewRunningActivity, value: record.activity?.name)

                    HStack(spacing: .spacingS) {
                        Button(L10n.generalOverviewActionStop) {
                            viewModel.stopRunningRecord()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityLabel(L10n.generalOverviewActionStop)

                        Button(L10n.generalOverviewActionAddNote) {
                            noteDraft = record.notice ?? ""
                            noteRecord = record
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel(L10n.generalOverviewActionAddNote)

                        Button(L10n.generalOverviewActionOpenRecord) {
                            viewModel.openStartInput()
                        }
                        .buttonStyle(TextButtonStyle())
                        .accessibilityLabel(L10n.generalOverviewActionOpenRecord)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: .spacingS) {
                    Text(L10n.generalOverviewStatusStopped)
                        .textStyle(.body1)

                    Button(L10n.generalOverviewActionStart) {
                        viewModel.openStartInput()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityLabel(L10n.generalOverviewActionStart)
                }
            }
        }
    }

    /// Builds one live elapsed text for a running record.
    ///
    /// - Parameters:
    ///   - viewModel: The dashboard state source.
    ///   - record: The currently running record.
    /// - Returns: A live-updating elapsed label.
    @ViewBuilder
    func runningElapsedText(viewModel: OverviewViewModel, record: TimeRecords) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timelineContext in
            let startDate = record.start_time ?? timelineContext.date
            let elapsedMinutes = max(Int(timelineContext.date.timeIntervalSince(startDate) / 60), 0)
            Text(L10n.generalOverviewElapsed(viewModel.durationLabel(for: elapsedMinutes)))
                .accessibilityLabel(L10n.generalOverviewElapsed(viewModel.durationLabel(for: elapsedMinutes)))
        }
    }

    /// Builds the latest-record summary card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The latest-record card.
    func latestRecordCard(viewModel: OverviewViewModel) -> some View {
        dashboardCard(title: L10n.generalOverviewLatestTitle, accessibilityLabel: L10n.accessibilityOverviewLatestCard) {
            if let record = viewModel.latestRecord {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    recordMetaLine(label: L10n.generalOverviewRunningOrder, value: record.order?.name)
                    recordMetaLine(label: L10n.generalOverviewRunningActivity, value: record.activity?.name)
                    Text(
                        L10n.generalOverviewLatestTime(
                            viewModel.shortTime(for: record.start_time),
                            viewModel.shortTime(for: record.end_time)
                        )
                    )
                    .textStyle(.body3)
                }
            } else {
                Text(L10n.generalOverviewNoLatestRecord)
                    .textStyle(.body1)
            }
        }
    }

    /// Builds the today-metrics card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The metrics card.
    func todayMetricsCard(viewModel: OverviewViewModel) -> some View {
        dashboardCard(title: L10n.generalOverviewTodayTitle, accessibilityLabel: L10n.accessibilityOverviewTodayCard) {
            VStack(alignment: .leading, spacing: .spacingXS) {
                metricRow(
                    title: L10n.generalOverviewTodayNet,
                    value: viewModel.durationLabel(for: viewModel.todayMetrics.netMinutes)
                )
                metricRow(
                    title: L10n.generalOverviewTodayBreak,
                    value: viewModel.durationLabel(for: viewModel.todayMetrics.breakMinutes)
                )
                metricRow(
                    title: L10n.generalOverviewTodayEntries,
                    value: "\(viewModel.todayMetrics.entryCount)"
                )
            }
        }
    }

    /// Builds the open-items workflow card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The open-items card.
    func openItemsCard(viewModel: OverviewViewModel) -> some View {
        dashboardCard(title: L10n.generalOverviewOpenItemsTitle, accessibilityLabel: L10n.accessibilityOverviewOpenItemsCard) {
            VStack(alignment: .leading, spacing: .spacingXS) {
                openItemButton(
                    title: L10n.generalOverviewOpenItemsApproval,
                    value: viewModel.openItems.approvalPendingCount,
                    route: .module(.timeRecordsList(filter: .approvalPending))
                )
                openItemButton(
                    title: L10n.generalOverviewOpenItemsBilling,
                    value: viewModel.openItems.billingOpenCount,
                    route: .module(.timeRecordsList(filter: .billingOpen))
                )
                openItemButton(
                    title: L10n.generalOverviewOpenItemsInvoicedPeriod,
                    value: viewModel.openItems.invoicedThisPeriodCount,
                    route: .module(.timeRecordsList(filter: .invoicedThisMonth))
                )
            }
        }
    }

    /// Builds the recent-records card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The recent-records card.
    func recentRecordsCard(viewModel: OverviewViewModel) -> some View {
        dashboardCard(title: L10n.generalOverviewRecentTitle, accessibilityLabel: L10n.accessibilityOverviewRecentCard) {
            if viewModel.recentRecords.isEmpty {
                Text(L10n.generalOverviewRecentEmpty)
                    .textStyle(.body1)
            } else {
                ForEach(viewModel.recentRecords, id: \.objectID) { record in
                    VStack(alignment: .leading, spacing: .spacingXXS) {
                        Text(normalizedValue(record.order?.name))
                            .textStyle(.body2)

                        Text(normalizedValue(record.activity?.name))
                            .textStyle(.body3)

                        Text(viewModel.shortDateTime(for: record.start_time ?? record.work_date))
                            .textStyle(.body3)

                        HStack(spacing: .spacingS) {
                            Button(L10n.generalOverviewActionOpenRecord) {
                                viewModel.openStartInput()
                            }
                            .buttonStyle(TextButtonStyle())

                            Button(L10n.generalOverviewActionDuplicate) {
                                viewModel.duplicate(record: record)
                            }
                            .buttonStyle(TextButtonStyle())
                        }
                    }
                    .padding(.vertical, .spacingXS)

                    if record.objectID != viewModel.recentRecords.last?.objectID {
                        Divider()
                    }
                }
            }
        }
    }

    /// Builds the quick-actions card.
    ///
    /// - Parameter viewModel: The dashboard state source.
    /// - Returns: The quick-actions card.
    func quickActionsCard(viewModel: OverviewViewModel) -> some View {
        dashboardCard(title: L10n.generalOverviewQuickActionsTitle, accessibilityLabel: L10n.accessibilityOverviewQuickActionsCard) {
            HStack(spacing: .spacingS) {
                Button(viewModel.runningRecord == nil ? L10n.generalOverviewActionStart : L10n.generalOverviewActionStop) {
                    if viewModel.runningRecord == nil {
                        viewModel.openStartInput()
                    } else {
                        viewModel.stopRunningRecord()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(L10n.generalOverviewActionNewEntry) {
                    viewModel.openStartInput()
                }
                .buttonStyle(SecondaryButtonStyle())

                NavigationLink(value: NavigationStackRoute.module(.timeRecordsList(filter: .all))) {
                    Text(L10n.generalOverviewActionOpenRecordsList)
                }
                .buttonStyle(TextButtonStyle())
            }
        }
    }

    /// Builds a generic dashboard card container.
    ///
    /// - Parameters:
    ///   - title: The card title.
    ///   - accessibilityLabel: The card accessibility label.
    ///   - content: The card body content.
    /// - Returns: A styled card.
    func dashboardCard(
        title: String,
        accessibilityLabel: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text(title)
                .textStyle(.title3)
            content()
        }
        .padding(.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.aListBackground)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Builds one key-value metric row.
    ///
    /// - Parameters:
    ///   - title: The metric label.
    ///   - value: The metric value.
    /// - Returns: A key-value row.
    func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .textStyle(.body1)
            Spacer()
            Text(value)
                .textStyle(.body2)
        }
    }

    /// Builds one open-item KPI button.
    ///
    /// - Parameters:
    ///   - title: The KPI title.
    ///   - value: The KPI count.
    ///   - route: The destination route triggered on tap.
    /// - Returns: A tappable KPI row.
    func openItemButton(
        title: String,
        value: Int,
        route: NavigationStackRoute
    ) -> some View {
        NavigationLink(value: route) {
            HStack {
                Text(title)
                    .textStyle(.body1)
                Spacer()
                Text("\(value)")
                    .textStyle(.body2)
            }
        }
        .buttonStyle(TextButtonStyle())
        .accessibilityLabel(L10n.accessibilityOverviewOpenItemValue(title, value))
        .accessibilityHint(L10n.accessibilityOverviewOpenItemHint)
    }

    /// Builds one record metadata line.
    ///
    /// - Parameters:
    ///   - label: The metadata label.
    ///   - value: The metadata value.
    /// - Returns: A metadata text row.
    func recordMetaLine(label: String, value: String?) -> some View {
        Text(L10n.generalOverviewMetaLine(label, normalizedValue(value)))
            .textStyle(.body3)
    }

    /// Returns one normalized display value for optional text content.
    ///
    /// - Parameter value: The optional raw value.
    /// - Returns: A fallback-safe text value.
    func normalizedValue(_ value: String?) -> String {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.generalOverviewValueUnknown : trimmed
    }

    /// Builds the note editing sheet for one record.
    ///
    /// - Parameter record: The record being edited.
    /// - Returns: The note sheet content.
    func noteSheet(record _: TimeRecords) -> some View {
        NavigationStack {
            Form {
                TextField(L10n.generalOverviewNotePlaceholder, text: $noteDraft, axis: .vertical)
                    .accessibilityLabel(L10n.generalOverviewNotePlaceholder)
            }
            .navigationTitle(L10n.generalOverviewNoteTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.generalCancel) {
                        noteRecord = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.generalOverviewActionSaveNote) {
                        if let noteRecord {
                            viewModel?.saveNote(for: noteRecord, note: noteDraft)
                        }
                        noteRecord = nil
                    }
                }
            }
        }
    }
}
