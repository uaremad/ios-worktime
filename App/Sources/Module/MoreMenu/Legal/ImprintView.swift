//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A view that displays the imprint content.
@MainActor
struct ImprintView: View {
    /// Opens external URLs such as the mail application.
    @Environment(\.openURL) private var openURL

    /// A flag indicating whether the mail sheet is displayed.
    @State private var showMailUnavailableAlert: Bool = false

    /// A flag indicating whether the copy toast is displayed.
    @State private var showCopyToast: Bool = false

    /// The task that hides the toast after a delay.
    @State private var toastTask: Task<Void, Never>?

    /// The responsible address shown in the imprint.
    private var responsibleAddress: String {
        "Jan Hendrik Damerau\nBertha-von-Suttner-Platz 6\n23558 Lübeck\nDeutschland"
    }

    /// The main content of the imprint screen.
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text(L10n.settingsImprintHeadingTitle)
                .textStyle(.title2)

            Text(L10n.settingsImprintResponsibleHeadline)
                .textStyle(.body2)

            Text(responsibleAddress)
                .textStyle(.body1)

            Button {
                guard let url = URL(string: L10n.settingsImprintContactMailto) else {
                    return
                }
                openURL(url) { accepted in
                    if accepted == false {
                        showMailUnavailableAlert = true
                    }
                }
            } label: {
                Text(L10n.settingsImprintContactButton)
                    .textStyle(.button1)
            }
            #if os(iOS)
            .buttonStyle(PrimaryButtonStyle())
            #else
            .buttonStyle(TertiaryButtonStyle())
            #endif
            .accessibilityLabel(L10n.accessibilityImprintContactLabel)
            .accessibilityHint(L10n.accessibilityImprintContactHint)
            .accessibilityAddTraits(.isButton)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacingS)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadius)
                .fill(Color.aListBackground)
        )
        .padding(.horizontal)
        .padding(.top, .spacingM)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
        .sheet(isPresented: $showMailUnavailableAlert) {
            mailUnavailableSheet
            #if os(iOS)
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
            #endif
        }
        .overlay(alignment: Alignment.bottom) {
            if showCopyToast {
                copyToastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, .spacingM)
            }
        }
        .navigationTitle(L10n.settingsImprintTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private extension ImprintView {
    /// The modal shown when the Mail app cannot be opened.
    var mailUnavailableSheet: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text(L10n.errorImprintMailUnavailableTitle)
                .textStyle(.title2)

            Text(L10n.errorImprintMailUnavailableMessage)
                .textStyle(.body1)

            Button {
                copyContactEmailToClipboard()
                showMailUnavailableAlert = false
                showCopyToastForClipboard()
            } label: {
                Text(L10n.generalCopyEmail)
                    .textStyle(.button1)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(L10n.generalCopyEmail)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.spacingM)
        .background(Color.aBackground)
        .foregroundStyle(Color.aPrimary)
        #if os(iOS)
            .presentationBackground(Color.aBackground)
        #endif
    }

    /// The toast shown after the email address was copied.
    var copyToastView: some View {
        Text(L10n.generalCopyEmailToast)
            .textStyle(.body3)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .cornerRadius(.cornerRadius)
            .accessibilityLabel(L10n.generalCopyEmailToast)
            .accessibilityAddTraits(.updatesFrequently)
    }

    /// Copies the contact email address to the system clipboard.
    func copyContactEmailToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = L10n.settingsImprintContactEmail
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(L10n.settingsImprintContactEmail, forType: .string)
        #endif
    }

    /// Shows the copy toast and hides it automatically.
    func showCopyToastForClipboard() {
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyToast = true
            }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyToast = false
            }
        }
    }
}
