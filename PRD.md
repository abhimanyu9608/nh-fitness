# NH Fitness — Product Requirements Document (PRD)

**Product:** NH Fitness gym app — one product, same features on Website, Android and iOS
**Version:** 1.0 (Phase 1, free plan)
**Date:** 9 Nov 2026
**Firebase project ID:** `nh-fitness-8a972`
**Build order:** Website first, then Android, then iOS (same codebase)

> This document is written so it can be handed to Claude Code as the single source of truth.
> Put this file at the root of the repo as `PRD.md`, and put the two design reference files in `/design`:
> - `design/nh-fitness-website-wireframe.html` (website layout, sections, animations)
> - `design/nh-fitness-app-sample-v1.html` (mobile layout, sections, animations)
>
> Open both in a browser and match them. Where this PRD and the design files disagree, **this PRD wins** (for example, payment methods — see §7.4).

---

## 1. Summary

NH Fitness is a gym in India. Members can see plans, register, pay for a membership, see their membership status and days left, and watch online classes. The gym owner uses an admin panel (inside the same app) to approve payments, manage members, change prices, upload classes and post announcements.

Phase 1 must run on **Firebase's free Spark plan** with **no Cloud Functions**. Because of that, payments are **manual**: the member pays by UPI (or cash at the gym), enters the UPI reference number, and the admin approves it. Approval activates the membership.

### 1.1 Goals
1. A member can go from first visit to an active membership with no phone call to the gym.
2. The owner can approve a payment in under 30 seconds from the admin panel.
3. Prices, plans, contact details and classes can all be changed from the admin panel without a new app release.
4. Website, Android app and iOS app behave the same, from one Flutter codebase and one Firebase database.

### 1.2 Non-goals (Phase 1)
- Automatic online payment (Razorpay, card, net banking) — Phase 2.
- Phone number OTP login — Phase 2.
- Supplements store and clothes store — shown as "Coming soon" only.
- Automatic push notifications (expiry reminders by push) — Phase 2. Phase 1 uses in-app banners.
- Attendance, QR check-in, trainer accounts, diet plan builder.

---

## 2. Users and roles

| Role | Who | How the role is given | Can do |
|---|---|---|---|
| Visitor | Anyone, not logged in | — | See home, explore, plans, prices, coming soon |
| Member | Anyone who registered | Signs up with email/password or Google | Everything a visitor can, plus: submit payment, see membership, days left, payment history, online classes (only while membership is active), profile |
| Admin | Gym owner and staff | A document `admins/{uid}` is created **by hand in the Firebase Console** | Everything, plus the admin panel |

There is no sign-up path to become admin. The first admin is created manually (see §11, step 7).

---

## 3. Platforms and tech stack

| Area | Choice | Notes |
|---|---|---|
| App framework | **Flutter (latest stable)**, one project | Targets: `web`, `android`, `ios` |
| State management | `flutter_riverpod` | |
| Routing | `go_router` with path URLs (no `#`) | Use `usePathUrlStrategy()` for web |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore` | Configure with `flutterfire configure --project=nh-fitness-8a972` |
| Google login | `google_sign_in` (mobile), Firebase Auth popup (web) | |
| Fonts | `google_fonts` | Barlow Condensed + Barlow |
| Animations | `flutter_animate` | Plus built-in implicit animations |
| Images | `cached_network_image` | Images are URLs (no Firebase Storage in Phase 1) |
| UPI QR | `qr_flutter` | Generates the UPI QR from settings |
| Open links / UPI apps | `url_launcher` | |
| Video | `youtube_player_iframe` | Classes are unlisted YouTube videos |
| Dates and money | `intl` | Indian number format `₹15,500`, locale `en_IN` |

**Do not use in Phase 1:** Cloud Functions, Firebase Storage, Firebase Hosting (the site is hosted on the owner's own hosting, see §12), any paid API.

Use the latest stable version of every package at the time of building. Do not pin old versions.

---

## 4. Firebase setup (one-time, by the owner)

1. Firebase Console → project `nh-fitness-8a972`.
2. **Authentication → Sign-in method:** enable **Email/Password** and **Google**.
3. **Authentication → Settings → Authorized domains:** add the website domain (for example `nhfitness.in` and `www.nhfitness.in`). `localhost` is there by default for testing.
4. **Firestore Database → Create database:** production mode, location **`asia-south1` (Mumbai)**. The location cannot be changed later.
5. **Firestore → Rules:** paste the rules from §9 and publish.
6. **Firestore → Indexes:** create the indexes in §10. Firestore also prints a link in the console when a query needs an index; clicking it creates it.
7. Add apps in Project settings: **Web app**, **Android app** (package `com.nhfitness.app`), **iOS app** (bundle `com.nhfitness.app`). For Google login on Android, add the debug and release **SHA-1** fingerprints.
8. Run `flutterfire configure --project=nh-fitness-8a972` in the Flutter project. This creates `lib/firebase_options.dart`.

The Firebase web config in `firebase_options.dart` is not a secret and is safe in the app. Security comes from the rules in §9. **Never** put a service-account key or admin credentials in the repo.

Spark plan limits (check current numbers at firebase.google.com/pricing): Firestore has a daily cap on reads and writes and 1 GiB storage. That is plenty for one gym if lists are paginated (§13).

---

## 5. Design system

Match `design/nh-fitness-app-sample-v1.html` (mobile) and `design/nh-fitness-website-wireframe.html` (web). Dark theme only.

### 5.1 Colors

| Token | Hex | Use |
|---|---|---|
| `bg` | `#0D0A0B` | Page background |
| `surface` | `#1A1516` | Cards, inputs |
| `surface2` | `#221B1C` | Raised cards |
| `line` | `#33292B` | Borders, dividers |
| `red` | `#DC1F2E` | Primary buttons, selected states, accents |
| `redDark` | `#B81624` | Red card shading, pressed state |
| `redDeep` | `#7A111A` | Hero slash stripes |
| `selectedBg` | `#3A0F14` | Background of a selected plan card |
| `text` | `#F5F1F1` | Main text |
| `muted` | `#C9BEC0` | Secondary text |
| `yellow` | `#FFD429` | Offers: "7 days free", "Best value", "Coming soon" |
| `ink` | `#1A1516` | Text on yellow |
| `success` | `#2FBF71` | Approved status only |
| `danger` | `#FF5A5F` | Rejected status and errors only |

