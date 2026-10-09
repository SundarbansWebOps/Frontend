# Sundarbans House

This glossary records the people, permissions, and content terms used while redesigning Sundarbans House as a student utility.

## People and governance

**WebAdmin**:
The technical super admin responsible for the site, users, roles, configuration, and recovery.

_Avoid_: using “super admin” as a public-facing role label; use WebAdmin in the product.

**Upper House Council (UHC)**:
The council whose public team roles and composition should be represented on the website.

**Admin**:
The shared content-management role for council operators such as the Secretary and Deputy Secretary.

**Regional Coordinator (RC)**:
A regional operator who manages meetups and region-specific updates for an assigned region.

**Public visitor**:
Any student or visitor using the public site without signing in.

**Member**:
A person on the active member roster. Membership grants access to the Members Lounge; it is not a council operator role.

**Member roster**:
The council-maintained list of members, kept in the council's Google Sheet. The Sheet is the roster's source of truth; the backend holds only a synced copy.

**Members Lounge**:
The members-only area of the site, entered by signing in with a Google account whose email is on the active member roster. Its home is about the member: their name, the live event, and their WhatsApp groups. Roll, region and Regional Coordinator live in the member's profile; IITM BS societies are not shown.
_Avoid_: "launch page" (a dictation slip for Lounge); "bots" (a dictation slip for boats, the WhatsApp groups moored at the ghat).

**Welcome tour**:
A journey a member takes before entering the Members Lounge: the house's story, past councils, this year's Upper House Council and the communities. Entering the Lounge or choosing Not now at the ghat marks it seen; Skip tour only advances to the ghat. The intended backend rule is once per member, with replay from the profile. Until backend sign-in is wired, every explicit Sign in replays the tour.

**Past council**:
The Secretary and Deputy Secretary of an earlier year, in that order. Web Admins are not listed per year; the house credits them through milestones.

**Milestone**:
A lasting achievement of the house, shown on its own in the welcome tour with the people who made it, e.g. 2023: moving from a Google Sites page to the house's own website, the first house to do so.

**Preferred name**:
The name a member chooses to be called in the Lounge. It starts as the roster name and the member confirms or changes it at the end of the welcome tour. It is how the Lounge addresses the member everywhere a name appears; the roll number is never used in its place. A member who has not given one is shown no name until they do.

## Content lifecycle

**Public content**:
Content that a public visitor can read without authentication, such as study resources, events, meetups, important dates, and the team directory.

**Draft**:
Content being prepared by an operator. It is not visible on public pages.

**Pending review**:
Content held for approval when a content type requires review before publication.

**Published**:
The approved version currently visible to public visitors.

**Region-scoped content**:
Content owned by one region, which an RC may manage within that region.
