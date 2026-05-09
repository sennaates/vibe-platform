type ToastType = "success" | "error" | "info"
type Listener = (msg: string, type: ToastType) => void

let _listener: Listener | null = null

export const toast = {
  show(msg: string, type: ToastType = "success") {
    _listener?.(msg, type)
  },
  success(msg: string) { this.show(msg, "success") },
  error(msg: string)   { this.show(msg, "error") },
  info(msg: string)    { this.show(msg, "info") },
  _subscribe(fn: Listener) { _listener = fn },
  _unsubscribe()           { _listener = null },
}
