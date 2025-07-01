//
//  ChartView.swift
//  BudgetTracker
//
//  Created by Razvan Scaueru on 29/06/2025.
//

import SwiftUI
import Charts

struct ChartView: View {
  @ObservedObject var vm: BudgetViewModel

  var body: some View {
    Chart {
      ForEach(vm.transactions.sorted(by: { $0.date < $1.date })) { tx in
        LineMark(x: .value("Date", tx.date),
                 y: .value("Balance", cumulative(to: tx)))
      }
    }
    .padding()
  }

  func cumulative(to tx: Transaction) -> Double {
    let relevant = vm.transactions.filter { $0.date <= tx.date }
    return relevant.map { $0.amount }.reduce(0, +)
  }
}
