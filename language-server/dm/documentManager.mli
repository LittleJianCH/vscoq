(**************************************************************************)
(*                                                                        *)
(*                                 VSCoq                                  *)
(*                                                                        *)
(*                   Copyright INRIA and contributors                     *)
(*       (see version control and README file for authors & dates)        *)
(*                                                                        *)
(**************************************************************************)
(*                                                                        *)
(*   This file is distributed under the terms of the MIT License.         *)
(*   See LICENSE file.                                                    *)
(*                                                                        *)
(**************************************************************************)

open Types
open Lsp.LspData
open CompletionItems

(** The document manager holds the view that Coq has of the currently open
    states. It makes it easy for IDEs to handle text edits, navigate
    and get feedback. Note that it does not require IDEs to parse vernacular
    sentences. *)

type state

type event
val pp_event : Format.formatter -> event -> unit

type events = event Sel.event list

val init : Vernacstate.t -> opts:Coqargs.injection_command list -> Uri.t -> text:string -> state * events
(** [init st opts uri text] initializes the document manager with initial vernac state
    [st] on which command line opts will be set. *)

val apply_text_edits : state -> text_edit list -> state
(** [apply_text_edits doc edits] updates the text of [doc] with [edits]. The new
    document is parsed, outdated executions states are invalidated, and the observe
    id is updated. *)

val interpret_to_position : stateful:bool -> state -> Position.t -> (state * events)
(** [interpret_to_position stateful doc pos] navigates to the last sentence ending
    before or at [pos] and returns the resulting state. The [stateful] flag 
    determines if we record the resulting position in the state. *)

val interpret_to_previous : state -> (state * events)
(** [interpret_to_previous doc] navigates to the previous sentence in [doc]
    and returns the resulting state. *)

val interpret_to_next : state -> (state * events)
(** [interpret_to_next doc] navigates to the next sentence in [doc]
    and returns the resulting state. *)

val interpret_to_end : state -> (state * events)
(** [interpret_to_end doc] navigates to the last sentence in [doc]
    and returns the resulting state. *)

val interpret_in_background : state -> (state * events)
(** [interpret_in_background doc] same as [interpret_to_end] but computation 
    is done in background (with lower priority) *)

val reset : state -> state * events
(** resets Coq *)

type exec_overview = {
  parsed : Range.t list;
  checked : Range.t list;
  checked_by_delegate : Range.t list;
  legacy_highlight : Range.t list;
}

val executed_ranges : state -> exec_overview
(** returns the ranges corresponding to the sentences
    that have been executed and remotely executes *)

val diagnostics : state -> Diagnostic.t list
(** diagnostics [doc] returns the diagnostics corresponding to the sentences
    that have been executed in [doc]. *)

val get_proof : state -> Position.t option -> Lsp.ProofState.t option

val get_completions : state -> Position.t -> (completion_item list, string) Result.t

val handle_event : event -> state -> (state option * events)
(** handles events and returns a new state if it was updated *)

val search : state -> id:string -> Position.t -> string -> notification Sel.event list

val about : state -> Position.t -> pattern:string -> (string,string) Result.t

val hover : state -> Position.t -> (string,string) Result.t option
(** Returns an optional Result:
    if None, the position did not have a word,
    if Some, an Ok/Error result is returned. *)

val check : state -> Position.t -> pattern:string -> (string,string) Result.t

val locate : state -> Position.t -> pattern:string -> (string, string) Result.t

val print : state -> Position.t -> pattern:string -> (string, string) Result.t


module Internal : sig

  val document : state -> Document.document
  val raw_document : state -> RawDocument.t
  val execution_state : state -> ExecutionManager.state
  val string_of_state : state -> string
  val observe_id : state -> Types.sentence_id option

  val validate_document : state -> state
  (** [validate_document doc] reparses the text of [doc] and invalidates the
      states impacted by the diff with the previously validated content. If the
      text of [doc] has not changed since the last call to [validate_document], it
      has no effect. *)


end
