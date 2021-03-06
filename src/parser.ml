(* --------------------------------------- *)
(* - Parser for chip-8 assembly language - *)
(* - Written by A. Correnson             - *) 
(* - and T. Barriere                     - *)
(* --------------------------------------- *)

open Lexer

(* Type for addresses and registers *)
type arg =
  | Reg of int
  | Addr of int
  | Saddr of string
  | Cst of int
  | I (* address register *)
  | F 
  | B
  | DT  (* delay Timer *)
  | ST  (* sound Timer *)
  | K   (* Keyboard *)


(* Type for instructions *)
type ins =
  | CLS
  | RET
  | CALL of arg
  | SE of arg * arg
  | SNE of arg * arg
  | LD of arg
  | LD2 of arg * arg
  | ADD of arg * arg
  | OR of arg * arg
  | AND of arg * arg
  | XOR of arg * arg
  | SUB of arg * arg
  | SHR of arg * arg
  | SUBN of arg * arg
  | SHL of arg * arg
  | RND of arg * arg
  | DRW of arg * arg * arg
  | SKP of arg
  | SKNP of arg
  | JP of arg
  | JP2 of arg * arg
  | DW of arg
  | END
  | LBL of string

let pp_arg a =
  match a with
  | Reg a -> print_int a; print_newline ();
  | Addr n -> print_int n; print_newline ();
  | Cst n -> print_int n; print_newline ();
  | I -> print_char 'I'; print_newline ();
  | K -> print_char 'K'; print_newline ();
  | F -> print_char 'F'; print_newline ();
  | B -> print_char 'B'; print_newline ();
  | DT -> print_string "DT"; print_newline ();
  | ST -> print_string "ST"; print_newline ();
  | Saddr a -> print_string a; print_newline ()

let pp_ins i =
  match i with
  | ADD (Reg n, Reg m) ->
    print_endline ("ADD V" ^ (string_of_int n) ^ " V" ^ (string_of_int m))
  | ADD (Reg n, Cst m) ->
    print_endline ("ADD V" ^ (string_of_int n) ^ " " ^ (string_of_int m))
  | JP (Addr n) -> print_endline ("JP " ^ (string_of_int n))
  | JP (Saddr s) -> print_endline ("JP " ^ s)
  | ADD (_, _) -> print_endline "ADD"
  | LD _ -> print_endline "LD a"
  | LD2 (Reg _, Reg _) -> print_endline "LD V V"
  | LD2 (Reg _, DT) -> print_endline "LD V DT"
  | LD2 (DT, Reg _) -> print_endline "LD DT V"
  | LD2 (ST, Reg _) -> print_endline "LD ST V"
  | LD2 (F, Reg _) -> print_endline "LD F V"
  | LD2 (B, Reg _) -> print_endline "LD B V"
  | LD2 (Reg _, Cst _) -> print_endline "LD V cst"
  | LD2 (Reg _, K) -> print_endline "LD V K"
  | LD2 (I, Addr _) -> print_endline "LD V cst"
  | LD2 (a, b) -> print_endline "Ukn LD"; pp_arg a; pp_arg b
  | XOR (_, _) -> print_endline "XOR"
  | OR (_, _) -> print_endline "OR"
  | AND _ -> print_endline "AND"
  | SHR _ -> print_endline "SHR"
  | SHL _ -> print_endline "SHL"
  | SKP _ -> print_endline "SKP"
  | SKNP _ -> print_endline "SKNP"
  | JP _ -> print_endline "JP"
  | CLS -> print_endline "CLS"
  | RET -> print_endline "RET"
  | SUB _ -> print_endline "SUB"
  | SUBN _ -> print_endline "SUBN"
  | DRW _ -> print_endline "DRW"
  | CALL _ -> print_endline "CALL"
  | SE _ -> print_endline "SE"
  | SNE _ -> print_endline "SNE"
  | DW _ -> print_endline "DW"
  | LBL _ -> print_endline "lbl"
  | END -> print_endline "END"
  | RND _ -> print_endline "RND"
  | JP2 _ -> print_endline "JP2"


let get_reg r =
  hex (String.sub r 1 ((String.length r) - 1) ) 0 0.0

let is_reg x =
  let r = Str.regexp "V[0-9A-F]+" in 
  Str.string_match r x 0

let is_addr x =
  let r = Str.regexp "[0-9]+" in
  Str.string_match r x 0

let ext_arg pks =
  let l = lex pks in
  match l with
  | Lsym n when is_reg n -> Reg (get_reg n)
  | Lsym n -> Saddr n
  | Lnum n -> Cst n
  | _ -> failwith "Expecting arg..."

let ext3_args pks =
  let l1 = lex pks in
  let l2 = lex pks in
  let l3 = lex pks in
  let l4 = lex pks in
  let l5 = lex pks in
  match (l1, l2, l3, l4, l5) with
  | (Lsym vx, Lsep, Lsym vy, Lsep, Lnum n) when is_reg vx && is_reg vy ->
    Reg (get_reg vx), Reg (get_reg vy), Cst n
  | _ -> failwith "Wrong args for DRW"

