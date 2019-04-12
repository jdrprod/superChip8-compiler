(* --------------------------------------- *)
(* - Parser for chip-8 assembly language - *)
(* - Written by A. Correnson ------------- *) 
(* - and T. Barriere  -------------------- *)
(* --------------------------------------- *)

open Str

(* Type for adresses and registers *)
type adr = Adr of int
type reg = Reg of int

(* Type for instructions *)
type ins = 
  | ADD of reg * reg
  | JP of adr


exception Adress_out_of_range
exception Non_existing_register


(* check if a register index is correct *)
(* chip-8 has 16 avaliable registers *)
let check_reg_index r =
  match r with
  | Reg n when n < 16 && n >= 0 -> ()
  | _ -> raise Non_existing_register


(* check if an adress is correct *)
(* chip-8 has 4096 8-bit memory slots *)
let check_adr a =
  match a with
  | Adr n when n < 4096 && n >= 0 -> ()
  | _ -> raise Adress_out_of_range


(* check if an instruction is correct *)
let check_ins i =
  match i with
  | ADD (r1, r2) ->
    check_reg_index r1; check_reg_index r2
  | JP a ->
    check_adr a


(* TEST FOR CHECK FUNCTIONS *)
let a = ADD (Reg 15, Reg 1)
let b = JP (Adr 23)
let c = JP (Adr 5000)
let main = 
  check_ins a; (* works *)
  check_ins b; (* works *)
  try check_ins c (* should fail *)
  with Adress_out_of_range ->
    print_endline "JP 5000 is not a valid instruction"


(* Alias for String.make *)
let to_str s =
  (String.make 1 s)

(* Prepend char to string *)
let prepend c s =
  (String.make 1 c) ^ s

(* Append char to string *)
let append s c =
  s ^ (String.make 1 c)


let rev l =
  let rec rev_r l lr =
    match l with
    | [] -> lr
    | h::t -> rev_r t (h::lr)
  in
  rev_r l []

let rec fill_buffer ic buff =
  try
    let c = input_char ic in
    fill_buffer ic (c::buff)
  with End_of_file -> rev buff

type lexem = 
  | Lins of string
  | Ladr of int
  | Lsep

let pp_lexem lx =
  match lx with
  | Lins str -> print_endline str
  | Ladr adr -> print_endline (string_of_int adr)
  | Lsep -> print_endline ","

(* test if a character is a digit *)
let is_digit d =
  let re = Str.regexp "[0-9]" in
  Str.string_match re (to_str d) 0

let is_char d =
  let re = Str.regexp "[_A-Za-z]" in
  Str.string_match re (to_str d) 0

let is_sep d =
  match d with
  '\n' | ' ' -> true
  | _ -> false

(* Scan for a number *)
let scan_number buff =
  let rec _scan_number buff number =
    match buff with
    | d::nbuff when is_digit d ->
      _scan_number nbuff (append number d)
    | _ -> Ladr (int_of_string number), buff
  in
  _scan_number buff ""


(* Scan for an instruction *)
let scan_ins buff =
  let rec _scan_string buff str =
    match buff with
    | c::nbuff when is_sep c -> Lins str, buff
    | c::nbuff -> _scan_string nbuff (append str c)
    | [] -> Lins str, buff
  in
  _scan_string buff ""

(* lex | tokenize a file *)
(* NOTE : This function is an exemple, it is not the real lexer *)
let lex f =
  let rec lex_r buff l =
    match buff with
    | c::tail when is_digit c ->
      let lx, nbuff = scan_number buff in
      lex_r nbuff (lx::l)
    | c::tail when c == ',' ->
      lex_r tail (Lsep::l)
    | c::tail when is_sep c ->
      lex_r tail l
    | c::tail when is_char c ->
      let lx, nbuff = scan_ins buff in
      lex_r nbuff (lx::l)
    | [] -> l
    | _ -> failwith "Lexing error"
  in
  let ic = open_in f in
  let buff = fill_buffer ic [] in
  rev (lex_r buff [])

let _ =
  List.iter pp_lexem (lex "test.txt");