# Swift App Update Notifier with Supabase

A simple tutorial showing how to add update notifications to your iOS 18+ Swift app using Supabase as backend.

## Features

* Automatic update checking
* iOS 18+ compatible  
* Critical and normal update support
* Dark/Light mode support
* Modern UI design

## Setup Guide

### Step 1: Supabase Setup

1. Create account at [Supabase](https://supabase.com)
2. Create new project
3. Go to SQL Editor and run this code:

```sql
-- Create the appversions table
CREATE TABLE public.appversions (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    version text NOT NULL,
    update_message text NOT NULL,
    is_critical boolean DEFAULT false,
    version_date timestamp with time zone DEFAULT now(),
    app_store_url text NOT NULL
);

-- Enable RLS and set policies
ALTER TABLE public.appversions ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read versions
CREATE POLICY "Anyone can read app versions" ON public.appversions
    FOR SELECT USING (true);

-- Insert sample data
INSERT INTO public.appversions (version, update_message, is_critical, app_store_url)
VALUES 
    ('1.1.0', 'New features added: Version tracking and automatic update notifications.', false, 'https://apps.apple.com/app/your-app/id123456789'),
    ('2.0.0', 'Important update: New design and improved functionality. Please update your app.', true, 'https://apps.apple.com/app/your-app/id123456789');
```

### Step 2: Swift App Setup

1. Clone this project:
```bash
git clone https://github.com/your-username/Swift-Update-Notifier.git
```

2. Open in Xcode

3. Update your Supabase credentials in `ContentView.swift`:

```swift
// Supabase Configuration
private let supabaseURL = "YOUR_SUPABASE_URL"
private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
private let currentVersion = "1.0.0" // Your current app version
```

## Key Code Implementation

### Update Check Function
```swift
func checkForUpdates() {
    guard let url = URL(string: "\(supabaseURL)/rest/v1/appversions?select=*&order=version_date.desc&limit=1") else { return }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle response and show update alert if needed
    }.resume()
}
```

### Update Alert View
```swift
struct AppUpdateView: View {
    let version: String
    let message: String
    let isCritical: Bool
    let appStoreURL: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Update Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Version \(version)")
                .font(.headline)
            
            Text(message)
                .multilineTextAlignment(.center)
            
            // Update buttons
        }
    }
}
```

## How It Works

1. App checks Supabase for latest version on startup
2. Compares with current app version  
3. Shows update dialog if newer version exists
4. Critical updates force users to update
5. Normal updates allow "Later" option

## Screenshots

*(Add your app screenshots here)*

## Supabase Tutorial Screenshots  

*(Add your Supabase setup screenshots here)*

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contact

Osman Bayram - [@your-twitter](https://twitter.com/your-twitter)

Project Link: [https://github.com/your-username/Swift-Update-Notifier](https://github.com/your-username/Swift-Update-Notifier) 