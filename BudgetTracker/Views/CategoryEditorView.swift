import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var vm: BudgetViewModel
    @State private var newCategory = ""
    @State private var selectedIcon = "tag"

    let standardCategories: [String] = [
        "Food", "Groceries", "Dining", "Transportation", "Travel", "Commute", "Car",
        "Shopping", "Clothes", "Retail", "Salary", "Income", "Paycheck",
        "Utilities", "Bills", "Electricity", "Water", "Gas", "Entertainment", "Movies",
        "Games", "Subscriptions", "Health", "Medical", "Doctor", "Pharmacy", "Insurance",
        "Housing", "Rent", "Mortgage", "Education", "School", "Tuition", "Personal",
        "Self-Care", "Beauty", "Pets", "Animals", "Gifts", "Donations", "Savings",
        "Investment", "Bank", "Taxes", "Phone", "Internet", "Misc", "Other"
    ]

    let availableIcons = [
        "fork.knife", "car.fill", "bag.fill", "banknote", "bolt.fill",
        "film", "cross.case.fill", "shield.lefthalf.fill", "house.fill",
        "book.fill", "person.crop.circle.fill", "pawprint.fill", "gift.fill",
        "chart.bar.fill", "percent", "wifi", "ellipsis.circle.fill", "folder.fill"
    ]

    func iconName(for category: String) -> String {
        switch category.lowercased() {
        case "food", "groceries", "dining": return "fork.knife"
        case "transportation", "travel", "commute", "car": return "car.fill"
        case "shopping", "clothes", "retail": return "bag.fill"
        case "salary", "income", "paycheck": return "banknote"
        case "utilities", "bills", "electricity", "water", "gas": return "bolt.fill"
        case "entertainment", "movies", "games", "subscriptions": return "film"
        case "health", "medical", "doctor", "pharmacy": return "cross.case.fill"
        case "insurance": return "shield.lefthalf.fill"
        case "housing", "rent", "mortgage": return "house.fill"
        case "education", "school", "tuition": return "book.fill"
        case "personal", "self-care", "beauty": return "person.crop.circle.fill"
        case "pets", "animals": return "pawprint.fill"
        case "gifts", "donations": return "gift.fill"
        case "savings", "investment", "bank": return "chart.bar.fill"
        case "taxes": return "percent"
        case "phone", "internet": return "wifi"
        case "misc", "other": return "ellipsis.circle.fill"
        default: return "folder.fill"
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach(vm.categories, id: \.self) { cat in
                    Label(cat.name, systemImage: cat.icon)
                }
                .onDelete { idx in
                    vm.categories.remove(atOffsets: idx)
                }
            }

            VStack {
                TextField("New category", text: $newCategory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .padding()
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Button("Add") {
                    guard !newCategory.isEmpty else { return }
                    let icon = iconName(for: newCategory)
                    vm.categories.append(Category(name: newCategory, icon: icon))
                    newCategory = ""
                    selectedIcon = "tag"
                }
                .padding(.top, 5)
            }
            .padding()
        }
        .onAppear {
            if vm.categories.isEmpty {
                for cat in standardCategories {
                    let icon = iconName(for: cat)
                    vm.categories.append(Category(name: cat, icon: icon))
                }
            }
        }
    }
}

