/** <module> SEMANTICS OF α-CTL

This module implements the semantics of α-CTL, a branching time
temporal logic with existential actions, especially designed to
solve non-deterministic planning problems involving extended
reachability goals.

Notation:
   * Σ : Labeled Transition System (LTS), representing a nondeterministic planning domain
   * Φ, Ψ : logical formulas
   * Π : set of pairs of the form (S,α), representing a nondeterministic policy
   * Δ : set of unlabeled states (only identifiers)
   * Λ : set of labeled states (identifiers + set of propositions)
   * Γ : set of transitions of the form (S,α,Δ)
   * τ : trivial action to mark goal states (i.e., live-ends)
   * λ : lambda function (to express global temporal operators)
   * μ : least fixed-point
   * ν : greatest fixed-point
   * ω : fixed-point characterization

Formulas:
   * atomic formulas: =p=, =q=, ..., =true=
   * propositional formulas: not(Φ), and(Φ,Ψ), or(Φ,Ψ)
   * local temporal formulas: ex(Φ), ax(Φ)
   * global temporal formulas: eu(Φ,Ψ), au(Φ,Ψ), ef(Φ), af(Φ), eg(Φ), ag(Φ)

Remarks:
   * Only atomic propositions can be negated!
   * An LTS Σ is represented in Prolog as a dictionary with tag =lts=,
     and keys =states= and =transitions=. For example, the dictionary
     =|lts{states:[0:[], 1:[p]], transitions: [(0,a,[0,1])]}|=
     represents the following LTS:
  ==
                                           0:[] --a--> 1:[p]
                                            ^    /
                                             \  /
                                              \/
  ==
@author  Silvio do Lago Pereira
@version November, 2019.

@compat This module is intended to be used with SWI-Prolog, version 8.0.3.
**/


%! sat(+M:integer, +Φ:formula) is semidet.
%
%  If model number M is defined by the predicate =model/2==:
%     * Synthesize a policy Π that achieves Φ, from LTS Σ, for _|model|_(_M_,_|Σ|_).
%     * Print the LTS induced by Π, with respect to Σ.
%  Otherwise, fail.
%
%  Here is an example, supposing that the following clause for predicate
%  =model/2= is defined:
%
%  ==
%  %            a--> 1:[p] ----b----> 2:[r]
%  %           /         ^    /      ^
%  %          /           \  /      /
%  %         /             \/      /
%  %  0:[p,q]                     /
%  %         \         a         /
%  %          \       / \       /
%  %           \     v   \     /
%  %            b--> 3:[q] ---c---> 4:[p,q,r]
%
%  model( 1,
%         lts{ states: [0: [p, q],
%                       1: [p],
%                       2: [r],
%                       3: [q],
%                       4: [p, q, r] ],
%
%              transitions: [(0, a, [1]),
%                            (0, b, [3]),
%                            (1, b, [1, 2]),
%                            (3, a, [3]),
%                            (3, c, [2 ,4]) ] } ).
%  ==
%
%  ==
%  ?- sat(1,  ef( and(r,not(p)) )  ).
%  lts{ states:      [ 0: [p, q],
%                      1: [p],
%                      2: [r],
%                      3: [q],
%                      4: [p, q, r] ],
%       transitions: [ (0, a, [1]),
%                      (0, b, [3]),
%                      (1, b, [1, 2]),
%                      (3, c, [2, 4]) ] }
%  ==


sat(M, Φ) :-
   integer(M), !,
   model(M, Σ),
   flag(scope, _, min),
   sort(Σ.sat(Φ), Π),
   format('~n~p', Σ.lts( Π ) ).


