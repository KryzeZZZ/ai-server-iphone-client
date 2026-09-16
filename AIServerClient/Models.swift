import Foundation

struct ServerStatus: Codable {
    let hostname: String
    let operatingSystem: String
    let kernel: String
    let uptimeSeconds: Double
    let cpuUsagePercent: Double
    let cpuLoadAverage: [Double]
    let memory: Usage
    let swap: Usage
    let disk: DiskUsage
    let networkInterfaces: [NetworkInterface]
    let systemTime: String

    enum CodingKeys: String, CodingKey { case hostname; case operatingSystem = "operating_system"; case kernel; case uptimeSeconds = "uptime_seconds"; case cpuUsagePercent = "cpu_usage_percent"; case cpuLoadAverage = "cpu_load_average"; case memory, swap, disk; case networkInterfaces = "network_interfaces"; case systemTime = "system_time" }
}

struct Usage: Codable { let totalBytes: Int64; let usedBytes: Int64; let percent: Double; enum CodingKeys: String, CodingKey { case totalBytes = "total_bytes"; case usedBytes = "used_bytes"; case percent } }
struct DiskUsage: Codable { let mountpoint: String; let totalBytes: Int64; let usedBytes: Int64; let percent: Double; enum CodingKeys: String, CodingKey { case mountpoint; case totalBytes = "total_bytes"; case usedBytes = "used_bytes"; case percent } }
struct NetworkInterface: Codable, Identifiable { var id: String { name }; let name: String; let isUp: Bool; let speedMbps: Int?; let ipAddresses: [IPAddress]; enum CodingKeys: String, CodingKey { case name; case isUp = "is_up"; case speedMbps = "speed_mbps"; case ipAddresses = "ip_addresses" } }
struct IPAddress: Codable { let family, address, netmask: String? }

struct ProcessList: Codable { let processes: [ServerProcess] }
struct ServerProcess: Codable, Identifiable { let pid: Int; var id: Int { pid }; let name, user, command: String; let cpuPercent, memoryPercent: Double; enum CodingKeys: String, CodingKey { case pid, name, user, command; case cpuPercent = "cpu_percent"; case memoryPercent = "memory_percent" } }

struct ServiceList: Codable { let services: [Service]? }
struct Service: Codable, Identifiable { var id: String { name }; let name: String; let status: String?; let description: String? }
struct DockerInfo: Codable { let available: Bool; let reason: String?; let containers: [DockerContainer]? }
struct DockerContainer: Codable, Identifiable { var id: String { name }; let name, image, status: String; let ports, uptime: String? }

struct ChatRequest: Encodable { let message: String }
struct ChatResponse: Codable { let message: String; let taskID: String?; let tools: [String]?; enum CodingKeys: String, CodingKey { case message; case taskID = "task_id"; case tools } }
struct ChatMessage: Identifiable { enum Role { case user, agent, event }; let id = UUID(); let role: Role; let text: String; let date = Date() }

struct TaskList: Codable { let tasks: [ApprovalTask] }
struct ApprovalTask: Codable, Identifiable { let id, tool, risk, status, createdAt, expiresAt: String; let arguments: [String: JSONValue]?; let approvedAt, completedAt: String?; let result: JSONValue?; let error: String?; enum CodingKeys: String, CodingKey { case id, tool, risk, status, arguments, result, error; case createdAt = "created_at"; case expiresAt = "expires_at"; case approvedAt = "approved_at"; case completedAt = "completed_at" } }
struct AuditList: Codable { let records: [AuditRecord]?; let audit: [AuditRecord]?; var values: [AuditRecord] { records ?? audit ?? [] } }
struct AuditRecord: Codable, Identifiable { let id: String?; let tool, createdAt, resultSummary: String?; let risk, status: String?; var stableID: String { id ?? "\(createdAt ?? "")-\(tool ?? "")" }; enum CodingKeys: String, CodingKey { case id, tool, risk, status; case createdAt = "created_at"; case resultSummary = "result_summary" } }

enum JSONValue: Codable, CustomStringConvertible { case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null
    init(from decoder: Decoder) throws { let c = try decoder.singleValueContainer(); if c.decodeNil() { self = .null } else if let v = try? c.decode(Bool.self) { self = .bool(v) } else if let v = try? c.decode(Double.self) { self = .number(v) } else if let v = try? c.decode(String.self) { self = .string(v) } else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) } else { self = .array(try c.decode([JSONValue].self)) } }
    func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); switch self { case .null: try c.encodeNil(); case .string(let v): try c.encode(v); case .number(let v): try c.encode(v); case .bool(let v): try c.encode(v); case .object(let v): try c.encode(v); case .array(let v): try c.encode(v) } }
    var description: String { switch self { case .string(let v): return v; case .number(let v): return String(v); case .bool(let v): return String(v); case .object(let v): return v.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", "); case .array(let v): return v.map(\.description).joined(separator: ", "); case .null: return "null" } }
}
