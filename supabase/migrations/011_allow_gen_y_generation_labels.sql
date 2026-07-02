-- Allow SOhS to use the public-facing "Gen Y" label while remaining
-- compatible with older rows or deployments that used "Millennial".

alter table public.profiles
drop constraint if exists profiles_generation_check;
alter table public.profiles
add constraint profiles_generation_check
check (
	generation is null
	or generation in ('Gen X', 'Gen Y', 'Millennial', 'Gen Z', 'Prefer not to say')
);
alter table public.human_question_answers
drop constraint if exists human_question_answers_generation_check;
alter table public.human_question_answers
add constraint human_question_answers_generation_check
check (
	generation is null
	or generation in ('Gen X', 'Gen Y', 'Millennial', 'Gen Z', 'Prefer not to say')
);
create or replace function public.submit_human_question_answer(
	question_id uuid,
	vote text,
	explanation text,
	generation text default 'Prefer not to say'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_vote text := lower(btrim(coalesce(vote, '')));
	v_generation text := nullif(btrim(coalesce(generation, 'Prefer not to say')), '');
	v_explanation text;
begin
	if v_user_id is null then
		raise exception 'Authentication is required to answer this question.';
	end if;

	if v_vote not in ('yes', 'no', 'depends') then
		raise exception 'Choose Yes, No, or Depends.';
	end if;

	if v_generation not in ('Gen X', 'Gen Y', 'Millennial', 'Gen Z', 'Prefer not to say') then
		raise exception 'Invalid generation value.';
	end if;

	if not exists (
		select 1
		from public.human_questions as hq
		where hq.id = submit_human_question_answer.question_id and hq.status = 'published'
	) then
		raise exception 'Published question not found.';
	end if;

	v_explanation := public.sohs_require_text(explanation, 'Explanation', 20, 800, 1);

	insert into public.human_question_answers (
		question_id,
		user_id,
		vote,
		explanation,
		generation,
		status
	)
	values (
		submit_human_question_answer.question_id,
		v_user_id,
		v_vote,
		v_explanation,
		v_generation,
		'pending'
	);

	return jsonb_build_object('ok', true);
end;
$$;
comment on function public.submit_human_question_answer(uuid, text, text, text) is
	'Validated authenticated human question answer submission. Forces pending status and accepts Gen Y/Millennial generation labels.';