### 5.2 Typography
- **Display:** Barlow Condensed, italic, weight 800, UPPERCASE, line height 0.92–0.95. Used for headings, prices and buttons (buttons use weight 700, not italic).
- **Body:** Barlow 400/500/600.
- **Labels:** Barlow 600, 12–13 px, uppercase, letter spacing 2–3 px.
- Sizes: hero 64–136 px (web, responsive), 68 px (mobile); section titles 44–76 px (web), 40–46 px (mobile); price 50–58 px; body 16 px; small 13–14 px.
- Money uses tabular figures.

### 5.3 Components
- **Primary button:** red fill, white text, 56 px tall, radius 14–16, uppercase display font. Arrow icon slides right 5 px on hover.
- **Ghost button:** transparent, 2 px `text` border; on hover border and text turn yellow.
- **Back button:** 44×44 square, radius 12, `surface` fill.
- **Plan card (picker):** `surface`, 2 px `line` border, radius 16–18. Selected: red border, `selectedBg` fill, tick circle filled red. Yearly card has a yellow "Best value" tag on its top edge.
- **Offer badge:** 2 px dashed yellow border, "7 days personal training FREE".
- **Coming soon card:** grayscale photo, yellow diagonal "Coming soon" tape.
- **Status pill:** Pending = yellow outline; Approved/Active = green; Rejected/Expired = red.
- **Logo:** text "N**H**" (H in red) + barbell icon + "FITNESS", italic display font. Replace with the real logo file when available.
- Icons: outline stroke icons (Material Symbols outlined or Lucide). No emoji.
- Minimum touch target 44×44.

### 5.4 Motion (must have)
| Where | Animation |
|---|---|
| Every screen load | Content fades up 22–34 px, 650 ms, curve `Cubic(0.2, 0.7, 0.2, 1)`, staggered 100 ms per block |
| Home hero (web) | Background photo slow zoom (Ken Burns) 18 s, alternating; headline lines rise one by one |
| Home hero | Three red slanted stripes slide in from the right |
| Logo | Barbell floats up and down 6 px, 2.6 s loop |
| Main CTA | Red pulse ring around the button, 1.8 s loop |
| Ticker (web) | Red band with "TRAIN HARD ✦ STAY FOCUSED ✦ BE STRONG ✦ BE FIT ✦ BE YOU", scrolling, tilted −1.5° |
| Web sections | Reveal on scroll (fade up) |
| Feature/path cards (web) | Photo zooms to 108% on hover |
| Price cards (web) | Lift 8 px with red glow on hover |
| Coming soon | Tape sways gently; "Coming soon" tag blinks on mobile |
| Online badge | Live dot blinks |
| Checkout | Total counts up/down to the new value in 450 ms when plan or add-on changes |
| Success | Red circle pops in, tick draws, confetti (red, yellow, white) for 3 s |

If the device has "reduce motion" on (`MediaQuery.disableAnimationsOf(context)`), skip all looping and entrance animations.

### 5.5 Responsive layout
| Width | Layout |
|---|---|
| < 600 px | Mobile layout (from the mobile sample). Single column. Logged-in members get a bottom nav: Home, Plans, Classes, Profile |
| 600–1023 px | Tablet: two-column grids, top bar with menu button |
| ≥ 1024 px | Desktop web layout (from the website wireframe): top nav, max content width 1200 px, side menu in Account and Admin |

The **same screens and features** exist at every size. Only the layout changes.

