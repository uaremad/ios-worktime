//
//  Copyright © 2026 - Jan-Hendrik Damerau. All rights reserved.
//

#if DEBUG
import CoreData
import Foundation

@MainActor
enum DeveloperDatabaseSeedService {
    /// Seeds random worktime data for the last 60 days.
    ///
    /// The seed creates or reuses one profile and related master data.
    /// It only inserts records for weekdays and leaves occasional missing days.
    ///
    /// - Parameter context: The managed object context used for all writes.
    /// - Returns: The number of newly created `TimeRecords`.
    /// - Throws: Any Core Data persistence error.
    static func seedLast60Days(into context: NSManagedObjectContext) throws -> Int {
        let now = Date()
        let calendar = Calendar.current

        let profile = try ensurePrimaryProfile(in: context, now: now)
        let activities = try ensureActivities(for: profile, in: context, now: now)
        let clients = try ensureClients(for: profile, in: context, now: now)
        let costCentres = try ensureCostCentres(for: profile, in: context, now: now)
        let orders = try ensureOrders(
            for: profile,
            clients: clients,
            costCentres: costCentres,
            in: context
        )
        let rates = try ensureRates(
            for: profile,
            orders: orders,
            activities: activities,
            in: context
        )

        let occupiedDays = try existingWorkDays(for: profile, in: context, calendar: calendar)
        var createdCount = 0

        for dayOffset in 0 ..< 60 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let weekday = calendar.component(.weekday, from: dayStart)

            // Monday...Friday in Gregorian calendars where Sunday is 1.
            guard (2 ... 6).contains(weekday) else { continue }
            guard occupiedDays.contains(dayStart) == false else { continue }

            // Missing day probability.
            if Double.random(in: 0 ... 1) < 0.16 {
                continue
            }

            let order = orders.randomElement()
            let activity = activities.randomElement()
            let rate = pickRate(for: order, from: rates)
            let splitCount = Int.random(in: 1 ... 3)
            let totalMinutes = randomWorkMinutesForDay()
            let slotMinutes = split(totalMinutes: totalMinutes, into: splitCount)
            var currentStart = calendar.date(bySettingHour: 8, minute: Int.random(in: 0 ... 30), second: 0, of: dayStart) ?? dayStart

            for minutes in slotMinutes where minutes > 0 {
                let breakMinutes = randomBreakMinutes(for: minutes)
                let end = calendar.date(byAdding: .minute, value: minutes, to: currentStart) ?? currentStart

                let record = TimeRecords.insert(into: context)
                record.created_at = now
                record.work_date = dayStart
                record.start_time = currentStart
                record.end_time = end
                record.duration_minutes = NSNumber(value: Double(minutes))
                record.break_minutes = NSNumber(value: Double(breakMinutes))
                record.net_minutes = NSNumber(value: Double(max(minutes - breakMinutes, 0)))
                record.is_running = NSNumber(value: false)
                record.locked = NSNumber(value: false)
                record.billing_status = BillingStatus.open.coreDataValue
                record.approval_status = ApprovalStatus.draft.coreDataValue
                record.profile = profile
                record.order = order
                record.costCentre = order?.costCentre
                record.activity = activity
                record.rate = rate

                createdCount += 1
                currentStart = calendar.date(byAdding: .minute, value: minutes + Int.random(in: 10 ... 35), to: end) ?? end
            }
        }

        if context.hasChanges {
            try context.save()
        }

        return createdCount
    }
}

private extension DeveloperDatabaseSeedService {
    /// Returns existing work days that already contain records.
    ///
    /// - Parameters:
    ///   - profile: The profile to scope the fetch.
    ///   - context: The managed object context.
    ///   - calendar: The calendar used for day normalization.
    /// - Returns: A set of occupied start-of-day dates.
    /// - Throws: Any fetch error from Core Data.
    static func existingWorkDays(
        for profile: Profile,
        in context: NSManagedObjectContext,
        calendar: Calendar
    ) throws -> Set<Date> {
        let request = TimeRecords.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        let records = try context.fetch(request)
        return Set(records.compactMap { record in
            guard let date = record.work_date ?? record.start_time ?? record.end_time else { return nil }
            return calendar.startOfDay(for: date)
        })
    }

