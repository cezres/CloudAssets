//
//  CloudResourcesOperationQueue.swift
//  CloudResources
//
//  Created by 翟泉 on 2022/8/8.
//

import Foundation
import Dispatch

actor CloudResourcesOperationQueue<Op, Value> where Op: Hashable, Op: Equatable {
    
    typealias Handler = (_ op: Op) async -> Value
    typealias Callback = (_ op: Op, _ value: Value) -> Void
    
    var todoList: [(op: Op, callbacks: [Callback])] = []
    var fetchingList: [Op: [Callback]] = [:]
    let maxConcurrentCount: UInt
    
    private let handler: Handler
    private let check: () -> Bool
    
    init(maxConcurrentCount: UInt, check: @escaping () -> Bool, handler: @escaping Handler) {
        self.maxConcurrentCount = maxConcurrentCount
        self.handler = handler
        self.check = check
    }
    
    func insert(op: Op, callback: @escaping Callback) {
        if let callbacks = fetchingList[op] {
            fetchingList[op] = callbacks + [callback]
        } else if let index = todoList.firstIndex(where: { $0.op == op }) {
            let todo = todoList.remove(at: index)
            todoList.append((op, todo.callbacks + [callback]))
        } else {
            todoList.append((op, [callback]))
        }
        handleTodoList()
    }
    
    func insert(op: Op) async -> Value {
        return await withUnsafeContinuation { (c: UnsafeContinuation<Value, Never>) in
            self.insert(op: op, callback: { op, value in
                c.resume(returning: value)
            })
        }
    }
    
    func handleTodoList() {
        guard check() else { return }
        
        let handler = handler
        while fetchingList.count < maxConcurrentCount && !todoList.isEmpty {
            let todo = todoList.removeLast()
            fetchingList[todo.op] = todo.callbacks
            
            Task.detached {
                let value = await handler(todo.op)
                await self.operationCompleted(op: todo.op, value: value)
            }
        }
    }
    
    func operationCompleted(op: Op, value: Value) {
        if let handlers = fetchingList.removeValue(forKey: op) {
            handlers.forEach { $0(op, value) }
        }
        handleTodoList()
    }
    
}
