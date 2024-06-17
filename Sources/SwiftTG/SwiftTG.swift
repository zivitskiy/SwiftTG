import Foundation

public class SwiftTG {
    private let apiId: Int
    private let apiHash: String
    private let phoneOrToken: String
    public var phoneCodeHash: String?
    
    public init(apiId: Int, apiHash: String, phoneOrToken: String) {
        self.apiId = apiId
        self.apiHash = apiHash
        self.phoneOrToken = phoneOrToken
    }
    
    public func registerApp() {
        let endpoint = "/bot\(phoneOrToken)/createApplication"
        guard let url = URL(string: "https://api.telegram.org" + endpoint) else {
            print("Invalid URL")
            return
        }
        
        let parameters: [String: Any] = [
            "api_id": apiId,
            "api_hash": apiHash,
            "name": "MyTelegramApp",
            "description": "Description of my Telegram app",
            "url": "https://example.com"
        ]
        
        performRequest(url: url, parameters: parameters, method: .post) { data in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let phoneCodeHash = json["phone_code_hash"] as? String {
                self.phoneCodeHash = phoneCodeHash
                self.enterCode()
            } else {
                print("Failed to register app or parse response")
            }
        }
    }
    
    public func enterCode() {
        guard let phoneCodeHash = self.phoneCodeHash else {
            print("Phone code hash is missing")
            return
        }
        
        print("Enter the code received on your phone:")
        if let code = readLine(), !code.isEmpty {
            self.confirmCode(code: code, phoneCodeHash: phoneCodeHash)
        } else {
            print("Invalid code")
        }
    }
    
    public func confirmCode(code: String, phoneCodeHash: String) {
        let endpoint = "/bot\(phoneOrToken)/signIn"
        guard let url = URL(string: "https://api.telegram.org" + endpoint) else {
            print("Invalid URL")
            return
        }
        
        let parameters: [String: Any] = [
            "phone_number": phoneOrToken,
            "phone_code_hash": phoneCodeHash,
            "code": code
        ]
        
        performRequest(url: url, parameters: parameters, method: .post) { _ in
            print("Signed in successfully.")
        }
    }
    
    public func sendMessage(to chatId: Int, message: String) {
        let endpoint = "/bot\(phoneOrToken)/sendMessage"
        guard let url = URL(string: "https://api.telegram.org" + endpoint) else {
            print("Invalid URL")
            return
        }
        
        let parameters: [String: Any] = [
            "chat_id": chatId,
            "text": message
        ]
        
        performRequest(url: url, parameters: parameters, method: .post) { _ in
            print("Message sent successfully.")
        }
    }
    
    private func performRequest(url: URL, parameters: [String: Any], method: HTTPMethod, completion: @escaping (Data?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(data)
        }
        task.resume()
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}
