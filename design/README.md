# Design references

`PRD.md` expects two HTML reference files in this folder:

- `nh-fitness-website-wireframe.html` — the desktop layout, sections and
  animations
- `nh-fitness-app-sample-v1.html` — the mobile layout, sections and animations

**Neither file was present when the app was built.** The implementation
therefore follows the written specification in the PRD instead:

| What | Where it came from |
|---|---|
| Colours | PRD section 5.1 → `lib/app/theme.dart` (`NHColors`) |
| Type | PRD section 5.2 → `lib/app/theme.dart` (`NHText`) |
| Components | PRD section 5.3 → `lib/core/widgets/` |
| Motion | PRD section 5.4 → `lib/core/motion.dart` |
| Breakpoints | PRD section 5.5 → `lib/core/responsive.dart` |
| Images | PRD section 5.6 → `lib/core/assets.dart` |
| Page content and order | PRD sections 7.1–7.3 → `lib/features/home/`, `explore/`, `plans/` |

Drop the two files in here and compare them against the running app. Where they
differ from the PRD, **the PRD wins** (PRD page 1) — with one difference already
settled in the PRD's favour:

> **Payment methods.** The mobile sample shows UPI / Card / Net banking buttons.
> PRD section 7.4 replaces them with **UPI** and **Pay at gym (cash)**, and
> shows Card and Net banking disabled with a "Coming soon" label. That is what
> `lib/features/checkout/checkout_screen.dart` does.

Anything in the design files that the PRD does not describe — exact spacing, a
particular photo crop, a specific easing curve — is worth bringing across once
the files are available.
