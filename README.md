Sundarbans-House
A centralized platform for managing events, resources, team collaboration, and digital initiatives of Sundarbans House.

<img width="1902" height="925" alt="image" src="https://github.com/user-attachments/assets/f0063f90-d829-442f-be5e-528be3d34f21" />

<img width="1903" height="926" alt="image" src="https://github.com/user-attachments/assets/8c514650-59d6-46cb-bb17-8edaf51febb8" />

<img width="1905" height="922" alt="image" src="https://github.com/user-attachments/assets/9e1a0f36-4d63-485f-b799-d4dc5d0d633a" />

<img width="1903" height="925" alt="image" src="https://github.com/user-attachments/assets/2846ce19-51da-428b-80fe-fa84fd89b447" />


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

