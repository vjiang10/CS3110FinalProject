open Bogue
open Main
open Pacmap
open Tsdl
open Utils
open Random
open Camel
open Sdl
module W = Widget
module L = Layout
module T = Trigger

(* SETUP *)
(* WIDGETS*)
let start_title_w =
  W.label ~size:32
    ~fg:Draw.(opaque (find_color "firebrick"))
    "The Pac-Camel Game"

let start_button_w = W.button "Start the Game"

(*LAYOUT*)

(* TODO @GUI (optional): animate in the title + add hovering to buttons upon
   user mouse hover event *)
(* TODO (add keyboard options for quit (Q), play/pause (spacebar or P), and H (H
   or ?); these would trigger events that the buttons that they correspond to
   trigger *)
let start_title_l = L.resident start_title_w ~y:2
let start_button_l = L.resident ~x:200 ~y:35 ~w:55 ~h:2 start_button_w

(* TODO @GUI (post-MS2): Implement more widgets 
 *  - score displayer
 *  - time displayer (perhaps we can set a time limit for the player)
 *  - a play/pause button
 *  - a reset button (has the same action as start button, just with the text changed) 
 *  - a text field to generate a map with a specific seed -> a button to apply (or just reset) 
 *  - a help button to open up a popup that shows the user the different features that are implemented
 *  - (optional) an algorithm selection drop down menu that selects what algorithm that the humans follow 
 *  - (optional) a speed and number of humans setting (set a minimum and maximum)
 *)

(* TODO @GUI (post-MS2): fix canvas margins; currently resizing windows causes
   undesirable behavior; perhaps set a minimum window dimension *)
let canvas = W.sdl_area ~w:500 ~h:500 ()
let canvas_l = L.resident ~w:200 ~h:200 ~x:0 ~y:0 canvas

(* reference to map *)
let map = ref (gen_map (int 500))
let camel = ref (Camel.init !map "assets/images/camel-cartoon.png")

let texture r =
  let camel_surface = Tsdl_image.Image.load "assets/images/camel-cartoon.png" in
  let t = create_texture_from_surface r (Result.get_ok camel_surface) in
  go t

type tmprect = {
  rect : Sdl.rect;
  color : int * int * int;
  created : int;
}

let sdl_area = W.get_sdl_area canvas
(* let reset_camel r = go (render_copy r (texture r)) *)

let reset_map (seed : int) =
  (* reset canvas *)
  Sdl_area.clear sdl_area;
  map := gen_map seed;
  (* camel := Camel.init !map "assets/images/camel-cartoon.png"; *)
  draw_map sdl_area !map

(* sets up the game *)
let reset_game seed = reset_map seed
let bg = (255, 255, 255, 255)

let make_board () =
  (* set what to be drawn *)
  (* TODO @GUI: clicking on widgets do not work: try to fix *)
  reset_game (int 10000);
  let layout = L.superpose [ canvas_l; Camel.get_layout !camel ] in

  (* TODO @GUI: fix widget dimensions ans positions *)
  (* TODO @GUI: fix error where initial click does not generate correct map *)
  (* action to be connected to start button *)
  let start_action _ _ _ =
    (* reset_game (int 10000); *)
    L.set_rooms layout [ start_button_l; canvas_l ]
    (* this line replace current layout with an empty list, add widgets (to be
       drawn after start) in this list e.g. map, camel, human etc. *)
  in
  (* connect action to button. Triggered when button is pushed*)
  let c = W.connect start_button_w start_button_w start_action T.buttons_down in
  (* set up board *)
  of_layout ~connections:[ c ] layout

let main () =
  let open Sdl in
  Sys.catch_break true;
  go (Sdl.init Sdl.Init.video);
  let win =
    go
      (Sdl.create_window ~w:800 ~h:800 "Pac-Camel Game"
         Sdl.Window.(shown + popup_menu))
  in
  let renderer = go (Sdl.create_renderer win) in
  (* very important: set blend mode: *)
  go (Sdl.set_render_draw_blend_mode renderer Sdl.Blend.mode_blend);
  Draw.set_color renderer bg;
  go (Sdl.render_clear renderer);
  self_init ();

  (* let show_gui = ref true in *)
  let board = make_board () in
  make_sdl_windows ~windows:[ win ] board;
  let start_fps, fps = Time.adaptive_fps 60 in
  let camel_texture =
    let camel_surface =
      Tsdl_image.Image.load "assets/images/camel-cartoon.png"
    in
    let t = create_texture_from_surface renderer (go camel_surface) in
    go t
  in
  let camel_x = get_x !camel in
  let camel_y = get_y !camel in
  let rec mainloop e =
    (if Sdl.poll_event (Some e) then
     match Trigger.event_kind e with
     | `Key_down when Sdl.Event.(get e keyboard_keycode) = Sdl.K.up ->
         print_endline "up"
     (* Camel.move !camel !map (Camel.get_x !camel, Camel.get_y !camel +. 1.); *)
     (* Sdl_area.set_texture (get_area !camel) (texture renderer) *)
     | `Key_down when Sdl.Event.(get e keyboard_keycode) = Sdl.K.right ->
         print_endline "right"
     (* Camel.move !camel !map (Camel.get_x !camel +. 1., Camel.get_y !camel) *)
     | `Key_down when Sdl.Event.(get e keyboard_keycode) = Sdl.K.down ->
         print_endline "down"
     (* Camel.move !camel !map (camel_x +. 20., camel_y +. 20.); *)
     (* Camel.move !camel !map (20., 20.); *)
     (* Sdl_area.set_texture (get_area !camel) camel_texture *)
     (* Result.get_ok (render_copy renderer (texture renderer)) *)
     | `Key_down when Sdl.Event.(get e keyboard_keycode) = Sdl.K.left ->
         print_endline "left"
     (* Camel.move !camel !map (Camel.get_x !camel -. 1., Camel.get_y !camel) *)
     | `Key_down
       when List.mem Sdl.Event.(get e keyboard_keycode) [ Sdl.K.r; Sdl.K.space ]
       ->
         print_endline "restart";
         reset_game (int 10000);
         (* Sdl_area.set_texture (get_area !camel) camel_texture *)
         go (render_copy renderer camel_texture)
     | _ -> ());

    Draw.set_color renderer bg;

    go (Sdl.render_clear renderer);
    refresh_custom_windows board;
    if
      not (one_step true (start_fps, fps) board)
      (* one_step returns true if fps was executed *)
    then fps ()
    else fps ();
    Sdl.render_present renderer;
    mainloop e
  in

  let e = Sdl.Event.create () in
  start_fps ();
  let () = try mainloop e with _ -> exit 0 in
  Sdl.destroy_window win;
  Draw.quit ()

(* TODO @GUI: add to this function, which should initialize gui widgets (be
   prepared to take in functions that should be called based on widget
   events) *)
let greeting = main ()
