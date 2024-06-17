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

public enum ChatEntity {
    case user(id: Int, username: String?, firstName: String?, lastName: String?)
    case group(id: Int, title: String)
    case channel(id: Int, title: String, username: String?)
    case unknown

    init?(json: [String: Any]) {
        guard let id = json["id"] as? Int else { return nil }
        if let type = json["type"] as? String {
            switch type {
            case "private":
                let username = json["username"] as? String
                let firstName = json["first_name"] as? String
                let lastName = json["last_name"] as? String
                self = .user(id: id, username: username, firstName: firstName, lastName: lastName)
            case "group":
                let title = json["title"] as? String ?? "Unknown Group"
                self = .group(id: id, title: title)
            case "channel":
                let title = json["title"] as? String ?? "Unknown Channel"
                let username = json["username"] as? String
                self = .channel(id: id, title: title, username: username)
            default:
                self = .unknown
            }
        } else {
            self = .unknown
        }
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
    
    public func RegisterApp() {
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
                    self.EnterCode()
                } else {
                    print("Failed to register app or parse response")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    public func EnterCode() {
        guard let phoneCodeHash = self.phoneCodeHash else {
            print("Phone code hash is missing")
            return
        }
        
        print("Enter the code received on your phone:")
        if let code = readLine(), !code.isEmpty {
            self.ConfirmCode(code: code, phoneCodeHash: phoneCodeHash)
        } else {
            print("Invalid code")
        }
    }
    
    public func ConfirmCode(code: String, phoneCodeHash: String) {
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
    
    public func SendMessage(to chatId: Int, message: String) {
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
    
    public func ForwardMessages(IntoChat: Int, FromChat: Int, MessageLink: String) {
        guard let messageId = extractMessageId(from: MessageLink) else {
            print("Invalid message link")
            return
        }
        
        let parameters: [String: Any] = [
            "chat_id": IntoChat,
            "from_chat_id": FromChat,
            "message_id": messageId
        ]
        
        botAPI.sendRequest(method: "forwardMessage", parameters: parameters) { result in
            switch result {
            case .success(_):
                print("Message forwarded successfully.")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    private func extractMessageId(from messageLink: String) -> Int? {
        // FROMAT MUST BE https://t.me/chatId/messageId  !!!!!!!!!!!!!
        let components = messageLink.split(separator: "/")
        guard let messageIdString = components.last, let messageId = Int(messageIdString) else {
            return nil
        }
        return messageId
    }
    
    public func GetEntity(Id: Int) {
        let parameters: [String: Any] = ["chat_id": Id]
        
        botAPI.sendRequest(method: "getChat", parameters: parameters) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let chatEntity = ChatEntity(json: json) {
                    self.presentChatEntity(chatEntity)
                } else {
                    print("Failed to parse chat entity data")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func presentChatEntity(_ entity: ChatEntity) {
        switch entity {
        case .user(let id, let username, let firstName, let lastName):
            print("User ID: \(id)")
            print("Username: \(username ?? "N/A")")
            print("First Name: \(firstName ?? "N/A")")
            print("Last Name: \(lastName ?? "N/A")")
        case .group(let id, let title):
            print("Group ID: \(id)")
            print("Title: \(title)")
        case .channel(let id, let title, let username):
            print("Channel ID: \(id)")
            print("Title: \(title)")
            print("Username: \(username ?? "N/A")")
        case .unknown:
            print("Unknown chat entity")
        }
    }
}