    /// Creates or reuses one primary profile.
    ///
    /// - Parameters:
    ///   - context: The managed object context.
    ///   - now: The current timestamp.
    /// - Returns: The profile used for all seeded data.
    /// - Throws: Any fetch error from Core Data.
    static func ensurePrimaryProfile(
        in context: NSManagedObjectContext,
        now: Date
    ) throws -> Profile {
        let request = Profile.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: true)]

        if let existing = try context.fetch(request).first {
            return existing
        }

        let profile = Profile.insert(into: context)
        profile.uuid = UUID().uuidString
        profile.name = "Standardprofil"
        profile.is_active = NSNumber(value: true)
        profile.created_at = now
        profile.updated_at = now
        return profile
    }

    /// Ensures activities for seeded records.
    ///
    /// - Parameters:
    ///   - profile: The parent profile.
    ///   - context: The managed object context.
    ///   - now: The current timestamp.
    /// - Returns: Reused or newly created activities.
    /// - Throws: Any fetch error from Core Data.
    static func ensureActivities(
        for profile: Profile,
        in context: NSManagedObjectContext,
        now: Date
    ) throws -> [Activities] {
        let request = Activities.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        var existing = try context.fetch(request)
        if existing.isEmpty == false { return existing }

        let names = ["Büro", "Kundentermin", "Dokumentation", "Reisezeit"]
        for name in names {
            let activity = Activities.insert(into: context)
            activity.profile = profile
            activity.name = name
            activity.shared_profile = NSNumber(value: false)
            activity.is_active = NSNumber(value: true)
            existing.append(activity)
        }
        profile.updated_at = now
        return existing
    }

    /// Ensures clients for seeded records.
    ///
    /// - Parameters:
    ///   - profile: The parent profile.
    ///   - context: The managed object context.
    ///   - now: The current timestamp.
    /// - Returns: Reused or newly created clients.
    /// - Throws: Any fetch error from Core Data.
    static func ensureClients(
        for profile: Profile,
        in context: NSManagedObjectContext,
        now: Date
    ) throws -> [Client] {
        let request = Client.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        var existing = try context.fetch(request)

        if existing.contains(where: { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) == "John Doe" }) == false {
            let client = Client.insert(into: context)
            client.profile = profile
            client.name = "John Doe"
            client.external_ref = "JD-CLIENT"
            client.country_code = "DE"
            client.is_active = NSNumber(value: true)
            client.shared_profile = NSNumber(value: false)
            client.created_at = now
            client.updated_at = now
            existing.append(client)
        }

        return existing
    }

    /// Ensures cost centres for seeded records.
    ///
    /// - Parameters:
    ///   - profile: The parent profile.
    ///   - context: The managed object context.
    ///   - now: The current timestamp.
    /// - Returns: Reused or newly created cost centres.
    /// - Throws: Any fetch error from Core Data.
    static func ensureCostCentres(
        for profile: Profile,
        in context: NSManagedObjectContext,
        now: Date
    ) throws -> [CostCentre] {
        let request = CostCentre.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        var existing = try context.fetch(request)
        if existing.isEmpty == false { return existing }

        let names = ["KST-100 Vertrieb", "KST-200 Support", "KST-300 Projekt"]
        for (index, name) in names.enumerated() {
            let costCentre = CostCentre.insert(into: context)
            costCentre.profile = profile
            costCentre.name = name
            costCentre.external_ref = "KST-\(index + 1)"
            costCentre.shared_profile = NSNumber(value: false)
            existing.append(costCentre)
        }
        profile.updated_at = now
        return existing
    }

    /// Ensures orders for seeded records.
    ///
    /// - Parameters:
    ///   - profile: The parent profile.
    ///   - clients: Available clients.
    ///   - costCentres: Available cost centres.
    ///   - context: The managed object context.
    /// - Returns: Reused or newly created orders.
    /// - Throws: Any fetch error from Core Data.
    static func ensureOrders(
        for profile: Profile,
        clients: [Client],
        costCentres: [CostCentre],
        in context: NSManagedObjectContext
    ) throws -> [Order] {
        let now = Date()
        let request = Order.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        var existing = try context.fetch(request)

        guard let demoClient = clients.first(where: { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) == "John Doe" }) else {
            return existing
        }

        let validFrom = Calendar.current.date(byAdding: .month, value: -6, to: now)
        let validTo = Calendar.current.date(byAdding: .month, value: 6, to: now)

        if existing.contains(where: { $0.client?.objectID == demoClient.objectID && $0.code == "JD-ORDER-1" }) == false {
            let hourlyOrder = Order.insert(into: context)
            hourlyOrder.profile = profile
            hourlyOrder.client = demoClient
            hourlyOrder.costCentre = costCentres.first
            hourlyOrder.uuid = UUID()
            hourlyOrder.code = "JD-ORDER-1"
            hourlyOrder.name = "John Doe Order 1"
            hourlyOrder.notice = "Seed hourly order"
            hourlyOrder.is_active = NSNumber(value: true)
            hourlyOrder.shared_profile = NSNumber(value: false)
            hourlyOrder.valid_from = validFrom
            hourlyOrder.valid_to = validTo
            hourlyOrder.created_at = now
            hourlyOrder.updated_at = now
            existing.append(hourlyOrder)
        }

        if existing.contains(where: { $0.client?.objectID == demoClient.objectID && $0.code == "JD-ORDER-2" }) == false {
            let fixedOrder = Order.insert(into: context)
            fixedOrder.profile = profile
            fixedOrder.client = demoClient
            fixedOrder.costCentre = costCentres.dropFirst().first ?? costCentres.first
            fixedOrder.uuid = UUID()
            fixedOrder.code = "JD-ORDER-2"
            fixedOrder.name = "John Doe Order 2"
            fixedOrder.notice = "Seed fixed order"
            fixedOrder.is_active = NSNumber(value: true)
            fixedOrder.shared_profile = NSNumber(value: false)
            fixedOrder.valid_from = validFrom
            fixedOrder.valid_to = validTo
            fixedOrder.created_at = now
            fixedOrder.updated_at = now
            existing.append(fixedOrder)
        }

        return existing
    }

    /// Ensures rates for seeded records.
    ///
    /// - Parameters:
    ///   - profile: The parent profile.
    ///   - orders: Available orders.
    ///   - activities: Available activities.
    ///   - context: The managed object context.
    /// - Returns: Reused or newly created rates.
    /// - Throws: Any fetch error from Core Data.
    static func ensureRates(
        for profile: Profile,
        orders: [Order],
        activities: [Activities],
        in context: NSManagedObjectContext
    ) throws -> [Rates] {
        let now = Date()
        let request = Rates.fetchRequest()
        request.predicate = NSPredicate(format: "profile == %@", profile)
        var existing = try context.fetch(request)

        let demoHourlyOrder = orders.first(where: { $0.code == "JD-ORDER-1" })
        let demoFixedOrder = orders.first(where: { $0.code == "JD-ORDER-2" })

        if let demoHourlyOrder,
           existing.contains(where: { $0.order?.objectID == demoHourlyOrder.objectID && ($0.is_default?.boolValue ?? false) }) == false
        {
            let hourlyRate = Rates.insert(into: context)
            hourlyRate.profile = profile
            hourlyRate.order = demoHourlyOrder
            hourlyRate.activity = activities.randomElement()
            hourlyRate.name = "John Doe Hourly Rate"
            hourlyRate.billing_type = BillingType.hourly.coreDataValue
            hourlyRate.hourly_rate = NSNumber(value: 95)
            hourlyRate.fixed_amount = nil
            hourlyRate.is_default = NSNumber(value: true)
            hourlyRate.shared_profile = NSNumber(value: false)
            hourlyRate.created_at = now
            hourlyRate.updated_at = now
            existing.append(hourlyRate)
        }

        if let demoFixedOrder,
           existing.contains(where: { $0.order?.objectID == demoFixedOrder.objectID && ($0.is_default?.boolValue ?? false) }) == false
        {
            let fixedRate = Rates.insert(into: context)
            fixedRate.profile = profile
            fixedRate.order = demoFixedOrder
            fixedRate.activity = activities.randomElement()
            fixedRate.name = "John Doe Fixed Rate"
            fixedRate.billing_type = BillingType.fixed.coreDataValue
            fixedRate.fixed_amount = NSNumber(value: 780)
            fixedRate.hourly_rate = nil
            fixedRate.is_default = NSNumber(value: true)
            fixedRate.shared_profile = NSNumber(value: false)
            fixedRate.created_at = now
            fixedRate.updated_at = now
            existing.append(fixedRate)
        }

        return existing
    }

    /// Picks one suitable rate for one order.
    ///
    /// - Parameters:
    ///   - order: The associated order.
    ///   - rates: All known rates.
    /// - Returns: A matching rate when available.
    static func pickRate(for order: Order?, from rates: [Rates]) -> Rates? {
        guard let order else { return rates.randomElement() }
        let orderRates = rates.filter { $0.order == order }
        return orderRates.randomElement()
    }

    /// Generates random work minutes for one day.
    ///
    /// - Returns: Total minutes in the range of regular work with occasional overtime.
    static func randomWorkMinutesForDay() -> Int {
        if Double.random(in: 0 ... 1) < 0.22 {
            return Int.random(in: 540 ... 660) // Overtime day.
        }
        return Int.random(in: 450 ... 510) // Around 8 hours.
    }

    /// Splits one total duration into multiple entries.
    ///
    /// - Parameters:
    ///   - totalMinutes: The total day duration in minutes.
    ///   - count: Number of entries to create.
    /// - Returns: Split minutes that sum up to `totalMinutes`.
    static func split(totalMinutes: Int, into count: Int) -> [Int] {
        guard count > 1 else { return [totalMinutes] }
        var remaining = totalMinutes
        var parts: [Int] = []

        for index in 0 ..< count {
            let slotsLeft = count - index - 1
            if slotsLeft == 0 {
                parts.append(max(remaining, 0))
                break
            }

            let minimumForRemaining = slotsLeft * 45
            let upperBound = max(120, remaining - minimumForRemaining)
            let part = Int.random(in: 45 ... upperBound)
            parts.append(part)
            remaining -= part
        }

        return parts
    }

    /// Returns random unpaid break minutes for one entry.
    ///
    /// - Parameter minutes: Entry duration in minutes.
    /// - Returns: Break minutes.
    static func randomBreakMinutes(for minutes: Int) -> Int {
        guard minutes >= 300 else { return Int.random(in: 0 ... 10) }
        let options = [15, 20, 30, 35, 45]
        return options.randomElement() ?? 30
    }
}

#endif
