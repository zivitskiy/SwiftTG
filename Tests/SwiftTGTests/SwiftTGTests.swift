import XCTest
@testable import SwiftTG

class MockBotAPI: BotAPI {
    let token: String
    
    init(token: String) {
        self.token = token
    }
    
    var responses: [String: Any] = [:]
    
    func sendRequest(method: String, parameters: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        if let response = responses[method] as? Data {
            completion(.success(response))
        } else {
            let error = NSError(domain: "MockBotAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock response found for method \(method)"])
            completion(.failure(error))
        }
    }
    
    func setMockResponse(for method: String, response: Any) {
        if let data = try? JSONSerialization.data(withJSONObject: response, options: []) {
            responses[method] = data
        }
    }
}

class SwiftTGTests: XCTestCase {
    var swiftTG: SwiftTG!
    var mockBotAPI: MockBotAPI!
    
    override func setUp() {
        super.setUp()
        mockBotAPI = MockBotAPI(token: "your_bot_token_or_phone_number")
        swiftTG = SwiftTG(apiId: 123456, apiHash: "abc123", phoneOrToken: "your_bot_token_or_phone_number", botAPI: mockBotAPI)
    }
    
    override func tearDown() {
        swiftTG = nil
        mockBotAPI = nil
        super.tearDown()
    }
    
    func testRegisterApp() {
        let expectation = self.expectation(description: "Registration completed")
        
        let mockResponse: [String: Any] = [
            "phone_code_hash": "expected_phone_code_hash_here"
        ]
        mockBotAPI.setMockResponse(for: "createApplication", response: mockResponse)
        
        swiftTG.RegisterApp()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let phoneCodeHash = self.swiftTG.phoneCodeHash {
                XCTAssertEqual(phoneCodeHash, "expected_phone_code_hash_here")
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
        
        let mockResponse: [String: Any] = [:] // Mock empty response for signIn
        mockBotAPI.setMockResponse(for: "signIn", response: mockResponse)
        
        swiftTG.ConfirmCode(code: code, phoneCodeHash: swiftTG.phoneCodeHash!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSendMessage() {
        let expectation = self.expectation(description: "Message sent")
        
        let mockResponse: [String: Any] = [:] // Mock empty response for sendMessage
        mockBotAPI.setMockResponse(for: "sendMessage", response: mockResponse)
        
        swiftTG.SendMessage(to: 123456789, message: "Hello from SwiftTG!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testForwardMessages() {
        let expectation = self.expectation(description: "Message forwarded")
        
        let mockResponse: [String: Any] = [:] // Mock empty response for forwardMessage
        mockBotAPI.setMockResponse(for: "forwardMessage", response: mockResponse)
        
        swiftTG.ForwardMessages(IntoChat: 987654321, FromChat: 123456789, MessageLink: "https://t.me/123456789/987654321")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetEntityUser() {
        let expectation = self.expectation(description: "Got user entity")
        
        let mockResponse: [String: Any] = [
            "id": 12345,
            "type": "private",
            "username": "testuser",
            "first_name": "Test",
            "last_name": "User"
        ]
        mockBotAPI.setMockResponse(for: "getChat", response: mockResponse)
        
        swiftTG.GetEntity(Id: 12345)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetEntityGroup() {
        let expectation = self.expectation(description: "Got group entity")
        
        let mockResponse: [String: Any] = [
            "id": 12345,
            "type": "group",
            "title": "Test Group"
        ]
        mockBotAPI.setMockResponse(for: "getChat", response: mockResponse)
        
        swiftTG.GetEntity(Id: 12345)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testGetEntityChannel() {
        let expectation = self.expectation(description: "Got channel entity")
        
        let mockResponse: [String: Any] = [
            "id": 12345,
            "type": "channel",
            "title": "Test Channel",
            "username": "testchannel"
        ]
        mockBotAPI.setMockResponse(for: "getChat", response: mockResponse)
        
        swiftTG.GetEntity(Id: 12345)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
