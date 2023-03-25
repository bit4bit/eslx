defmodule ESLx do
  @moduledoc """
  `ESLx` a layer for Freeswitch Event Socket Protocol
  """

  alias ESLx.ConnectionDetails

  defmodule Events do
    @moduledoc """
    Continually receive events.
    """

    def start_link(connection_details, timeout) do
      ESLx.LibESL.Events.start_link(
        ConnectionDetails.host(connection_details),
        ConnectionDetails.port(connection_details),
        ConnectionDetails.password(connection_details),
        timeout
      )
    end

    defdelegate events(node, events), to: ESLx.LibESL.Events
  end

  @doc """
  executes api once and closes connection
  """
  @spec api(ConnectionDetails.t(), cmd :: String.t(), timeout :: pos_integer()) ::
          {:ok, String.t()} | :error
  def api(connection_details, cmd, opts) do
    connection_timeout = Keyword.get(opts, :connect_timeout, 1_000)
    command_timeout = Keyword.get(opts, :command_timeout, 1_000)

    {:ok, esl} =
      ESLx.LibESL.Inbound.start_link(
        ConnectionDetails.host(connection_details),
        ConnectionDetails.port(connection_details),
        ConnectionDetails.password(connection_details),
        connection_timeout
      )

    case ESLx.LibESL.send_recv(esl, "api #{cmd}\n\n", command_timeout) do
      {:ok, data} ->
        ESLx.LibESL.close(esl)
        data

      {:error, _error} ->
        ESLx.LibESL.close(esl)
        :error
    end
  end
end
