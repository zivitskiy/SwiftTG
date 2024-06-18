// SwiftTG for swift
//
// open-source telegram client library
//
//
//
// inspired by Telethon
//
// created by zivitskiy. 16.06.2024, 12:59 UTC+2
//

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
    
    public func GetEntity(Id: Int, completion: @escaping (ChatEntity?) -> Void) {
        let parameters: [String: Any] = ["chat_id": Id]
        
        botAPI.sendRequest(method: "getChat", parameters: parameters) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let chatEntity = ChatEntity(json: json) {
                    completion(chatEntity)
                } else {
                    print("Failed to parse chat entity data")
                    completion(nil)
                }
            case .failure(let error):
                print("Error: \(error)")
                completion(nil)
            }
        }
    }
    func ChangeAvatar(photoPath: String, token: String) {
        let url = URL(string: "https://api.telegram.org/bot\(token)/setUserProfilePhoto")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let photoData = try! Data(contentsOf: URL(fileURLWithPath: photoPath))
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(photoData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error!)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Profile photo updated successfully")
            } else {
                print("Failed to update profile photo")
            }
        }
        task.resume()
    }
    
    func ChangeUsername(newUsername: String, token: String) {
        let url = URL(string: "https://api.telegram.org/bot\(token)/updateUsername")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "username": newUsername
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error!)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Username updated successfully")
            } else {
                print("Failed to update username")
            }
        }
        task.resume()
    }
    
    func Terminate(token: String) {
        let url = URL(string: "https://api.telegram.org/bot\(token)/terminateAllSessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error!)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("All sessions terminated successfully")
            } else {
                print("Failed to terminate sessions")
            }
        }
        task.resume()
    }
    public func SendFile(to chatId: Int, File: URL, caption: String?) {
        let parameters: [String: Any] = [
            "chat_id": chatId,
            "caption": caption ?? ""
        ]
        
        let url = URL(string: "https://api.telegram.org/bot\(phoneOrToken)/sendDocument")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"document\"; filename=\"\(File.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        
        do {
            let fileData = try Data(contentsOf: File)
            body.append(fileData)
        } catch {
            print("Error reading file data: \(error)")
            return
        }
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error!)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("File sent successfully")
            } else {
                print("Failed to send file")
            }
        }
        task.resume()
    }
    
}
