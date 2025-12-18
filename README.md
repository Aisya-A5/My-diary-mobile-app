# My diary mobile app
Mobile app for placing your daily life into words.

This app UI built using flutter and use Firebase as database.
and has a built in AI; Speech-to-text and Activities recomendations based on your top 3 feelings using LLM to understand your feelings

lib/
├── firebase_options.dart         
├── main.dart                     
│
├── models/
│   └── diary_entry.dart          
│
├── pages/
│   ├── about_page.dart           
│   ├── agenda_page.dart          
│   ├── diary_entry_detail_page.dart 
│   ├── diary_entry_page.dart     
│   ├── github_debug_page.dart    
│   ├── login_page.dart           
│   ├── main_navigation_page.dart 
│   └── profile_page.dart         
│
└── services/
    ├── auth_service.dart         
    └── diary_service.dart        
