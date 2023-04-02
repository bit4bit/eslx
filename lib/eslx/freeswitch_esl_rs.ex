defmodule ESLx.FreeswitchESLRs.Events do
  use Rustler,
    otp_app: :eslx,
    crate: "eslx_freeswitcheslrs_events"

  def start_link(_listener, _host, _port, _password, _events, _timeout),
    do: :erlang.nif_error(:nif_not_loaded)
end
