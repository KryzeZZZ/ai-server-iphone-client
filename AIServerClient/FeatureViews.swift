import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View { NavigationStack { List { if let s = store.status { Section(s.hostname) { MetricRow(title: "CPU", value: s.cpuUsagePercent, icon: "cpu"); MetricRow(title: "内存", value: s.memory.percent, icon: "memorychip"); MetricRow(title: "磁盘 \(s.disk.mountpoint)", value: s.disk.percent, icon: "internaldrive"); LabeledContent("运行时间", value: duration(s.uptimeSeconds)); LabeledContent("系统", value: s.operatingSystem).lineLimit(1); LabeledContent("内核", value: s.kernel).lineLimit(1) }; if !s.networkInterfaces.isEmpty { Section("网络") { ForEach(s.networkInterfaces) { nic in VStack(alignment: .leading, spacing: 4) { Text(nic.name).font(.headline); Text(nic.ipAddresses.compactMap(\.address).joined(separator: "  ")).foregroundStyle(.secondary); Text(nic.isUp ? "已连接" : "未连接").font(.caption).foregroundStyle(nic.isUp ? .green : .red) } } } } } else { ContentUnavailableView("暂无服务器数据", systemImage: "server.rack", description: Text("下拉刷新以连接服务器")) } } .navigationTitle("服务器概览").refreshable { await store.refreshAll() }.toolbar { Button { Task { await store.refreshAll() } } label: { Image(systemName: "arrow.clockwise") } } } }
    private func duration(_ seconds: Double) -> String { let f = DateComponentsFormatter(); f.allowedUnits = [.day, .hour, .minute]; f.unitsStyle = .abbreviated; return f.string(from: seconds) ?? "—" }
}

private struct MetricRow: View { let title: String; let value: Double; let icon: String; var body: some View { HStack { Label(title, systemImage: icon); Spacer(); Text(value, format: .number.precision(.fractionLength(1))).monospacedDigit(); Text("%").foregroundStyle(.secondary) }.accessibilityLabel("\(title) \(value)%") } }

struct ChatView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft = ""
    var body: some View { NavigationStack { VStack(spacing: 0) { if store.messages.isEmpty { ContentUnavailableView("向服务器助手提问", systemImage: "sparkles", description: Text("例如：查看服务器当前状态")) } else { ScrollView { LazyVStack(alignment: .leading, spacing: 12) { ForEach(store.messages) { message in MessageBubble(message: message) } }.padding() } }; Divider(); HStack(alignment: .bottom) { TextField("输入请求…", text: $draft, axis: .vertical).lineLimit(1...5).textFieldStyle(.roundedBorder); Button { let value = draft; draft = ""; Task { await store.send(value) } } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }.disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }.padding() } .navigationTitle("服务器助手") } }
}

private struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(color, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(message.role == .user ? .white : .primary)
            if message.role != .user { Spacer(minLength: 40) }
        }
    }
    private var color: Color {
        switch message.role {
        case .user: return .accentColor
        case .agent: return Color(uiColor: .secondarySystemBackground)
        case .event: return .orange.opacity(0.18)
        }
    }
}

struct TasksView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View { NavigationStack { List { let pending = store.tasks.filter { $0.status == "pending" }; if !pending.isEmpty { Section("需要确认") { ForEach(pending) { TaskCard(task: $0) } } }; Section("最近任务") { ForEach(store.tasks.filter { $0.status != "pending" }) { task in TaskCard(task: task) } }; if store.tasks.isEmpty { ContentUnavailableView("没有任务", systemImage: "checklist") } } .navigationTitle("审批任务").refreshable { await store.loadTasks() } } }
}

private struct TaskCard: View { @EnvironmentObject private var store: AppStore; let task: ApprovalTask; @State private var showConfirm = false
    var body: some View { VStack(alignment: .leading, spacing: 8) { HStack { Text(task.tool).font(.headline); Spacer(); Text(task.risk).font(.caption.weight(.bold)).padding(.horizontal, 7).padding(.vertical, 3).background(task.risk.uppercased() == "HIGH" ? .red.opacity(0.18) : .orange.opacity(0.18), in: Capsule()) }; if let args = task.arguments, !args.isEmpty { Text(args.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n")).font(.footnote.monospaced()).foregroundStyle(.secondary) }; Text("状态：\(task.status) · 截止：\(task.expiresAt)").font(.caption).foregroundStyle(.secondary); if task.status == "pending" { HStack { Button("拒绝", role: .destructive) { Task { await store.decide(task, approve: false) } }; Spacer(); Button("确认执行") { showConfirm = true }.buttonStyle(.borderedProminent) } } }.padding(.vertical, 4).alert("确认高风险操作？", isPresented: $showConfirm) { Button("取消", role: .cancel) {}; Button("确认执行", role: .destructive) { Task { await store.decide(task, approve: true) } } } message: { Text("将执行 \(task.tool)。请确认参数和风险等级无误。") } }
}

struct OperationsView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View { NavigationStack { List { Section("进程（\(store.processes.count)）") { ForEach(store.processes) { p in VStack(alignment: .leading) { HStack { Text(p.name).font(.headline); Spacer(); Text("PID \(p.pid)").foregroundStyle(.secondary) }; Text("CPU \(p.cpuPercent, specifier: "%.1f")% · 内存 \(p.memoryPercent, specifier: "%.1f")% · \(p.user)").font(.caption).foregroundStyle(.secondary); Text(p.command).lineLimit(1).font(.caption2).foregroundStyle(.tertiary) } } }; Section("服务（\(store.services.count)）") { ForEach(store.services) { s in LabeledContent(s.name, value: s.status ?? "未知") } }; Section("Docker") { if let docker = store.docker { if docker.available { ForEach(docker.containers ?? []) { c in VStack(alignment: .leading) { Text(c.name).font(.headline); Text("\(c.image) · \(c.status)").font(.caption).foregroundStyle(.secondary) } } } else { Text(docker.reason ?? "Docker 不可用").foregroundStyle(.secondary) } } else { Text("正在读取…").foregroundStyle(.secondary) } }; Section("审计记录") { ForEach(store.audit.prefix(10), id: \.stableID) { record in VStack(alignment: .leading) { Text(record.tool ?? "操作"); Text(record.resultSummary ?? record.status ?? "").font(.caption).foregroundStyle(.secondary) } } } } .navigationTitle("资源与审计").refreshable { await store.loadProcesses(); await store.loadServices(); await store.loadDocker(); await store.loadAudit() } } }
}
