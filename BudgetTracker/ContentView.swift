//
//  ContentView.swift
//  BudgetTracker
//
//  Created by Razvan Scaueru on 29/06/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ContentView: View {
  @StateObject var vm = BudgetViewModel()
  @State private var selectedTab = 0
    @State private var showChart = false
    @State private var showRecurring = false
    @State private var showCategories = false

    
  var body: some View {
      let cardFillColor: Color = {
          #if os(macOS)
          return Color(nsColor: NSColor.windowBackgroundColor)
          #else
          return Color(uiColor: UIColor.systemGray6)
          #endif
      }()

      VStack {
          HStack {
              let total = vm.transactions.map { $0.amount }.reduce(0, +)

              Text("Total Balance: £\(total, format: .number.precision(.fractionLength(2)))")
                  .font(.title2.weight(.bold))
                  .foregroundColor(.primary)
                  .padding(8)
                  .background(
                      RoundedRectangle(cornerRadius: 10)
                          .fill(cardFillColor)
                          .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                  )



            Spacer()
            Button(action: { showChart = true }) {
              Image(systemName: "chart.line.uptrend.xyaxis")
            }
            .sheet(isPresented: $showChart) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Chart")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showChart = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .overlay(Divider(), alignment: .bottom)

                    ChartView(vm: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 500, minHeight: 300)
            }


            Button(action: { showRecurring = true }) {
              Image(systemName: "repeat")
            }
            .sheet(isPresented: $showRecurring) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Recurring")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showRecurring = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .overlay(Divider(), alignment: .bottom)

                    RecurringListView(vm: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 400, minHeight: 300)
            }






            Button(action: { showCategories = true }) {
              Image(systemName: "tag")
            }
            .sheet(isPresented: $showCategories) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showCategories = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .overlay(Divider(), alignment: .bottom)

                    CategoryEditorView(vm: vm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 400, minHeight: 300)
            }

          }
          .padding()


        Divider()

        switch selectedTab {
        case 0: BudgetListView(vm: vm)
        case 1: ChartView(vm: vm)
        case 2: RecurringListView(vm: vm)
        case 3: CategoryEditorView(vm: vm)
        default: BudgetListView(vm: vm)
        }
      }
      .padding()

  }
}
