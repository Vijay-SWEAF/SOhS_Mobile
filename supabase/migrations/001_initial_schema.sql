-- SOhS initial database schema.
-- Conservative RLS-first design for public reading, authenticated UGC submission,
-- and moderator/admin workflows.

create extension if not exists pgcrypto;
-- Keep updated_at timestamps current.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
	new.updated_at = now();
	return new;
end;
$$;
-- User profile and role metadata. Roles are intentionally limited to user,
-- moderator, and admin.
create table public.profiles (
	id uuid primary key references auth.users(id) on delete cascade,
	display_name text,
	generation text check (generation in ('Gen X', 'Millennial', 'Gen Z', 'Prefer not to say')),
	role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.profiles is 'SOhS user profiles and conservative role metadata.';
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
-- Auth role helpers.
-- These are SECURITY DEFINER so policies can check the current user's role without
-- requiring broad profile read access. Keep search_path fixed for safety.
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
	select coalesce(
		(select role from public.profiles where id = auth.uid()),
		'user'
	);
$$;
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
	select public.current_user_role() = 'admin';
$$;
create or replace function public.is_moderator_or_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
	select public.current_user_role() in ('moderator', 'admin');
$$;
-- Public article taxonomy.
create table public.categories (
	id uuid primary key default gen_random_uuid(),
	name text not null,
	slug text not null unique,
	description text,
	sort_order integer not null default 0,
	is_active boolean not null default true,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.categories is 'Public taxonomy for SOhS knowledge articles and civic themes.';
create trigger set_categories_updated_at
before update on public.categories
for each row execute function public.set_updated_at();
-- Editorial knowledge articles. Only published articles are publicly readable.
create table public.articles (
	id uuid primary key default gen_random_uuid(),
	category_id uuid references public.categories(id) on delete set null,
	author_id uuid references public.profiles(id) on delete set null,
	title text not null,
	slug text not null unique,
	subtitle text,
	summary text not null,
	reality_summary text,
	what_is_happening text,
	what_people_misunderstand text,
	human_impact text,
	ethical_question text,
	different_perspectives text[] not null default '{}',
	action_step text,
	status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
	published_at timestamptz,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.articles is 'Editorial SOhS knowledge articles with draft, published, and archived states.';
create trigger set_articles_updated_at
before update on public.articles
for each row execute function public.set_updated_at();
-- Sources attached to articles. Public can read sources only for published articles.
create table public.article_sources (
	id uuid primary key default gen_random_uuid(),
	article_id uuid not null references public.articles(id) on delete cascade,
	label text not null,
	url text,
	source_type text not null default 'reference' check (
		source_type in ('reference', 'study', 'report', 'book', 'article', 'other')
	),
	sort_order integer not null default 0,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.article_sources is 'Source references for knowledge articles.';
create trigger set_article_sources_updated_at
before update on public.article_sources
for each row execute function public.set_updated_at();
-- User-generated opinions on articles. All UGC defaults to pending.
create table public.opinions (
	id uuid primary key default gen_random_uuid(),
	article_id uuid not null references public.articles(id) on delete cascade,
	user_id uuid not null references public.profiles(id) on delete cascade,
	body text not null,
	structured_position text,
	status text not null default 'pending' check (
		status in ('pending', 'approved', 'rejected', 'flagged', 'hidden')
	),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.opinions is 'User-generated article opinions; moderation status defaults to pending.';
create trigger set_opinions_updated_at
before update on public.opinions
for each row execute function public.set_updated_at();
-- Reports against opinions. Reports are moderation items and default pending.
create table public.opinion_reports (
	id uuid primary key default gen_random_uuid(),
	opinion_id uuid not null references public.opinions(id) on delete cascade,
	reporter_id uuid references public.profiles(id) on delete set null,
	reason text not null,
	details text,
	status text not null default 'pending' check (
		status in ('pending', 'reviewed', 'dismissed', 'actioned')
	),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.opinion_reports is 'User reports for article opinions and moderation review.';
create trigger set_opinion_reports_updated_at
before update on public.opinion_reports
for each row execute function public.set_updated_at();
-- Daily or featured human questions. Only published questions are public.
create table public.human_questions (
	id uuid primary key default gen_random_uuid(),
	title text not null,
	slug text not null unique,
	summary text not null,
	status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
	featured_status text not null default 'open' check (
		featured_status in ('open', 'featured', 'closed')
	),
	published_at timestamptz,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.human_questions is 'Published human question prompts for civic reflection.';
create trigger set_human_questions_updated_at
before update on public.human_questions
for each row execute function public.set_updated_at();
-- User answers to human questions. All answers default to pending.
create table public.human_question_answers (
	id uuid primary key default gen_random_uuid(),
	question_id uuid not null references public.human_questions(id) on delete cascade,
	user_id uuid not null references public.profiles(id) on delete cascade,
	vote text not null check (vote in ('yes', 'no', 'depends')),
	explanation text,
	generation text check (generation in ('Gen X', 'Millennial', 'Gen Z', 'Prefer not to say')),
	status text not null default 'pending' check (
		status in ('pending', 'approved', 'rejected', 'flagged', 'hidden')
	),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.human_question_answers is 'Authenticated user answers to human questions; UGC defaults to pending.';
create trigger set_human_question_answers_updated_at
before update on public.human_question_answers
for each row execute function public.set_updated_at();
-- Moral dilemma prompts. Only published dilemmas are public.
create table public.moral_dilemmas (
	id uuid primary key default gen_random_uuid(),
	title text not null,
	slug text not null unique,
	scenario text not null,
	reflection_prompt text,
	status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
	published_at timestamptz,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.moral_dilemmas is 'Published moral dilemma prompts for tradeoff reasoning.';
create trigger set_moral_dilemmas_updated_at
before update on public.moral_dilemmas
for each row execute function public.set_updated_at();
-- Multiple-choice options for moral dilemmas.
create table public.dilemma_options (
	id uuid primary key default gen_random_uuid(),
	dilemma_id uuid not null references public.moral_dilemmas(id) on delete cascade,
	label text not null,
	sort_order integer not null default 0,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.dilemma_options is 'Multiple-choice options attached to moral dilemmas.';
create trigger set_dilemma_options_updated_at
before update on public.dilemma_options
for each row execute function public.set_updated_at();
-- User votes and reasons for moral dilemmas. All votes default to pending.
create table public.dilemma_votes (
	id uuid primary key default gen_random_uuid(),
	dilemma_id uuid not null references public.moral_dilemmas(id) on delete cascade,
	option_id uuid not null references public.dilemma_options(id) on delete cascade,
	user_id uuid not null references public.profiles(id) on delete cascade,
	reason text,
	status text not null default 'pending' check (
		status in ('pending', 'approved', 'rejected', 'flagged', 'hidden')
	),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (dilemma_id, user_id)
);
comment on table public.dilemma_votes is 'Authenticated user votes and reasoning for moral dilemmas; UGC defaults to pending.';
create trigger set_dilemma_votes_updated_at
before update on public.dilemma_votes
for each row execute function public.set_updated_at();
-- User topic suggestions. All requests default to pending.
create table public.topic_requests (
	id uuid primary key default gen_random_uuid(),
	user_id uuid references public.profiles(id) on delete set null,
	topic_type text not null check (
		topic_type in ('article', 'human_question', 'moral_dilemma', 'correction', 'other')
	),
	title text not null,
	context text,
	sources text[] not null default '{}',
	status text not null default 'pending' check (
		status in ('pending', 'approved', 'rejected', 'reviewing', 'closed')
	),
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.topic_requests is 'Authenticated user requests for new topics, questions, dilemmas, or corrections.';
create trigger set_topic_requests_updated_at
before update on public.topic_requests
for each row execute function public.set_updated_at();
-- Donation records. Keep donor/payment details private and server-managed.
create table public.donations (
	id uuid primary key default gen_random_uuid(),
	user_id uuid references public.profiles(id) on delete set null,
	amount_cents integer not null check (amount_cents > 0),
	currency text not null default 'INR',
	tier text check (tier in ('supporter', 'civil_supporter', 'humanity_patron', 'custom')),
	status text not null default 'pending' check (
		status in ('pending', 'succeeded', 'failed', 'refunded', 'cancelled')
	),
	provider text,
	provider_reference text,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);
comment on table public.donations is 'Private donation records; donations never influence editorial truth.';
create trigger set_donations_updated_at
before update on public.donations
for each row execute function public.set_updated_at();
-- Moderation audit trail. Managed by moderators/admins only.
create table public.moderation_actions (
	id uuid primary key default gen_random_uuid(),
	moderator_id uuid references public.profiles(id) on delete set null,
	target_table text not null check (
		target_table in (
			'opinions',
			'opinion_reports',
			'human_question_answers',
			'dilemma_votes',
			'topic_requests',
			'articles',
			'human_questions',
			'moral_dilemmas'
		)
	),
	target_id uuid not null,
	action text not null check (
		action in ('approve', 'reject', 'flag', 'hide', 'restore', 'archive', 'note')
	),
	reason text,
	created_at timestamptz not null default now()
);
comment on table public.moderation_actions is 'Moderator/admin audit log for content and UGC decisions.';
-- Useful indexes.
create index categories_slug_idx on public.categories (slug);
create index categories_active_sort_idx on public.categories (is_active, sort_order);
create index articles_slug_idx on public.articles (slug);
create index articles_status_idx on public.articles (status);
create index articles_category_id_idx on public.articles (category_id);
create index articles_author_id_idx on public.articles (author_id);
create index articles_created_at_idx on public.articles (created_at desc);
create index articles_published_at_idx on public.articles (published_at desc);
create index article_sources_article_id_idx on public.article_sources (article_id);
create index article_sources_created_at_idx on public.article_sources (created_at desc);
create index opinions_article_id_idx on public.opinions (article_id);
create index opinions_user_id_idx on public.opinions (user_id);
create index opinions_status_idx on public.opinions (status);
create index opinions_created_at_idx on public.opinions (created_at desc);
create index opinion_reports_opinion_id_idx on public.opinion_reports (opinion_id);
create index opinion_reports_reporter_id_idx on public.opinion_reports (reporter_id);
create index opinion_reports_status_idx on public.opinion_reports (status);
create index opinion_reports_created_at_idx on public.opinion_reports (created_at desc);
create index human_questions_slug_idx on public.human_questions (slug);
create index human_questions_status_idx on public.human_questions (status);
create index human_questions_published_at_idx on public.human_questions (published_at desc);
create index human_question_answers_question_id_idx on public.human_question_answers (question_id);
create index human_question_answers_user_id_idx on public.human_question_answers (user_id);
create index human_question_answers_status_idx on public.human_question_answers (status);
create index human_question_answers_created_at_idx on public.human_question_answers (created_at desc);
create index moral_dilemmas_slug_idx on public.moral_dilemmas (slug);
create index moral_dilemmas_status_idx on public.moral_dilemmas (status);
create index moral_dilemmas_published_at_idx on public.moral_dilemmas (published_at desc);
create index dilemma_options_dilemma_id_idx on public.dilemma_options (dilemma_id);
create index dilemma_options_sort_idx on public.dilemma_options (dilemma_id, sort_order);
create index dilemma_votes_dilemma_id_idx on public.dilemma_votes (dilemma_id);
create index dilemma_votes_option_id_idx on public.dilemma_votes (option_id);
create index dilemma_votes_user_id_idx on public.dilemma_votes (user_id);
create index dilemma_votes_status_idx on public.dilemma_votes (status);
create index dilemma_votes_created_at_idx on public.dilemma_votes (created_at desc);
create index topic_requests_user_id_idx on public.topic_requests (user_id);
create index topic_requests_status_idx on public.topic_requests (status);
create index topic_requests_created_at_idx on public.topic_requests (created_at desc);
create index donations_user_id_idx on public.donations (user_id);
create index donations_status_idx on public.donations (status);
create index donations_created_at_idx on public.donations (created_at desc);
create index moderation_actions_moderator_id_idx on public.moderation_actions (moderator_id);
create index moderation_actions_target_idx on public.moderation_actions (target_table, target_id);
create index moderation_actions_created_at_idx on public.moderation_actions (created_at desc);
-- Row level security.
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.articles enable row level security;
alter table public.article_sources enable row level security;
alter table public.opinions enable row level security;
alter table public.opinion_reports enable row level security;
alter table public.human_questions enable row level security;
alter table public.human_question_answers enable row level security;
alter table public.moral_dilemmas enable row level security;
alter table public.dilemma_options enable row level security;
alter table public.dilemma_votes enable row level security;
alter table public.topic_requests enable row level security;
alter table public.donations enable row level security;
alter table public.moderation_actions enable row level security;
-- Profiles: users can read and create their own user profile. Role escalation is
-- not allowed through user policies.
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (id = auth.uid());
create policy "profiles_insert_own_user_role"
on public.profiles for insert
to authenticated
with check (id = auth.uid() and role = 'user');
create policy "profiles_update_own_safe_fields"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid() and role = 'user');
create policy "profiles_admin_manage"
on public.profiles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Categories: public can read active categories. Admin-only writes.
create policy "categories_public_read_active"
on public.categories for select
to anon, authenticated
using (is_active = true);
create policy "categories_admin_manage"
on public.categories for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Articles: public can read published articles. Admin-only writes for now.
-- TODO: add editorial workflow policies when author/editor roles are finalized.
create policy "articles_public_read_published"
on public.articles for select
to anon, authenticated
using (status = 'published');
create policy "articles_admin_manage"
on public.articles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Article sources: public can read sources for published articles. Admin-only writes.
create policy "article_sources_public_read_for_published_articles"
on public.article_sources for select
to anon, authenticated
using (
	exists (
		select 1
		from public.articles
		where articles.id = article_sources.article_id
			and articles.status = 'published'
	)
);
create policy "article_sources_admin_manage"
on public.article_sources for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Opinions: approved opinions can be read publicly. Authenticated users can
-- insert their own pending opinions only.
create policy "opinions_public_read_approved"
on public.opinions for select
to anon, authenticated
using (status = 'approved');
create policy "opinions_insert_own_pending"
on public.opinions for insert
to authenticated
with check (user_id = auth.uid() and status = 'pending');
create policy "opinions_user_read_own"
on public.opinions for select
to authenticated
using (user_id = auth.uid());
create policy "opinions_moderators_manage"
on public.opinions for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
-- Opinion reports: authenticated users can report; moderators/admins manage.
create policy "opinion_reports_insert_own_pending"
on public.opinion_reports for insert
to authenticated
with check (
	(reporter_id = auth.uid() or reporter_id is null)
	and status = 'pending'
);
create policy "opinion_reports_user_read_own"
on public.opinion_reports for select
to authenticated
using (reporter_id = auth.uid());
create policy "opinion_reports_moderators_manage"
on public.opinion_reports for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
-- Human questions: public can read published questions. Admin-only writes.
create policy "human_questions_public_read_published"
on public.human_questions for select
to anon, authenticated
using (status = 'published');
create policy "human_questions_admin_manage"
on public.human_questions for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Human question answers: authenticated users can insert their own pending answers.
create policy "human_question_answers_insert_own_pending"
on public.human_question_answers for insert
to authenticated
with check (user_id = auth.uid() and status = 'pending');
create policy "human_question_answers_user_read_own"
on public.human_question_answers for select
to authenticated
using (user_id = auth.uid());
create policy "human_question_answers_moderators_manage"
on public.human_question_answers for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
-- Moral dilemmas: public can read published dilemmas. Admin-only writes.
create policy "moral_dilemmas_public_read_published"
on public.moral_dilemmas for select
to anon, authenticated
using (status = 'published');
create policy "moral_dilemmas_admin_manage"
on public.moral_dilemmas for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Dilemma options: public can read options for published dilemmas. Admin-only writes.
create policy "dilemma_options_public_read_for_published_dilemmas"
on public.dilemma_options for select
to anon, authenticated
using (
	exists (
		select 1
		from public.moral_dilemmas
		where moral_dilemmas.id = dilemma_options.dilemma_id
			and moral_dilemmas.status = 'published'
	)
);
create policy "dilemma_options_admin_manage"
on public.dilemma_options for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Dilemma votes: authenticated users can insert their own pending vote.
create policy "dilemma_votes_insert_own_pending"
on public.dilemma_votes for insert
to authenticated
with check (user_id = auth.uid() and status = 'pending');
create policy "dilemma_votes_user_read_own"
on public.dilemma_votes for select
to authenticated
using (user_id = auth.uid());
create policy "dilemma_votes_moderators_manage"
on public.dilemma_votes for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
-- Topic requests: authenticated users can insert and read their own pending requests.
create policy "topic_requests_insert_own_pending"
on public.topic_requests for insert
to authenticated
with check (user_id = auth.uid() and status = 'pending');
create policy "topic_requests_user_read_own"
on public.topic_requests for select
to authenticated
using (user_id = auth.uid());
create policy "topic_requests_moderators_manage"
on public.topic_requests for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
-- Donations: no public read access. Users may read their own records; service role
-- should perform payment writes server-side. Admins can read/manage for operations.
create policy "donations_user_read_own"
on public.donations for select
to authenticated
using (user_id = auth.uid());
create policy "donations_admin_manage"
on public.donations for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
-- Moderation actions: moderators/admins can read and insert audit records.
-- TODO: if stricter separation is needed, allow only admins to update/delete.
create policy "moderation_actions_moderators_read"
on public.moderation_actions for select
to authenticated
using (public.is_moderator_or_admin());
create policy "moderation_actions_moderators_insert"
on public.moderation_actions for insert
to authenticated
with check (
	public.is_moderator_or_admin()
	and (moderator_id = auth.uid() or moderator_id is null)
);
create policy "moderation_actions_admin_manage"
on public.moderation_actions for all
to authenticated
using (public.is_admin())
with check (public.is_admin());
