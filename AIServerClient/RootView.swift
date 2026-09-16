import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        Group { if store.token.isEmpty { SetupView() } else { MainTabs() } }
            .alert("提示", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("确定", role: .cancel) {} } message: { Text(store.error ?? "") }
            .overlay { if store.isLoading { ProgressView().padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
    }
}

private struct MainTabs: View {
    var body: some View { TabView { DashboardView().tabItem { Label("概览", systemImage: "gauge.with.dots.needle.50percent") }; ChatView().tabItem { Label("助手", systemImage: "bubble.left.and.bubble.right") }; TasksView().tabItem { Label("任务", systemImage: "checklist") }; OperationsView().tabItem { Label("资源", systemImage: "server.rack") }; SettingsView().tabItem { Label("设置", systemImage: "gearshape") } } }
}

struct SetupView: View {
    @EnvironmentObject private var store: AppStore
    @State private var url = "https://msadream.cn/agent"
    @State private var token = ""
    var body: some View { NavigationStack { Form { Section("连接服务器") { TextField("API 地址", text: $url).textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled(); SecureField("API Token", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled() }; Section { Text("Token 仅保存在此设备的 Keychain 中，不会写入日志或 UserDefaults。 ").font(.footnote).foregroundStyle(.secondary) } } .navigationTitle("AI Server") .toolbar { ToolbarItem(placement: .confirmationAction) { Button("保存") { Task { _ = await store.saveSettings(url: url, token: token) } }.disabled(url.isEmpty || token.isEmpty) } } } }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var url = ""; @State private var token = ""
    var body: some View { NavigationStack { Form { Section("服务器") { TextField("API 地址", text: $url).textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled(); SecureField("API Token", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled(); Button("保存并重新连接") { Task { _ = await store.saveSettings(url: url, token: token) } } }; Section { Button("退出并清除 Token", role: .destructive) { store.signOut() } } } .navigationTitle("设置").onAppear { url = store.baseURL; token = store.token } } }
}
