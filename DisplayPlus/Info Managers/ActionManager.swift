//
//  ActionManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 11/11/25.
//

import Foundation
import SwiftUI

class ActionManager: ObservableObject {
    @StateObject var theme: ThemeColors
    @Published var actions: [[action]]
    @Published var rowKey: [String]
    
    init(themeIn: ThemeColors) {
        _theme = StateObject(wrappedValue: themeIn)
        let systemActions: [action] = [
            action(name: "Toggle display", symbol: "lightswitch.on"),
            action(name: "Next page", symbol: "arrow.right.circle")
            ]
        actions = [systemActions]
        rowKey = ["System"]
    }
    
    //MARK: - Adding functions
    func addAction(row: Int, actionIn: action) {
        actions[row].append(actionIn)
    }
    func addRowFromThing(thing: Thing) {
        var newRow: [action] = []
        newRow = thing.actions
        
        rowKey.append(thing.name)
        actions.append(newRow)
    }
    func addRow(rowIn: [action], key: String) {
        rowKey.append(key)
        actions.append(rowIn)
    }
    
    //MARK: - Fetching functions
    func getAction(row: Int, index: Int) -> action {
        return actions[row][index]
    }
    func getActionByKey(keyIn: String, index: Int) -> action? {
        if let rowIndex = rowKey.firstIndex(of: keyIn) {
            return actions[rowIndex][index]
        } else {
            print("No action row found for key: \(keyIn)")
            return nil
        }
    }
    func getRow(row: Int) -> [action] {
        return actions[row]
    }
    func getRowByKey(keyIn: String) -> [action]? {
        if let rowIndex = rowKey.firstIndex(of: keyIn) {
            return actions[rowIndex]
        } else {
            print("No action row found for key: \(keyIn)")
            return nil
        }
    }
    
    //MARK: - Removing functions
    
    //MARK: - View returning functions
    func AllActionsToView() -> some View {
        return VStack {
            ForEach(0..<actions.count, id: \.self) { rowIndex in
                self.RowOfActionsToView(row: rowIndex)
            }
        }
    }
    func RowOfActionsToView(row: Int) -> some View {
        return HStack {
            ForEach(0..<self.actions[row].count, id: \.self) { actionIndex in
                self.ActionToView(self.actions[row][actionIndex])
            }
        }
    }
    func RowOfActionsToViewByKey(keyIn: String) -> some View {
        return HStack {
            if let rowIndex = rowKey.firstIndex(of: keyIn) {
                RowOfActionsToView(row: rowIndex)
            } else {
                AnyView(EmptyView())
            }
        }
    }
    private func ActionToView(_ action: action) -> some View {
        return VStack {
            Image(systemName: action.symbol)
                .frame(width: 48, height: 48)
                .font(.system(size: 32))
            Text(action.name)
        }
    }
}

class action {
    var name: String
    var symbol: String
    private var handler: (() -> Void)?

    init(name: String, symbol: String, handler: (() -> Void)? = nil) {
        self.name = name
        self.symbol = symbol
        self.handler = handler
    }

    func toString() -> String {
        return " \(symbol) \(name)"
    }

    func setAction(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func performAction() {
        handler?()
    }
}

#Preview {
    let theme = ThemeColors()
    let am = ActionManager(themeIn: theme)
    am.addRow(rowIn: [action(name: "Test1", symbol: "circle"), action(name: "Test2", symbol: "square")], key: "Row1")
    am.addRow(rowIn: [action(name: "Test3", symbol: "triangle"), action(name: "Test4", symbol: "star")], key: "Row2")
    return ScrollView(.vertical) {
        VStack {
            Text("All Actions")
                .font(theme.headerFont)
            am.AllActionsToView()
            Divider()
            Text("Return by index")
                .font(theme.headerFont)
            Text("\n\nRow 0")
            am.RowOfActionsToView(row: 0)
            Text("\n\nRow 1")
            am.RowOfActionsToView(row: 1)
            Text("\n\nRow 2")
            am.RowOfActionsToView(row: 2)
            Divider()
            Text("Return by key")
                .font(theme.headerFont)
            Text("\n\nSystem")
            am.RowOfActionsToViewByKey(keyIn: "System")
            Text("\n\nRow1")
            am.RowOfActionsToViewByKey(keyIn: "Row1")
            Text("\n\nRow2")
            am.RowOfActionsToViewByKey(keyIn: "Row2")
            Text("\n\nInvalid Key (should be empty)")
            am.RowOfActionsToViewByKey(keyIn: "InvalidKey")
        }
        .font(theme.bodyFont)
    }
}
