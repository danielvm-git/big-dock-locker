import SwiftUI
import CoreGraphics

struct DashboardView: View {
    @ObservedObject var viewModel: DockLockViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            header
            
            if !viewModel.isGranted {
                permissionWarning
            }
            
            displayList
            
            footer
        }
        .padding()
        .frame(width: 400, height: 400)
    }
    
    private var header: some View {
        HStack {
            Text("DockLock Dashboard")
                .font(.headline)
            Spacer()
            Circle()
                .fill(viewModel.isRunning ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(viewModel.isRunning ? "Active" : "Stopped")
                .font(.caption)
        }
    }
    
    private var permissionWarning: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Accessibility Permission Required")
                    .fontWeight(.bold)
            }
            Text("DockLock needs Accessibility permissions to prevent the Dock from jumping.")
                .font(.caption)
            Button("Grant Permission") {
                viewModel.requestPermissions()
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var displayList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.displays) { display in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(display.name)
                                .font(.body)
                            Text("ID: \(display.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if display.isMain {
                            Text("Main")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.lockedDisplayID == display.id },
                            set: { _ in viewModel.toggleLock(for: display.id) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .padding(10)
                    .background(viewModel.lockedDisplayID == display.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { _ in viewModel.toggleLaunchAtLogin() }
                ))
                .toggleStyle(.switch)
                Spacer()
            }
            
            Divider()
            
            HStack {
                Button(viewModel.isRunning ? "Stop Engine" : "Start Engine") {
                    if viewModel.isRunning {
                        viewModel.stopEngine()
                    } else {
                        viewModel.startEngine()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isRunning ? .red : .blue)
                
                Spacer()
                
                Button("Refresh") {
                    viewModel.refresh()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
