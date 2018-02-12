:- multifile(typeannot/2).

% System predicates

system_type_annot(=, [tyvar(A), tyvar(A)], unit).
system_type_annot(\=, [tyvar(A), tyvar(A)], unit).
system_type_annot(==, [tyvar(A), tyvar(A)], unit).
system_type_annot(\==, [tyvar(A), tyvar(A)], unit).
system_type_annot(!, [], unit).
system_type_annot(\+, [unit], unit).
system_type_annot(true, [], unit).
system_type_annot(fail, [], unit).
system_type_annot(is, [int, int], unit).
system_type_annot(+, [int, int], int).
system_type_annot(-, [int, int], int).
system_type_annot(*, [int, int], int).
system_type_annot(/, [int, int], int).
system_type_annot(<, [int, int], unit).
system_type_annot(=<, [int, int], unit).
system_type_annot(>, [int, int], unit).
system_type_annot(>=, [int, int], unit).
system_type_annot(',', [unit, unit], unit).
system_type_annot([], [], list(tyvar(_A))).
system_type_annot('[|]', [tyvar(A), list(tyvar(A))], list(tyvar(A))).

% tyvar predicate ensure that the definition is not more spezial
% than die type annotation
new_inst_tyvars(InTy, OutTy) :- 
   new_inst_tyvars_list([InTy], [OutTy]).

new_inst_tyvars_list(InTys, OutTys) :- 
   new_inst_tyvars_list_cxt(_, InTys, OutTys).

new_inst_tyvars_list_cxt(_Cxt, [], []).
new_inst_tyvars_list_cxt(Cxt, [In|InS], [Out|OutS]) :- 
   new_inst_tyvars_cxt(Cxt, In, Out), 
   new_inst_tyvars_list_cxt(Cxt, InS, OutS).

new_inst_tyvars_cxt(Cxt, tyvar(In), Out) :-
  tyvar_cxt_lookup(Cxt, tyvar(In), Out).
new_inst_tyvars_cxt(_Cxt, int, int).
new_inst_tyvars_cxt(_Cxt, unit, unit).
new_inst_tyvars_cxt(Cxt, list(In), list(Out)) :- 
   new_inst_tyvars_cxt(Cxt, In, Out).

tyvar_cxt_lookup(Context, tyvar(In), Out) :-
   var(Context), !, Out = _NewVar,
   Context = [(tyvar(In), Out)| _NewContext].
tyvar_cxt_lookup([(tyvar(In1), Out1)|_Cxt], tyvar(In2), Out2) :-
   In1 == In2, !, Out1 = Out2.
tyvar_cxt_lookup([(tyvar(In1), _)|Cxt], tyvar(In2), Out) :-
  In1 \== In2, !, context_write(Cxt, tyvar(In2), Out).

context_write(Context, Y, T) :-
  var(Context), !, Context = [(Y, T)| _NewContext].

context_write([(X, T1)|_Context], Y, T2) :-
  write("context_write check found"), nl,
  X == Y, !, T1 = T2.

context_write([(X, _)|Context], Y, T) :-
  X \== Y, context_write(Context, Y, T).

checkparams(_Context, [], []).
checkparams(Context, [X|Xs], [Ty|Tys]) :-
  hastype(Context, X, Ty),
  checkparams(Context, Xs, Tys).

hastype(Context, A, T) :-
  var(A), !,
  write("hastype variable"), nl,
  context_write(Context, A, T).

hastype(_Context, A, int) :-
  integer(A), !,
  write("hastype integer"), nl.

hastype(Context, A, Ret) :-
  A =.. [B|Params], (atom(B); B == []), !,
  write("hastype predicate: "), write(B), nl,
  ((typeannot(B, Ty), Ret = unit) ;
	  system_type_annot(B, Ty, RetV)),
  write(typeannot(B, Ty)),nl,
  new_inst_tyvars_list(Ty, Ty2),
  new_inst_tyvars(RetV, Ret2),
  write(ret(Ret2)), nl,
  Ret2 = Ret,
  checkparams(Context, Params, Ty2).


zip([], [], _Zs).
zip([X|Xs], [Y|Ys], [Z|Zs]) :-
  Z = (X,Y),
  zip(Xs, Ys, Zs).

initcontext(Params, Tys, Context) :-
  zip(Params, Tys, Context).

checkrules :-
  forall(
    (typeannot(Id, Ty), atom(Id)),
    (length(Ty, TyLength),
      prettyprint(Id, Ty),
      functor(Head, Id, TyLength),
      forall(
        clause(Head, Body),
        (write("  Checking "), write(Head), nl,
         Head =.. [_|Params],
         normalize(Params, Body, NParams, NBody),
         write("  Params: "), write(NParams),nl,
         write("  Body: "), write(NBody),nl,
         initcontext(NParams, Ty, Context),
         hastype(Context, NBody, _T)
        )
      )
    )
  ).

prettyprint(Id, Ty) :-
  write(Id), tab(1), write(:), tab(1), write(Ty), nl.

samelength(XS, YS) :- length(XS, N), length(YS, N).

%?- current_predicate(p/X).
%X = 1 ;
%X = 2 ;
%false.
