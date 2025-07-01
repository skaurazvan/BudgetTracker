//
//  RecurringTransaction.swift
//  BudgetTracker
//
//  Created by Razvan Scaueru on 29/06/2025.
//
import SwiftUI
import Foundation

struct RecurringTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var category: String
    var name: String
    var description: String
    var amount: Double
    var recurrence: Recurrence
}


