-- Harden public approved human question answer access.
--
-- Public pages should display approved answers through the limited
-- get_approved_question_answers RPC only. Direct anonymous table reads expose a
-- broader row shape than the public UI needs, so this migration removes that
-- public table policy while preserving authenticated own-row and moderator/admin
-- policies from the base schema.

drop policy if exists "human_question_answers_public_read_approved" on public.human_question_answers;
-- Extra defense: anonymous visitors should not read the raw UGC table directly.
-- The SECURITY DEFINER RPC below remains executable by anon/authenticated users
-- and returns only the public fields needed by the question page.
revoke select on public.human_question_answers from anon;
create or replace function public.get_approved_question_answers(target_question_id uuid)
returns table (
	id uuid,
	question_id uuid,
	vote text,
	explanation text,
	generation text,
	created_at timestamptz,
	display_name text
)
language sql
stable
security definer
set search_path = public
as $$
	select
		hqa.id,
		hqa.question_id,
		hqa.vote,
		hqa.explanation,
		hqa.generation,
		hqa.created_at,
		coalesce(nullif(btrim(p.display_name), ''), 'SOhS Contributor') as display_name
	from public.human_question_answers as hqa
	join public.human_questions as hq
		on hq.id = hqa.question_id
	left join public.profiles as p
		on p.id = hqa.user_id
	where hqa.question_id = target_question_id
		and hqa.status = 'approved'
		and hq.status = 'published'
	order by hqa.created_at desc
	limit 100;
$$;
revoke all on function public.get_approved_question_answers(uuid) from public;
grant execute on function public.get_approved_question_answers(uuid) to anon, authenticated;
comment on function public.get_approved_question_answers(uuid) is
	'Returns public approved human question answers through a limited RPC. Does not expose emails, user ids, pending content, reports, or moderation metadata.';
create or replace function public.admin_health_check()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_required_tables text[] := array[
		'profiles',
		'categories',
		'articles',
		'article_sources',
		'opinions',
		'opinion_reports',
		'human_questions',
		'human_question_answers',
		'moral_dilemmas',
		'dilemma_options',
		'dilemma_votes',
		'topic_requests',
		'donations',
		'moderation_actions',
		'visitor_events'
	];
	v_required_views text[] := array[
		'visitor_stats_view'
	];
	v_required_functions text[] := array[
		'moderate_item',
		'submit_opinion',
		'submit_human_question_answer',
		'submit_dilemma_vote',
		'submit_topic_request',
		'report_opinion',
		'admin_health_check',
		'get_approved_question_answers'
	];
	v_missing_tables text[];
	v_missing_views text[];
	v_missing_functions text[];
begin
	if auth.uid() is null then
		raise exception 'Authentication is required to run admin health checks.';
	end if;

	if not public.is_moderator_or_admin() then
		raise exception 'Only admins and moderators can run admin health checks.';
	end if;

	select coalesce(array_agg(required_name order by required_name), '{}')
	into v_missing_tables
	from unnest(v_required_tables) as required_name
	where not exists (
		select 1
		from information_schema.tables
		where table_schema = 'public'
			and table_type = 'BASE TABLE'
			and table_name = required_name
	);

	select coalesce(array_agg(required_name order by required_name), '{}')
	into v_missing_views
	from unnest(v_required_views) as required_name
	where not exists (
		select 1
		from information_schema.views
		where table_schema = 'public'
			and table_name = required_name
	);

	select coalesce(array_agg(required_name order by required_name), '{}')
	into v_missing_functions
	from unnest(v_required_functions) as required_name
	where not exists (
		select 1
		from pg_proc p
		join pg_namespace n on n.oid = p.pronamespace
		where n.nspname = 'public'
			and p.proname = required_name
	);

	return jsonb_build_object(
		'ok',
		cardinality(v_missing_tables) = 0
			and cardinality(v_missing_views) = 0
			and cardinality(v_missing_functions) = 0,
		'missing_tables',
		v_missing_tables,
		'missing_views',
		v_missing_views,
		'missing_functions',
		v_missing_functions
	);
end;
$$;
comment on function public.admin_health_check() is
	'Read-only admin/moderator health check for required SOhS tables, views, and RPCs.';
revoke all on function public.admin_health_check() from public;
grant execute on function public.admin_health_check() to authenticated;
