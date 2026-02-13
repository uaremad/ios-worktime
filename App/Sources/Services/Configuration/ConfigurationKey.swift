//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

import Foundation

/// Defines known configuration keys stored in the `Configuration` entity.
public enum ConfigurationKey: String, CoreDataStringEnum {
    /// Stores the singular label for counterparties in the UI.
    case counterpartyLabelSingular = "counterparty.label.singular"

    /// Stores the plural label for counterparties in the UI.
    case counterpartyLabelPlural = "counterparty.label.plural"

    /// Stores the singular label for orders in the UI.
    case orderLabelSingular = "order.label.singular"

    /// Stores the plural label for orders in the UI.
    case orderLabelPlural = "order.label.plural"

    /// Stores the singular label for cost centres in the UI.
    case costCentreLabelSingular = "costcentre.label.singular"

    /// Stores the plural label for cost centres in the UI.
    case costCentreLabelPlural = "costcentre.label.plural"

    /// Stores the default currency value.
    case defaultCurrency = "defaults.currency"

    /// Stores the default tax rate value.
    case defaultTaxRate = "defaults.tax_rate"

    /// Stores the default tax mode value.
    case defaultTaxMode = "defaults.tax_mode"

    /// Stores the default jurisdiction value.
    case defaultJurisdiction = "defaults.jurisdiction"

    /// Stores the default payment terms value.
    case defaultPaymentTerms = "defaults.payment_terms"

    /// Stores the default invoice rounding mode.
    case defaultRoundingMode = "defaults.rounding_mode"

    /// Stores the invoice numbering prefix.
    case invoiceNumberPrefix = "invoice.numbering.prefix"

    /// Stores the invoice numbering pattern.
    case invoiceNumberPattern = "invoice.numbering.pattern"

    /// Stores the next invoice sequence number.
    case invoiceNextSequence = "invoice.numbering.next_seq"

    /// Stores the invoice sequence reset rule.
    case invoiceSequenceResetRule = "invoice.numbering.reset_rule"

    /// Stores the default issuer object URI identifier.
    case defaultIssuerObjectURI = "invoice.default_issuer.object_uri"

    /// Stores retention years for invoice records.
    case retentionInvoicesYears = "retention.invoices.years"

    /// Stores retention years for time records.
    case retentionTimeRecordsYears = "retention.timerecords.years"
}
