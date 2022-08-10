//
//  CloudResourcesTests.swift
//  CloudResourcesTests
//
//  Created by azusa on 2022/6/9.
//

import XCTest
@testable import CloudResources

class CloudResourcesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testTaksGroup() async {
        let queue = CloudResourcesOperationQueue<Int, String>()
        
        await queue.handle { op in
            
            let timeInterval = TimeInterval(200 + arc4random_uniform(800)) / 1000
            Thread.sleep(forTimeInterval: timeInterval)
//            Task.sleep(nanoseconds: <#T##UInt64#>)
            print("Handle - \(op)")
            return "Azusa - \(op)"
        }
        
//        await group.insert(op: 10) { op, value in
//            print(op, value)
//        }
//        await group.insert(op: 10) { op, value in
//            print(op, value)
//        }
//        await group.insert(op: 20) { op, value in
//            print(op, value)
//        }
        
        await withTaskGroup(of: Void.self, body: { group in
            
            group.addTask {
                print(await queue.insert(op: 4))
            }
            group.addTask {
                print(await queue.insert(op: 8))
            }
            
            for i in 0..<30 {
                group.addTask {
                    print(await queue.insert(op: i))
                }
            }
        })
        
    }

}
