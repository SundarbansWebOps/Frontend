Sundarbans-House
A centralized platform for managing events, resources, team collaboration, and digital initiatives of Sundarbans House.

<img width="1902" height="925" alt="image" src="https://github.com/user-attachments/assets/f0063f90-d829-442f-be5e-528be3d34f21" />



<img width="1470" height="803" alt="Screenshot 2026-04-15 at 11 50 18" src="https://github.com/user-attachments/assets/65d285ed-e47b-4ba9-ac84-96444b8f1f2d" />


<img width="1470" height="728" alt="Screenshot 2026-04-02 at 10 57 30" src="https://github.com/user-attachments/assets/890ea9bb-9ed4-4cb8-b451-e50d6f2c563f" />

<img width="1111" height="677" alt="Screenshot 2026-04-15 at 11 51 30" src="https://github.com/user-attachments/assets/bfa0416c-d0cc-4473-ba4e-94eee8d91757" />

<img width="1470" height="434" alt="Screenshot 2026-04-15 at 11 52 05" src="https://github.com/user-attachments/assets/713db9a5-2d45-4e5b-b52f-4f247284ec49" />


Structure

```
Sundarbans-House_Vue-main/
├── index.html                        # App entry HTML
├── vite.config.js                    # Vite build config
├── package.json                      # Dependencies and scripts
│
├── public/                           # Static assets (served as-is)
│   ├── assets/
│   │   ├── logo.png
│   │   └── frames/                   # Animation frames (001–240 JPEGs)
│   │                                 # Used for scroll-based video animation
│   └── data/
│       └── doubts.json               # Static FAQ/doubts data
│
├── sundarbans/                       # Legacy standalone HTML version
│   ├── login.html / login.css / login.js
│   ├── dashboard.html / dashboard.css / dashboard.js / dashboard.json
│   ├── members.html / members.css / members.js / members.json
│   └── whatsapp.html
│
└── src/                              # Vue app source
    ├── main.js                       # App bootstrap (router, theme, tokens)
    ├── App.vue                       # Shell: nav, page, footer, course sheet, toast
    ├── router/
    │   └── index.js                  # All routes, old-URL redirects, scroll + page transitions
    ├── pages/                        # One *Page.vue per route (Home = Pat)
    ├── components/
    │   └── site/                     # Components used by the pages
    ├── lib/                          # Shared state and data adapters (store, events, house, courses, theme)
    ├── data/                         # Static data: events, council, teams, course data
    │   └── meetups/json/             # Per-region meetup data
    └── assets/
        ├── tokens.css                # Colours (light/dark), type, spacing
        └── pat/                      # Pat home artwork
```

