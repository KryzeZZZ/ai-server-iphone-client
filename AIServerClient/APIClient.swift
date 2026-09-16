import Foundation

enum APIError: LocalizedError { case invalidURL, unauthorized, server(String), decoding
    var errorDescription: String? { switch self { case .invalidURL: return "服务器地址无效"; case .unauthorized: return "Token 无效或缺失"; case .server(let message): return message; case .decoding: return "服务器返回的数据格式无法识别" } }
}

actor APIClient {
    var baseURL: URL
    var token: String?
    private let decoder = JSONDecoder()
    init(baseURL: String = "https://msadream.cn/agent", token: String? = nil) { self.baseURL = URL(string: baseURL)!; self.token = token }
    func configure(baseURL: String, token: String?) throws { guard let url = URL(string: baseURL), url.scheme == "https" || url.scheme == "http" else { throw APIError.invalidURL }; self.baseURL = url; self.token = token }
    func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T { var request = URLRequest(url: baseURL.appending(path: path)); request.httpMethod = method; request.httpBody = body; request.setValue("application/json", forHTTPHeaderField: "Accept"); if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }; if let token, !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request); let code = (response as? HTTPURLResponse)?.statusCode ?? 0; if code == 401 { throw APIError.unauthorized }; guard (200..<300).contains(code) else { throw APIError.server("请求失败（HTTP \(code)）") }; do { return try decoder.decode(T.self, from: data) } catch { throw APIError.decoding }
    }
    func status() async throws -> ServerStatus { try await request("status") }
    func processes() async throws -> [ServerProcess] { let response: ProcessList = try await request("processes?limit=50"); return response.processes }
    func services() async throws -> [Service] { let response: ServiceList = try await request("services?limit=100"); return response.services ?? [] }
    func docker() async throws -> DockerInfo { try await request("docker") }
    func chat(_ text: String) async throws -> ChatResponse { let body = try JSONEncoder().encode(ChatRequest(message: text)); return try await request("chat", method: "POST", body: body) }
    func tasks() async throws -> [ApprovalTask] { let response: TaskList = try await request("tasks?offset=0&limit=50"); return response.tasks }
    func decide(task: String, approve: Bool) async throws -> ApprovalTask { try await request("tasks/\(task)/\(approve ? "approve" : "reject")", method: "POST") }
    func audit() async throws -> [AuditRecord] { let response: AuditList = try await request("audit?offset=0&limit=50"); return response.values }
    func webSocketRequest() throws -> URLRequest { var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!; components.scheme = baseURL.scheme == "https" ? "wss" : "ws"; components.path = "/" + baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/ws"; guard let url = components.url else { throw APIError.invalidURL }; var request = URLRequest(url: url); if let token, !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }; return request }
}
