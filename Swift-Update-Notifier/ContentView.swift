import SwiftUI

// MARK: - Models
/// Data model representing app update information from Supabase
struct AppUpdateInfo: Codable {
    let version: String
    let updateMessage: String
    let isCritical: Bool
    let appStoreUrl: String
    
    /// Custom coding keys to match Supabase column names (snake_case to camelCase)
    enum CodingKeys: String, CodingKey {
        case version
        case updateMessage = "update_message"
        case isCritical = "is_critical"
        case appStoreUrl = "app_store_url"
    }
}

// MARK: - Update Service
/// Service class that handles checking for app updates from Supabase
@MainActor
class UpdateService: ObservableObject {
    /// Controls whether the update alert is shown
    @Published var showUpdateAlert = false
    /// Holds the latest update information from server
    @Published var updateInfo: AppUpdateInfo?
    
    // MARK: - Configuration
    /// ⚠️ IMPORTANT: Replace these with your actual Supabase project credentials
    /// You can find these in your Supabase project settings
    private let supabaseURL = "supabase URL" // Replace with your Supabase URL
    private let supabaseKey = "supabase key" // Replace with your Supabase key
    private let currentVersion = "1.0.0" // Current version
    
    /// Fetches the latest app version from Supabase and compares with current version
    func checkForUpdates() {
        // Build the Supabase REST API URL to get the latest version
        // Orders by version_date descending to get the newest first, limits to 1 result
        guard let url = URL(string: "\(supabaseURL)/rest/v1/appversions?select=*&order=version_date.desc&limit=1") else { return }
        
        // Setup HTTP request with Supabase authentication headers
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")  // Required by Supabase
        
        // Make the network request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                // Decode JSON response into AppUpdateInfo array
                let updates = try JSONDecoder().decode([AppUpdateInfo].self, from: data)
                if let latestUpdate = updates.first {
                    DispatchQueue.main.async {
                        // Compare versions and show alert if newer version exists
                        if self?.isVersionNewer(latestUpdate.version, than: self?.currentVersion ?? "1.0.0") == true {
                            self?.updateInfo = latestUpdate
                            self?.showUpdateAlert = true
                        }
                    }
                }
            } catch { 
                // Silently handle JSON decode errors (you might want to log these in production)
            }
        }.resume()
    }
    
    /// Compares two semantic version strings (e.g., "1.2.3" vs "1.1.0")
    /// Returns true if newVersion is higher than currentVersion
    private func isVersionNewer(_ newVersion: String, than currentVersion: String) -> Bool {
        // Split version strings and convert to integers
        let newComponents = newVersion.split(separator: ".").compactMap { Int($0) }
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        
        // Compare each version component (major.minor.patch)
        for i in 0..<max(newComponents.count, currentComponents.count) {
            let new = i < newComponents.count ? newComponents[i] : 0
            let current = i < currentComponents.count ? currentComponents[i] : 0
            
            if new > current { return true }      // New version is higher
            else if new < current { return false } // Current version is higher
            // If equal, continue to next component
        }
        return false // Versions are identical
    }
}

// MARK: - Update Alert View
/// Custom modal view that displays update notification to users
struct AppUpdateView: View {
    let updateInfo: AppUpdateInfo
    @Environment(\.colorScheme) private var colorScheme  // Detect dark/light mode
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {            
            VStack(spacing: 25) {
                // MARK: Header Section
                HStack {
                    // App update icon
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    // Title and version info
                    VStack(alignment: .leading) {
                        Text("Update Available")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Version \(updateInfo.version)")
                            .font(.subheadline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)
                    }
                    
                    Spacer()
                    
                    // Critical update badge (only shown for critical updates)
                    if updateInfo.isCritical {
                        Text("Critical")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                }
                
                // MARK: Update Message
                Text(updateInfo.updateMessage)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // MARK: Action Buttons
                HStack(spacing: 20) {
                    // "Later" button - allows users to dismiss non-critical updates
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Later")
                            .font(.body)
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .opacity(updateInfo.isCritical ? 0.5 : 1.0)  // Dimmed for critical updates
                    
                    // "Update Now" button - opens App Store
                    Button(action: {
                        // Open App Store URL
                        if let url = URL(string: updateInfo.appStoreUrl) {
                            UIApplication.shared.open(url)
                        }
                        // Only dismiss alert for non-critical updates
                        // Critical updates keep the alert visible to force update
                        if !updateInfo.isCritical {
                            withAnimation(.easeOut) {
                                isPresented = false
                            }
                        }
                    }) {
                        Text("Update Now")
                            .font(.body)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .frame(width: min(UIScreen.main.bounds.width - 60, 340))  // Responsive width
            .background(
                // Adaptive background color for dark/light mode
                colorScheme == .dark ?
                    Color(.systemGray6) :
                    Color.white
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)  // Drop shadow
            .padding(.horizontal, 30)
            .transition(.opacity)  // Smooth fade transition
        }
    }
}

// MARK: - Main Content View
/// Main app content view that triggers update checks
struct ContentView: View {
    @StateObject private var updateService = UpdateService()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            // Check for updates when the app launches
            updateService.checkForUpdates()
        }
        .overlay(
            // Overlay the update alert when needed
            Group {
                if updateService.showUpdateAlert,
                   let updateInfo = updateService.updateInfo {
                    AppUpdateView(
                        updateInfo: updateInfo,
                        isPresented: $updateService.showUpdateAlert
                    )
                    .transition(.opacity)
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
