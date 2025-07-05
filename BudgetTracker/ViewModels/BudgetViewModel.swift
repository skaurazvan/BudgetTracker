//
//  BudgetViewModel.swift
//  BudgetTracker
//
//  Created by Razvan Scaueru on 29/06/2025.
//

import SwiftUI
import Combine

class BudgetViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var recurring: [RecurringTransaction] = []
    @Published var categories: [Category] = [
        Category(name: "Food", icon: "fork.knife"),
        Category(name: "Rent", icon: "house"),
        Category(name: "Salary", icon: "dollarsign.circle")
    ]
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
    
    init() {
        ensureStandardCategories()
        load()
        print("Recurring loaded:", recurring)
        insertMissingRecurring()
        
        // Observe and auto-save
        $transactions
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
        $recurring
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
        
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    var recurringFileURL: URL {
        let fm = FileManager.default
        
        let folder = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BudgetTracker")
        
        
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("recurring.json")
    }
    
    func saveRecurringToFile(to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(recurring)
            try data.write(to: url, options: [.atomic])
            print("✅ Recurring saved to \(url)")
        } catch {
            print("❌ Failed to save recurring: \(error)")
        }
    }

    
    func loadRecurringFromFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let loaded = try decoder.decode([RecurringTransaction].self, from: data)
            DispatchQueue.main.async {
                self.recurring = loaded
            }
            print("✅ Recurring loaded from \(url)")
        } catch {
            print("❌ Failed to load recurring: \(error)")
        }
    }

    
    
    func ensureStandardCategories() {
        let existingNames = Set(categories.map { $0.name.lowercased() })
        
        let standard: [(name: String, icon: String)] = [
            ("Food", "fork.knife"),
            ("Groceries", "fork.knife"),
            ("Dining", "fork.knife"),
            ("Transportation", "car.fill"),
            ("Travel", "car.fill"),
            ("Commute", "car.fill"),
            ("Car", "car.fill"),
            ("Shopping", "bag.fill"),
            ("Clothes", "bag.fill"),
            ("Retail", "bag.fill"),
            ("Salary", "banknote"),
            ("Income", "banknote"),
            ("Paycheck", "banknote"),
            ("Utilities", "bolt.fill"),
            ("Bills", "bolt.fill"),
            ("Electricity", "bolt.fill"),
            ("Water", "bolt.fill"),
            ("Gas", "bolt.fill"),
            ("Entertainment", "film"),
            ("Movies", "film"),
            ("Games", "film"),
            ("Subscriptions", "film"),
            ("Health", "cross.case.fill"),
            ("Medical", "cross.case.fill"),
            ("Doctor", "cross.case.fill"),
            ("Pharmacy", "cross.case.fill"),
            ("Insurance", "shield.lefthalf.fill"),
            ("Housing", "house.fill"),
            ("Rent", "house.fill"),
            ("Mortgage", "house.fill"),
            ("Education", "book.fill"),
            ("School", "book.fill"),
            ("Tuition", "book.fill"),
            ("Personal", "person.crop.circle.fill"),
            ("Self-Care", "person.crop.circle.fill"),
            ("Beauty", "person.crop.circle.fill"),
            ("Pets", "pawprint.fill"),
            ("Animals", "pawprint.fill"),
            ("Gifts", "gift.fill"),
            ("Donations", "gift.fill"),
            ("Savings", "chart.bar.fill"),
            ("Investment", "chart.bar.fill"),
            ("Bank", "chart.bar.fill"),
            ("Taxes", "percent"),
            ("Phone", "wifi"),
            ("Internet", "wifi"),
            ("Misc", "ellipsis.circle.fill"),
            ("Other", "ellipsis.circle.fill")
        ]
        
        for cat in standard where !existingNames.contains(cat.name.lowercased()) {
            categories.append(Category(name: cat.name, icon: cat.icon))
        }
    }
    func insertMissingRecurring() {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let defaultEnd = Calendar.current.date(byAdding: .day, value: 90, to: start)!

        // ✅ Remove expired one-time RecurringTransactions
        recurring.removeAll { r in
            r.recurrence == .none && r.date < start
        }

        for r in recurring {
            if r.recurrence == .none {
                // One-time recurring: add only if not already present and in the future or today
                guard r.date >= start else { continue }

                let adjustedDate = adjustForWeekendOnly(r.date)

                let exists = transactions.contains {
                    $0.recurringID == r.id && Calendar.current.isDate($0.date, inSameDayAs: adjustedDate)
                }

                if !exists {
                    let tx = Transaction(
                        id: UUID(),
                        recurringID: r.id,
                        date: adjustedDate,
                        category: r.category,
                        name: r.name,
                        description: r.description,
                        amount: r.amount,
                        recurrence: .none
                    )
                    transactions.append(tx)
                }
                continue
            }

            // Recurring case
            var next = max(r.date, start)
            let recurrenceEnd = r.endDate ?? defaultEnd

            // Rewind to aligned recurrence window
            while true {
                let prev = rewindDate(next, by: r.recurrence)
                if prev < r.date || prev < start { break }
                next = prev
            }

            while next <= recurrenceEnd {
                if next >= r.date {
                    let adjustedDate = adjustForWeekendOnly(next)
                    let alreadyExists = transactions.contains {
                        $0.recurringID == r.id && Calendar.current.isDate($0.date, inSameDayAs: adjustedDate)
                    }

                    if !alreadyExists {
                        let tx = Transaction(
                            id: UUID(),
                            recurringID: r.id,
                            date: adjustedDate,
                            category: r.category,
                            name: r.name,
                            description: r.description,
                            amount: r.amount,
                            recurrence: r.recurrence
                        )
                        transactions.append(tx)
                    }
                }

                next = advanceDate(next, by: r.recurrence)
            }
        }

        transactions.sort { $0.date > $1.date }
    }




    private func adjustForWeekendOnly(_ date: Date) -> Date {
        var adjusted = Calendar.current.startOfDay(for: date)
        let cal = Calendar.current
        let wd = cal.component(.weekday, from: adjusted)
        
        if wd == 7 {
            // Saturday → Monday
            adjusted = cal.date(byAdding: .day, value: 2, to: adjusted)!
        } else if wd == 1 {
            // Sunday → Monday
            adjusted = cal.date(byAdding: .day, value: 1, to: adjusted)!
        }

        return adjusted
    }


    
    private func advanceDate(_ date: Date, by recurrence: Recurrence) -> Date {
        switch recurrence {
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: 7, to: date)!
        case .fourWeekly:
            return Calendar.current.date(byAdding: .day, value: 28, to: date)!
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: date)!
        case .none:
            return date
        }
    }
    
    private func rewindDate(_ date: Date, by recurrence: Recurrence) -> Date {
        switch recurrence {
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: -7, to: date)!
        case .fourWeekly:
            return Calendar.current.date(byAdding: .day, value: -28, to: date)!
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: -1, to: date)!
        case .none:
            return date
        }
    }
    
    
    private func dateComponent(for rec: Recurrence) -> DateComponents {
        switch rec {
        case .weekly:
            return DateComponents(weekOfYear: 1)
        case .fourWeekly:
            return DateComponents(day: 28)
        case .monthly:
            return DateComponents(month: 1)
        case .none:
            return DateComponents(day: 1) // fallback
        }
    }
    
    
    private let transactionsKey = "transactions"
    private let recurringKey = "recurringTransactions"
    
    func save() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
        if let encodedRecurring = try? JSONEncoder().encode(recurring) {
            UserDefaults.standard.set(encodedRecurring, forKey: recurringKey)
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let decoded = try? JSONDecoder().decode([RecurringTransaction].self, from: data) {
            recurring = decoded
        }
    }
    func deleteRecurring(at offsets: IndexSet) {
        let idsToDelete = offsets.map { recurring[$0].id }
        
        // Remove from recurring list
        recurring.removeAll { idsToDelete.contains($0.id) }
        
        // Remove associated transactions
        transactions.removeAll { tx in
            if let id = tx.recurringID {
                return idsToDelete.contains(id)
            }
            return false
        }
        
        // Save changes
        save()
    }
    
    func refreshTransactions() {
        transactions.removeAll { $0.recurringID != nil }
        insertMissingRecurring()
        save()
    }

    
}