%! sat(+Φ:formula, +Σ:lts, -Π:policy) is det.
%
%  Synthesize a policy Π that achieves Φ, from LTS Σ.
%
%  Syntactic sugar: Π = Σ.sat( Φ )
%
%  Here is an example, supposing that the following clause for predicate
%  =model/2= is defined:
%
%  ==
%  %            a--> 1:[p] ----b----> 2:[r]
%  %           /         ^    /      ^
%  %          /           \  /      /
%  %         /             \/      /
%  %  0:[p,q]                     /
%  %         \         a         /
%  %          \       / \       /
%  %           \     v   \     /
%  %            b--> 3:[q] ---c---> 4:[p,q,r]
%
%  model( 1,
%         lts{ states: [0: [p, q],
%                       1: [p],
%                       2: [r],
%                       3: [q],
%                       4: [p, q, r] ],
%
%              transitions: [(0, a, [1]),
%                            (0, b, [3]),
%                            (1, b, [1, 2]),
%                            (3, a, [3]),
%                            (3, c, [2 ,4]) ] } ).
%  ==
%
%  ==
%  ?- model(1, M), P =  M.sat( ag(ef(and(r,not(p)))) ).
%  M = lts{ states:      [ 0: [p, q],
%                          1: [p],
%                          2: [r],
%                          3: [q],
%                          4: [p, q, r] ],
%           transitions: [ (0, a, [1]),
%                          (0, b, [3]),
%                          (1, b, [1, 2]),
%                          (3, a, [3]),
%                          (3, c, [2, 4]) ] },
%  P = [(0, a),  (1, b),  (2, τ)].
%
%  ?- model(1, M), S = M.lts( M.sat( ag(ef(and(r,not(p)))) ) ).
%  M = lts{ states:      [ 0: [p, q],
%                          1: [p],
%                          2: [r],
%                          3: [q],
%                          4: [p, q, r] ],
%           transitions: [ (0, a, [1]),
%                          (0, b, [3]),
%                          (1, b, [1, 2]),
%                          (3, a, [3]),
%                          (3, c, [2, 4]) ] },
%  S = lts{ states:      [ 0: [p, q],
%                          1: [p],
%                          2: [r] ],
%           transitions: [ (0, a, [1]),
%                          (1, b, [1, 2]) ] }.
%  ==
%
%  Notice that Σ.lts(Π) returns the LTS induced by policy Π, w.r.t. Σ.


%  Atomic formulas

Σ.sat( Φ ) :=  Π :-
   atm(Φ), !,
   set(S, ( member(S:L, Σ.states),
            memberchk(Φ, [true|L]) ), Δ),
   set((S,τ), member(S,Δ), Π).            % use τ-transitions to mark goal states


%  Propositional formulas

Σ.sat( not(Φ) ) := Π  :-
   atm(Φ), !,
   subtract(Σ.sat(true), Σ.sat(Φ), Π).

Σ.sat( and(Φ,Ψ) ) := Π  :- !,
   intersection(Σ.sat(Φ), Σ.sat(Ψ), Π).

Σ.sat( or(Φ,Ψ) ) := Π  :- !,
   union(Σ.sat(Φ), Σ.sat(Ψ), Π).


%  Local temporal formulas

Σ.sat( ex(Φ) ) := Π  :- !,
   Π0 = Σ.wpi( Σ.sat(Φ) ),
   set((S,τ), member((S,_), Π0), Π).

Σ.sat( ax(Φ) ) := Π  :- !,
   Π0 = Σ.spi( Σ.sat(Φ) ),
   set((S,τ), member((S,_), Π0), Π).


%  Global temporal formulas

Σ.sat( eu(Ψ,Φ) ) := Π  :- !,
   dom(Σ.sat(Ψ), Δ),
   ω(eu, Δ, Σ.sat(Φ), Σ, Ω),
   Π = Σ.μ(Ω).

Σ.sat( au(Ψ,Φ) ) := Π  :- !,
   dom(Σ.sat(Ψ), Δ),
   ω(au, Δ, Σ.sat(Φ), Σ, Ω),
   Π = Σ.μ(Ω).

Σ.sat( ef(Φ) ) := Π  :- !,
   ω(ef, Σ.sat(Φ), Σ, Ω),
   Π = Σ.μ(Ω).

Σ.sat( af(Φ) ) := Π  :- !,
   ω(af, Σ.sat(Φ), Σ, Ω),
   Π = Σ.μ(Ω).

Σ.sat( eg(Φ) ) := Π  :- !,
   flag(scope, Outer, max),
   Π0 = Σ.sat(Φ),
   Σ0 = Σ.tau(Π0),
   ω(eg, Σ0, Ω0),
   Π1 = Σ0.ν(Ω0),            % fixed-point to remove outgoing/unconnected
   Σ1 = Σ.tau(Π1),
   goals(Π1, Δ1),
   flag(scope, _, min),
   ω(ef, Δ1, Σ1, Ω1),
   Π  = Σ1.μ(Ω1),            % fixed-point to remove nonprogressing/traps
   flag(scope, _, Outer).

