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
    @State private var showLoadOptions = false
    @State private var showSaveOptions = false
    @State private var showDeleteConfirmation = false


    var body: some View {
        List {
            ForEach(vm.recurring.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }), id: \.id) { r in
                RecurringCard(r: r) {
                    editingRecurring = r
                    showEditSheet = true
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onDelete { idx in
                let idsToDelete = idx.map { vm.recurring[$0].id }
                vm.recurring.removeAll { idsToDelete.contains($0.id) }
                vm.transactions.removeAll { tx in
                    if let recurringID = tx.recurringID {
                        return idsToDelete.contains(recurringID)
                    }
                    return false
                }
                vm.save()
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity) // optional, for full width

        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { vm.refreshTransactions() }) {
                    Image(systemName: "arrow.clockwise")
                        .help("Refresh")
                }

                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .help("Add")
                }

                Button(action: { showLoadOptions = true }) {
                    Image(systemName: "tray.and.arrow.down")
                        .help("Load")
                }

                Button(action: { showSaveOptions = true }) {
                    Image(systemName: "tray.and.arrow.up")
                        .help("Save")
                }

                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .help("Delete All")
                }
            }
        }

        // MARK: - Load Options Sheet
        .sheet(isPresented: $showLoadOptions) {
            VStack(spacing: 16) {
                Text("Load From File")
                    .font(.title2)
                    .fontWeight(.semibold)

                Button("Load Transactions") {
                    vm.loadFromExternalFile()
                    showLoadOptions = false
                }

                Button("Load Recurring") {
                    vm.loadRecurringFromFile()
                    showLoadOptions = false
                }

                Button("Cancel", role: .cancel) {
                    showLoadOptions = false
                }
            }
            .padding()
            .frame(width: 300)
        }

        // MARK: - Save Options Sheet
        .sheet(isPresented: $showSaveOptions) {
            VStack(spacing: 16) {
                Text("Save To File")
                    .font(.title2)
                    .fontWeight(.semibold)

                Button("Save Transactions") {
                    vm.saveToExternalFile()
                    showSaveOptions = false
                }

                Button("Save Recurring") {
                    vm.saveRecurringToFile()
                    showSaveOptions = false
                }

                Button("Cancel", role: .cancel) {
                    showSaveOptions = false
                }
            }
            .padding()
            .frame(width: 300)
        }
        .alert("Delete All Transactions?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                vm.recurring.removeAll()
                vm.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all transactions permanently.")
        }

        .sheet(isPresented: $showAddSheet) {
            VStack(spacing: 0) {
                HStack {
                    Text("New Recurring")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { showAddSheet = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                .overlay(Divider(), alignment: .bottom)

                RecurringEditView(
                    vm: vm,
                    recurring: RecurringTransaction(
                        id: UUID(),
                        date: Date(),
                        category: "",
                        name: "",
                        description: "",
                        amount: 0.0,
                        recurrence: .none
                    ),
                    isNew: true
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400, minHeight: 300)
        }

        .sheet(isPresented: $showEditSheet) {
            if let editingRecurring = editingRecurring {
                VStack(spacing: 0) {
                    HStack {
                        Text("Edit Recurring")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showEditSheet = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .overlay(Divider(), alignment: .bottom)

                    RecurringEditView(
                        vm: vm,
                        recurring: editingRecurring,
                        isNew: false
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }

    }
}

struct RecurringCard: View {
    let r: RecurringTransaction
    let onTap: () -> Void

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
                    Text(r.name)
                        .font(.headline)

                    if !r.description.isEmpty {
                        Text(r.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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

                Text("£\(r.amount, format: .number.precision(.fractionLength(2)))")
                    .font(.title3.bold())
                    .foregroundColor(r.amount >= 0 ? .green : .red)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding()
        .frame(maxWidth: .infinity) // ← Ensures full width
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.vertical, 4)
        .onTapGesture { onTap() }
    }
}


