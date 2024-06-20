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
            XCTAssertEqual(self.swiftTG.phoneCodeHash, "expected_phone_code_hash_here")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testEnterCode() {
        swiftTG.phoneCodeHash = "test_phone_code_hash"
        
        let expectation = self.expectation(description: "Code entered")
        let code = "12345"
        
        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "signIn", response: mockResponse)
        
        swiftTG.ConfirmCode(code: code, phoneCodeHash: swiftTG.phoneCodeHash!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSendMessage() {
        let expectation = self.expectation(description: "Message sent")
        
        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "sendMessage", response: mockResponse)
        
        swiftTG.SendMessage(to: 123456789, message: "Hello from SwiftTG!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testForwardMessages() {
        let expectation = self.expectation(description: "Message forwarded")
        
        let mockResponse: [String: Any] = [:]
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
        
        swiftTG.GetEntity(Id: 12345) { chatEntity in
            if case let .user(id, username, firstName, lastName) = chatEntity {
                XCTAssertEqual(id, 12345)
                XCTAssertEqual(username, "testuser")
                XCTAssertEqual(firstName, "Test")
                XCTAssertEqual(lastName, "User")
            } else {
                XCTFail("Expected user entity")
            }
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
        
        swiftTG.GetEntity(Id: 12345) { chatEntity in
            if case let .group(id, title) = chatEntity {
                XCTAssertEqual(id, 12345)
                XCTAssertEqual(title, "Test Group")
            } else {
                XCTFail("Expected group entity")
            }
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
        
        swiftTG.GetEntity(Id: 12345) { chatEntity in
            if case let .channel(id, title, username) = chatEntity {
                XCTAssertEqual(id, 12345)
                XCTAssertEqual(title, "Test Channel")
                XCTAssertEqual(username, "testchannel")
            } else {
                XCTFail("Expected channel entity")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testChangeAvatar() {
        let expectation = self.expectation(description: "Avatar changed")
        
        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "setUserProfilePhoto", response: mockResponse)
        
        let photoPath = "/Users/admin/Home/Pictures/askdjasdasjdkasd.jpg"
        let token = "6725849873:AAH9sP6ZSNgX4MuveLcbk1kgHfaxwgvgVY0"
        
        swiftTG.ChangeAvatar(photoPath: photoPath, token: token)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testChangeUsername() {
        let expectation = self.expectation(description: "Username changed")
        
        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "updateUsername", response: mockResponse)
        
        let newUsername = "new_username"
        let token = "your_bot_token_or_phone_number"
        
        swiftTG.ChangeUsername(newUsername: newUsername, token: token)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testTerminate() {
        let expectation = self.expectation(description: "Sessions terminated")
        
        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "terminateAllSessions", response: mockResponse)
        
        let token = "your_bot_token_or_phone_number"
        
        swiftTG.Terminate(token: token)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testSendFile() {
        let expectation = self.expectation(description: "File sent")
        
        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "sendDocument", response: mockResponse)
        
        let fileUrl = URL(fileURLWithPath: "")
        
        swiftTG.SendFile(to: 123456789, File: fileUrl, caption: "Test file")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testStartPolling() {
        let expectation = self.expectation(description: "Polling started")
        var isExpectationFulfilled = false

        let mockResponse: [String: Any] = [
            "result": [
                [
                    "update_id": 1001,
                    "message": [
                        "message_id": 1,
                        "from": ["id": 123456789, "is_bot": false, "first_name": "Test", "username": "testuser"],
                        "chat": ["id": 123456789, "first_name": "Test", "username": "testuser", "type": "private"],
                        "date": 1609459200,
                        "text": "/start"
                    ]
                ]
            ]
        ]
        
        mockBotAPI.setMockResponse(for: "getUpdates", response: mockResponse)
        
        let startEvent = NewMessageEvent(pattern: "^/start$") { message in
            if let chat = message["chat"] as? [String: Any],
               let chatId = chat["id"] as? Int {
                XCTAssertEqual(chatId, 123456789)
                if !isExpectationFulfilled {
                    expectation.fulfill()
                    isExpectationFulfilled = true
                }
            }
        }
        
        swiftTG.registerEventHandler(startEvent)
        swiftTG.startPolling()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !isExpectationFulfilled {
                expectation.fulfill()
                isExpectationFulfilled = true
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testForwardMessages2() {
        let expectation = self.expectation(description: "Message forwarded")

        let mockResponse: [String: Any] = [:]
        mockBotAPI.setMockResponse(for: "forwardMessage", response: mockResponse)

        swiftTG.ForwardMessages(IntoChat: 987654321, FromChat: 123456789, MessageLink: "https://t.me/123456789/987654321")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}