### 5.6 Images
Phase 1 uses image URLs (no upload). The design file uses free Unsplash/Pexels photos as placeholders; keep them until the gym's own photos are ready, then swap the URLs in one constants file `lib/core/assets.dart`. Every image needs a dark fallback color and alt text (`semanticLabel`).

---

## 6. Information architecture and routes

| Route | Screen | Access |
|---|---|---|
| `/` | Home | Public |
| `/explore` | Pick your path | Public |
| `/plans` | Choose your plan | Public |
| `/checkout` | Payment (UPI or cash) | Member (redirect to `/login?next=/checkout`) |
| `/checkout/submitted` | Request submitted | Member |
| `/login` | Login | Public |
| `/register` | Create account | Public |
| `/forgot-password` | Reset password | Public |
| `/account` | Member dashboard (My membership) | Member |
| `/account/classes` | Online classes list | Member |
| `/account/classes/:id` | Class player | Member with active membership |
| `/account/payments` | Payment history | Member |
| `/account/profile` | Profile | Member |
| `/admin` | Admin dashboard | Admin |
| `/admin/payments` | Pending and past payments | Admin |
| `/admin/members` | Members list | Admin |
| `/admin/members/:uid` | Member detail | Admin |
| `/admin/plans` | Plans and prices | Admin |
| `/admin/classes` | Online classes | Admin |
| `/admin/announcements` | Announcements | Admin |
| `/admin/settings` | Gym settings | Admin |
| `/privacy`, `/terms`, `/refund-policy` | Legal pages | Public |
| any other | 404 page with "Back to home" | Public |

Route guards in `go_router` `redirect`: not logged in → `/login?next=…`; logged in but not admin on `/admin/*` → `/account`.

Header (web and tablet): logo, Home, Plans, Online classes, Supplements (Soon), Clothes (Soon), then **Login** + **Register now** when logged out, or **My account** (+ **Admin** for admins) when logged in.

---

## 7. Feature requirements

Each requirement has an ID. Acceptance criteria are written as "Given / When / Then" or as checks.

### 7.1 Home (`/`) — public
Content in this order (same text as the designs):
1. Hero: label "GYM MEMBERSHIP"; headline "STRONGER THAN YESTERDAY" ("YESTERDAY" in red); line "Train hard. Stay focused. Be strong."; buttons **Start your fitness journey** → `/explore` and **Register now** → `/plans`; badge "7 days personal training FREE — With every new membership".
2. Ticker band (web/tablet only).
3. "Why NH Fitness": 4 cards — Modern equipment, Expert trainers, Diet consultation, Clean and hygienic (photo + icon + title).
4. "Gym membership": one card per active plan from Firestore (name, price, per-month price, "Choose plan"). Best-value plan uses the red card style. Clicking goes to `/plans?plan={id}`. Below: Registration charge, 7 days PT free, Personal training charge — all values from `settings/app`.
5. "Pick your path" (same as `/explore`).
6. Offer band "7 DAYS PERSONAL TRAINING FREE!" + Register now.
7. Footer: logo, "Thank you!", links, address, timings, phone, email, Instagram (from `settings/app`), "BE FIT. BE STRONG. BE YOU.", legal links.

If an announcement is active (§7.9), show it as a dismissible strip above the hero.

**HOME-1** Prices and plan list come from Firestore, never hard-coded.
**HOME-2** If Firestore cannot be reached, show the layout with a "Prices could not load. Try again." message and a Retry button.

On mobile (< 600 px) Home follows the mobile sample: logo, hero text, 4 feature tiles in a 2×2 grid, offer badge, the two buttons at the bottom. Plans and paths are on their own screens.

### 7.2 Explore (`/explore`) — public
Cards: **Membership plans** (big red card, "7 days PT free" tag, "From ₹{lowest monthly-equivalent price} a month") → `/plans`; **Online classes** → `/account/classes` (asks to log in if needed); **Supplements** and **Clothes** shown as Coming soon (tap shows a toast "Coming soon").

**EXP-1** Supplements and Clothes read `settings/app.supplementsEnabled` and `clothesEnabled`. While `false`, they show Coming soon. (In Phase 1 both are always false; the flags exist for later.)

### 7.3 Plans (`/plans`) — public
- Plan picker cards (2×2 grid), Yearly selected by default, or the plan in `?plan=`.
- Each card: name, price, per-month price (`price / months`, rounded to the rupee) or "Pay as you go" for 1 month, "Best value" tag where `isBestValue`.
- Add-on toggle: "Add personal training — ₹{ptFee} — First {ptFreeDays} days free".
- Order summary: plan price, registration charge (only if the user has never joined, see PLAN-3), personal training (if selected), **Total**.
- Button **Continue to payment** → `/checkout` with the selection kept in state (and in the URL query so a refresh keeps it).

