defmodule ESLx.LibESL.Inbound do
  @moduledoc false

  def start_link(host, port, password, timeout) when is_integer(timeout) do
    with {:ok, esl} = r <- ESLx.LibESL.start_link(),
         :ok <- Unifex.CNode.call(esl, :connect_timeout, [host, port, "", password, timeout]) do
      r
    end
  end

  defdelegate send_recv(cnode, cmd, timeout), to: ESLx.LibESL
  defdelegate recv_event(cnode, timeout), to: ESLx.LibESL
end
