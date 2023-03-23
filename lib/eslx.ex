defmodule ESLx do
  @moduledoc """
  `ESLx` a layer for Freeswitch Event Socket Protocol
  """

  alias ESLx.ConnectionDetails

  @doc """
  executes api once and closes connection
  """
  @spec api(ConnectionDetails.t(), cmd :: String.t(), timeout :: pos_integer()) ::
          {:ok, String.t()} | :error
  def api(connection_details, cmd, opts) do
    connection_timeout = Keyword.get(opts, :connect_timeout, 1_000)
    command_timeout = Keyword.get(opts, :command_timeout, 1_000)

    {:ok, esl} =
      LibESL.Inbound.start_link(
        ConnectionDetails.host(connection_details),
        ConnectionDetails.port(connection_details),
        ConnectionDetails.password(connection_details),
        connection_timeout
      )

    case LibESL.send_recv(esl, "api #{cmd}\n\n", command_timeout) do
      {:ok, data} ->
        LibESL.close(esl)
        data

      {:error, _error} ->
        LibESL.close(esl)
        :error
    end
  end
end
