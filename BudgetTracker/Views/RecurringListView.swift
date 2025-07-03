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
    @State private var showFilePicker = false
    @State private var filePickerType: DocumentPicker.PickerType = .open
    
    var backgroundColor: Color {
#if os(macOS)
        return Color(nsColor: NSColor.windowBackgroundColor)
#else
        return Color(UIColor.systemBackground)
#endif
    }
    
    enum PickerType: Equatable {
        case open
        case save(Data, String)
    }
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
                
                //                Button(action: {
                //                    filePickerType = .open
                //                    showFilePicker = true
                //                }) {
                //                    Image(systemName: "tray.and.arrow.down")
                //                        .help("Load Recurring")
                //                }
                //
                //                Button(action: {
                //                    let encoder = JSONEncoder()
                //                    encoder.dateEncodingStrategy = .secondsSince1970
                //                    if let data = try? encoder.encode(vm.recurring) {
                //                        filePickerType = .save(data, "recurring.json")
                //                        showFilePicker = true
                //                    } else {
                //                        print("❌ Failed to encode recurring data")
                //                    }
                //                }) {
                //                    Image(systemName: "tray.and.arrow.up")
                //                        .help("Save Recurring")
                //                }
                
                
                
                
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .help("Delete All")
                }
            }
        }
        .sheet(isPresented: $showFilePicker) {
#if os(iOS)
            NavigationView {
                VStack(spacing: 0) {
                    HStack {
                        Text(titleForPickerType(filePickerType))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showFilePicker = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .overlay(Divider(), alignment: .bottom)
                    
                    Spacer()
                    
                    DocumentPicker(pickerType: filePickerType) { url in
                        guard let url else { return }
                        
                        switch filePickerType {
                        case .open:
                            if url.startAccessingSecurityScopedResource() {
                                defer { url.stopAccessingSecurityScopedResource() }
                                do {
                                    let data = try Data(contentsOf: url)
                                    let decoder = JSONDecoder()
                                    decoder.dateDecodingStrategy = .secondsSince1970
                                    let loaded = try decoder.decode([RecurringTransaction].self, from: data)
                                    DispatchQueue.main.async {
                                        vm.recurring = loaded
                                    }
                                    print("✅ Recurring loaded from \(url)")
                                } catch {
                                    print("❌ Failed to load recurring: \(error)")
                                }
                            } else {
                                print("❌ Failed to access security scoped resource for \(url)")
                            }
                            
                            
                        case .save:
                            print("✅ Recurring saved to \(url)")
                        }
                        
                        showFilePicker = false
                    }
                    
                    Spacer()
                }
                .navigationBarHidden(true)
            }
#else
            VStack(spacing: 0) {
                HStack {
                    Text(titleForPickerType(filePickerType))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { showFilePicker = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(Color(nsColor: NSColor.windowBackgroundColor))
                .overlay(Divider(), alignment: .bottom)
                
                Spacer()
                
                DocumentPicker(pickerType: filePickerType) { url in
                    guard let url else { return }
                    
                    switch filePickerType {
                    case .open:
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            do {
                                let data = try Data(contentsOf: url)
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .secondsSince1970
                                let loaded = try decoder.decode([RecurringTransaction].self, from: data)
                                DispatchQueue.main.async {
                                    vm.recurring = loaded
                                }
                                print("✅ Recurring loaded from \(url)")
                            } catch {
                                print("❌ Failed to load recurring: \(error)")
                            }
                        } else {
                            print("❌ Failed to access security scoped resource for \(url)")
                        }
                        
                        
                    case .save:
                        print("✅ Recurring saved to \(url)")
                    }
                    
                    showFilePicker = false
                }
                
                Spacer()
            }
            .frame(minWidth: 400, minHeight: 200)
#endif
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
                .background(backgroundColor)
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
                    .background(backgroundColor)
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
func titleForPickerType(_ type: DocumentPicker.PickerType) -> String {
    switch type {
    case .open:
        return "Load Recurring"
    case .save:
        return "Save Recurring"
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


