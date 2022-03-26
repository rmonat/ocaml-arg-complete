type complete = string -> string list

type spec =
  | Unit of (unit -> unit)
  | Bool of (bool -> unit)
  | Set of bool ref
  | Clear of bool ref
  | String of (string -> unit) * complete
  | Set_string of string ref * complete
  | Int of (int -> unit) * complete
  | Set_int of int ref * complete
  | Float of (float -> unit) * complete
  | Set_float of float ref * complete

type arg_speclist = (Arg.key * Arg.spec * Arg.doc) list
type speclist = (Arg.key * spec * Arg.doc) list

let arg_spec: spec -> Arg.spec = function
  | Unit f -> Arg.Unit f
  | Bool f -> Arg.Bool f
  | Set r -> Arg.Set r
  | Clear r -> Arg.Clear r
  | String (f, _c) -> Arg.String f
  | Set_string (r, _c) -> Arg.Set_string r
  | Int (f, _c) -> Arg.Int f
  | Set_int (r, _c) -> Arg.Set_int r
  | Float (f, _c) -> Arg.Float f
  | Set_float (r, _c) -> Arg.Set_float r

let arg_speclist: speclist -> arg_speclist = fun l ->
  List.map (fun (k, sc, d) -> (k, arg_spec sc, d)) l

let complete_strings l s =
  List.filter (String.starts_with ~prefix:s) l

let complete_argv (argv: string array) (speclist: speclist) (_anon_complete: complete): string list =
  let rec complete_arg (argv: string list) =
    match argv with
    | [] -> []
    | arg :: argv' ->
      try
        let (_, spec, _) = List.find (fun (key, _, _) -> arg = key) speclist in
        match spec, argv' with
        | Unit _f, argv' -> complete_arg argv'
        | Bool _f, [arg'] -> complete_strings ["false"; "true"] arg'
        | Bool _f, _ :: argv' -> complete_arg argv'
        | Set _r, argv' -> complete_arg argv'
        | Clear _r, argv' -> complete_arg argv'
        | String (_f, c), [arg'] -> c arg'
        | String (_f, _c), _ :: argv' -> complete_arg argv'
        | Set_string (_r, c), [arg'] -> c arg'
        | Set_string (_r, _c), _ :: argv' -> complete_arg argv'
        | Int (_f, c), [arg'] -> c arg'
        | Int (_f, _c), _ :: argv' -> complete_arg argv'
        | Set_int (_r, c), [arg'] -> c arg'
        | Set_int (_r, _c), _ :: argv' -> complete_arg argv'
        | Float (_f, c), [arg'] -> c arg'
        | Float (_f, _c), _ :: argv' -> complete_arg argv'
        | Set_float (_r, c), [arg'] -> c arg'
        | Set_float (_r, _c), _ :: argv' -> complete_arg argv'
        | _, _ -> failwith "cannot complete"
      with Not_found ->
        List.filter_map (fun (key, _spec, _doc) ->
            if String.starts_with ~prefix:arg key then
              Some key
            else
              None
          ) speclist
  in
  complete_arg (List.tl (Array.to_list argv))