**PLAN-1** Total = plan price + registration fee (if applicable) + PT fee (if selected). The total animates to the new value.
**PLAN-2** Plans with `active == false` are hidden. Order by `sortOrder`.
**PLAN-3** Registration fee is charged only on a member's **first** membership (`users/{uid}.hasJoined == false`). For a visitor (not logged in) show it, with the note "One-time, for new members".
**PLAN-4** "7 days personal training free" is shown to new members only (`hasJoined == false`).

### 7.4 Checkout and payment (`/checkout`) — member
Phase 1 payment methods (this **replaces** the UPI / Card / Net banking buttons in the mobile sample):
- **UPI** (default)
- **Pay at gym (cash)**
- Card and Net banking: shown disabled with the label "Coming soon" (Phase 2).

**UPI flow:**
1. Show the total and a QR code generated from
   `upi://pay?pa={upiId}&pn={upiName}&am={total}&cu=INR&tn=NH Fitness {planName}`
   using `settings/app.upiId` and `upiName`.
2. Show the UPI ID as text with a **Copy** button.
3. On Android, also show **Pay with UPI app** which opens the same `upi://` link with `url_launcher` (hide this on web and iOS if it cannot be opened).
4. Field: **UPI reference number (UTR)** — exactly 12 digits, required.
5. Button **I have paid ₹{total}** → creates a `paymentRequests` document with `status: "pending"`, then goes to `/checkout/submitted`.

**Cash flow:**
1. Text: "Pay ₹{total} at the gym reception. Your plan starts when the gym confirms payment."
2. Button **Submit request** → creates a `paymentRequests` document with `method: "cash"`, `upiRef: null`, `status: "pending"`.

**Submitted screen:** red check animation, "Request sent", "The gym will check your payment and activate your plan. This usually takes [time set by gym].", buttons **Go to my account** and **Back to home**.

**PAY-1** A member can have only one pending request at a time. If one exists, `/plans` and `/checkout` show "You already have a request waiting for approval" with a link to `/account`.
**PAY-2** The request stores the exact prices at the moment of submission (plan price, registration fee, PT fee, total). The security rules (§9) reject a request whose prices do not match Firestore.
**PAY-3** UTR must be 12 digits. Show the error "Enter the 12-digit UPI reference number from your payment app" otherwise.
**PAY-4** The checkout page shows the note "Sample payment flow: we never ask for your UPI PIN" — the app must never ask for a PIN, card number or bank password.
**PAY-5** If the user is not logged in, `/checkout` redirects to login and returns to checkout with the same selection.

### 7.5 Login and registration — public
- **Register:** name, email, phone (10 digits, optional but recommended), password (min 8 characters), confirm password, checkbox "I agree to the Terms and Privacy Policy" (required). Or **Continue with Google**.
- **Login:** email + password, or Google. Link to Forgot password.
- **Forgot password:** email → Firebase password reset email.
- After register/login: go to `next` query param if present, else `/account`.
- On first login (any method), create `users/{uid}` if it does not exist (see §8).
- Errors are shown in plain words (wrong password, email already used, no internet).
- Small note on login: "Phone OTP login coming soon".

**AUTH-1** Email verification: send a verification email on register; show a banner "Verify your email" in the account area until verified. Do not block use in Phase 1.
**AUTH-2** Logout is in the profile screen and in the web account side menu.

### 7.6 Member dashboard (`/account`) — member
Shows (matches "My membership" in the website wireframe):
1. Greeting "Hi, {first name}".
2. **Membership card**:
   - Active: plan name, "Active" pill, start date, valid-till date, progress bar of time used, **days left**, "Renew plan" button.
   - Pending request: "Waiting for approval" with plan, amount, method, date submitted.
   - Rejected (latest request): "Payment not approved" + admin's reason + "Try again".
   - No membership: "You don't have a plan yet" + "Choose a plan".
   - Expired: "Your plan ended on {date}" + "Renew plan".
3. **Expiry banner** when 7 days or fewer are left: "Your plan ends in {n} days. Renew now."
4. **Free personal training** card for new members: "{ptFreeDays - ptFreeDaysUsed} of {ptFreeDays} free days left".
5. Online classes preview (3 latest) → `/account/classes`.
6. Payment history preview (last 3) → `/account/payments`.

