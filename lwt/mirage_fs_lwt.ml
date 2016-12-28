(*
 * Copyright (C) 2013 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt.Infix
open Result

module type S = Mirage_fs.S
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

module To_KV_RO (FS: S) = struct

  type t = FS.t
  type +'a io = 'a Lwt.t
  type page_aligned_buffer = FS.page_aligned_buffer

  type error = [ Mirage_kv.error | `FS of FS.error ]

  let pp_error ppf = function
    | #Mirage_kv.error as e -> Mirage_kv.pp_error ppf e
    | `FS e                 -> FS.pp_error ppf e

  let disconnect t = FS.disconnect t

  let mem t name =
    FS.stat t name >|= function
    | Ok _ -> Ok true
    | Error `Not_a_directory
    | Error `No_directory_entry -> Ok false
    | Error e -> Error (`FS e)

  let read t name off len =
    FS.read t name (Int64.to_int off) (Int64.to_int len) >|= function
    | Error `Not_a_directory | Error `No_directory_entry ->
      Error (`Unknown_key name)
    | Error e -> Error (`FS e)
    | Ok l -> Ok l

  let size t name =
    FS.stat t name >|= function
    | Error `Not_a_directory
    | Error `No_directory_entry -> Error (`Unknown_key name)
    | Error e -> Error (`FS e)
    | Ok stat -> Ok (stat.Mirage_fs.size)

end
