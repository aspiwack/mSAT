(**************************************************************************)
(*                                                                        *)
(*                                  Cubicle                               *)
(*             Combining model checking algorithms and SMT solvers        *)
(*                                                                        *)
(*                  Sylvain Conchon, Evelyne Contejean                    *)
(*                  Francois Bobot, Mohamed Iguernelala, Alain Mebsout    *)
(*                  CNRS, Universite Paris-Sud 11                         *)
(*                                                                        *)
(*  Copyright 2011. This file is distributed under the terms of the       *)
(*  Apache Software License version 2.0                                   *)
(*                                                                        *)
(**************************************************************************)

module type S = sig
  (** Signature for theories to be given to the Model Constructing Solver. *)

  type term
  (** The type of terms. Should be compatible with Expr_intf.Term.t*)

  type formula
  (** The type of formulas. Should be compatble with Expr_intf.Formula.t *)

  type proof
  (** A custom type for the proofs of lemmas produced by the theory. *)

  type assumption =
    | Lit of formula
    | Assign of term * term (* Assign(x, alpha) *)

  type slice = {
    start : int;
    length : int;
    get : int -> assumption * int;
    push : formula list -> proof -> unit;
    propagate : formula -> int -> unit;
  }
  (** The type for a slice of litterals to assume/propagate in the theory.
      [get] operations should only be used for integers [ start <= i < start + length].
      [push clause proof] allows to add a tautological clause to the sat solver. *)

  type level
  (** The type for levels to allow backtracking. *)

  (** Type returned by the theory, either the current set of assumptions is satisfiable,
      or it is not, in which case a tautological clause (hopefully minimal) is returned.
      Formulas in the unsat clause must come from the current set of assumptions, i.e
      must have been encountered in a slice. *)
  type res =
    | Sat
    | Unsat of formula list * proof

  type eval_res =
    | Valued of bool * int
    | Unknown

  val dummy : level
  (** A dummy level. *)

  val current_level : unit -> level
  (** Return the current level of the theory (either the empty/beginning state, or the
      last level returned by the [assume] function). *)

  val assume : slice -> res
  (** Assume the formulas in the slice, possibly pushing new formulas to be propagated,
      and returns the result of the new assumptions. *)

  val backtrack : level -> unit
  (** Backtrack to the given level. After a call to [backtrack l], the theory should be in the
      same state as when it returned the value [l], *)

  val assign : term -> term
  (** Returns an assignment value for the given term. *)

  val iter_assignable : (term -> unit) -> formula -> unit
  (** An iterator over the subterms of a formula that should be assigned a value (usually the poure subterms) *)

  val eval : formula -> eval_res
  (** Returns the evaluation of the formula in the current assignment *)

  val proof_debug : proof -> string * (formula list) * (term list) * (string option)
  (** Returns debugging information on a proof, as a triplet consisting of
      a name/identification string associated with the proof, arguments of the proof,
      and an optional color for the proof background *)

end

