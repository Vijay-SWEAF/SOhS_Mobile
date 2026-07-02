-- Admin article editorial workflow support.
-- Adds only the editorial fields required by the website admin form.

alter table public.articles
	add column if not exists content_md text;
comment on column public.articles.content_md is 'Plain markdown article body managed from the SOhS admin article workflow.';
alter table public.article_sources
	add column if not exists notes text;
comment on column public.article_sources.notes is 'Optional internal/source context notes for the admin editorial workflow.';
drop policy if exists "articles_admin_manage" on public.articles;
drop policy if exists "articles_moderators_manage" on public.articles;
create policy "articles_moderators_manage"
on public.articles for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
drop policy if exists "article_sources_admin_manage" on public.article_sources;
drop policy if exists "article_sources_moderators_manage" on public.article_sources;
create policy "article_sources_moderators_manage"
on public.article_sources for all
to authenticated
using (public.is_moderator_or_admin())
with check (public.is_moderator_or_admin());
