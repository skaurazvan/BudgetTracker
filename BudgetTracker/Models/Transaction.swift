//
//  Transaction.swift
//  BudgetTracker
//
//  Created by Razvan Scaueru on 29/06/2025.
//
import SwiftUI
import Foundation

enum Recurrence: String, Codable, CaseIterable, Equatable {
    case weekly, fourWeekly, monthly, none
}



struct Transaction: Identifiable, Codable, Equatable {
    let id: UUID
    var recurringID: UUID?
    var date: Date
    var category: String
    var name: String
    var description: String
    var amount: Double
    var recurrence: Recurrence
}



