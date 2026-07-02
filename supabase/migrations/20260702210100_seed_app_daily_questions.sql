-- ─────────────────────────────────────────────────────────────
-- SOhS mobile app — Phase 3, migration 2 of 2
--
-- ADDITIVE ONLY. Seeds the first seven daily questions into
-- app_daily_questions (days 1–3 ported verbatim from the approved
-- prototype; days 4–7 new, same civic register) and pre-creates
-- their zero-count rows. Day 1 goes live on the UTC date this
-- migration is applied; one question per day after that.
--
-- These rows live only in app_daily_questions — the website's
-- question flow never sees them.
-- ─────────────────────────────────────────────────────────────

with new_questions as (
  insert into public.app_daily_questions
    (day_number, active_date, kind, question_text, context, options, think, twist)
  values
    (
      1,
      (now() at time zone 'utc')::date,
      'HUMAN QUESTION',
      $q$Is being legally right always morally right?$q$,
      $q$Laws create order, but history shows legality and morality do not always move together.$q$,
      '[{"label":"Yes"},{"label":"No"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$Legality and morality are separate systems — laws have permitted slavery, and banned dissent.$q$,
        'opinion', $q$Whether one should ever override the other is a genuine moral argument, not a settled fact.$q$,
        'watch',   $q$Beware anyone who treats “it’s legal” as the end of a moral question. It’s the start of one.$q$
      ),
      $q$Under-25s were the most likely to say Yes — trust in law falls sharply with age.$q$
    ),
    (
      2,
      (now() at time zone 'utc')::date + 1,
      'MORAL DILEMMA',
      $q$You find a wallet with cash and ID. Nobody saw you. Return it?$q$,
      $q$A note inside suggests the owner urgently needs the money too.$q$,
      '[{"label":"Return it"},{"label":"Keep it"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$“Lost letter” and dropped-wallet field experiments consistently show return rates below what people predict.$q$,
        'opinion', $q$Whether hardship could justify keeping it is where sincere people genuinely disagree.$q$,
        'watch',   $q$Notice the gap between what we say we'd do and what we do. That gap is the real subject.$q$
      ),
      $q$Stated intentions run far higher than what field studies actually observe.$q$
    ),
    (
      3,
      (now() at time zone 'utc')::date + 2,
      'HUMAN QUESTION',
      $q$Should a lie ever be told to protect someone's feelings?$q$,
      $q$Honesty and kindness are both values — and they don't always agree.$q$,
      '[{"label":"Yes"},{"label":"No"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$Ethical traditions split here: strict Kantians say never; care-ethicists allow it to prevent harm.$q$,
        'opinion', $q$Where you land depends on which value you rank higher — a real choice, not an error.$q$,
        'watch',   $q$“White lies” can hide both kindness and cowardice. Ask which one is doing the work.$q$
      ),
      $q$Cultures that prize directness (e.g. Germany) leaned most toward No.$q$
    ),
    (
      4,
      (now() at time zone 'utc')::date + 3,
      'HUMAN QUESTION',
      $q$If a machine could judge crimes more fairly than humans, should it?$q$,
      $q$Algorithms already advise judges on bail and sentencing in several countries.$q$,
      '[{"label":"Yes"},{"label":"No"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$Risk-assessment tools already sit in courtrooms — studies find them more consistent than judges, and biased by the data they learn from.$q$,
        'opinion', $q$Whether justice requires a human face, even an imperfect one, is a question of values — not engineering.$q$,
        'watch',   $q$Watch for “fairer” quietly becoming “more consistent.” Consistency and justice are not the same thing.$q$
      ),
      $q$People trust algorithmic judgement far more for strangers' cases than for their own.$q$
    ),
    (
      5,
      (now() at time zone 'utc')::date + 4,
      'HUMAN QUESTION',
      $q$Is it wrong to live well while others lack necessities?$q$,
      $q$Most of us live above the global median without ever having decided to.$q$,
      '[{"label":"Yes"},{"label":"No"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$Philosophers from Peter Singer onward argue affluence carries duties; ethical traditions disagree sharply on how far those duties reach.$q$,
        'opinion', $q$Where comfort ends and excess begins is a line every tradition draws differently — and each of us draws somewhere.$q$,
        'watch',   $q$Beware of guilt that changes nothing. The question isn't how you feel about your comforts — it's what they cost, and whom.$q$
      ),
      $q$Higher earners were slightly more likely to answer Yes — and no more likely to say they'd change anything.$q$
    ),
    (
      6,
      (now() at time zone 'utc')::date + 5,
      'HUMAN QUESTION',
      $q$Does voting make you responsible for what your government does?$q$,
      $q$Every ballot is one voice among millions — yet governments act in all our names.$q$,
      '[{"label":"Yes"},{"label":"No"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$Democratic theory splits: some hold that voters share in outcomes; others say responsibility requires real causal power.$q$,
        'opinion', $q$How much weight one vote among millions carries is a genuine philosophical dispute — not arithmetic.$q$,
        'watch',   $q$Notice how “I'm just one vote” escapes responsibility while “the people decided” assigns it. Both can't be the whole truth.$q$
      ),
      $q$Non-voters were more likely than voters to say Yes — voting binds you.$q$
    ),
    (
      7,
      (now() at time zone 'utc')::date + 6,
      'HUMAN QUESTION',
      $q$Should the internet ever forget what you did?$q$,
      $q$The EU recognises a “right to be forgotten.” Others call that erasing the record.$q$,
      '[{"label":"Yes"},{"label":"No"}]'::jsonb,
      jsonb_build_object(
        'fact',    $q$Since 2014, EU law lets people ask search engines to delist certain results about them; the US recognises no equivalent right.$q$,
        'opinion', $q$Whether a person's worst moment should follow them forever is a real conflict between mercy and the public record.$q$,
        'watch',   $q$Ask who benefits from forgetting, case by case. Second chances and cover-ups arrive through the same door.$q$
      ),
      $q$Support for forgetting rises sharply when people are asked about their own past instead of someone else's.$q$
    )
  returning id
)
insert into public.app_vote_counts (question_id)
select id from new_questions;
