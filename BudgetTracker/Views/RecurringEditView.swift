import SwiftUI

struct RecurringEditView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: BudgetViewModel
    @State var recurring: RecurringTransaction
    var isNew: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Basic fields
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

            // Category picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                Picker("", selection: $recurring.category) {
                    ForEach(vm.categories, id: \.name) { cat in
                        Label(cat.name, systemImage: cat.icon).tag(cat.name)
                    }
                }
                .pickerStyle(.menu)
            }

            // Date picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Start Date")
                DatePicker("", selection: $recurring.date, displayedComponents: .date)
                    .labelsHidden()
            }

            // Recurrence picker
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

            // Buttons
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Save") {
                    guard !recurring.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        return
                    }

                    if isNew {
                        vm.recurring.append(recurring)
                    } else {
                        if let idx = vm.recurring.firstIndex(where: { $0.id == recurring.id }) {
                            vm.recurring[idx] = recurring
                        }
                    }

                    vm.insertMissingRecurring()
                    vm.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
