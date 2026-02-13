//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import CoreData
import SwiftUI

/// Provides the add-time-record entry view and coordinates platform-specific layouts.
@MainActor
struct AddTimeRecordView: View {
    /// Provides the Core Data context used for loading form reference data.
    @Environment(\.managedObjectContext) private var context

    /// Stores the view model that holds all form state and logic.
    @State private var viewModel: AddTimeRecordViewModel?

    /// Creates the body content for the add-time-record form.
    var body: some View {
        Group {
            if let viewModel {
                platformContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .accessibilityLabel(L10n.timerecordInputUnknownValue)
            }
        }
        .appThemeColors()
        .task {
            configureViewModelIfNeeded()
        }
    }

    /// Creates the view model once when the view appears.
    private func configureViewModelIfNeeded() {
        guard viewModel == nil else {
            return
        }
        viewModel = AddTimeRecordViewModel(context: context)
    }
}

extension AddTimeRecordView {
    /// Resolves the current platform-specific content.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: Platform-specific form layout.
    @ViewBuilder
    func platformContent(viewModel: AddTimeRecordViewModel) -> some View {
        Group {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            iOSContent(viewModel: viewModel)
            #elseif os(macOS)
            macContent(viewModel: viewModel)
            #else
            iOSContent(viewModel: viewModel)
            #endif
        }
        .onAppear {
            viewModel.refreshDurationFromTimeRange()
        }
        .onChange(of: viewModel.startTime) { _, _ in
            viewModel.refreshDurationFromTimeRange()
        }
        .onChange(of: viewModel.endTime) { _, _ in
            viewModel.refreshDurationFromTimeRange()
        }
    }

