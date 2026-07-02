-- Privacy-friendly anonymous visitor counting.
-- This stores only a random browser id, the visited path, and a timestamp.
-- It does not store IP addresses, user agents, emails, or personal profile data.

create table public.visitor_events (
	id uuid primary key default gen_random_uuid(),
	anonymous_id text not null check (
		char_length(anonymous_id) between 8 and 128
	),
	path text not null check (
		path like '/%'
		and char_length(path) <= 512
	),
	created_at timestamptz not null default now()
);
comment on table public.visitor_events is 'Privacy-friendly anonymous visit events. No IP address or personal data is stored.';
comment on column public.visitor_events.anonymous_id is 'Random browser id generated client-side and stored in localStorage.';
comment on column public.visitor_events.path is 'Visited path only; query strings are intentionally excluded by the frontend.';
create index visitor_events_created_at_idx on public.visitor_events (created_at desc);
create index visitor_events_anonymous_id_created_at_idx on public.visitor_events (anonymous_id, created_at desc);
create index visitor_events_path_created_at_idx on public.visitor_events (path, created_at desc);
alter table public.visitor_events enable row level security;
revoke all on public.visitor_events from anon, authenticated;
grant insert on public.visitor_events to anon, authenticated;
create policy "visitor_events_public_insert"
on public.visitor_events for insert
to anon, authenticated
with check (
	anonymous_id <> ''
	and path like '/%'
	and char_length(path) <= 512
);
-- Public aggregate only. Raw visitor_events rows remain private by RLS and grants.
create or replace view public.visitor_stats_view as
select
	count(*)::bigint as total_visits,
	count(distinct anonymous_id) filter (
		where created_at >= date_trunc('month', now())
	)::bigint as unique_visitors_this_month
from public.visitor_events;
comment on view public.visitor_stats_view is 'Public aggregate visitor stats. Does not expose raw anonymous ids or paths.';
grant select on public.visitor_stats_view to anon, authenticated;