Σ.sat( ag(Φ) ) := Π  :- !,
   flag(scope, Outer, max),
   Π0 = Σ.sat(Φ),
   Σ0 = Σ.tau( Π0 ),
   ω(ag, Σ0, Ω0),
   Π1 = Σ0.ν(Ω0),            % fixed-point to remove outgoing/unconnected
   Σ1 = Σ.tau(Π1),
   goals(Π1, Δ1),
   flag(scope, _, min),
   ω(ef, Δ1, Σ1, Ω1),
   Π  = Σ1.μ(Ω1),            % fixed-point to remove nonprogressing/traps
   flag(scope, _, Outer).


%  Fixed-point characterizations of global temporal operators

ω(eu, Φ, Ψ, Σ,
   λ(X, ( wpi(X, Σ, W),
          inter(W, Φ, I),
          prune(I, X, P),
          union(P, X, U),
          union(U, Ψ, Y) ), Y)).

ω(au, Φ, Ψ, Σ,
   λ(X, ( spi(X, Σ, W),
          inter(W, Φ, I),
          prune(I, X, P),
          union(P, X, U),
          union(U, Ψ, Y) ), Y)).

ω(ef, Φ, Σ,
   λ(X, ( wpi(X, Σ, W),
          prune(W, X, P),
          union(P, X, U),
          union(U, Φ, Y) ), Y)).

ω(af, Φ, Σ,
   λ(X, ( spi(X, Σ, W),
          prune(W, X, P),
          union(P, X, U),
          union(U, Φ, Y) ), Y)).

ω(eg, Σ,  % partial characterization!
   λ(X, ( wpi(X, Σ, S),
          intersection(S, Σ.univ(), Y) ), Y )).

ω(ag, Σ,  % partial characterization!
   λ(X, ( spi(X, Σ, S),
          intersection(S, Σ.univ(), Y) ), Y)).


/*
 *  OPERATIONS ON LTSs
 */


%  Π is the universal policy w.r.t. Σ

Σ.univ() := Π :-
   set((S,A), member((S,A,_), Σ.transitions), Π).


%  Σ is the LTS induced by the policy Π, w.r.t. Σ0

Σ0.lts(Π) := Σ :-
   set(S:L, ( member((S,A), Π),                 % collect states mapped by Π
              member(S:L, Σ0.states) ), Λ0),
   set(S:L, ( member((S0,A), Π),                % collect dead-ends of Π
              member((S0,A,Δ), Σ0.transitions),
              member(S, Δ),
              member(S:L, Σ0.states) ), Λ1),
   union(Λ0, Λ1, Λ),
   set((S,A,Δ), ( member((S,A), Π),
                  member((S,A,Δ), Σ0.transitions) ), Γ),
   Σ = lts{states: Λ, transitions: Γ}.


%  Σ is the LTS induced by the policy Π, w.r.t. Σ0, extended with τ-transitions

Σ0.tau(Π) := Σ :-
   Σ1 = Σ0.lts(Π),
   set((S,τ,[S]), member((S,τ), Π), Γ0),
   union(Σ1.transitions, Γ0, Γ),
   Σ = lts{states: Σ1.states, transitions: Γ}.


%  Π is the weak preimage of Π0, w.r.t. Σ

Σ.wpi(Π0) := Π :-
   dom(Π0, Δ0),
   set((S,A), ( member((S,A,Δ1), Σ.transitions),
                not(intersection(Δ1, Δ0, [])),
                ( Δ1 \= [S]      % exclude non-trivial self-loops
                ; A = τ ) ),     % include trivial self-loops
       Π).


%  Π is the strong preimage of Π0, w.r.t. Σ

Σ.spi(Π0) := Π :-
   dom(Π0, Δ0),
   set((S,A), ( member((S,A,Δ1), Σ.transitions),
                subset(Δ1, Δ0),
                ( Δ1 \= [S]      % exclude non-trivial self-loops
                ; A = τ ) ),     % include trivial self-loops
       Π).


