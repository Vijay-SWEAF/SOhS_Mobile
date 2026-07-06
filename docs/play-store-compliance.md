# SOhS Mobile Play Store Compliance Checklist

Last reviewed: 2026-07-04

This checklist is based on the current SOhS Mobile codebase and Google Play's Data safety guidance. It is an engineering checklist, not legal advice. Keep the Play Console answers aligned with the actual app behavior on every release.

## Current App Facts

- Package name: `biz.sweaf.sohs`
- App name: `SOhS`
- Current release version: `versionCode 4`, `versionName "1.0.2"`
- Current Android permissions: `INTERNET`, `POST_NOTIFICATIONS`
- No mobile login, account creation, ads, server push notifications, camera, microphone, contacts, precise location, payment, or analytics SDK.
- The app can request notification permission after the second launch to schedule a local daily reminder at 9:00 AM device time. This is not a server push service and does not collect additional user data.
- The daily word puzzle is generated in-app from the active question and saves completion progress locally on the device only. It does not send puzzle progress or scores to the backend.
- Country chips show vote counts for low-sample countries and only show percentages once a country has enough votes for the percentage to be meaningful.
- Public policy links exposed in-app:
  - Privacy: `https://www.societyofhomosapiens.org/privacy/`
  - Terms: `https://www.societyofhomosapiens.org/terms/`
  - About: `https://www.societyofhomosapiens.org/about/`
  - Support: `https://www.societyofhomosapiens.org/support/`
  - Corrections: `https://www.societyofhomosapiens.org/correction-policy/`
- Direct support email exposed in-app: `sohs@societyofhomosapiens.org`
- Release AAB path after Phase 10A: `android/app/build/outputs/bundle/release/app-release.aab`

## Google Play Setup

### Privacy Policy

Use this URL in Play Console:

```text
https://www.societyofhomosapiens.org/privacy/
```

Before production rollout, confirm the web privacy policy explicitly covers the mobile app behavior:

- Anonymous mobile voting.
- Anonymous app/device UUID used to prevent duplicate votes.
- Country-level signal inferred from locale/timezone when available.
- Backend/database service provider.
- User support/deletion requests through `sohs@societyofhomosapiens.org`.

### App Access

Suggested answer:

```text
All functionality is available without login or special access.
```

The app has no account gate and no test credentials are needed.

### Ads

Suggested answer:

```text
No, this app does not contain ads.
```

No ad SDK is present.

### App Category

Suggested category:

```text
Education
```

Alternative if Play Console fit is better later: `Social`. For MVP, `Education` is cleaner because the app is a daily civic/moral question experience, not a chat network.

### Target Audience

Suggested answer:

```text
Not designed for children.
```

Set intended age group to adults/older teens as appropriate in Play Console. Do not opt into Families.

## Data Safety Answers

Google defines "collect" as transmitting data off the user's device. Pseudonymous data that can reasonably be re-associated with a user/app instance still needs disclosure. Use the conservative answers below.

### Data Collection And Security

Question: Does the app collect or share user data?

```text
Yes
```

Question: Is all user data collected by the app encrypted in transit?

```text
Yes
```

Reason: Backend and SOhS website calls use HTTPS/WSS.

Question: Do you provide a way for users to request data deletion?

```text
Yes
```

Mechanism:

```text
sohs@societyofhomosapiens.org
```

Operational note: App votes are anonymous and tied to an app-generated UUID. If a user requests deletion, they may need to provide enough context to locate the relevant anonymous vote record. If you are not ready to process deletion requests operationally, answer `No` until a process is ready.

### Data Types To Declare

#### Device Or Other IDs

Select:

```text
Device or other IDs
```

Why:

- The app generates and stores an anonymous UUID in Capacitor Preferences.
- The UUID is sent to the backend vote function to prevent duplicate votes per question.
- This is not the Android advertising ID, IMEI, MAC address, or hardware identifier.

Collection:

```text
Collected
```

Sharing:

```text
Not shared
```

Reason: The backend provider acts as a service provider for SOhS. No advertising or third-party profiling use is present.

Processed ephemerally:

```text
No
```

Required or optional:

```text
Required
```

Purpose:

```text
App functionality
Fraud prevention, security, and compliance
```

Linked to user:

```text
No, not linked to a signed-in identity. It is linked to an anonymous app install/vote record.
```

#### Approximate Location

Select:

```text
Approximate location
```

Why:

