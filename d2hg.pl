% Prolog representation of a grammar to ask a query of a database
% Builds a query which can then be asked of the knowledge base
%  This is not meant to be polished or lingustically reasonable, but purely to show what can be done

% This is expanded code of Figure 13.12 in Section 13.6.6 of
% Poole and Mackworth, Artificial Intelligence: foundations of
% computational agents, Cambridge, 2017

% Copyright (c) David Poole and Alan Mackworth 2017. This program
% is released under GPL, version 3 or later; see http://www.gnu.org/licenses/gpl.html

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

% Try:
%?- noun_phrase([a,spanish,speaking,country],L1,E1,C0,C1).
%?- noun_phrase([a,country,that,borders,chile],L1,E1,C0,C1).
%?- noun_phrase([a,spanish,speaking,country,that,borders,chile],L1,E1,C0,C1).

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
adj([large | L],L,Entity, [large(Entity)|C],C).
adj([Lang,speaking | L],L,Entity, [speaks(Entity,Lang)|C],C).
adj([Lang,-,speaking | L],L,Entity, [speaks(Entity,Lang)|C],C).

noun([country | L],L,Entity, [country(Entity)|C],C).
noun([city | L],L,Entity, [city(Entity)|C],C).

% Countries and languages are proper nouns.
% We could either have it check a language dictionary or add the constraints. We chose to check the dictionary.
proper_noun([X | L],L,X, C,C) :- country(X).
proper_noun([X | L],L,X,C,C) :- language(X).

reln([borders | L],L,O1,O2,[borders(O1,O2)|C],C).
reln([the,capital,of | L],L,O1,O2, [capital(O2,O1)|C],C).
reln([next,to | L],L,O1,O2, [borders(O1,O2)|C],C).

% question(Question,QR,Entity) is true if Query provides an answer about Entity to Question
question(['Is' | L0],L2,Entity,C0,C2) :-
    noun_phrase(L0,L1,Entity,C0,C1),
    mp(L1,L2,Entity,C1,C2).
question(['What',is | L0], L1, Entity,C0,C1) :-
    mp(L0,L1,Entity,C0,C1).
question(['What',is | L0],L1,Entity,C0,C1) :-
    noun_phrase(L0,L1,Entity,C0,C1).
question(['What' | L0],L2,Entity,C0,C2) :-
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


%  The Database of Facts to be Queried

% country(C) is true if C is a country
country(argentina).
country(brazil).
country(chile).
country(paraguay).
country(peru).
country(test_test).

% large(C) is true if the area of C is greater than 2m km^2
large(brazil).
large(test_test).
large(argentina).

% language(L) is true if L is a language
language(spanish).
language(portugese).

% speaks(Country,Lang) is true of Lang is an official language of Country
speaks(argentina,spanish).
speaks(brazil,portugese).
speaks(chile,spanish).
speaks(paraguay,spanish).
speaks(peru,spanish).

capital(argentina,'Buenos Aires').
capital(chile,'Santiago').
capital(peru,'Lima').
capital(brazil,'Brasilia').
capital(paraguay,'Asunción').

% borders(C1,C2) is true if country C1 borders country C2
borders(peru,chile).
borders(chile,peru).
borders(argentina,chile).
borders(chile,argentina).
borders(brazil,peru).
borders(peru,brazil).
borders(argentina,brazil).
borders(brazil,argentina).
borders(brazil,paraguay).
borders(paraguay,brazil).
borders(argentina,paraguay).
borders(paraguay,argentina).

/* Try the following queries:
?- ask(['What',is,a,country],A).
?- ask(['What',is,a,spanish,speaking,country],A).
?- ask(['What',is,the,capital,of, chile],A).
?- ask(['What',is,the,capital,of, a, country],A).
?- ask(['What',is, a, country, that, borders,chile],A).
?- ask(['What',is, a, country, that, borders,a, country,that,borders,chile],A).
?- ask(['What',is,the,capital,of, a, country, that, borders,chile],A).
?- ask(['What',country,borders,chile],A).
?- ask(['What',country,that,borders,chile,borders,paraguay],A).
*/


% To get the input from a line:

q(Ans) :-
    write("Ask me: "), flush_output(current_output),
    readln(Ln),
    ask(Ln,Ans).
   

/*
?- q(Ans).
Ask me: What is a country that borders chile?
Ans = argentina ;
Ans = peru ;
false.

?- q(Ans).
Ask me: What is the capital of a spanish speaking country that borders argentina?
Ans = 'Santiago' ;
Ans = 'Asunción' ;
false.

Some more questions:
What is next to chile?
Is brazil next to peru?
What is a country that borders a country that borders chile.
What is borders chile?
What borders chile?
What country borders chile?
What country that borders chile is next to paraguay?
What country that borders chile next to paraguay?

What country borders chile?
What country that borders chile is next to paraguay?
What country that borders chile next to paraguay?
*/