let ext2_args pks =
  let l1 = lex pks in
  let l2 = lex pks in
  let l3 = lex pks in
  match (l1, l2, l3) with
  (* Vx, byte *)
  | (Lsym n, Lsep, Lnum m) when is_reg n -> Reg (get_reg n), Cst m
  (* Vx, Vy *)
  | (Lsym n, Lsep, Lsym m) when is_reg n && is_reg m -> Reg (get_reg n), Reg (get_reg m)
  (* I, Vx *)
  | (Lsym "I", Lsep, Lsym m) when is_reg m -> I, Reg (get_reg m)
  (* I, addr *)
  | (Lsym "I", Lsep, Lsym m) -> I, Saddr  m
  (* DT, Vx *)
  | (Lsym "DT", Lsep, Lsym m) when is_reg m -> DT, Reg (get_reg m)
  (* ST, Vx *)
  | (Lsym "ST", Lsep, Lsym m) when is_reg m -> ST, Reg (get_reg m)
  (* Vx, DT *)
  | (Lsym n, Lsep, Lsym "DT") when is_reg n -> Reg (get_reg n), DT
  (* Vx, ST *)
  | (Lsym n, Lsep, Lsym "ST") when is_reg n -> Reg (get_reg n), ST
  (* F, Vx *)
  | (Lsym "F", Lsep, Lsym m) when is_reg m -> F, Reg (get_reg m)
  (* B, Vx *)
  | (Lsym "B", Lsep, Lsym m) when is_reg m -> B, Reg (get_reg m)
  | _ -> pp_lexem l1; pp_lexem l2; pp_lexem l3; failwith "Expecting 2 args..."


let process_ld pks =
  let l1 = lex pks in
  let l2 = lex pks in
  let l3 = lex pks in
  match (l1, l2, l3) with
  | (Lsym n, Lsep, Lsym "DT") when is_reg n -> LD2 (Reg (get_reg n), DT)
  | (Lsym "DT", Lsep, Lsym n) when is_reg n -> LD2 (DT, Reg (get_reg n))
  | (Lsym "ST", Lsep, Lsym n) when is_reg n -> LD2 (ST, Reg (get_reg n))
  | (Lsym n, Lsep, Lsym "ST") when is_reg n -> LD2 (Reg (get_reg n), ST)
  | (Lsym "I", Lsep, Lsym n) when is_reg n  -> LD2 (I, Reg (get_reg n))
  | (Lsym n, Lsep, Lsym "I") when is_reg n  -> LD2 (Reg (get_reg n), I)
  | (Lsym "I", Lsep, Lsym m)    -> LD2 (I, Saddr m)
  | (Lsym n, Lsep, Lsym "K") when is_reg n  -> LD2 (Reg (get_reg n), K)
  | (Lsym "B", Lsep, Lsym n) when is_reg n  -> LD2 (B, Reg (get_reg n))
  | (Lsym "F", Lsep, Lsym n) when is_reg n  -> LD2 (F, Reg (get_reg n))
  | (Lsym n, Lsep, Lsym m) when is_reg n && is_reg m -> LD2 (Reg (get_reg n), Reg (get_reg m))
  | (Lsym n, Lsep, Lsym m) when is_reg n    -> LD2 (Reg (get_reg n), Saddr m)
  | (Lsym n, Lsep, Lnum m) when is_reg n    -> LD2 (Reg (get_reg n), Cst m)
  | (a, _, b) -> pp_lexem a; pp_lexem b; failwith "Incorrect use of LD"


let parser pks =
  let l = lex pks in
  match l with
  | Lend -> END
  | Lsep -> failwith "useless sep ,"
  | Lnum n -> failwith ("useless num " ^ (string_of_int n))
  | Llbl -> failwith "empty label"
  | Lsym "CLS" -> CLS
  | Lsym "CALL" ->
    let a = ext_arg pks in CALL a
  | Lsym "RET" -> RET
  | Lsym "DW" ->
    let a = ext_arg pks in DW a
  | Lsym "RND" ->
    let a, b = ext2_args pks in RND (a, b)
  | Lsym "ADD" ->
    let a, b = ext2_args pks in ADD (a, b)
  | Lsym "JP" ->
    let a = ext_arg pks in JP a
  | Lsym "SE" ->
    let a, b = ext2_args pks in SE (a, b)
  | Lsym "LD" ->
    process_ld pks
  | Lsym "SHL" ->
    let a, b = ext2_args pks in SHL (a, b)
  | Lsym "SHR" ->
    let a, b = ext2_args pks in SHR (a, b)
  | Lsym "SUB" ->
    let a, b = ext2_args pks in SUB (a, b)
  | Lsym "SUBN" ->
    let a, b = ext2_args pks in SUBN (a, b)
  | Lsym "XOR" ->
    let a, b = ext2_args pks in XOR (a, b)
  | Lsym "OR" ->
    let a, b = ext2_args pks in OR (a, b)
  | Lsym "AND" ->
    let a, b = ext2_args pks in AND (a, b)
  | Lsym "DRW" ->
    let a, b, c = ext3_args pks in DRW (a, b, c)
  | Lsym "SKP" ->
    let a = ext_arg pks in SKP a
  | Lsym "SKNP" ->
    let a = ext_arg pks in SKNP a
  | Lsym "SNE" ->
    let a, b = ext2_args pks in SNE (a, b)
  | Lsym x ->
    match lex pks with
    | Llbl -> LBL x
    | _ -> failwith ("unknown symbol " ^ x ^ " you may have forgot a :")
