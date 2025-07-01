//
//  Category.swift
//  BudgetTracker
//
//  Created by Razvan Scaueru on 29/06/2025.
//
import SwiftUI
import Foundation


struct Category: Identifiable, Hashable {
  var id: String { name }
  let name: String
  let icon: String // system image name, e.g. "cart", "house", etc.
}
