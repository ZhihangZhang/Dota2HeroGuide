:- [heroes].
:- [attack_type].
:- [attribute].
:- [counters_and_synergies].
:- [role].

% noun_phrase(L0,L4,Entity,C0,C4) is true if
%  L0 and L4 are list of words, such that
%        L4 is an ending of L0
%        the words in L0 before L4 (written L0-L4) form a noun phrase
%  Entity is an individual that the noun phrase is referring to
% C0 is a list such that C4 is an ending of C0 and C0-C4 contains the constraints imposed by the noun phrase

% A noun phrase is a determiner followed by adjectives followed
% by a noun followed by an optional modifying phrase:
noun_phrase(L0,L4,Entity,C0,C4) :-
    det(L0,L1,Entity,C0,C1),
    adjectives(L1,L2,Entity,C1,C2),
    noun(L2,L3,Entity,C2,C3),
    mp(L3,L4,Entity,C3,C4).

noun_phrase(L0,L4,Entity,C0,C4) :-
    proper_noun(L0,L4,Entity,C0,C4).

% Determiners (articles) are ignored in this oversimplified example.
% They do not provide any extra constraints.
det([the | L],L,_,C,C).
det([a | L],L,_,C,C).
det(L,L,_,C,C).

% adjectives(L0,L2,Entity,C0,C2) is true if
% L0-L2 is a sequence of adjectives imposes constraints C0-C2 on Entity
adjectives(L0,L2,Entity,C0,C2) :-
    adj(L0,L1,Entity,C0,C1),
    adjectives(L1,L2,Entity,C1,C2).
adjectives(L,L,_,C,C).

% An optional modifying phrase / relative clause is either
% a relation (verb or preposition) followed by a noun_phrase or
% 'that' followed by a relation then a noun_phrase or
% nothing
mp(L0,L2,Subject,C0,C2) :-
    reln(L0,L1,Subject,Object,C0,C1),
    noun_phrase(L1,L2,Object,C1,C2).
mp([that|L0],L2,Subject,C0,C2) :-
    reln(L0,L1,Subject,Object,C0,C1),
    noun_phrase(L1,L2,Object,C1,C2).
mp(L,L,_,C,C).

% DICTIONARY
% adj(L0,L1,Entity,C0,C1) is true if L0-L1
% is an adjective that imposes constraints C0-C1 Entity
adj([melee | L],L,Entity, [prop(Entity, attack_type, melee)|C],C).
adj([ranged | L],L,Entity, [prop(Entity, attack_type, ranged)|C],C).
adj([strength | L],L,Entity, [prop(Entity, attribute, strength)|C],C).
adj([agility | L],L,Entity, [prop(Entity, attribute, agility)|C],C).
adj([intelligence | L],L,Entity, [prop(Entity, attribute, intelligence)|C],C).


noun([hero | L],L,Entity, [prop(Entity, type, hero)|C],C).
noun([support | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, support)|C],C).
noun([nuker | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, nuker)|C],C).
noun([disabler | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, disabler)|C],C).
noun([jungler | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, jungle)|C],C).
noun([jungle | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, jungle)|C],C).
noun([durable | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, durable)|C],C).
noun([escape | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, escape)|C],C).
noun([pusher | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, pusher)|C],C).
noun([initiator | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, initiator)|C],C).
noun([carry | L],L,Entity, [prop(Entity, type, hero), prop(Entity, role, carry)|C],C).

% Heroes are proper nouns
proper_noun([X | L],L,X, C,C) :- prop(X, type, hero).

% Used in "What is a hero..."
reln([counters | L],L, O1, O2, [prop(O1, counters, O2) | C],C).
reln([synergizes, with | L],L,O1,O2, [prop(O1, synergizes, O2) | C],C).

% Used in "Does <hero>..."
reln([counter | L],L, O1, O2, [prop(O1, counters, O2) | C],C).
reln([synergize, with | L],L, O1, O2, [prop(O1, synergizes, O2) | C],C).

% question(Question,QR,Entity) is true if Query provides an answer about Entity to Question
question(['What',is | L0],L1,Entity,C0,C1) :-
    noun_phrase(L0,L1,Entity,C0,C1).
question(['Does' | L0],L2,Entity,C0,C2) :-
    noun_phrase(L0,L1,Entity,C0,C1),
    mp(L1,L2,Entity,C1,C2).


% ask(Q,A) gives answer A to question Q
ask(Q,A) :-
    get_constraints_from_question(Q,A,C),
    prove_all(C).

% get_constraints_from_question(Q,A,C) is true if C is the constaints on A to infer question Q
get_constraints_from_question(Q,A,C) :-
    question(Q,End,A,C,[]),
    member(End,[[],['?'],['.']]).


% prove_all(L) is true if all elements of L can be proved from the knowledge base
prove_all([]).
prove_all([H|T]) :-
    call(H),      % built-in Prolog predicate calls an atom
    prove_all(T).


% To get the input from a line:

q(Ans) :-
    write("Ask me: "), flush_output(current_output),
    % https://www.swi-prolog.org/pldoc/doc/_SWI_/library/readln.pl
    % http://amzi.com/manuals/amzi/pro/ref_terms.htm
    % to allow dash in hero name. e.g anti-mage
    readln(Ln, _, _, [95, 45], uppercase),
    ask(Ln,Ans).


% Tests
/*
?- q(Ans).
Ask me: What is a hero that counters earthshaker?
Ans = puck ;
Ans = windranger ;
Ans = clockwerk ;
Ans = zeus ;
Ans = huskar ;
Ans = sniper ;
Ans = templar_assassin ;
Ans = jakiro ;
Ans = ogre_magi ;
Ans = rubick ;
Ans = disruptor ;
Ans = earth_spirit ;
Ans = skywrath_mage ;
Ans = phoenix ;
Ans = razor ;
Ans = venomancer ;
Ans = lifestealer ;
Ans = night_stalker ;
Ans = viper ;
Ans = necrophos ;
Ans = spectre ;
Ans = death_prophet ;
Ans = outworld_destroyer ;
false.

?- q(Ans).
Ask me: What is a intelligence hero that counters outworld_destroyer?
Ans = pugna ;
Ans = rubick ;
Ans = silencer ;
false.

?- q(Ans).
Ask me: What is a melee hero that synergizes with tusk?
Ans = axe ;
Ans = centaur_warrunner ;
Ans = juggernaut ;
Ans = legion_commander ;
Ans = lifestealer ;
Ans = meepo ;
Ans = omniknight ;
Ans = tidehunter ;
Ans = tiny ;
false.

?- q(Ans).
Ask me: Does meepo counter anti-mage?
Ans = meepo ;
false.

?- q(Ans).
Ask me: What is a agility hero that counters anti-mage?
Ans = bloodseeker ;
Ans = clinkz ;
Ans = drow_ranger ;
Ans = faceless_void ;
Ans = meepo ;
Ans = phantom_assassin ;
Ans = phantom_lancer ;
Ans = riki ;
Ans = slark ;
Ans = templar_assassin ;
Ans = terrorblade ;
Ans = troll_warlord ;
Ans = viper ;
false.

?- q(Ans).
Ask me: What is a ranged hero that synergizes with anti-mage?
Ans = bane ;
Ans = dazzle ;
Ans = disruptor ;
Ans = lion ;
Ans = oracle ;
Ans = shadow_demon ;
Ans = silencer ;
false.
*/

