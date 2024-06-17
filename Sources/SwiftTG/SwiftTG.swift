import Foundation

public protocol BotAPI {
    func sendRequest(method: String, parameters: [String: Any], completion: @escaping (Result<Data, Error>) -> Void)
}

public class NetworkBotAPI: BotAPI {
    let token: String
    
    init(token: String) {
        self.token = token
    }
    
    var baseURL: URL {
        return URL(string: "https://api.telegram.org/bot\(token)/")!
    }
    
    public func sendRequest(method: String, parameters: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(method), resolvingAgainstBaseURL: false)!
        
        urlComponents.queryItems = parameters.map { (key, value) in
            return URLQueryItem(name: key, value: "\(value)")
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "BotAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
}

public class SwiftTG {
    private let apiId: Int
    private let apiHash: String
    private let phoneOrToken: String
    public var phoneCodeHash: String?
    private let botAPI: BotAPI
    
    public init(apiId: Int, apiHash: String, phoneOrToken: String, botAPI: BotAPI? = nil) {
        self.apiId = apiId
        self.apiHash = apiHash
        self.phoneOrToken = phoneOrToken
        self.botAPI = botAPI ?? NetworkBotAPI(token: phoneOrToken)
    }
    
    public func registerApp() {
        let parameters: [String: Any] = [
            "api_id": apiId,
            "api_hash": apiHash,
            "name": "MyTelegramApp",
            "description": "Description of my Telegram app",
            "url": "https://example.com"
        ]
        
        botAPI.sendRequest(method: "createApplication", parameters: parameters) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let phoneCodeHash = json["phone_code_hash"] as? String {
                    self.phoneCodeHash = phoneCodeHash
                    self.enterCode()
                } else {
                    print("Failed to register app or parse response")
                }
            case .failure(let error):
                print("Error: \(error)")
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
        let parameters: [String: Any] = [
            "phone_number": phoneOrToken,
            "phone_code_hash": phoneCodeHash,
            "code": code
        ]
        
        botAPI.sendRequest(method: "signIn", parameters: parameters) { result in
            switch result {
            case .success(_):
                print("Signed in successfully.")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    public func sendMessage(to chatId: Int, message: String) {
        let parameters: [String: Any] = [
            "chat_id": chatId,
            "text": message
        ]
        
        botAPI.sendRequest(method: "sendMessage", parameters: parameters) { result in
            switch result {
            case .success(_):
                print("Message sent successfully.")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
