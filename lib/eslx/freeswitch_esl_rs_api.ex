defmodule ESLx.FreeswitchESLRs.API do
  use Rustler,
    otp_app: :eslx,
    crate: "eslx_freeswitcheslrs_api"

  def start_link(_host, _port, _password, _timeout),
    do: :erlang.nif_error(:nif_not_loaded)

  def close(_name), do: :erlang.nif_error(:nif_not_loaded)

  def api(_name, _cmd, _arg, _timeout), do: :erlang.nif_error(:nif_not_loaded)
end