%  Π is the least fixed-point of a function Ω, w.r.t. Σ

Σ.μ( Ω ) := Π :-
   is_dict(Σ),
   fixpt(Ω, [], Π).


%  Π is the greatest fixed-point of a function Ω, w.r.t. Σ

Σ.ν( Ω ) := Π :-
   is_dict(Σ),
   fixpt(Ω, Σ.univ(), Π).


/*
 *  AUXILIARY PREDICATES
 */


:- meta_predicate set(?, ^, -).


% True if P is an atomic formula (i.e., a proposition)

atm(Φ) :-
   (   atomic(Φ), !
   ;   ground(Φ),
       compound_name_arity(Φ, N, _),
       not( memberchk(N, [not, and, or, ex, ax, eu, au, ef, af, eg, ag]) ) ).


%  S is the set of elements X that satisfy the condition C

set(X, C, S) :-
   findall(X, C, L),
   sort(L, S).


%  Δ is the domain of policy Π (i.e., the set of states covered by Π)

dom(Π, Δ) :-
   set(S, member((S,_), Π), Δ).


%  Π is the intersection of a policy Π0 and a set of unlabeled states Δ

inter(Π0, Δ, Π) :-
   set((S,A), ( member((S,A), Π0),
                member(S, Δ) ), Π).


%  Π is the policy Π0 pruned w.r.t. states already covered by policy Π1

prune(Π0, Π1, Π) :-
   (   flag(scope, min, min)
   ->  dom(Π1, Δ),
       set((S,A), ( member((S,A), Π0),
                    not(member(S, Δ)) ), Π)
   ;   Π = Π0 ).


%  Π is the subset of Π0 that contains all live-ends of Π0

goals(Π0, Π) :-
   set((S,τ), member((S,τ), Π0), Π).


%  Fixed-point of a λ-lambda function, starting with X = X0

fixpt(λ(X,Ω,Y), X0, Y) :-
   nb_setval(fp, x(X0)),
   repeat,
      nb_getval(fp, x(X)),
      call(Ω),
      nb_setval(fp, x(Y)),
   Y = X, !.


/*
 *  EXTRA-LOGICAL PREDICATES
 */


%  Print formatted LTS

portray(Σ) :-
   is_dict(Σ, lts),
   sort(Σ.states, Λ),
   sort(Σ.transitions, Γ),
   wherex(X),
   Column is X + 5,
   write('lts{ '),
   ansi_format([bold], 'states:      ', []),
   portray_list(Γ, Λ),
   writeln(','),
   tab(Column),
   ansi_format([bold], 'transitions: ', []),
   portray_list(Γ, Γ),
   write(' }').

portray_list(Γ, L) :-
   wherex(X),
   Column is X - 6,
   write('[ '),
   portray_list(Γ, L, true, Column),
   write(' ]').

portray_list(_, [], _, _) :- !.
portray_list(Γ, [H|T], First, Column) :-
   ( First -> true ; tab(Column) ),
   portray_item(Γ, H),
   (  T \= []
   -> writeln(', ')
   ;  true  ),
   portray_list(Γ, T, false, Column).

portray_item(Γ, S:L) :- !,
   (   member((S,_,_), Γ)
   ->  format('~w: ~W', [S, L, [spacing(next_argument)]])
   ;   ansi_format([fg(red)], '~w: ~W', [S, L, [spacing(next_argument)]]) ).

portray_item(_, (S1,A,S2)) :- !,
   ansi_format([fg(blue)], '(~w, ~w, ~W)', [S1, A, S2, [spacing(next_argument)]]).


%  Get cursor current column in the output

wherex(X) :-
   stream_property(current_output, position(Position)),
   stream_position_data(line_position, Position, X).


%  Generate web documentation

gendoc :-
    doc_server(4000),
    portray_text(true),
    doc_browser.

/*
 *  MODELS (LTSs REPRESENTING NONDETERMINISTIC PLANNING DOMAINS)
 */


