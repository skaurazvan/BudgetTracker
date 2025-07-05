import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct RecurringListView: View {
    @ObservedObject var vm: BudgetViewModel
    @State private var showAddSheet = false
    @State private var editingRecurring: RecurringTransaction?
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            ForEach(vm.recurring.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }), id: \.id) { r in
                RecurringCard(r: r,
                              onTap: {
                                  editingRecurring = r
                                  showEditSheet = true
                              },
                              onDelete: {
                                  if let index = vm.recurring.firstIndex(where: { $0.id == r.id }) {
                                      vm.recurring.remove(at: index)
                                      vm.transactions.removeAll { $0.recurringID == r.id }
                                      vm.save()
                                  }
                              })
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { vm.refreshTransactions() }) {
                    Image(systemName: "arrow.clockwise").help("Refresh")
                }
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus").help("Add")
                }
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash").help("Delete All")
                }
            }
        }
        .alert("Delete All Transactions?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                vm.recurring.removeAll()
                vm.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all transactions permanently.")
        }
        .sheet(isPresented: $showAddSheet) {
            RecurringEditView(vm: vm, recurring: RecurringTransaction(id: UUID(), date: Date(), category: "", name: "", description: "", amount: 0.0, recurrence: .none), isNew: true)
        }
        .sheet(isPresented: $showEditSheet) {
            if let editingRecurring = editingRecurring {
                RecurringEditView(vm: vm, recurring: editingRecurring, isNew: false)
            }
        }
    }
}

struct RecurringCard: View {
    let r: RecurringTransaction
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let cardBackgroundColor: Color = {
#if os(macOS)
            return Color(nsColor: NSColor.windowBackgroundColor)
#else
            return Color(uiColor: UIColor.secondarySystemBackground)
#endif
        }()

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(r.name).font(.headline)
                    if !r.description.isEmpty {
                        Text(r.description).font(.subheadline).foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                            Text(r.category.isEmpty ? "Uncategorized" : r.category)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                            Text(r.recurrence.rawValue.capitalized)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("£\(r.amount, format: .number.precision(.fractionLength(2)))")
                        .font(.title3.bold())
                        .foregroundColor(r.amount >= 0 ? .green : .red)

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBackgroundColor).shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1))
        .padding(.vertical, 4)
        .onTapGesture { onTap() }
    }
}
