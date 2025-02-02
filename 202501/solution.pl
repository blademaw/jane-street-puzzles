%% Description: Solution for January 2025 Jane Street puzzle.
%% Author:      Jack Oliver
%%
%% Instructions: open SWI-Prolog (`swipl`) and load the file (`[solution].`),
%% then call `solve_puzzle(G, GCD), maplist(portray_clause, G).`

% `CLP(FD)` for constraint propagation and `pairs` for key-wise sorting
:- use_module(library(clpfd)).
:- use_module(library(pairs)).


% factors deduced via Python script
factors(1, [2, 3, 4, 6, 9, 11, 12, 18, 22, 33, 36, 37, 44, 66, 74, 99, 111, 132, 148, 198, 222, 333, 396, 407, 444, 666, 814, 1221, 1332, 1628, 2442, 3663, 4884, 7326, 14652, 333667, 667334, 1001001, 1334668, 2002002, 3003003, 3670337, 4004004, 6006006, 7340674, 11011011, 12012012, 12345679, 14681348, 22022022, 24691358, 33033033, 37037037, 44044044, 49382716, 66066066, 74074074, 111111111, 132132132, 135802469, 148148148, 222222222, 271604938, 407407407, 444444444, 543209876, 814814814, 1222222221, 1629629628, 2444444442, 4888888884]).
factors(3, [2, 3, 6, 7, 9, 14, 18, 21, 27, 37, 42, 54, 63, 74, 111, 126, 189, 222, 259, 333, 378, 518, 666, 777, 999, 1554, 1998, 2331, 4662, 6993, 13986, 333667, 667334, 1001001, 2002002, 2335669, 3003003, 4671338, 6006006, 7007007, 9009009, 12345679, 14014014, 18018018, 21021021, 24691358, 37037037, 42042042, 63063063, 74074074, 86419753, 111111111, 126126126, 172839506, 222222222, 259259259, 333333333, 518518518, 666666666, 777777777, 1555555554, 2333333331, 4666666662]).
factors(4, [3, 9, 37, 41, 111, 123, 333, 369, 1517, 4551, 13653, 333667, 1001001, 3003003, 12345679, 13680347, 37037037, 41041041, 111111111, 123123123, 506172839, 1518518517, 4555555551]).
factors(6, [1, 3, 9, 13, 27, 37, 39, 111, 117, 333, 351, 481, 999, 1443, 4329, 12987, 333667, 1001001, 3003003, 4337671, 9009009, 12345679, 13013013, 37037037, 39039039, 111111111, 117117117, 160493827, 333333333, 481481481, 1444444443, 4333333329]).
factors(7, [2, 3, 6, 9, 18, 19, 37, 38, 57, 74, 111, 114, 171, 222, 333, 342, 666, 703, 1406, 2109, 4218, 6327, 12654, 333667, 667334, 1001001, 2002002, 3003003, 6006006, 6339673, 12345679, 12679346, 19019019, 24691358, 37037037, 38038038, 57057057, 74074074, 111111111, 114114114, 222222222, 234567901, 469135802, 703703703, 1407407406, 2111111109, 4222222218]).
factors(8, [3, 9, 37, 111, 333, 1369, 4107, 12321, 333667, 1001001, 3003003, 12345679, 37037037, 111111111, 456790123, 1370370369, 4111111107]).
factors(9, [2, 3, 4, 6, 9, 12, 18, 27, 36, 37, 54, 74, 81, 108, 111, 148, 162, 222, 324, 333, 444, 666, 999, 1332, 1998, 2997, 3996, 5994, 11988, 333667, 667334, 1001001, 1334668, 2002002, 3003003, 4004004, 6006006, 9009009, 12012012, 12345679, 18018018, 24691358, 27027027, 36036036, 37037037, 49382716, 54054054, 74074074, 108108108, 111111111, 148148148, 222222222, 333333333, 444444444, 666666666, 999999999, 1333333332, 1999999998, 3999999996]).


% solve_puzzle/2 binds a grid G and GCD with a solution satisfying the puzzle
solve_puzzle(G, GCD) :-
  candidates(SortedCandidates),
  solve_puzzle_aux(G, SortedCandidates, GCD).


% auxiliary predicate for solve_puzzle--iteratively tries GCD candidates until
% a valid solution is found
solve_puzzle_aux(G, [Factor-Digit|T], GCD) :-
  puzzle(G),
  ( valid_sol(G, Digit, Factor) ->
    GCD = Factor, !
  ; solve_puzzle_aux(G, T, GCD)
  ).


% candidates/1 binds ordered Candidates in key-value format where the key is
% the factor and the value is the deleted digit
candidates(Candidates) :-
  findall(
    Factor-DelDigit,
    (
      factors(DelDigit, Factors),
      member(Factor, Factors)
    ),
    AllCandidates
  ),
  keysort(AllCandidates, SortedCandidates),
  reverse(SortedCandidates, Candidates).


% predicate to solve puzzle given a grid, excluded digit, and a GCD
valid_sol(Grid, DelDigit, GCD) :-
  % valid sudoku shape
  length(Grid, 9),
  maplist(same_length(Grid), Grid),
  append(Grid, AllCells),

  % puzzle uses digits 0-9 except one
  AllCells ins 0..9,
  member(DelDigit, [1,3,4,6,7,8,9]),
  maplist(clpfd_ne(DelDigit), AllCells),

  % all rows & columns have distinct digits
  maplist(all_distinct, Grid),
  transpose(Grid, Cols), maplist(all_distinct, Cols),

  % sudoku boxes
  Grid = [As,Bs,Cs,Ds,Es,Fs,Gs,Hs,Is],
  blocks(As, Bs, Cs),
  blocks(Ds, Es, Fs),
  blocks(Gs, Hs, Is),

  % puzzle constraint: GCD divides each row-wise number
  maplist(list_to_integer, Grid, RowNumbers),
  maplist(is_divisible(GCD), RowNumbers),
  maplist(label, Grid).


% helper predicate for boxes
blocks([], [], []).
blocks([N1,N2,N3|Ns1], [N4,N5,N6|Ns2], [N7,N8,N9|Ns3]) :-
  all_distinct([N1,N2,N3,N4,N5,N6,N7,N8,N9]),
  blocks(Ns1, Ns2, Ns3).


% custom CLPFD predicate for inequality
clpfd_ne(A, B) :- A #\= B.


% flipped predicate for divisibility
is_divisible(B, A) :- A mod B #= 0.


% predicate to convert list of digits to integer
list_to_integer([], 0).
list_to_integer([Digit|Rest], Number) :-
  list_to_integer(Rest, RestNumber),
  length(Rest, Len),
  Power #= 10^Len,
  Number #= Digit * Power + RestNumber.


puzzle(Grid) :-
  Grid = [
  [_, _, _, _, _, _, _, 2, _],
  [_, _, _, _, 2, _, _, _, 5], % note that this 2 is implicit in the grid
  [_, 2, _, _, _, _, _, _, _],
  [_, _, 0, _, _, _, _, _, _],
  [_, _, _, _, _, _, _, _, _],
  [_, _, _, 2, _, _, _, _, _],
  [_, _, _, _, 0, _, _, _, _],
  [_, _, _, _, _, 2, _, _, _],
  [_, _, _, _, _, _, 5, _, _]
  ].
