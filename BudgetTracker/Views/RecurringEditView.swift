import SwiftUI

struct RecurringEditView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: BudgetViewModel
    @State var recurring: RecurringTransaction
    var isNew: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Name")
                TextField("Enter name", text: $recurring.name)
                    .textFieldStyle(.roundedBorder)

                Text("Description")
                TextField("Optional description", text: $recurring.description)
                    .textFieldStyle(.roundedBorder)

                Text("Amount")
                TextField("0.00", value: $recurring.amount, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                Picker("", selection: $recurring.category) {
                    ForEach(vm.categories, id: \.name) { cat in
                        Label(cat.name, systemImage: cat.icon).tag(cat.name)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Start Date")
                DatePicker("", selection: $recurring.date, displayedComponents: .date)
                    .labelsHidden()
            }
            

            VStack(alignment: .leading, spacing: 8) {
                Text("Recurrence")
                Picker("", selection: $recurring.recurrence) {
                    Text("None").tag(Recurrence.none)
                    Text("Weekly").tag(Recurrence.weekly)
                    Text("Every 4 Weeks").tag(Recurrence.fourWeekly)
                    Text("Monthly").tag(Recurrence.monthly)
                }
                .pickerStyle(.segmented)
            }
            // End Date picker
            Toggle("Has End Date", isOn: Binding(
                get: { recurring.endDate != nil },
                set: { hasEnd in
                    recurring.endDate = hasEnd ? Calendar.current.date(byAdding: .month, value: 1, to: recurring.date) : nil
                }
            ))

            if let _ = recurring.endDate {
                DatePicker("End Date", selection: Binding(
                    get: { recurring.endDate ?? recurring.date },
                    set: { newDate in recurring.endDate = newDate }
                ), in: recurring.date..., displayedComponents: .date)
                .labelsHidden()
            }
            HStack {
                if !isNew {
                    Button(role: .destructive) {
                        vm.recurring.removeAll { $0.id == recurring.id }
                        vm.transactions.removeAll { $0.recurringID == recurring.id }
                        vm.save()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("Delete")
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .help("Cancel")

                Button {
                    guard !recurring.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return
                    }

                    if isNew {
                        vm.recurring.append(recurring)
                    } else if let idx = vm.recurring.firstIndex(where: { $0.id == recurring.id }) {
                        vm.recurring[idx] = recurring
                    }

                    vm.insertMissingRecurring()
                    vm.save()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .help("Save")
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
