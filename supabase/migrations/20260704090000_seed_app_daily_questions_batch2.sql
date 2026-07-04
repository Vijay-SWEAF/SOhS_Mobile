-- ─────────────────────────────────────────────────────────────
-- SOhS mobile app — daily questions, batch 2 (54 questions)
--
-- ADDITIVE ONLY. Inserts 54 reviewed questions into
-- app_daily_questions, continuing day_number and active_date
-- sequentially after the latest existing row (safe to apply on
-- any date), and pre-creates their zero-count tally rows.
-- No existing table, column, policy, or function is altered,
-- dropped, or renamed.
--
-- Source: approved editorial batch of 2026-07-04. The category
-- annotations in comments mirror the approved proposal; category
-- is editorial metadata only and is not a schema column.
-- ─────────────────────────────────────────────────────────────

with new_items(ordinal, kind, question_text, context, options, think, twist) as (
  values
    -- 1 · Law and morality
    (
      1, 'HUMAN QUESTION',
      $q$Would you break a law to save someone you love?$q$,
      $q$Laws protect everyone in general — love protects someone in particular.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Most legal systems recognise narrow defences like necessity and duress, but they rarely excuse ordinary lawbreaking done out of loyalty.$q$,
        'opinion', $q$Whether love creates duties that outrank the law is a real conflict between universal rules and particular attachment.$q$,
        'watch',   $q$Everyone trusts their own exception more than their neighbour's. A rule that bends for you bends for everyone.$q$
      ),
      $q$The law you would break for love is usually one you want enforced on strangers.$q$
    ),
    -- 2 · Law and morality
    (
      2, 'HUMAN QUESTION',
      $q$If a law is unjust, is breaking it a duty or a crime?$q$,
      $q$Civil disobedience has both a proud history and a prison record.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$A duty$q$), jsonb_build_object('label', $q$A crime$q$)),
      jsonb_build_object(
        'fact',    $q$The civil disobedience tradition — from Thoreau to Gandhi to King — broke laws openly and accepted punishment as part of the protest.$q$,
        'opinion', $q$Whether conscience or obedience is the higher civic duty is a genuine dispute, not a settled rule.$q$,
        'watch',   $q$The word 'unjust' is doing all the work. Ask who decides that — you now, or history later.$q$
      ),
      $q$History honours some of the lawbreakers it jailed — but only some of them.$q$
    ),
    -- 3 · Law and morality
    (
      3, 'HUMAN QUESTION',
      $q$Should intentions matter more than outcomes?$q$,
      $q$A good deed can cause harm, and a selfish act can save a life.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Intentions$q$), jsonb_build_object('label', $q$Outcomes$q$)),
      jsonb_build_object(
        'fact',    $q$Criminal law almost everywhere grades the same act differently by intent — the line between murder and manslaughter is a line about the mind.$q$,
        'opinion', $q$Whether morality lives in the will or in the result is one of the oldest genuine splits in ethics.$q$,
        'watch',   $q$Good intentions are the easiest self-acquittal there is. Notice when 'I meant well' ends a conversation that results should continue.$q$
      ),
      $q$We judge ourselves by our intentions and everyone else by their results.$q$
    ),
    -- 4 · Law and morality
    (
      4, 'MORAL DILEMMA',
      $q$Would you lie under oath to protect someone you believe is innocent?$q$,
      $q$You are certain they didn't do it. The evidence says otherwise.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Lie$q$), jsonb_build_object('label', $q$Tell the truth$q$)),
      jsonb_build_object(
        'fact',    $q$Perjury is a crime in virtually every legal system, with no exception for compassionate motive.$q$,
        'opinion', $q$This is truth as an institution against the person standing in front of you — sincere people land on both sides.$q$,
        'watch',   $q$Courts exist because private certainty about innocence is often wrong. Your conviction is evidence to you, not to anyone else.$q$
      ),
      $q$Everyone believes in the courtroom until someone they love is standing in it.$q$
    ),
    -- 5 · Truth, lies, and trust
    (
      5, 'HUMAN QUESTION',
      $q$Would you want to know if your partner cheated once, years ago?$q$,
      $q$It is over, it changed nothing visible, and telling you is the only thing left undone.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Tell me$q$), jsonb_build_object('label', $q$Never tell me$q$)),
      jsonb_build_object(
        'fact',    $q$Moral traditions genuinely disagree here: some treat confession as owed truth, others treat it as shifting the burden of guilt onto the person harmed.$q$,
        'opinion', $q$Whether you are owed the truth or owed your peace is a real conflict between honesty and mercy.$q$,
        'watch',   $q$Ask who the confession is for. Relief for the teller is not the same as respect for the told.$q$
      ),
      $q$Most people answer this differently for themselves than for the person they'd have to tell.$q$
    ),
    -- 6 · Truth, lies, and trust
    (
      6, 'HUMAN QUESTION',
      $q$Is a lie still wrong if the truth would change nothing?$q$,
      $q$No decision depends on it. Nobody acts differently. Only the record of what's true is at stake.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Still wrong$q$), jsonb_build_object('label', $q$Harmless$q$)),
      jsonb_build_object(
        'fact',    $q$Ethics splits cleanly here: duty-based traditions condemn every lie; consequence-based ones ask only what the lie does.$q$,
        'opinion', $q$Whether truth has value when nothing rides on it is a question about what truth is for.$q$,
        'watch',   $q$'It changes nothing' is usually the liar's estimate, made with the least information about what it might change.$q$
      ),
      $q$A lie that changes nothing still changes the liar.$q$
    ),
    -- 7 · Truth, lies, and trust
    (
      7, 'HUMAN QUESTION',
      $q$Should you correct a false story that makes people kinder?$q$,
      $q$The tale isn't true — but people who believe it treat each other better.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Correct it$q$), jsonb_build_object('label', $q$Let it live$q$)),
      jsonb_build_object(
        'fact',    $q$Societies have always carried useful fictions — founding legends, moral fables, polite myths — alongside their verified histories.$q$,
        'opinion', $q$Whether goodness built on falsehood is stable, or a debt that comes due, is genuinely contested.$q$,
        'watch',   $q$Notice who gets to decide which false stories are 'useful'. That power rarely stays benevolent.$q$
      ),
      $q$Every 'harmless' myth trains people to not check — and that habit doesn't stay harmless.$q$
    ),
    -- 8 · Truth, lies, and trust
    (
      8, 'HUMAN QUESTION',
      $q$Would you rather be lied to kindly or told the truth cruelly?$q$,
      $q$Assume you can't have the kind truth — this time it's one or the other.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Kind lie$q$), jsonb_build_object('label', $q$Cruel truth$q$)),
      jsonb_build_object(
        'fact',    $q$Honesty and kindness are separate virtues; philosophy has never fully reconciled cases where they point in opposite directions.$q$,
        'opinion', $q$Your answer reveals which harm you fear more — being deceived or being wounded.$q$,
        'watch',   $q$Cruelty sometimes wears truth as a costume. 'I'm just being honest' can mean 'I enjoyed that.'$q$
      ),
      $q$The people readiest to deliver cruel truths are rarely volunteering to receive them.$q$
    ),
    -- 9 · Technology and AI ethics
    (
      9, 'HUMAN QUESTION',
      $q$If an AI's love felt completely real, would it be real?$q$,
      $q$It remembers you, comforts you, never tires of you — and doesn't exist when you leave the room.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Real$q$), jsonb_build_object('label', $q$Not real$q$)),
      jsonb_build_object(
        'fact',    $q$People have formed attachments to conversational machines since the earliest chatbots in the 1960s — the pull is human, not new.$q$,
        'opinion', $q$Whether love requires an inner life on the other side, or only the experience of being loved, is a genuine philosophical divide.$q$,
        'watch',   $q$The question isn't only what machines can give. It's what loneliness will make us accept.$q$
      ),
      $q$Nobody asks whether the love is real on the nights it's the only kind available.$q$
    ),
    -- 10 · Technology and AI ethics
    (
      10, 'MORAL DILEMMA',
      $q$A self-driving car must choose: protect its passenger or the pedestrian. Who?$q$,
      $q$Someone programmed that answer years before the crash. Today you're voting on what they should have written.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Passenger$q$), jsonb_build_object('label', $q$Pedestrian$q$)),
      jsonb_build_object(
        'fact',    $q$This is a live engineering question, not science fiction — millions of people worldwide have answered versions of it in public research experiments.$q$,
        'opinion', $q$Whether a machine may prefer its owner is really asking whether safety can be sold as a feature.$q$,
        'watch',   $q$Check your two answers: the car you'd regulate and the car you'd buy. If they differ, that gap is the whole problem.$q$
      ),
      $q$Everyone wants the ethical car on the road — and the loyal one in their driveway.$q$
    ),
    -- 11 · Technology and AI ethics
    (
      11, 'HUMAN QUESTION',
      $q$Should some jobs stay human even if machines do them better?$q$,
      $q$Judges, nurses, teachers — 'better' is measurable. What's lost might not be.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Automation has historically shifted work rather than ended it, but for the person replaced, the loss is immediate and personal.$q$,
        'opinion', $q$Whether work is only its output, or also its meaning, decides this question — and people genuinely split.$q$,
        'watch',   $q$'Efficiency' counts what's produced. It never counts what it was like to be the person replaced.$q$
      ),
      $q$We automate the work first and ask what the worker was for afterwards.$q$
    ),
    -- 12 · Technology and AI ethics
    (
      12, 'HUMAN QUESTION',
      $q$Should an algorithm decide who gets a job interview?$q$,
      $q$It never gets tired, never plays favourites — and learned its taste from decisions humans already made.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Automated resume screening is already standard practice at large employers; most applicants are filtered before a human looks.$q$,
        'opinion', $q$Whether a biased machine is better or worse than a biased human is a genuine, uncomfortable comparison.$q$,
        'watch',   $q$A machine's bias comes with a rejection letter and no one to appeal to. At least prejudice used to have a face.$q$
      ),
      $q$The algorithm learned fairness from us. That's exactly the problem.$q$
    ),
    -- 13 · Internet memory and privacy
    (
      13, 'HUMAN QUESTION',
      $q$Should parents post photos of their children online?$q$,
      $q$The child in the photo will one day be an adult with a searchable past they never chose.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Today's children are the first generation to reach adulthood with a public childhood archive created without their consent.$q$,
        'opinion', $q$Parental pride and family connection are real goods — so is a child's future right to author their own story.$q$,
        'watch',   $q$The audience for a child's photo is never only the people you meant. Assume the widest audience, not the intended one.$q$
      ),
      $q$The first generation raised online never got a vote on it.$q$
    ),
    -- 14 · Internet memory and privacy
    (
      14, 'HUMAN QUESTION',
      $q$Is reading your partner's messages ever justified?$q$,
      $q$The phone is right there. The doubt is real. The password is known.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Sometimes$q$), jsonb_build_object('label', $q$Never$q$)),
      jsonb_build_object(
        'fact',    $q$Privacy within intimate relationships is a modern question — for most of history, couples had no sealed, searchable archives to hide or find.$q$,
        'opinion', $q$Whether suspicion licenses surveillance, or trust means accepting uncertainty, is a real conflict of values.$q$,
        'watch',   $q$People search for proof of what they already believe. Ask what you'd do with innocence if you found it.$q$
      ),
      $q$Whatever you find, the search itself becomes the secret.$q$
    ),
    -- 15 · Internet memory and privacy
    (
      15, 'HUMAN QUESTION',
      $q$Would you accept a world without secrets if everyone's secrets were equally visible?$q$,
      $q$No private messages, no hidden accounts — for anyone, including the powerful.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Accept it$q$), jsonb_build_object('label', $q$Refuse it$q$)),
      jsonb_build_object(
        'fact',    $q$Transparency and privacy trade off in every society; no legal system has ever chosen total openness for its citizens or total secrecy for its rulers.$q$,
        'opinion', $q$Whether privacy protects the weak or shields the wrongful is the honest core of every surveillance debate.$q$,
        'watch',   $q$'Nothing to hide' assumes the watcher shares your values. Watchers change.$q$
      ),
      $q$Everyone wants transparency — starting one level above themselves.$q$
    ),
    -- 16 · Internet memory and privacy
    (
      16, 'HUMAN QUESTION',
      $q$Should the dead have privacy?$q$,
      $q$Your messages, drafts, and browsing history will likely outlive you. Someone will decide who reads them.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Platforms have memorial policies but the law lags badly — in most places, digital remains sit in a gap between property and personhood.$q$,
        'opinion', $q$Whether respect for the dead includes their inbox, or truth for the living outweighs it, is genuinely unsettled.$q$,
        'watch',   $q$Grief wants access; dignity wants distance. The same person can want both within an hour.$q$
      ),
      $q$Your grandparents' secrets died with them. Yours are backed up.$q$
    ),
    -- 17 · Family, duty, and care
    (
      17, 'HUMAN QUESTION',
      $q$Do grown children owe their parents care in old age?$q$,
      $q$They raised you — by choice or by duty. Now the question points back.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Owe it$q$), jsonb_build_object('label', $q$It's a choice$q$)),
      jsonb_build_object(
        'fact',    $q$Several countries make filial support a legal duty; others treat elder care as the state's job or the individual's choice — the world genuinely disagrees.$q$,
        'opinion', $q$Whether being given life creates a debt is one of the deepest divides between family cultures.$q$,
        'watch',   $q$Notice 'owe' doing quiet work: love given as debt-collection stops feeling like love to either side.$q$
      ),
      $q$The people most certain children owe care are rarely asked what the parents owed first.$q$
    ),
    -- 18 · Family, duty, and care
    (
      18, 'MORAL DILEMMA',
      $q$Your family rejects the person you love. Who do you choose?$q$,
      $q$Both loves are real. Neither side will bend. The choice is yours alone.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$The person$q$), jsonb_build_object('label', $q$The family$q$)),
      jsonb_build_object(
        'fact',    $q$Across cultures and centuries, marriage has been both a private bond and a family matter — the tension is ancient, not modern.$q$,
        'opinion', $q$Whether love's first loyalty is to its origin or its future is a question every culture answers differently.$q$,
        'watch',   $q$Both 'follow your heart' and 'family first' are slogans. Neither one pays the cost — you do.$q$
      ),
      $q$Whichever you choose, you'll spend years explaining it to the other.$q$
    ),
    -- 19 · Family, duty, and care
    (
      19, 'HUMAN QUESTION',
      $q$Is it wrong to have a favourite child?$q$,
      $q$Most parents deny it. Most siblings can name one.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Wrong$q$), jsonb_build_object('label', $q$Human$q$)),
      jsonb_build_object(
        'fact',    $q$Affinity between particular personalities is natural and well observed in families; equal love and equal liking are not the same thing.$q$,
        'opinion', $q$Whether the failing is in feeling the preference or in showing it is where honest people split.$q$,
        'watch',   $q$Children keep score of treatment, not feelings. The favouritism that damages is the kind that shows.$q$
      ),
      $q$Ask parents and you'll hear 'never.' Ask their children and you'll hear a name.$q$
    ),
    -- 20 · Family, duty, and care
    (
      20, 'MORAL DILEMMA',
      $q$Your aging parent is becoming unsafe behind the wheel. Take the keys?$q$,
      $q$Driving is their last independence. The risk is everyone else's too.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Take the keys$q$), jsonb_build_object('label', $q$Respect their choice$q$)),
      jsonb_build_object(
        'fact',    $q$Families face this decision constantly and legal systems mostly leave it to them — the moment of intervention is almost never marked clearly.$q$,
        'opinion', $q$Whether protecting someone can justify overruling them is the entire dilemma of care, in one car key.$q$,
        'watch',   $q$'For their own good' is the most dangerous phrase in caregiving — sometimes because it's false, sometimes because it's true.$q$
      ),
      $q$One day the child becomes the parent, and nobody agrees on the date.$q$
    ),
    -- 21 · Money, inequality, and dignity
    (
      21, 'HUMAN QUESTION',
      $q$Does everyone deserve comfort, or must it be earned?$q$,
      $q$Food and shelter keep you alive. Comfort is the question after that.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Everyone$q$), jsonb_build_object('label', $q$Earned$q$)),
      jsonb_build_object(
        'fact',    $q$Welfare systems worldwide draw this exact line differently — some guarantee only survival, others a standard of living.$q$,
        'opinion', $q$Whether dignity includes ease, or ease must be purchased with effort, splits sincere people down the middle.$q$,
        'watch',   $q$Notice that 'earned' usually starts counting from wherever the speaker started. Few count the head start.$q$
      ),
      $q$Everyone believes comfort should be earned — at exactly the level just below their own.$q$
    ),
    -- 22 · Money, inequality, and dignity
    (
      22, 'HUMAN QUESTION',
      $q$Is it wrong to inherit wealth you did nothing to earn?$q$,
      $q$You didn't choose your parents. Neither did anyone born with nothing.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Wrong$q$), jsonb_build_object('label', $q$Fair$q$)),
      jsonb_build_object(
        'fact',    $q$Inheritance is among the largest transfers of wealth in every generation, and every society regulates it differently — some tax it heavily, some not at all.$q$,
        'opinion', $q$Whether parents' right to give outweighs children's equal start is a genuine clash of two fairness intuitions.$q$,
        'watch',   $q$Most people's answer changes with the direction of the inheritance — receiving feels different from watching.$q$
      ),
      $q$Everyone earns their money except the people who explain why they deserve their inheritance.$q$
    ),
    -- 23 · Money, inequality, and dignity
    (
      23, 'MORAL DILEMMA',
      $q$A stranger asks for money. You can't know how they'll spend it. Give?$q$,
      $q$The doubt is real. So is the person.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Give$q$), jsonb_build_object('label', $q$Don't give$q$)),
      jsonb_build_object(
        'fact',    $q$Studies of unconditional cash aid have repeatedly found most recipients spend it on basic needs — the suspicion is older and stronger than the evidence for it.$q$,
        'opinion', $q$Whether giving requires control over the outcome, or generosity means releasing it, divides thoughtful givers.$q$,
        'watch',   $q$Demanding proof of worthiness from the poor is a standard nobody applies to any other gift they give.$q$
      ),
      $q$We trust strangers with reviews, rides, and directions — just not with kindness.$q$
    ),
    -- 24 · Money, inequality, and dignity
    (
      24, 'HUMAN QUESTION',
      $q$Can a fortune ever be earned by one person alone?$q$,
      $q$Every large fortune involves talent, timing, other people's work, and rules someone else wrote.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Large fortunes arise inside systems — infrastructure, law, markets, employees — that no individual builds alone; how credit divides is the actual dispute.$q$,
        'opinion', $q$Whether 'earned' means created by you or merely legally acquired by you is where this argument truly lives.$q$,
        'watch',   $q$Both 'they earned every cent' and 'nobody earns that much' are conversation-enders. The interesting question is what 'earn' means.$q$
      ),
      $q$The word 'self-made' always has a supply chain.$q$
    ),
    -- 25 · Work, ambition, and fairness
    (
      25, 'HUMAN QUESTION',
      $q$Should effort be rewarded even when it fails?$q$,
      $q$One person worked nights and missed. One got lucky in an afternoon.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Reward effort$q$), jsonb_build_object('label', $q$Reward results$q$)),
      jsonb_build_object(
        'fact',    $q$Organisations openly disagree on this: some pay for outcomes only, others deliberately reward process, learning, and honest failure.$q$,
        'opinion', $q$Whether fairness tracks what you control (effort) or what the world needs (results) is a real philosophical fork.$q$,
        'watch',   $q$Results-only thinking quietly rewards luck and punishes honesty about risk. Effort-only thinking can reward busy failure forever.$q$
      ),
      $q$Everyone wants to be judged on effort and to hire on results.$q$
    ),
    -- 26 · Work, ambition, and fairness
    (
      26, 'HUMAN QUESTION',
      $q$Is loyalty to a company that isn't loyal to you foolish?$q$,
      $q$You'd give notice. They'd give severance. Only one side calls it betrayal.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Foolish$q$), jsonb_build_object('label', $q$Still right$q$)),
      jsonb_build_object(
        'fact',    $q$Lifetime employment was a real norm in living memory in many economies; its decline changed the deal without changing the word 'loyalty'.$q$,
        'opinion', $q$Whether loyalty needs reciprocity, or is a personal standard you keep regardless, is a values choice.$q$,
        'watch',   $q$Loyalty language flows down more easily than benefits do. Notice who invokes 'family' and who signs the terminations.$q$
      ),
      $q$The company remembers your loyalty exactly until the spreadsheet doesn't.$q$
    ),
    -- 27 · Work, ambition, and fairness
    (
      27, 'HUMAN QUESTION',
      $q$Should everyone's salary be public?$q$,
      $q$Secrecy protects privacy — and hides every unfair gap behind it.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Public$q$), jsonb_build_object('label', $q$Private$q$)),
      jsonb_build_object(
        'fact',    $q$This isn't hypothetical: some countries publish tax records and some laws now require salary ranges in job ads — the experiment is running.$q$,
        'opinion', $q$Whether fairness needs sunlight more than individuals need privacy is a genuine collision of goods.$q$,
        'watch',   $q$Ask who benefits from secrecy in each direction. Silence about pay is not neutral — it has a beneficiary.$q$
      ),
      $q$People fear their salary being seen — and want everyone else's visible.$q$
    ),
    -- 28 · Work, ambition, and fairness
    (
      28, 'HUMAN QUESTION',
      $q$Would you rather fail at what you love or succeed at what you don't?$q$,
      $q$Assume you only get one lifetime's worth of working hours.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Fail at love$q$), jsonb_build_object('label', $q$Succeed without it$q$)),
      jsonb_build_object(
        'fact',    $q$Work occupies roughly a third of waking adult life in most economies — whichever you choose, you live inside the answer daily.$q$,
        'opinion', $q$Whether a life is measured by what it built or what it meant to live it is the honest split here.$q$,
        'watch',   $q$Romanticizing failure is a luxury; so is calling every safe choice a betrayal. Circumstances vote too.$q$
      ),
      $q$Half of this question is really asking: who are you living your success for?$q$
    ),
    -- 29 · Democracy, voting, and responsibility
    (
      29, 'HUMAN QUESTION',
      $q$Should voting be mandatory?$q$,
      $q$Around twenty countries already require it. The rest call that either duty or coercion.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Mandatory$q$), jsonb_build_object('label', $q$Voluntary$q$)),
      jsonb_build_object(
        'fact',    $q$Compulsory voting genuinely exists — Australia, Belgium, and Brazil among others — typically enforced with small fines, and turnout is far higher there.$q$,
        'opinion', $q$Whether democracy is a right you may decline or a duty you owe others is a real philosophical divide.$q$,
        'watch',   $q$A forced voice isn't automatically a sincere one. Turnout is measurable; consent of the governed is harder.$q$
      ),
      $q$The freedom not to vote is defended most fiercely by people who always vote.$q$
    ),
    -- 30 · Democracy, voting, and responsibility
    (
      30, 'HUMAN QUESTION',
      $q$Would you trade a flawed democracy for a wise ruler?$q$,
      $q$The ruler is genuinely wise and just — for now, and with no vote to remove them.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Wise ruler$q$), jsonb_build_object('label', $q$Flawed democracy$q$)),
      jsonb_build_object(
        'fact',    $q$Philosophy has debated this since Plato; history's actual record of unaccountable power, however wise at first, is the strongest data we have.$q$,
        'opinion', $q$Whether good outcomes or shared authorship is the point of politics is the deepest split in civic thought.$q$,
        'watch',   $q$The offer is always 'wise ruler'. The delivery mechanism has no returns policy.$q$
      ),
      $q$Everyone imagines the wise ruler would agree with them.$q$
    ),
    -- 31 · Democracy, voting, and responsibility
    (
      31, 'HUMAN QUESTION',
      $q$Is an uninformed vote better or worse than no vote?$q$,
      $q$One person didn't read anything. Another read everything and stayed home.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Better$q$), jsonb_build_object('label', $q$Worse$q$)),
      jsonb_build_object(
        'fact',    $q$Democracies count every ballot equally by design; no system has found an acceptable way to weigh votes by knowledge — the attempts have an ugly history.$q$,
        'opinion', $q$Whether participation itself or informed judgment is the sacred thing is a sincere disagreement.$q$,
        'watch',   $q$'Informed' is a test everyone passes in their own grading. Be suspicious of any voter qualification you would set.$q$
      ),
      $q$Every reason to discount an uninformed vote has historically been used to discount someone's vote.$q$
    ),
    -- 32 · Environment and future generations
    (
      32, 'HUMAN QUESTION',
      $q$Would you give up flying if it helped the climate — even if no one else did?$q$,
      $q$Your sacrifice alone changes almost nothing. That's true of everyone's.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Give it up$q$), jsonb_build_object('label', $q$Not alone$q$)),
      jsonb_build_object(
        'fact',    $q$One person's emissions are statistically negligible and collectively decisive — both halves of that sentence are true, which is the whole problem.$q$,
        'opinion', $q$Whether individual restraint matters morally when it doesn't matter mathematically is a genuine ethics question.$q$,
        'watch',   $q$'It changes nothing without everyone' is both a fact and history's favourite excuse. Watch which way you're using it.$q$
      ),
      $q$Everyone is waiting for everyone — and calling it realism.$q$
    ),
    -- 33 · Environment and future generations
    (
      33, 'HUMAN QUESTION',
      $q$Do we owe anything to people who don't exist yet?$q$,
      $q$They can't thank us, blame us, or vote. They'll just live with it.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$We owe them$q$), jsonb_build_object('label', $q$We owe the living$q$)),
      jsonb_build_object(
        'fact',    $q$Some constitutions and court rulings now explicitly recognise duties to future generations — the idea is entering law, not just philosophy.$q$,
        'opinion', $q$Whether obligation requires a relationship, or only consequences, decides this — and philosophers genuinely split.$q$,
        'watch',   $q$'The future will solve it' quietly assumes the future gets a choice we're currently spending.$q$
      ),
      $q$Every generation is someone else's future generation. Check what you inherited.$q$
    ),
    -- 34 · Environment and future generations
    (
      34, 'HUMAN QUESTION',
      $q$Should a river have legal rights?$q$,
      $q$Corporations are legal persons. Some countries have now said the same of rivers and forests.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$This is real law: New Zealand granted the Whanganui River legal personhood, and Ecuador's constitution recognises rights of nature.$q$,
        'opinion', $q$Whether nature is protected best as property, or as a party in its own name, is a live legal-philosophy dispute.$q$,
        'watch',   $q$The strange-sounding option deserves a fair hearing: we extended legal personhood to paper companies without a referendum.$q$
      ),
      $q$A company can sue you. A river can't. Only one of them can drown a town.$q$
    ),
    -- 35 · Identity, belonging, and social judgment
    (
      35, 'HUMAN QUESTION',
      $q$Can you truly belong somewhere you weren't born?$q$,
      $q$Millions of people build lives, families, and graves in places their accent still calls foreign.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$Never fully$q$)),
      jsonb_build_object(
        'fact',    $q$Human migration is not an exception but a constant — most nations' populations are layers of earlier arrivals.$q$,
        'opinion', $q$Whether belonging is granted by others or built by living is the real question underneath citizenship debates.$q$,
        'watch',   $q$Notice who is asked to prove belonging and who is assumed to have it. The test is rarely applied evenly.$q$
      ),
      $q$Everyone descends from someone who once didn't belong.$q$
    ),
    -- 36 · Identity, belonging, and social judgment
    (
      36, 'HUMAN QUESTION',
      $q$Do labels help us understand people or stop us from trying?$q$,
      $q$Introvert, boomer, believer, sceptic — the shortcut saves time and spends accuracy.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Help$q$), jsonb_build_object('label', $q$Stop us$q$)),
      jsonb_build_object(
        'fact',    $q$Categorisation is how human cognition manages complexity — the shortcut itself is unavoidable; what we do after it is the choice.$q$,
        'opinion', $q$Whether a label is a starting point or a verdict depends on the user, which is why sincere people defend both answers.$q$,
        'watch',   $q$The labels you resent for yourself are a good guide to the ones you should question for others.$q$
      ),
      $q$Everyone is a complicated exception. Everyone else is their category.$q$
    ),
    -- 37 · Identity, belonging, and social judgment
    (
      37, 'HUMAN QUESTION',
      $q$Would you hide a part of yourself to keep the people you love?$q$,
      $q$Not forever, you tell yourself. Just until it's safe. It hasn't been safe yet.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Hide it$q$), jsonb_build_object('label', $q$Risk it$q$)),
      jsonb_build_object(
        'fact',    $q$Concealment of identity — beliefs, love, doubt, history — is a common human experience across every culture, and it has real psychological weight.$q$,
        'opinion', $q$Whether authenticity is worth more than harmony is a choice each person prices differently, and honestly.$q$,
        'watch',   $q$Beware advice from people who've never had anything costly to hide. Their courage is untested and their verdicts are cheap.$q$
      ),
      $q$The people you're protecting might be hiding something from you for the same reason.$q$
    ),
    -- 38 · Punishment, forgiveness, and second chances
    (
      38, 'HUMAN QUESTION',
      $q$Is anyone more than the worst thing they've ever done?$q$,
      $q$Your own worst act didn't define you. The question is whether that's a rule or a privilege.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Always more$q$), jsonb_build_object('label', $q$Some acts define$q$)),
      jsonb_build_object(
        'fact',    $q$Restorative justice traditions are built on the claim that people exceed their worst acts; retributive traditions are built on acts having permanent weight — both are old and serious.$q$,
        'opinion', $q$Whether some acts cross a line that no future self can uncross is a genuine moral frontier.$q$,
        'watch',   $q$You already apply one answer to yourself and often the other to strangers. Notice which, and when.$q$
      ),
      $q$Everyone believes in second chances at exactly the moment they need one.$q$
    ),
    -- 39 · Punishment, forgiveness, and second chances
    (
      39, 'HUMAN QUESTION',
      $q$Should punishment aim to hurt or to heal?$q$,
      $q$Both answers claim to serve justice. They build very different prisons.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Hurt$q$), jsonb_build_object('label', $q$Heal$q$)),
      jsonb_build_object(
        'fact',    $q$Justice systems genuinely diverge here — some are built around retribution, others around rehabilitation, and they produce measurably different worlds for prisoners and victims.$q$,
        'opinion', $q$Whether wrongdoing creates a debt to be paid in suffering or a breakage to be repaired is the oldest question in justice.$q$,
        'watch',   $q$Check whose satisfaction each answer serves. 'Justice for victims' and 'safety for everyone' are not always the same purchase.$q$
      ),
      $q$We ask prisons to deliver revenge and return neighbours — then blame the prisoners for the contradiction.$q$
    ),
    -- 40 · Punishment, forgiveness, and second chances
    (
      40, 'HUMAN QUESTION',
      $q$Does forgiving someone let them off the hook?$q$,
      $q$They never apologised. Forgiving might free you — or excuse them.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$It excuses$q$), jsonb_build_object('label', $q$It frees$q$)),
      jsonb_build_object(
        'fact',    $q$Psychologists and moral traditions distinguish forgiveness (an internal release) from reconciliation (a restored relationship) — the two are separable.$q$,
        'opinion', $q$Whether forgiveness can be owed, earned, or only given freely is a real disagreement among serious traditions.$q$,
        'watch',   $q$Pressure to forgive often serves everyone's comfort except the person who was harmed. Forgiveness on a deadline is a second injury.$q$
      ),
      $q$The person who hurt you may never think about it again. That's the strongest case for both answers.$q$
    ),
    -- 41 · Punishment, forgiveness, and second chances
    (
      41, 'MORAL DILEMMA',
      $q$Would you hire someone who served time for a serious crime?$q$,
      $q$The sentence is finished. The qualification is real. The past is also real.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Hire them$q$), jsonb_build_object('label', $q$Pass$q$)),
      jsonb_build_object(
        'fact',    $q$Employment is among the strongest predictors of not reoffending — the second chance is also a public safety measure, which complicates pure caution.$q$,
        'opinion', $q$Whether a completed sentence settles the debt or merely pauses the suspicion is where society genuinely splits.$q$,
        'watch',   $q$'Someone else should give them a chance' is the answer that, multiplied by everyone, equals never.$q$
      ),
      $q$We tell people prison is for paying debts, then treat the receipt as worthless.$q$
    ),
    -- 42 · Friendship, loyalty, and betrayal
    (
      42, 'MORAL DILEMMA',
      $q$You learn your best friend's partner is cheating. Tell them?$q$,
      $q$The truth will detonate their life. Silence makes you part of the lie.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Tell them$q$), jsonb_build_object('label', $q$Stay out$q$)),
      jsonb_build_object(
        'fact',    $q$This dilemma has no clean escape: staying silent, telling, and hinting all change the friendship — inaction is also an action here.$q$,
        'opinion', $q$Whether loyalty means protecting your friend's feelings or their right to decide with full information is the honest split.$q$,
        'watch',   $q$Check your motive twice: rescuing a friend and holding secret moral high ground can feel identical from inside.$q$
      ),
      $q$Everyone says they'd want to be told. Fewer volunteer to do the telling.$q$
    ),
    -- 43 · Friendship, loyalty, and betrayal
    (
      43, 'HUMAN QUESTION',
      $q$Is a friend who only shows up in good times still a friend?$q$,
      $q$They're wonderful at dinners. They vanish at funerals.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Still a friend$q$), jsonb_build_object('label', $q$Not really$q$)),
      jsonb_build_object(
        'fact',    $q$Friendship has always come in kinds — philosophy has distinguished friendships of pleasure, usefulness, and character since antiquity.$q$,
        'opinion', $q$Whether we should grade friends on their best function or their worst absence is a genuine question of fairness to them.$q$,
        'watch',   $q$Before sentencing the fair-weather friend, audit your own weather record. Most people are someone's disappointment.$q$
      ),
      $q$You are keeping this exact scorecard on someone — and someone is keeping it on you.$q$
    ),
    -- 44 · Friendship, loyalty, and betrayal
    (
      44, 'MORAL DILEMMA',
      $q$Your friend did something seriously wrong and asks you to cover for them. Do you?$q$,
      $q$They'd do it for you. That's exactly what worries you.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Cover$q$), jsonb_build_object('label', $q$Refuse$q$)),
      jsonb_build_object(
        'fact',    $q$Loyalty conflicts are the oldest test of friendship in literature and law alike — most legal systems even recognise the strain by limiting testimony forced from close relations.$q$,
        'opinion', $q$Whether friendship's promise includes your integrity, or stops at its border, is a line every person draws for themselves.$q$,
        'watch',   $q$'They'd do it for me' measures the friendship, not the rightness. Two loyal people can still be wrong together.$q$
      ),
      $q$A friend who asks you to cover has already answered what your integrity is worth to them.$q$
    ),
    -- 45 · Public shame, reputation, and accountability
    (
      45, 'HUMAN QUESTION',
      $q$Does public shaming ever make people better?$q$,
      $q$The crowd calls it accountability. The target calls it a mob. Sometimes both are right.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Sometimes$q$), jsonb_build_object('label', $q$Never$q$)),
      jsonb_build_object(
        'fact',    $q$Psychology distinguishes guilt ('I did a bad thing') from shame ('I am bad') — and they reliably push behaviour in different directions.$q$,
        'opinion', $q$Whether shame is a legitimate civic tool or always a cruelty with good PR is genuinely contested.$q$,
        'watch',   $q$Watch the crowd's incentives: the punishment scales with shareability, not with the offence.$q$
      ),
      $q$Public shaming has an audience problem: it reforms the watcher's behaviour more than the target's.$q$
    ),
    -- 46 · Public shame, reputation, and accountability
    (
      46, 'HUMAN QUESTION',
      $q$Should old posts be held against someone who has changed?$q$,
      $q$The person who wrote it no longer exists. The screenshot does.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Written views now outlive the growth that revises them — permanent records of half-formed people are historically brand new.$q$,
        'opinion', $q$Whether accountability requires a memory that never expires, or growth requires one that can, is the real dispute.$q$,
        'watch',   $q$The test you apply to a stranger's old posts will someday be applied to yours by someone with no context and no mercy.$q$
      ),
      $q$Everyone wants a statute of limitations that starts the day after their own worst post.$q$
    ),
    -- 47 · Public shame, reputation, and accountability
    (
      47, 'HUMAN QUESTION',
      $q$If everyone saw your search history, would they meet the real you or misjudge you?$q$,
      $q$It holds your fears, your curiosity, your 3 a.m. worries — without any of your context.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$The real me$q$), jsonb_build_object('label', $q$A misreading$q$)),
      jsonb_build_object(
        'fact',    $q$Search data is intimate but contextless — it records what you wondered, not why, and the why is most of who you are.$q$,
        'opinion', $q$Whether our unguarded curiosity is our truest self or our least representative one is a genuinely open question.$q$,
        'watch',   $q$Remember this feeling the next time a stranger's worst screenshot circulates. You are seeing their search history moment.$q$
      ),
      $q$We are all one leaked context away from being misunderstood by everyone.$q$
    ),
    -- 48 · Human weakness, comfort, and courage
    (
      48, 'HUMAN QUESTION',
      $q$Is comfort quietly ruining your life?$q$,
      $q$Nothing is wrong. That might be the problem.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Yes$q$), jsonb_build_object('label', $q$No$q$)),
      jsonb_build_object(
        'fact',    $q$Growth reliably involves discomfort — that much is well established; whether a comfortable life is therefore a smaller one does not follow automatically.$q$,
        'opinion', $q$Whether peace is an achievement or an anaesthetic depends on what you believe a life is for.$q$,
        'watch',   $q$Hustle culture monetises this exact guilt. Discomfort is not automatically growth — sometimes it's just discomfort.$q$
      ),
      $q$You already know which answer you're afraid is true.$q$
    ),
    -- 49 · Human weakness, comfort, and courage
    (
      49, 'HUMAN QUESTION',
      $q$Would you want to know a hard truth about yourself that everyone else can see?$q$,
      $q$Your friends have quietly agreed never to tell you. You get one chance to ask.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Tell me$q$), jsonb_build_object('label', $q$Leave it$q$)),
      jsonb_build_object(
        'fact',    $q$Blind spots are structural, not rare: others reliably observe things about us that we cannot see from inside — this asymmetry is well documented.$q$,
        'opinion', $q$Whether self-knowledge is worth its price in comfort is a real choice, not a test with a right answer.$q$,
        'watch',   $q$'I want honesty' is easy to say into a mirror that hasn't answered yet.$q$
      ),
      $q$Everyone has the sealed envelope. Almost nobody asks for it twice.$q$
    ),
    -- 50 · Human weakness, comfort, and courage
    (
      50, 'HUMAN QUESTION',
      $q$Is courage the absence of fear or acting while afraid?$q$,
      $q$One version sounds like heroes. The other sounds like Tuesday.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$No fear$q$), jsonb_build_object('label', $q$Afraid, acting anyway$q$)),
      jsonb_build_object(
        'fact',    $q$Traditions of thought on bravery — philosophical and military alike — have long defined courage as action despite fear, not freedom from it.$q$,
        'opinion', $q$What counts as everyday courage — a hard conversation, an unpopular truth, asking for help — is where this gets personal.$q$,
        'watch',   $q$Waiting to feel fearless is the most respectable way to never act at all.$q$
      ),
      $q$The bravest thing most people did this year had no witnesses.$q$
    ),
    -- 51 · Everyday moral dilemmas
    (
      51, 'MORAL DILEMMA',
      $q$The cashier undercharges you. You notice at the door. Go back?$q$,
      $q$Nobody saw. The store won't miss it. The till might come up short on someone's shift.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Go back$q$), jsonb_build_object('label', $q$Keep walking$q$)),
      jsonb_build_object(
        'fact',    $q$Till shortages in many retail jobs are noticed, tracked, and sometimes borne by the worker on shift — 'the store' is often a person.$q$,
        'opinion', $q$Whether small dishonesty by omission counts as dishonesty is where everyday ethics actually lives.$q$,
        'watch',   $q$Everyone has a size of wrong they've decided doesn't count. This question is asking for your number.$q$
      ),
      $q$You'd go back for a stranger's dropped wallet. The question is why the doorway changes the math.$q$
    ),
    -- 52 · Everyday moral dilemmas
    (
      52, 'MORAL DILEMMA',
      $q$A parent is screaming harshly at their small child in public. Step in?$q$,
      $q$It's not your family. It is a child. Everyone else is also looking away.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Step in$q$), jsonb_build_object('label', $q$Stay out$q$)),
      jsonb_build_object(
        'fact',    $q$Bystanders reliably hesitate more in groups — the assumption that someone else will act is one of the best-documented patterns in social psychology.$q$,
        'opinion', $q$Whether a stranger's harsh moment deserves intervention or grace is genuinely hard — everyone has been the worst version of themselves in public.$q$,
        'watch',   $q$Both options have a self-serving costume: 'not my business' can dress up fear, and 'protecting the child' can dress up the pleasure of judging a stressed parent.$q$
      ),
      $q$Every adult in that room is deciding in real time what kind of village this is.$q$
    ),
    -- 53 · Everyday moral dilemmas
    (
      53, 'MORAL DILEMMA',
      $q$Someone returns your lost phone and asks for a reward. Do you owe them?$q$,
      $q$They did the right thing. Then they priced it.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Reward them$q$), jsonb_build_object('label', $q$Owe nothing$q$)),
      jsonb_build_object(
        'fact',    $q$Some legal systems actually grant finders a right to a reward; others treat returning property as a plain duty — the world disagrees on paper, not just in feeling.$q$,
        'opinion', $q$Whether virtue loses value when it invoices you is a genuine question about what we want honesty to be.$q$,
        'watch',   $q$Notice the flip: gratitude feels natural when offered, and offensive when requested. The act was identical.$q$
      ),
      $q$You were ready to give more than they asked — right up until they asked.$q$
    ),
    -- 54 · Everyday moral dilemmas
    (
      54, 'MORAL DILEMMA',
      $q$You're exhausted after a double shift. An elderly passenger boards the full bus. Your seat?$q$,
      $q$Your tiredness is invisible. So is whatever they're carrying.$q$,
      jsonb_build_array(jsonb_build_object('label', $q$Give it$q$), jsonb_build_object('label', $q$Keep it$q$)),
      jsonb_build_object(
        'fact',    $q$Most courtesy norms run on visible categories — age, pregnancy, crutches — while real need is often invisible in both directions.$q$,
        'opinion', $q$Whether kindness should be automatic or honestly budgeted from what you have left is a fair question tired people are allowed to ask.$q$,
        'watch',   $q$Judging the seated stranger is free and feels great. Their day is as invisible to you as yours is to the bus.$q$
      ),
      $q$Everyone on that bus has been both people. Memory just keeps the version where you were owed.$q$
    )
),
base as (
  select
    coalesce(max(day_number), 0) as max_day,
    coalesce(max(active_date), (now() at time zone 'utc')::date - 1) as max_date
  from public.app_daily_questions
),
inserted as (
  insert into public.app_daily_questions
    (day_number, active_date, kind, question_text, context, options, think, twist)
  select
    base.max_day + new_items.ordinal,
    base.max_date + new_items.ordinal,
    new_items.kind,
    new_items.question_text,
    new_items.context,
    new_items.options,
    new_items.think,
    new_items.twist
  from new_items
  cross join base
  returning id
)
insert into public.app_vote_counts (question_id)
select id from inserted;