- The app infers a country code from timezone/locale when available.
- The app does not request Android location permission.
- The app does not collect GPS, precise location, city, street, or coordinates.

Collection:

```text
Collected
```

Sharing:

```text
Not shared
```

Processed ephemerally:

```text
No
```

Required or optional:

```text
Required
```

Purpose:

```text
App functionality
Analytics
```

Reason: Country-level counts power the public country chips and website/mobile pulse aggregates.

Linked to user:

```text
No, not linked to a signed-in identity. It may be stored with the anonymous app vote record.
```

#### App Activity

Select:

```text
App activity > Other actions
```

Why:

- A user's selected answer option is sent to the backend when they vote.
- The data is used to produce aggregate vote percentages and duplicate-vote protection.

Do not select `App interactions` unless the app later starts collecting general taps/page visits. The current app does not send page views, session counts, or generic interaction analytics.

Collection:

```text
Collected
```

Sharing:

```text
Not shared
```

Processed ephemerally:

```text
No
```

Required or optional:

```text
Required for voting/reveal functionality.
```

Purpose:

```text
App functionality
Analytics
Fraud prevention, security, and compliance
```

Linked to user:

```text
No, not linked to a signed-in identity. It is associated with the anonymous app/device UUID.
```

### Data Types Not Collected In The Mobile App

Do not select these for the current mobile app:

- Name
- Email address
- Phone number
- Address
- User payment info
- Purchase history
- Health info
- Fitness info
- Messages
- Photos or videos
- Audio files
- Files and docs
- Calendar
- Contacts
- Installed apps
- Web browsing history
- Crash logs
- Diagnostics
- Precise location

Notes:

- The generated share PNG is created by the app and saved in app cache for user-initiated sharing. It is not collected by SOhS from the user.
- Native share is user-initiated. The user chooses whether to send the generated image to another app.
- Website links open public SOhS pages. If users browse the open web, that is not mobile-app controlled collection.

## Third-Party Services And SDKs

### Backend Database Service

Used for:

- Loading daily questions.
- Reading aggregate vote counts.
- Submitting votes via `cast_vote()`.
- Reading country-level aggregate counts.

Data sent:

- App daily question UUID.
- Anonymous app/device UUID.
- Selected option index.
- Country code when available.

### Capacitor Plugins

Used plugins:

- `@capacitor/preferences`: local anonymous UUID and local vote flags.
- `@capacitor/browser`: opens SOhS public policy/discussion URLs.
- `@capacitor/filesystem`: writes generated share PNG to app cache.
- `@capacitor/share`: opens native share sheet for user-initiated sharing.
- `@capacitor/haptics`: tap/reveal feedback only.
- `@capacitor/local-notifications`: schedules an optional local daily reminder after the user allows notifications.

The app manifest requests `INTERNET` for backend/website access and `POST_NOTIFICATIONS` for the optional local daily reminder on Android 13+.

## Store Listing Copy Draft

Short description:

```text
Answer one daily moral question and see how humanity thinks.
```

Full description draft:

```text
SOhS Mobile gives you one daily civic or moral question. Vote anonymously, reveal the global result, compare country-level signals, and open the full discussion on Society Of homoSapiens.

The app has no login, no ads, and no follower system. It is built for clear thinking, respectful disagreement, and daily reflection.

Support and feedback: sohs@societyofhomosapiens.org
```

## Release Checklist Before Upload

- [x] Privacy/Terms/Support links are visible in the mobile app.
- [x] Release signing is configured without committing keystore secrets.
- [x] Signed release AAB can be built.
- [x] Android manifest requests only `INTERNET` and `POST_NOTIFICATIONS`.
- [ ] Confirm web support page visibly lists `sohs@societyofhomosapiens.org`.
- [ ] Confirm web privacy policy includes mobile app voting data.
- [ ] Upload `android/app/build/outputs/bundle/release/app-release.aab` to an internal testing track.
- [ ] Complete Play Console App content forms:
  - Privacy policy.
  - Data Safety.
  - Ads.
  - App access.
  - Target audience and content.
  - Content rating.
- [ ] Run final internal test on Vivo after Play internal track install.

## Source References

- Google Play Data safety form guidance: `https://support.google.com/googleplay/android-developer/answer/10787469`
- Google Play Developer Policy Center: `https://play.google/developer-content-policy/`
- Google Play user-facing Data safety explanation: `https://play.google.com/store/apps/editorial?id=mc_data_safety_fcp`
