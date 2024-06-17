import XCTest
@testable import SwiftTG

class SwiftTGTests: XCTestCase {
    var swiftTG: SwiftTG!
    
    override func setUp() {
        super.setUp()
        swiftTG = SwiftTG(apiId: 123456, apiHash: "abc123", phoneOrToken: "your_bot_token_or_phone_number")
    }
    
    override func tearDown() {
        swiftTG = nil
        super.tearDown()
    }
    
    func testRegisterApp() {
        let expectation = self.expectation(description: "Registration completed")
        
        swiftTG.registerApp { success in
            if success, let phoneCodeHash = swiftTG.phoneCodeHash {
                XCTAssertEqual(phoneCodeHash, "expected_phone_code_hash_here") // Replace with expected phone code hash
                expectation.fulfill()
            } else {
                XCTFail("Registration failed or phoneCodeHash was not set")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    
    func testEnterCode() {
        swiftTG.phoneCodeHash = "test_phone_code_hash"
        
        let expectation = self.expectation(description: "Code entered")
        let code = "12345"
        
        swiftTG.confirmCode(code: code, phoneCodeHash: swiftTG.phoneCodeHash!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSendMessage() {
        swiftTG.phoneCodeHash = "test_phone_code_hash"
        
        let expectation = self.expectation(description: "Message sent")
        
        swiftTG.sendMessage(to: 123456789, message: "Hello from SwiftTG!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