%---------------------------------------------------------------
%  SELF-LOOP IN STATE 3
%
%            a--> 1:[p] ----b----> 2:[r]
%           /         ^    /      ^
%          /           \  /      /
%         /             \/      /
%  0:[p,q]                     /
%         \         a         /
%          \       / \       /
%           \     v   \     /
%            b--> 3:[q] ---c---> 4:[p,q,r]
%
%
%  ?- sat(1, ef(and(not(p),r)) ).
%  ?- sat(1, ag(ef(and(not(p),r))) ).

model( 1,
       lts{ states: [ 0: [p, q],
                      1: [p],
                      2: [r],
                      3: [q],
                      4: [p, q, r] ],

            transitions: [ (0, a, [1]),
                           (0, b, [3]),
                           (1, b, [1, 2]),
                           (3, a, [3]),
                           (3, c, [2 ,4]) ] } ).


%---------------------------------------------------------------
%  SELF-LOOP IN STATE 3 IS DISSOLVED BY ACTION d
%
%            a--> 1:[p] ----b----> 2:[r]
%           /       ^ ^    /      ^
%          /        |  \  /      /
%         /         |   \/      /
%  0:[p,q]          |          /
%         \         d         /
%          \       / \       /
%           \     v   \     /
%            b--> 3:[q] ---c---> 4:[p,q,r]
%                 ^   /
%                  \ /
%                   a
%
%  ?- sat(2, ef(and(r,not(p))) ).
%  ?- sat(2, ag(ef(and(r,not(p)))) ).

model( 2,
       lts{ states: [ 0: [p, q],
                      1: [p],
                      2: [r],
                      3: [q],
                      4: [p, q, r] ],

            transitions: [ (0, a, [1]),
                           (0, b, [3]),
                           (1, b, [1, 2]),
                           (3, a, [3]),
                           (3, c, [2 ,4]),
                           (3, d, [1, 3]) ] } ).


%---------------------------------------------------------------
%  SELF-LOOP IN STATE 3 AND TRAP FORMED BY STATES 3 AND 4
%
%            a--> 1:[p] ----b----> 2:[r]
%           /         ^    /      ^
%          /           \  /      /
%         /             \/      /
%  0:[p,q]                     /
%         \         a         /
%          \       / \       /
%           \     v   \     /
%            b--> 3:[q] ---c---> 4:[p,q,r]
%                  ^ \
%                 /   \
%                a     b
%                 \   /
%                  \ v
%                5:[p,r]
%
%  ?- sat(3, ag(ef(and(r,not(p)))) ).
%  ?- sat(3, ag(eu(p,r)) ).
%  ?- sat(3, ag(eu(q,r)) ).

model( 3,
       lts{ states: [ 0: [p, q],
                      1: [p],
                      2: [r],
                      3: [q],
                      4: [p, q, r],
                      5: [p, r] ],

            transitions: [ (0, a, [1]),
                           (0, b, [3]),
                           (1, b, [1, 2]),
                           (3, b, [5]),
                           (3, a, [3]),
                           (3, c, [2 ,4]),
                           (5, a, [3]) ] } ).


%---------------------------------------------------------------
%  SELF-LOOP IN STATE 3 AND TRAP FORMED BY STATES 3 AND 4
%  ARE DISSOLVED BY ACTION d
%
%            a--> 1:[p] ----b----> 2:[r]
%           /      ^  ^    /      ^
%          /        \  \  /      /
%         /          \  \/      /
%  0:[p,q]            \        /
%         \       a   d--+    /
%          \     / \  / /    /
%           \   v   \/ v    /
%            b--> 3:[q] ---c---> 4:[p,q,r]
%                  ^ \
%                 /   \
%                a     b
%                 \   /
%                  \ v
%                5:[p,r]
%
%  ?- sat(4, ag(ef(and(r,not(p)))) ).
%  ?- sat(4, ag(ef(r)) ).
%  ?- sat(4, ag(eu(p,r)) ).
%  ?- sat(4, ag(eu(q,r)) ).
%  ?- sat(4, ag(eu(or(p,q), r)) ).

model( 4,
       lts{ states: [ 0: [p, q],
                      1: [p],
                      2: [r],
                      3: [q],
                      4: [p, q, r],
                      5: [p, r] ],

            transitions: [ (0, a, [1]),
                           (0, b, [3]),
                           (1, b, [1, 2]),
                           (3, a, [3]),
                           (3, b, [5]),
                           (3, c, [2 ,4]),
                           (3, d, [1, 3]),
                           (5, a, [3]) ] } ).