**ACC-1** Days left = whole days from today (gym's local date, Asia/Kolkata) to `endDate`, inclusive of the end date. Never negative.
**ACC-2** Status is derived on the client: active if `startDate <= today <= endDate`; upcoming if `startDate > today`; expired if `endDate < today`.

### 7.7 Online classes — member
- `/account/classes`: grid of published classes (thumbnail, title, category, duration). Filter chips by category.
- `/account/classes/:id`: YouTube player, title, description.
- **CLS-1** Only members with an active membership can open classes (enforced by rules, §9). Others see "Online classes are for active members" + "Choose a plan".
- **CLS-2** Classes use unlisted YouTube links. (Known limit: anyone with the link can watch. Accept for Phase 1.)

### 7.8 Payment history and profile — member
- `/account/payments`: list of the member's payment requests, newest first: date, plan, total, method, status pill, UTR, rejection reason if any. Paginate 20 per page.
- `/account/profile`: edit name and phone; show email (read-only); change password (email users); logout.

### 7.9 Announcements — member and public
- Admin creates announcements (title, message, active, optional end date).
- Active announcements show as a strip at the top of Home and the account dashboard. Dismissing hides it on that device (local storage).

### 7.10 Admin panel (`/admin/*`) — admin
Layout: side menu on web/tablet (Dashboard, Pending payments (badge count), Members, Plans and prices, Online classes, Announcements, Settings, Back to site, Log out); a drawer on mobile.

**Dashboard (`/admin`)**
- Tiles: Active members, Expiring in next 7 days, Pending approvals, Income this month (sum of `total` of approved requests with `reviewedAt` in the current month).
- List: pending requests (top 5) with Approve/Reject.
- List: memberships expiring in the next 7 days (member name, plan, end date, phone with copy button).

**Payments (`/admin/payments`)**
- Tabs: Pending, Approved, Rejected. Newest first, 20 per page.
- Row: member name, phone, plan, add-on, total, method, UTR, submitted date.
- **Duplicate UTR warning:** if another request has the same `upiRef`, show a red "UTR already used" warning on the row.
- **Approve** opens a confirm sheet showing the start date (default per ADM-2, editable) and end date (computed), then does the batch write in ADM-1.
- **Reject** asks for a reason (required, e.g. "Payment not received") and sets `status: "rejected"`.

**ADM-1 Approval** is one Firestore batch:
1. Update the request: `status: "approved"`, `reviewedAt`, `reviewedBy`, `membershipId`.
2. Create `memberships/{id}` with `uid`, plan details, `startDate`, `endDate`, `withPT`, `paymentRequestId`.
3. Update `users/{uid}`: `activeUntil` = the later of the existing `activeUntil` and the new `endDate`; `hasJoined: true`; `currentMembershipId`.

**ADM-2 Start date rule:** if the member has a membership that ends today or later, the new one starts the day after it ends (renewal stacks). Otherwise it starts on the approval date. `endDate = startDate + months − 1 day`.
**ADM-3** Approve and Reject are only possible on `pending` requests.

**Members (`/admin/members`)**
- Search by name, email or phone. Filter: All, Active, Expiring soon, Expired, Never joined.
- Row: name, phone, plan, valid till, status pill.
- **Record cash payment** button (for a registered member who paid at the desk): pick the member, plan, add-on → creates an approved request + membership in one batch with `method: "cash"` and `createdBy: admin`.

**Member detail (`/admin/members/:uid`)**
- Profile, all memberships, all payment requests.
- Free PT days: "+1 day used" / "−1" buttons updating `ptFreeDaysUsed` (0 to `ptFreeDays`).
- Edit a membership's end date (with a confirm step) for corrections.

**Plans and prices (`/admin/plans`)**
- Edit name, months, price, best-value flag, sort order, active on/off. Add a new plan.
- Plans are never deleted, only made inactive (old payment records point to them).
- If no plans exist, show **Create default plans** which writes the defaults in §8.2.

**Online classes (`/admin/classes`)**
- Create/edit: title, description, category, duration (minutes), YouTube URL, thumbnail URL (default: the YouTube thumbnail), published on/off, sort order. Preview before saving.

**Announcements (`/admin/announcements`)** — create, edit, turn on/off.

**Settings (`/admin/settings`)** — registration fee, PT fee, PT free days, UPI ID, UPI name, approval time text, gym address, timings, phone, email, Instagram URL, supplements/clothes enabled flags.

**ADM-4** Every admin write stores `updatedAt` and `updatedBy`.
**ADM-5** The admin panel works on mobile too, but is designed for web first.

### 7.11 Legal pages
`/privacy`, `/terms`, `/refund-policy` with placeholder text marked `[TO BE WRITTEN BY GYM]`. They must exist before publishing to the app stores. The privacy page must list what data is stored (name, email, phone, payment records, UTR) and how to ask for deletion.

---

## 8. Data model (Cloud Firestore)

All timestamps are Firestore `Timestamp`. Dates that represent a calendar day (`startDate`, `endDate`) are stored as a Timestamp at **00:00 Asia/Kolkata** of that day. Money is stored as **whole rupees (int)**.

### 8.1 Collections

**`users/{uid}`**
| Field | Type | Written by | Notes |
|---|---|---|---|
| name | string | member | |
| email | string | member (on create) | |
| phone | string? | member | 10 digits |
| createdAt | timestamp | member (on create) | |
| hasJoined | bool | admin only | false until first approval |
| activeUntil | timestamp? | admin only | end of latest membership; used by rules for classes |
| currentMembershipId | string? | admin only | |
| ptFreeDaysUsed | int | admin only | starts 0 |
| updatedAt | timestamp | any writer | |

**`admins/{uid}`** — created by hand in the Console: `{ name: string, addedAt: timestamp }`.

**`plans/{planId}`** — `name`, `months` (int), `price` (int), `sortOrder` (int), `isBestValue` (bool), `active` (bool), `updatedAt`, `updatedBy`.

**`settings/app`** (single document) — `registrationFee`, `ptFee`, `ptFreeDays`, `upiId`, `upiName`, `approvalTimeText`, `address`, `timings`, `phone`, `email`, `instagramUrl`, `supplementsEnabled`, `clothesEnabled`, `updatedAt`, `updatedBy`.

**`paymentRequests/{id}`**
| Field | Type | Notes |
|---|---|---|
| uid | string | member who paid |
| userName, userPhone | string | copied at submit, for the admin list |
| planId, planName | string | |
| months | int | |
| planPrice | int | must equal `plans/{planId}.price` |
| registrationFee | int | 0 or `settings/app.registrationFee` |
| ptFee | int | 0 or `settings/app.ptFee` |
| withPT | bool | |
| total | int | = planPrice + registrationFee + ptFee |
| method | `"upi"` \| `"cash"` | |
| upiRef | string? | 12 digits for UPI, null for cash |
| status | `"pending"` \| `"approved"` \| `"rejected"` | |
| rejectReason | string? | |
| membershipId | string? | set on approval |
| createdAt | timestamp | |
| reviewedAt, reviewedBy | timestamp?, string? | |
| createdBy | string | uid of creator (member, or admin for desk cash) |

**`memberships/{id}`** — `uid`, `planId`, `planName`, `months`, `withPT`, `startDate`, `endDate`, `paymentRequestId`, `createdAt`, `createdBy`, `updatedAt`.

**`classes/{id}`** — `title`, `description`, `category`, `durationMin`, `youtubeUrl`, `thumbnailUrl`, `published`, `sortOrder`, `createdAt`, `updatedAt`.

**`announcements/{id}`** — `title`, `message`, `active`, `endsAt?`, `createdAt`, `updatedAt`.

### 8.2 Default data (seed)

`plans`:
| id | name | months | price | sortOrder | isBestValue | active |
|---|---|---|---|---|---|---|
| monthly | Monthly | 1 | 1500 | 1 | false | true |
| quarterly | Quarterly | 3 | 4000 | 2 | false | true |
| half_yearly | Half yearly | 6 | 7800 | 3 | false | true |
| yearly | Yearly | 12 | 15000 | 4 | true | true |

`settings/app`: `registrationFee: 500`, `ptFee: 5000`, `ptFreeDays: 7`, `upiId: "[GYM UPI ID]"`, `upiName: "NH Fitness"`, `approvalTimeText: "within a few hours during gym timings"`, `address`, `timings`, `phone`, `email`, `instagramUrl` = `"[TO BE FILLED]"`, `supplementsEnabled: false`, `clothesEnabled: false`.

Seed through the admin panel's **Create default plans** button (§7.10), or by hand in the Console.

---

## 9. Firestore security rules

Put this in `firestore.rules` in the repo and publish it in the Console. Claude Code must also write tests for these rules with the Firebase Emulator (`@firebase/rules-unit-testing`) covering every allow/deny case listed under each match.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function isAdmin() {
      return signedIn() && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    function isSelf(uid) { return signedIn() && request.auth.uid == uid; }
    function settings() { return get(/databases/$(database)/documents/settings/app).data; }
    function userDoc() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data; }
    function isActiveMember() {
      return signedIn()
        && exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && userDoc().get('activeUntil', null) != null
        && userDoc().activeUntil > request.time;
    }

    // Admin list: only created by hand in the Console.
    match /admins/{uid} {
      allow read: if isSelf(uid) || isAdmin();
      allow write: if false;
    }

    match /users/{uid} {
      allow read: if isSelf(uid) || isAdmin();
      // Member creates own profile; admin-only fields must start at safe values.
      allow create: if isSelf(uid)
        && request.resource.data.keys().hasOnly(['name','email','phone','createdAt','hasJoined','ptFreeDaysUsed','updatedAt'])
        && request.resource.data.hasJoined == false
        && request.resource.data.ptFreeDaysUsed == 0;
      // Member may only change name, phone, updatedAt. Admin may change anything.
      allow update: if isAdmin()
        || (isSelf(uid) && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['name','phone','updatedAt']));
      allow delete: if false;
    }

    match /plans/{planId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /settings/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /paymentRequests/{id} {
      allow read: if isAdmin() || (signedIn() && resource.data.uid == request.auth.uid);

      // Member submits a pending request with prices that match Firestore.
      allow create: if isAdmin() || (
        signedIn()
        && request.resource.data.uid == request.auth.uid
        && request.resource.data.createdBy == request.auth.uid
        && request.resource.data.status == 'pending'
        && request.resource.data.method in ['upi', 'cash']
        && (request.resource.data.method == 'cash'
            || (request.resource.data.upiRef is string && request.resource.data.upiRef.matches('^[0-9]{12}$')))
        && request.resource.data.planPrice == get(/databases/$(database)/documents/plans/$(request.resource.data.planId)).data.price
        && get(/databases/$(database)/documents/plans/$(request.resource.data.planId)).data.active == true
        && request.resource.data.registrationFee in [0, settings().registrationFee]
        && (userDoc().hasJoined == false || request.resource.data.registrationFee == 0)
        && request.resource.data.ptFee == (request.resource.data.withPT ? settings().ptFee : 0)
        && request.resource.data.total == request.resource.data.planPrice + request.resource.data.registrationFee + request.resource.data.ptFee
        && !('membershipId' in request.resource.data)
        && !('reviewedBy' in request.resource.data)
      );
      allow update, delete: if isAdmin();
    }

    match /memberships/{id} {
      allow read: if isAdmin() || (signedIn() && resource.data.uid == request.auth.uid);
      allow write: if isAdmin();
    }

    match /classes/{id} {
      // Queries from members must include where('published', '==', true).
      allow read: if isAdmin() || (isActiveMember() && resource.data.published == true);
      allow write: if isAdmin();
    }

    match /announcements/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

Notes:
- "One pending request at a time" (PAY-1) is enforced in the app, not in rules. The admin sees duplicates anyway.
- Rules cannot stop a member from submitting a fake UTR. That is why a human approves every payment.

---

## 10. Firestore indexes

Create these composite indexes (also save them in `firestore.indexes.json`):

| Collection | Fields |
|---|---|
| paymentRequests | `status` ASC, `createdAt` DESC |
| paymentRequests | `uid` ASC, `createdAt` DESC |
| paymentRequests | `upiRef` ASC, `createdAt` DESC |
| paymentRequests | `status` ASC, `reviewedAt` DESC |
| memberships | `uid` ASC, `endDate` DESC |
| classes | `published` ASC, `sortOrder` ASC |
| plans | `active` ASC, `sortOrder` ASC |

The expiring-soon list queries `memberships` by `endDate` range only (single-field index, automatic).

---

## 11. Key flows (end to end)

**New member joins (UPI)**
1. Visitor opens Home → Start your fitness journey → Explore → Membership plans.
2. Picks Yearly, adds PT → total ₹15,000 + ₹500 + ₹5,000 = ₹20,500.
3. Continue to payment → asked to log in → registers with email.
4. Back on checkout → scans QR, pays ₹20,500 in their UPI app → enters 12-digit UTR → I have paid.
5. Request saved as pending → Submitted screen → Account shows "Waiting for approval".
6. Admin opens Pending payments → checks the bank/UPI app for ₹20,500 with that UTR → Approve.
7. Member's account now shows Yearly, Active, valid till date, 365 days left, 7 free PT days, and classes unlock.

**Renewal:** member with plan ending 10 Jan renews on 5 Jan → after approval the new plan starts 11 Jan (ADM-2). No registration fee (PLAN-3).

**Rejected payment:** admin rejects with reason → member sees "Payment not approved: {reason}" and **Try again** (pre-filled checkout).

**Cash at desk:** admin → Members → Record cash payment → membership active immediately.

**Expiry:** 7 days before `endDate` the member sees the renew banner; the admin dashboard lists them with phone numbers to call.

---

## 12. Website hosting (owner's own hosting)

1. Build: `flutter build web --release` (base href `/`).
2. Add this `.htaccess` in `web/` so it is copied into `build/web/` (needed for path URLs like `/plans` on Apache/cPanel hosting):
   ```
   RewriteEngine On
   RewriteBase /
   RewriteRule ^index\.html$ - [L]
   RewriteCond %{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_FILENAME} !-d
   RewriteRule . /index.html [L]
   ```
3. Upload everything inside `build/web/` to `public_html/` (or the domain's folder) with the hosting file manager or FTP.
4. Make sure HTTPS is on for the domain.
5. Add the domain in Firebase Auth → Authorized domains (§4 step 3).
6. Set the page title, meta description and social preview image in `web/index.html` (title "NH Fitness — Gym membership", description from the hero text).

Known limit: a Flutter website is not well indexed by Google. If ranking for "gym near me" matters later, add a Google Business Profile and, if needed, a small static landing page.

---

## 13. Non-functional requirements

- **Performance:** first load of Home under 4 s on a 4G phone. Use `--web-renderer` default (CanvasKit/auto) and keep images under 300 KB (use `w=` size params on image URLs).
- **Firestore usage (free plan):** paginate all lists (20 per page); never listen to whole collections in real time except the admin pending list and the member's own requests; cache `plans` and `settings` in memory for the session.
- **Offline:** Firestore offline cache on mobile is on by default; show a "You are offline" bar when there is no connection.
- **Accessibility:** text contrast at least 4.5:1, touch targets 44×44, every image and icon button has a label, works with keyboard on web (visible focus ring in yellow).
- **Localization:** English only in Phase 1; all strings in one file (`lib/l10n/` with ARB) so Hindi can be added later. Currency always `₹` with Indian grouping.
- **Time zone:** all date logic uses Asia/Kolkata.
- **Privacy:** store only what is listed in §8. No UPI PIN, card or bank details are ever collected. Follow India's DPDP Act basics: clear privacy policy, consent checkbox at sign-up, ability to request deletion (Phase 1: by email to the gym; admin deletes by hand).
- **Security:** no secrets in the repo; rules in §9 are the security boundary; admin access only via `admins/{uid}`.
- **Error handling:** every screen has loading, empty and error states. Errors say what happened and what to do.

---

## 14. Project structure (Flutter)

```
lib/
  main.dart
  firebase_options.dart          (generated by flutterfire)
  app/router.dart                 (go_router + guards)
  app/theme.dart                  (colors, text styles from §5)
  core/assets.dart                (all image URLs)
  core/format.dart                (₹ formatting, dates in Asia/Kolkata)
  core/widgets/                   (buttons, cards, pills, logo, animations)
  features/
    home/  explore/  plans/  checkout/
    auth/  account/  classes/  announcements/
    admin/ (dashboard, payments, members, plans, classes, announcements, settings)
  data/
    models/                       (User, Plan, Settings, PaymentRequest, Membership, ClassItem, Announcement)
    repositories/                 (one per collection; the only place that talks to Firestore)
  l10n/
test/                             (unit + widget tests)
firestore.rules
firestore.indexes.json
rules-test/                       (emulator tests for rules)
design/                           (the two reference HTML files)
web/.htaccess
```

---

## 15. Milestones (build in this order)

| # | Milestone | Done when |
|---|---|---|
| M0 | Project setup | Flutter app runs on web and Android; Firebase connected to `nh-fitness-8a972`; theme and fonts in place |
| M1 | Design system and public pages | Home, Explore, Plans match the design files at mobile and desktop widths, with all motion in §5.4; plans/settings read from Firestore |
| M2 | Auth | Register, login (email + Google), forgot password, logout; `users/{uid}` created on first login; guards work |
| M3 | Checkout | UPI QR, copy UPI ID, UTR validation, cash option, pending request saved; rules reject wrong prices |
| M4 | Member area | Dashboard states (none, pending, active, rejected, expired), days left, payment history, profile |
| M5 | Admin core | Admin guard, dashboard tiles, pending payments approve/reject (batch), members list and detail, record cash, plans and settings editing, seed defaults |
| M6 | Classes and announcements | Admin CRUD; member list/player; locked for non-active members |
| M7 | Rules tests and polish | All rules tests pass in the emulator; loading/empty/error states; accessibility pass |
| M8 | Web launch | Built and uploaded to the owner's hosting with `.htaccess`; domain authorized in Firebase |
| M9 | Android release | Signed release build; SHA-1 added; Play Store listing (needs Play Console account) |
| M10 | iOS release | Needs Apple Developer account and a Mac with Xcode |

---

## 16. Phase 2 (later, needs Firebase Blaze plan)

- Razorpay checkout (UPI, card, net banking) with order creation and signature verification in Cloud Functions; auto-activate membership on verified payment.
- Phone OTP login.
- Push notifications (FCM) for approval, rejection and expiry reminders, sent by a scheduled Cloud Function.
- Firebase Storage for gym photos and class thumbnails uploaded from the admin panel.
- Supplements and clothes store.
- Attendance with QR check-in at the gym.

---

## 17. Open questions (defaults used until answered)

| Question | Default in this PRD |
|---|---|
| Is the registration fee charged only once, or on every renewal? | Once (first membership only) |
| How long does the ₹5,000 personal training last (1 month? same as plan?) | Shown as a one-time add-on; duration `[CONFIRM]` |
| Do the 7 free PT days apply to every new member, or only with certain plans? | Every new member |
| Should walk-in members without the app be recorded? | No; they register on the app (staff can help), then admin records cash |
| Gym UPI ID, address, timings, phone, email, Instagram | Placeholders; admin fills them in Settings |
| Real logo file and gym photos | Text logo and free stock photos until provided |
| Who are the admins (emails)? | Owner adds them in the Console |

---

## 18. How to use this PRD with Claude Code

1. Create an empty folder, put `PRD.md` in it and the two design files in `design/`.
2. Start Claude Code in that folder and give it this first message:

> Read PRD.md and the files in /design. Build the NH Fitness Flutter app (web, Android, iOS) exactly as specified, milestone by milestone starting with M0. Firebase project ID is nh-fitness-8a972. Ask me before deviating from the PRD. After each milestone, run the app on web, run the tests, and summarise what was done and what I need to do in the Firebase Console.

3. After M2, create your admin: log in once on the app, copy your UID from Firebase Console → Authentication, then in Firestore create document `admins/{your UID}` with `name` and `addedAt`.
