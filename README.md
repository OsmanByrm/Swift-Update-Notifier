# Swift App Update Notifier with Supabase

A simple iOS 18+ Swift app demonstrating how to implement automatic update notifications using Supabase as backend database.

## 🚀 Features

* ✅ Automatic update checking
* 📱 iOS 18+ compatible  
* ⚠️ Critical and normal update support
* 🌙 Dark/Light mode support
* 🎨 Modern SwiftUI design
* 🔒 Secure with Supabase RLS policies

## 📋 Prerequisites

- Xcode 15.0+
- iOS 18.0+
- Supabase account (free tier available)

## 🛠 Setup Guide

### Step 1: Supabase Database Setup

1. Create a free account at [Supabase](https://supabase.com)
2. Create a new project
3. Go to **SQL Editor** and run the setup script:

```sql
-- Swift Update Notifier - Supabase Setup
-- Copy and paste this code into your Supabase SQL Editor

-- Önce tabloyu siliyoruz (eğer varsa)
DROP TABLE IF EXISTS public.appversions;

-- Create the appversions table
CREATE TABLE public.appversions (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    version text NOT NULL,
    update_message text NOT NULL,
    is_critical boolean DEFAULT false,
    version_date timestamp with time zone DEFAULT now(),
    app_store_url text NOT NULL
);

-- Add comment on the table
COMMENT ON TABLE public.appversions IS 'Stores information about different app versions';

-- Add comments on the columns
COMMENT ON COLUMN public.appversions.id IS 'Unique identifier for the app version';
COMMENT ON COLUMN public.appversions.version IS 'Version number in semver format (e.g., 1.2.3)';
COMMENT ON COLUMN public.appversions.update_message IS 'Message to display to users about the update';
COMMENT ON COLUMN public.appversions.is_critical IS 'Whether this update is critical and users should be forced to update';
COMMENT ON COLUMN public.appversions.version_date IS 'When this version was released';
COMMENT ON COLUMN public.appversions.app_store_url IS 'URL to the app in the App Store';

-- Set up RLS policies to allow anonymous users to read
ALTER TABLE public.appversions ENABLE ROW LEVEL SECURITY;

-- Anyone can read app versions (including anonymous users)
CREATE POLICY "Anyone can read app versions" ON public.appversions
    FOR SELECT USING (true);

-- Only admins can insert/update/delete app versions
-- ⚠️ Change 'admin@example.com' to your actual admin email
CREATE POLICY "Only admins can insert app versions" ON public.appversions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.email() = 'admin@example.com');

CREATE POLICY "Only admins can update app versions" ON public.appversions
    FOR UPDATE USING (auth.role() = 'authenticated' AND auth.email() = 'admin@example.com');

CREATE POLICY "Only admins can delete app versions" ON public.appversions
    FOR DELETE USING (auth.role() = 'authenticated' AND auth.email() = 'admin@example.com');

-- Insert some sample data with higher version than 1.0.0
-- ⚠️ Replace the app store URL with your actual app URL
INSERT INTO public.appversions (version, update_message, is_critical, app_store_url)
VALUES 
    ('1.1.0', 'new features added: Version tracking and automatic update notifications.', false, 'https://apps.apple.com/app/your-app/id123456789'),
```

### Step 2: iOS App Configuration

1. Open `Swift-Update-Notifier.xcodeproj` in Xcode

2. Update your Supabase credentials in `ContentView.swift`:

```swift
// TODO: Replace with your Supabase project details
private let supabaseURL = "YOUR_SUPABASE_PROJECT_URL"
private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
private let currentVersion = "1.0.0" // Your current app version
```

3. Build and run the project

## 🏗 Architecture Overview

### Core Components

- **`ContentView.swift`**: Main app interface with update checking logic
- **`Swift_Update_NotifierApp.swift`**: App entry point
- **`AppUpdateView`**: Custom update notification UI component

### Update Flow

```
App Launch → Check Supabase → Compare Versions → Show Update Alert (if needed) → Redirect to App Store
```

## 💻 Key Implementation

### Update Checking Function
```swift
func checkForUpdates() {
    guard let url = URL(string: "\(supabaseURL)/rest/v1/appversions?select=*&order=version_date.desc&limit=1") else { return }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else { return }
        
        // Parse response and handle update logic
        if let versions = try? JSONDecoder().decode([AppVersion].self, from: data),
           let latestVersion = versions.first {
            DispatchQueue.main.async {
                handleUpdateResponse(latestVersion)
            }
        }
    }.resume()
}
```

### Custom Update Alert UI
```swift
struct AppUpdateView: View {
    let version: String
    let message: String
    let isCritical: Bool
    let appStoreURL: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isCritical ? "exclamationmark.triangle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(isCritical ? .red : .blue)
            
            Text("Update Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Version \(version)")
                .font(.headline)
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 15) {
                if !isCritical {
                    Button("Later") {
                        // Handle later action
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Update Now") {
                    // Open App Store
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

## 🔄 How It Works

1. **Startup Check**: App automatically checks Supabase database on launch
2. **Version Comparison**: Compares current app version with latest in database
3. **Smart Notifications**: Shows update dialog only when newer version exists
4. **Update Types**:
   - **Critical Updates**: Forces immediate update (no "Later" option)
   - **Normal Updates**: Allows user to postpone update
5. **App Store Integration**: Direct redirect to App Store for updates

## 🔧 Customization

### Adding New Update Types
Extend the database schema to include update categories:
```sql
ALTER TABLE public.appversions ADD COLUMN update_type text DEFAULT 'normal';
```

### Custom Update Messages
You can include rich text formatting in update messages and parse them in your Swift code.

## 🚀 Deployment

### For Development
1. Use Supabase development environment
2. Test with sample data provided in setup script

### For Production
1. Create production Supabase project
2. Update URLs and API keys
3. Configure proper App Store URLs
4. Test update flow thoroughly

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Osman Bayram**
- LinkedIn: [osman-bayram-785931250](https://www.linkedin.com/in/osman-bayram-785931250/)
- GitHub: [@OsmanBayram](https://github.com/OsmanByrm)

## ⭐ Support

If this project helped you, please give it a ⭐ star on GitHub!

---

**Project Link**: [https://github.com/OsmanBayram/Swift-Update-Notifier](https://github.com/OsmanByrm/Swift-Update-Notifier) 
