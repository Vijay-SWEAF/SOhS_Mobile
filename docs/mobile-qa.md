# SOhS Mobile QA Checklist

Phase 9A keeps QA repeatable without adding debug UI to the production app.

Android backup is disabled for this app so anonymous device ids and local vote markers are not restored after a QA clear, reinstall, or device transfer.

## Device Prep

Confirm the Vivo is visible:

```bash
adb devices
```

Clear local app data when you need a fresh install state:

```bash
npm run qa:android:reset
```

This clears Capacitor Preferences, including:

- `sohs_device_id`
- `sohs_vote_{app_daily_question_id}`

It does not change Supabase rows.

## Deploy To Device

Use the connected device id when more than one device is attached:

```bash
npm run qa:android:run -- 10BDAQ0XMQ00065
```

Without a target, Capacitor will prompt/select normally:

```bash
npm run qa:android:run
```

## Screenshot Evidence

Capture the current phone screen:

```bash
npm run qa:android:screenshot
```

Or choose the output path:

```bash
npm run qa:android:screenshot -- /private/tmp/sohs_vote_reveal.png
```

## Optional Supabase Vote Reset

Use this only when you need to reset today's app vote counts for QA. Do not delete `app_daily_questions`; that table is the mobile schedule.

```sql
with target_question as (
  select id
  from public.app_daily_questions
  where active_date <= (now() at time zone 'utc')::date
  order by active_date desc
  limit 1
)
delete from public.app_votes
where question_id in (select id from target_question);

with target_question as (
  select id
  from public.app_daily_questions
  where active_date <= (now() at time zone 'utc')::date
  order by active_date desc
  limit 1
)
update public.app_vote_counts
set option0_count = 0,
    option1_count = 0,
    updated_at = now()
where question_id in (select id from target_question);

with target_question as (
  select id
  from public.app_daily_questions
  where active_date <= (now() at time zone 'utc')::date
  order by active_date desc
  limit 1
)
delete from public.app_vote_country_counts
where question_id in (select id from target_question);
```

## Smoke Test

1. Clear local app data.
2. Deploy to Vivo.
3. Confirm today's question opens on the vote screen.
4. Vote once.
5. Confirm the reveal appears and the country chip updates.
6. Try voting again after app restart; it should show the already-counted state.
7. Tap `Read the full discussion on SOhS`.
8. Confirm the website discussion opens.
9. Tap `Share your answer`, then `Share PNG`.
10. Confirm Android share sheet opens with the SOhS image preview.
11. Open the matching website page and confirm `Mobile pulse` reflects the app count.
