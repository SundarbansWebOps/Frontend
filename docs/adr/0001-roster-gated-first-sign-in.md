# Create rostered student accounts on first Google sign-in

On 2026-10-09, Raja chose roster-gated first-sign-in account creation over pre-creating
all student Auth accounts. Approved email eligibility is established before login;
Google sign-in creates the account only when that student first uses it, while the
product offers a sign-in-only interface and refuses unlisted emails. This avoids
provisioning unused accounts and preserves the separation between roster approval and
account creation. Existing accounts are retained. The optional-name/phone and region
bootstrap requirements remain in `../specs/003-backend-data-decisions.md`, Q1–Q6.