%---------------------------------------------------------------
%  CASCADING PRUNING, STARTING FROM STATE 13
%
%  0:[] ---b---> 2:[q] ---a--> 5:[p,q] --a----> 9:[q,s]
%   |                ^               ^  /
%   a                 \               \/
%   |                  \
%   v                   \
%  1:[p] ---b--> 4:[s] --a---> 8:[q,r] --a--> 12:[p,q,s]
%   |             ^                       \
%   c             |                        \
%   |             a                         \
%   v             |                          v
%  3:[r] ---b--> 7:[p,s] -c-> 11:[p,q,r] -a-> 14:[q,r,s]
%   | ^ ^              ^                      ^ |
%   a c  \             |            b        /  c
%   | |\  \           / \          / \      /   |
%   v | v  \         v   \        v   \    /    v
%  6:[p,r] -b-> 10:[r,s] -c-> 13:[p,r,s] -a-> 15:[p,q,r,s]
%
%  ?- sat(5, af(and(and(not(p),q),and(r,s))) ).
%  ?- sat(5, ag(ef(and(and(not(p),q),and(r,s)))) ).

model( 5,
       lts{ states: [  0: [],
                       1: [p],
                       2: [q],
                       3: [r],
                       4: [s],
                       5: [p, q],
                       6: [p, r],
                       7: [p, s],
                       8: [q, r],
                       9: [q, s],
                      10: [r, s],
                      11: [p, q, r],
                      12: [p, q, s],
                      13: [p, r, s],
                      14: [q, r, s],
                      15: [p, q, r, s] ],

            transitions: [ ( 0, a, [1]),
                           ( 0, b, [2]),
                           ( 1, c, [3]),
                           ( 1, b, [4]),
                           ( 2, a, [5]),
                           ( 3, a, [6]),
                           ( 3, b, [7]),
                           ( 4, a, [2, 8]),
                           ( 5, a, [5, 9]),
                           ( 6, b, [3, 10]),
                           ( 6, c, [3, 6]),
                           ( 7, a, [4]),
                           ( 7, c, [11]),
                           ( 8, a, [12, 14]),
                           (10, c, [7, 10, 13]),
                           (11, a, [14]),
                           (13, a, [14, 15]),
                           (13, b, [13]),
                           (14, c, [15]) ] } ).


%---------------------------------------------------------------
%  GRIPPER DOMAIN, WITH TWO ROOMS AND ONE BALL
%  ACTION GRAB IS NONDETERMINISTIC

model( 6,

       lts{states: [ 0: [free(left),  free(right), at(robot,1), at(ball,1)],
                     1: [free(left),  free(right), at(robot,2), at(ball,1)],
                     2: [free(right), at(robot,1), carry(ball,left)],
                     3: [free(left),  at(robot,1), carry(ball,right)],
                     4: [free(right), at(robot,2), carry(ball,left)],
                     5: [free(left),  at(robot,2), carry(ball,right)],
                     6: [free(left),  free(right), at(robot,2), at(ball,2)],
                     7: [free(left),  free(right), at(robot,1), at(ball,2)] ],

         transitions: [ (0, move(1,2),          [1]),
                        (0, grab(ball,left),    [0, 2]),
                        (0, grab(ball,right),   [0, 3]),
                        (1, move(2,1),          [0]),
                        (2, drop(ball,1,left),  [0]),
                        (2, move(1,2),          [4]),
                        (3, drop(ball,1,right), [0]),
                        (3, move(1,2),          [5]),
                        (4, move(2,1),          [2]),
                        (4, drop(ball,2,left),  [6]),
                        (5, move(2,1),          [3]),
                        (5, drop(ball,2,right), [6]),
                        (6, grab(ball,2,left),  [4, 6]),
                        (6, grab(ball,2,right), [5, 6]),
                        (6, move(2,1),          [7]),
                        (7, move(1,2),          [6]) ] } ).

% ?- sat(6, ag(ef( at(ball,2) )) ).
% ?- sat(6, ag(eu(free(right),at(ball,2))) ). % mantain left gripper free






