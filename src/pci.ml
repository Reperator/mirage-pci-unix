type error = Mirage_pci.Pci.error

let pp_error = Mirage_pci.Pci.pp_error

type device_info =
  { bus_master_enable : bool
  ; map_bar0 : bool
  ; map_bar1 : bool
  ; map_bar2 : bool
  ; map_bar3 : bool
  ; map_bar4 : bool
  ; map_bar5 : bool
  ; vendor_id : int
  ; device_id : int
  ; class_code : int
  ; subclass_code : int
  ; progif : int
  ; dma_size : int
  }

type t =
  { id : string
  ; fd : Unix.file_descr
  ; info : device_info
  ; mutable active : bool
  ; bar0 : Cstruct.t
  ; bar1 : Cstruct.t
  ; bar2 : Cstruct.t
  ; bar3 : Cstruct.t
  ; bar4 : Cstruct.t
  ; bar5 : Cstruct.t
  ; dma : Cstruct.t
  }

external pci_attach : string -> Unix.file_descr = "mirage_pci_attach"

external enable_dma : Unix.file_descr -> unit = "mirage_enable_dma"

external mirage_map_region : Unix.file_descr -> int -> Cstruct.buffer = "mirage_map_region"

external mirage_allocate_dma : int -> Cstruct.buffer = "mirage_allocate_dma"

let map_region fd n = Cstruct.of_bigarray (mirage_map_region fd n)

let allocate_dma size = Cstruct.of_bigarray (mirage_allocate_dma size)

let connect (info : device_info) dev =
  let fd = pci_attach dev in
  begin if info.bus_master_enable then enable_dma fd end;
  Lwt.return
    { id = dev
    ; fd
    ; info
    ; active = true
    ; bar0 = if info.map_bar0 then map_region fd 0 else Cstruct.empty
    ; bar1 = if info.map_bar1 then map_region fd 1 else Cstruct.empty
    ; bar2 = if info.map_bar2 then map_region fd 2 else Cstruct.empty
    ; bar3 = if info.map_bar3 then map_region fd 3 else Cstruct.empty
    ; bar4 = if info.map_bar4 then map_region fd 4 else Cstruct.empty
    ; bar5 = if info.map_bar5 then map_region fd 5 else Cstruct.empty
    ; dma = if info.dma_size > 0 then allocate_dma info.dma_size else Cstruct.empty
    }

let vendor_id t = t.info.vendor_id

let device_id t = t.info.device_id

let class_code t = t.info.class_code

let subclass_code t = t.info.subclass_code

let progif t = t.info.progif

let bar0 t = if Cstruct.len t.bar0 = 0 then None else Some t.bar0

let bar1 t = if Cstruct.len t.bar1 = 0 then None else Some t.bar1

let bar2 t = if Cstruct.len t.bar2 = 0 then None else Some t.bar2

let bar3 t = if Cstruct.len t.bar3 = 0 then None else Some t.bar3

let bar4 t = if Cstruct.len t.bar4 = 0 then None else Some t.bar4

let bar5 t = if Cstruct.len t.bar5 = 0 then None else Some t.bar5

let dma t = t.dma

let name t = t.id

let disconnect t = t.active <- false; Lwt.return_unit
