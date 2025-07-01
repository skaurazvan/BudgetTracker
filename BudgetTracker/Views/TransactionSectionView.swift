import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct TransactionSectionView: View {
    var items: [(tx: Transaction, balance: Decimal)]
    @ObservedObject var vm: BudgetViewModel
    @State private var editingTransaction: Transaction?
    @State private var showEditSheet = false

    var body: some View {
        VStack{
            ForEach(Array(items.enumerated()), id: \.element.tx.id) { index, pair in
                transactionRow(tx: pair.tx, balance: pair.balance)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {
                        editingTransaction = pair.tx
                        showEditSheet = true
                    }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let editingTransaction = editingTransaction {
                TransactionEditView(
                    vm: vm,
                    transaction: editingTransaction,
                    onDelete: {
                        showEditSheet = false
                    }
                )
            }
        }

    }

    func iconName(for category: String) -> String {
        switch category.lowercased() {
        case "food", "groceries", "dining":
            return "fork.knife"
        case "transportation", "travel", "commute", "car":
            return "car.fill"
        case "shopping", "clothes", "retail":
            return "bag.fill"
        case "salary", "income", "paycheck":
            return "banknote"
        case "utilities", "bills", "electricity", "water", "gas":
            return "bolt.fill"
        case "entertainment", "movies", "games", "subscriptions":
            return "film"
        case "health", "medical", "doctor", "pharmacy":
            return "cross.case.fill"
        case "insurance":
            return "shield.lefthalf.fill"
        case "housing", "rent", "mortgage":
            return "house.fill"
        case "education", "school", "tuition":
            return "book.fill"
        case "personal", "self-care", "beauty":
            return "person.crop.circle.fill"
        case "pets", "animals":
            return "pawprint.fill"
        case "gifts", "donations":
            return "gift.fill"
        case "savings", "investment", "bank":
            return "chart.bar.fill"
        case "taxes":
            return "percent"
        case "phone", "internet":
            return "wifi"
        case "misc", "other":
            return "ellipsis.circle.fill"
        default:
            return "folder.fill"
        }
    }


    @ViewBuilder
    func transactionRow(tx: Transaction, balance: Decimal) -> some View {
        let doubleBalance = (balance as NSDecimalNumber).doubleValue
        let cardFillColor: Color = {
            #if os(macOS)
            return Color(nsColor: NSColor.windowBackgroundColor)
            #else
            return Color(uiColor: UIColor.systemGray6)
            #endif
        }()

        HStack(alignment: .center, spacing: 16) {
            dateView(tx.date)

            VStack(alignment: .leading, spacing: 4) {
                categoryHeader(tx)
                if !tx.description.isEmpty {
                    Text(tx.description)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            amountView(Decimal(tx.amount))
            balanceView(doubleBalance)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardFillColor)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                .shadow(color: .white.opacity(0.4), radius: 1, x: -1, y: -1)
        )
        .padding(.vertical, 4)
    }

    func dateView(_ date: Date) -> some View {
        Text(date.formatted(.dateTime.day().month(.abbreviated)))
            .font(.title3.weight(.semibold))
            .foregroundColor(.primary)
            .frame(width: 70, alignment: .leading)
    }

    func categoryHeader(_ tx: Transaction) -> some View {
        HStack(spacing: 8) {
            Image(systemName: iconName(for: tx.category))
                .foregroundColor(.blue)
            Text(tx.name)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            if tx.recurrence != .none {
                Image(systemName: "repeat")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
    }

    func amountView(_ amount: Decimal) -> some View {
        Text("£\(amount, format: .number.precision(.fractionLength(2)))")
            .foregroundColor(amount >= 0 ? .green : .red)
            .font(.headline)
            .frame(width: 80, alignment: .trailing)
    }

    func balanceView(_ balance: Double) -> some View {
        Text("£\(balance, format: .number.precision(.fractionLength(2)))")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: 80, alignment: .trailing)
    }

    func delete(indexSet: IndexSet) {
        let idsToDelete = indexSet.map { items[$0].tx.id }
        for id in idsToDelete {
            if let i = vm.transactions.firstIndex(where: { $0.id == id }) {
                vm.transactions.remove(at: i)
            }
        }
    }
}
