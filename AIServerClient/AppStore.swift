import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var baseURL = UserDefaults.standard.string(forKey: "baseURL") ?? "https://msadream.cn/agent"
    @Published var token = KeychainStore.read() ?? ""
    @Published var status: ServerStatus?
    @Published var processes: [ServerProcess] = []
    @Published var services: [Service] = []
    @Published var docker: DockerInfo?
    @Published var tasks: [ApprovalTask] = []
    @Published var audit: [AuditRecord] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: String?
    private let client = APIClient()
    private var socketTask: URLSessionWebSocketTask?

    func bootstrap() async { await applyConfiguration(); guard !token.isEmpty else { return }; await refreshAll(); await connectSocket() }
    func saveSettings(url: String, token: String) async -> Bool { do { try KeychainStore.save(token); UserDefaults.standard.set(url, forKey: "baseURL"); self.baseURL = url; self.token = token; await applyConfiguration(); await refreshAll(); await connectSocket(); return true } catch { self.error = "无法安全保存 Token"; return false } }
    func signOut() { socketTask?.cancel(with: .goingAway, reason: nil); KeychainStore.delete(); token = ""; status = nil; tasks = [] }
    func refreshAll() async { guard !token.isEmpty else { return }; isLoading = true; defer { isLoading = false }; await loadStatus(); async let p: Void = loadProcesses(); async let s: Void = loadServices(); async let d: Void = loadDocker(); async let t: Void = loadTasks(); async let a: Void = loadAudit(); _ = await (p, s, d, t, a) }
    func loadStatus() async { await capture { self.status = try await self.client.status() } }
    func loadProcesses() async { await capture { self.processes = try await self.client.processes() } }
    func loadServices() async { await capture { self.services = try await self.client.services() } }
    func loadDocker() async { await capture { self.docker = try await self.client.docker() } }
    func loadTasks() async { await capture { self.tasks = try await self.client.tasks() } }
    func loadAudit() async { await capture { self.audit = try await self.client.audit() } }
    func send(_ text: String) async { let clean = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !clean.isEmpty else { return }; messages.append(.init(role: .user, text: clean)); await capture { let response = try await self.client.chat(clean); self.messages.append(.init(role: .agent, text: response.message)); if response.taskID != nil { await self.loadTasks() } } }
    func decide(_ task: ApprovalTask, approve: Bool) async { isLoading = true; defer { isLoading = false }; await capture { _ = try await self.client.decide(task: task.id, approve: approve); await self.loadTasks(); await self.loadAudit() } }
    private func applyConfiguration() async { do { try await client.configure(baseURL: baseURL, token: token) } catch { self.error = error.localizedDescription } }
    private func capture(_ operation: () async throws -> Void) async { do { try await operation() } catch { self.error = error.localizedDescription } }
    private func connectSocket() async { socketTask?.cancel(with: .goingAway, reason: nil); guard !token.isEmpty else { return }; do { let request = try await client.webSocketRequest(); let task = URLSession.shared.webSocketTask(with: request); socketTask = task; task.resume(); receiveSocket(task) } catch { self.error = error.localizedDescription } }
    private func receiveSocket(_ task: URLSessionWebSocketTask) { task.receive { [weak self] result in guard let self else { return }; Task { @MainActor in defer { self.receiveSocket(task) }; guard case .success(let message) = result else { return }; let text: String; switch message { case .string(let value): text = value; case .data(let value): text = String(data: value, encoding: .utf8) ?? ""; @unknown default: return }; self.handleEvent(text) } } }
    private func handleEvent(_ text: String) { guard let data = text.data(using: .utf8), let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let type = event["type"] as? String else { return }; if type == "approval_required" || type == "tool_finished" { Task { await loadTasks(); await loadAudit() } }; if let message = event["data"] as? [String: Any], let display = message["message"] as? String { messages.append(.init(role: .event, text: display)) } else if type == "agent_thinking", let data = event["data"] as? String { messages.append(.init(role: .event, text: data)) } }
}
