(**************************************************************************)
(*                                                                        *)
(*                                  Cubicle                               *)
(*             Combining model checking algorithms and SMT solvers        *)
(*                                                                        *)
(*                  Mohamed Iguernelala                                   *)
(*                  Universite Paris-Sud 11                               *)
(*                                                                        *)
(*  Copyright 2011. This file is distributed under the terms of the       *)
(*  Apache Software License version 2.0                                   *)
(*                                                                        *)
(**************************************************************************)

module V = Sparse_vec

type t = {heap : int Vec.t; indices : int V.t }

let _absent_index = -1

let init sz =
  { heap    =  Vec.init sz (fun i -> i) 0;
    indices =  V.init sz (fun i -> i) _absent_index}

let left i   = (i lsl 1) + 1 (* i*2 + 1 *)
let right i  = (i + 1) lsl 1 (* (i+1)*2 *)
let parent i = (i - 1) asr 1 (* (i-1) / 2 *)

(*
let rec heap_property cmp ({heap=heap} as s) i =
  i >= (Vec.size heap)  ||
    ((i = 0 || not(cmp (Vec. get heap i) (Vec.get heap (parent i))))
     && heap_property cmp s (left i) && heap_property cmp s (right i))

let heap_property cmp s = heap_property cmp s 1
*)

let percolate_up cmp {heap=heap;indices=indices} i =
  let x = Vec.get heap i in
  let pi = ref (parent i) in
  let i = ref i in
  while !i <> 0 && cmp x (Vec.get heap !pi) do
    Vec.set heap !i (Vec.get heap !pi);
    V.set indices (Vec.get heap !i) !i;
    i  := !pi;
    pi := parent !i
  done;
  Vec.set heap !i x;
  V.set indices x !i

let percolate_down cmp {heap=heap;indices=indices} i =
  let x = Vec.get heap i in
  let sz = Vec.size heap in
  let li = ref (left i) in
  let ri = ref (right i) in
  let i = ref i in
  (try
     while !li < sz do
       let child =
         if !ri < sz && cmp (Vec.get heap !ri) (Vec.get heap !li) then !ri
         else !li
       in
       if not (cmp (Vec.get heap child) x) then raise Exit;
       Vec.set heap !i (Vec.get heap child);
       V.set indices (Vec.get heap !i) !i;
       i  := child;
       li := left !i;
       ri := right !i
     done;
   with Exit -> ());
  Vec.set heap !i x;
  V.set indices x !i

let in_heap s n = n < V.length s.indices && V.get s.indices n >= 0

let decrease cmp s n =
  assert (in_heap s n); percolate_up cmp s (V.get s.indices n)

let increase cmp s n =
  assert (in_heap s n); percolate_down cmp s (V.get s.indices n)

let filter s filt cmp =
  let j = ref 0 in
  let lim = Vec.size s.heap in
  for i = 0 to lim - 1 do
    if filt (Vec.get s.heap i) then begin
      Vec.set s.heap !j (Vec.get s.heap i);
      V.set s.indices (Vec.get s.heap i) !j;
      incr j;
    end
    else V.set s.indices (Vec.get s.heap i) _absent_index;
  done;
  Vec.shrink s.heap (lim - !j);
  for i = (lim / 2) - 1 downto 0 do
    percolate_down cmp s i
  done

let size s = Vec.size s.heap

let is_empty s = Vec.is_empty s.heap

let clear {heap; indices} =
  Vec.clear heap;
  V.clear indices;
  ()

let insert cmp s n =
  if not (in_heap s n) then
    begin
      V.set s.indices n (Vec.size s.heap);
      Vec.push s.heap n;
      percolate_up cmp s (V.get s.indices n)
    end

let grow_to_by_double s sz =
  V.resize s.indices sz;
  Vec.grow_to_by_double s.heap sz

(*
let update cmp s n =
  assert (heap_property cmp s);
  begin
    if in_heap s n then
      begin
        percolate_up cmp s (Vec.get s.indices n);
        percolate_down cmp s (Vec.get s.indices n)
      end
    else insert cmp s n
  end;
  assert (heap_property cmp s)
*)

let remove_min cmp ({heap=heap; indices=indices} as s) =
  if Vec.size heap=0 then raise Not_found;
  let x = Vec.get heap 0 in
  Vec.set heap 0 (Vec.last heap); (*heap.last()*)
  V.set indices (Vec.get heap 0) 0;
  V.set indices x (-1);
  Vec.pop s.heap;
  if Vec.size s.heap > 1 then percolate_down cmp s 0;
  x

