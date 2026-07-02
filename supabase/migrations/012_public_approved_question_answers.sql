-- Public approved human question answers.
-- Pending/rejected/flagged/hidden answers remain private. Public display uses
-- a safe RPC that exposes display names, not email addresses.

drop policy if exists "human_question_answers_public_read_approved" on public.human_question_answers;
create policy "human_question_answers_public_read_approved"
on public.human_question_answers for select
to anon, authenticated
using (
	status = 'approved'
	and exists (
		select 1
		from public.human_questions as hq
		where hq.id = human_question_answers.question_id
			and hq.status = 'published'
	)
);
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
	order by hqa.created_at desc;
$$;
revoke all on function public.get_approved_question_answers(uuid) from public;
grant execute on function public.get_approved_question_answers(uuid) to anon, authenticated;
comment on function public.get_approved_question_answers(uuid) is
	'Returns public approved human question answers with display names only. Does not expose email addresses or pending content.';