    /// Builds the order search section with autocomplete suggestions.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A view with order search and suggestions.
    @ViewBuilder
    func orderSearchSection(viewModel: AddTimeRecordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(L10n.timerecordInputOrder)
                .textStyle(.body1)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: .spacingXS) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.aPrimary.opacity(0.65))
                    .accessibilityHidden(true)

                TextField(viewModel.orderSearchPlaceholder, text: $viewModel.orderSearchQuery)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.selectedClient == nil)
                    .accessibilityLabel(L10n.timerecordInputOrder)
                    .accessibilityHint(viewModel.orderSearchPlaceholder)
            }

            if viewModel.selectedClient != nil, !viewModel.orderSearchQuery.isEmpty {
                autocompleteResults(viewModel: viewModel)
            }
        }
    }

    /// Builds the date field.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A labeled date input field.
    @ViewBuilder
    func dateField(viewModel: AddTimeRecordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        TimeRecordInputField(title: L10n.timerecordInputDate) {
            DatePicker(
                "",
                selection: $viewModel.workDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .accessibilityLabel(L10n.timerecordInputDate)
        }
    }

    /// Builds the read-only duration field.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A labeled duration display field.
    @ViewBuilder
    func durationField(viewModel: AddTimeRecordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        TimeRecordInputField(title: L10n.timerecordInputDuration) {
            TextField(L10n.timerecordInputDurationPlaceholder, text: $viewModel.durationMinutesText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 72)
                .disabled(true)
                .accessibilityLabel(L10n.timerecordInputDuration)
                .accessibilityValue(viewModel.durationMinutesText)
        }
    }

    /// Builds the activity selection field.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A labeled activity picker menu.
    @ViewBuilder
    func activityField(viewModel: AddTimeRecordViewModel) -> some View {
        TimeRecordInputField(title: L10n.timerecordInputActivity) {
            Menu {
                if !viewModel.recentActivities.isEmpty {
                    Section(L10n.timerecordInputActivityRecent) {
                        ForEach(viewModel.recentActivities, id: \.objectID) { activity in
                            Button(viewModel.activityDisplayName(activity)) {
                                viewModel.selectActivity(activity)
                            }
                        }
                    }
                    Divider()
                }

                ForEach(viewModel.availableActivities, id: \.objectID) { activity in
                    Button(viewModel.activityDisplayName(activity)) {
                        viewModel.selectActivity(activity)
                    }
                }
            } label: {
                menuFieldLabel(viewModel.activityFieldTitle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.timerecordInputActivity)
        }
    }

    /// Builds the start time field.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A labeled start-time input field.
    @ViewBuilder
    func startTimeField(viewModel: AddTimeRecordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        TimeRecordInputField(title: L10n.timerecordInputStartTime) {
            DatePicker(
                "",
                selection: $viewModel.startTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .accessibilityLabel(L10n.timerecordInputStartTime)
        }
    }

    /// Builds the end time field.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A labeled end-time input field.
    @ViewBuilder
    func endTimeField(viewModel: AddTimeRecordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        TimeRecordInputField(title: L10n.timerecordInputEndTime) {
            DatePicker(
                "",
                selection: $viewModel.endTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .accessibilityLabel(L10n.timerecordInputEndTime)
        }
    }

    /// Builds the form clear button.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A plain icon button for clearing transient inputs.
    @ViewBuilder
    func clearButton(viewModel: AddTimeRecordViewModel) -> some View {
        Button {
            viewModel.clearTransientInputs()
        } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.timerecordInputClear)
    }

    /// Builds the description input section.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A view with description label and text field.
    @ViewBuilder
    func descriptionSection(viewModel: AddTimeRecordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(L10n.timerecordInputDescription)
                .textStyle(.body1)
                .accessibilityAddTraits(.isHeader)

            TextField("", text: $viewModel.descriptionText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(L10n.timerecordInputDescription)
        }
    }

    /// Builds the client selection section.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A view with client picker menu.
    @ViewBuilder
    func clientSection(viewModel: AddTimeRecordViewModel) -> some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(L10n.timerecordInputClient)
                .textStyle(.body1)
                .accessibilityAddTraits(.isHeader)

            Menu {
                ForEach(viewModel.availableClients, id: \.objectID) { client in
                    Button(viewModel.clientDisplayName(client)) {
                        viewModel.selectClient(client)
                    }
                }
                if viewModel.selectedClient != nil {
                    Divider()
                    Button(L10n.timerecordInputClientClear) {
                        viewModel.clearClientSelection()
                    }
                }
            } label: {
                menuFieldLabel(viewModel.clientFieldTitle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.timerecordInputClient)
        }
    }

    /// Builds the autocomplete results list for order search.
    ///
    /// - Parameter viewModel: The state and logic container for the form.
    /// - Returns: A result list view for order suggestions.
    @ViewBuilder
    func autocompleteResults(viewModel: AddTimeRecordViewModel) -> some View {
        VStack(alignment: .leading, spacing: .spacingXXXXS) {
            if viewModel.filteredOrders.isEmpty {
                Text(L10n.timerecordInputOrderNoResults)
                    .textStyle(.body3)
                    .foregroundStyle(Color.aPrimary.opacity(0.7))
                    .padding(.horizontal, .spacingXS)
                    .padding(.vertical, .spacingXXS)
            } else {
                ForEach(viewModel.filteredOrders.prefix(5), id: \.objectID) { order in
                    Button {
                        viewModel.selectOrder(order)
                    } label: {
                        HStack {
                            Text(viewModel.orderDisplayName(order))
                                .textStyle(.body1)
                            Spacer()
                        }
                        .padding(.horizontal, .spacingXS)
                        .padding(.vertical, .spacingXXS)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: .spacingXXS, style: .continuous)
                .fill(Color.aListBackground)
        )
    }

    /// Builds a shared styled menu label field.
    ///
    /// - Parameter title: The title displayed inside the field.
    /// - Returns: A stroked field-like label with chevron.
    @ViewBuilder
    func menuFieldLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.aPrimary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .accessibilityHidden(true)
        }
        .padding(.horizontal, .spacingXS)
        .padding(.vertical, .spacingXS)
        .background(
            RoundedRectangle(cornerRadius: .spacingXXS, style: .continuous)
                .stroke(Color.accentColor, lineWidth: 1)
        )
    }
}

/// Renders one labeled field container used inside the time-record form.
struct TimeRecordInputField<Content: View>: View {
    /// Defines the title shown above the embedded field.
    let title: String

    /// Produces the field content view.
    @ViewBuilder let content: Content

    /// Creates the field container body.
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXXS) {
            Text(title)
                .textStyle(.body1)
                .accessibilityAddTraits(.isHeader)

            content
        }
    }
}
