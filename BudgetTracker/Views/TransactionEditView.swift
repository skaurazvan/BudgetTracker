import SwiftUI

struct TransactionEditView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var vm: BudgetViewModel
    @State var transaction: Transaction
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Transaction")
                .font(.headline)

            Group {
                Text("Name")
                TextField("Name", text: $transaction.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Description")
                TextField("Description", text: $transaction.description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Amount")
                TextField("Amount", value: $transaction.amount, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Category")
                Picker("Category", selection: $transaction.category) {
                    ForEach(vm.categories) { cat in
                        HStack {
                            Image(systemName: cat.icon)
                            Text(cat.name)
                        }
                        .tag(cat.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Spacer()

            HStack {
                Spacer()

                Button {
                    vm.transactions.removeAll { $0.id == transaction.id }
                    vm.save()
                    onDelete?()
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .help("Delete Transaction")

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .help("Cancel")

                Button {
                    if let index = vm.transactions.firstIndex(where: { $0.id == transaction.id }) {
                        let recurringID = vm.transactions[index].recurringID
                        vm.transactions[index] = transaction
                        vm.transactions[index].recurringID = recurringID
                        vm.save()
                    }
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .keyboardShortcut(.defaultAction)
                .help("Save Changes")
            }
        }
        .padding()
        .frame(width: 400)
    }
}
