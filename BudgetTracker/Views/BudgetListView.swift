import SwiftUI

struct BudgetListView: View {
    @ObservedObject var vm: BudgetViewModel

    var groupedWithBalances: [(month: Date, transactions: [(tx: Transaction, balance: Decimal)])] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 90, to: startDate)!

        let filtered = vm.transactions
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted(by: { $0.date < $1.date })

        var runningTotal: Decimal = 0
        let txWithBalance = filtered.map { tx -> (Transaction, Decimal) in
            runningTotal += Decimal(tx.amount)
            return (tx, runningTotal)
        }

        let grouped = Dictionary(grouping: txWithBalance) { pair in
            calendar.date(from: calendar.dateComponents([.year, .month], from: pair.0.date))!
        }

        return grouped
            .map { (month: $0.key, transactions: $0.value) }
            .sorted { $0.month < $1.month }
    }

    var body: some View {
        List {
            ForEach(groupedWithBalances, id: \.month) { group in
                Section(header: Text(group.month.formatted(.dateTime.year().month()))) {
                    TransactionSectionView(
                        items: group.transactions,
                        vm: vm
                    )
                }
            }
        }
        
    }
}
