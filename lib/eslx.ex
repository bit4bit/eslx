defmodule ESLx do
  @moduledoc """
  `ESLx` a layer for Freeswitch Event Socket Protocol

  ## Examples

  ### Listening Events
      iex> {:ok, esl} = ESLx.Events.start_link(URI.parse("esl://:ClueCon@localhost:8021"), 3_000)
      iex> ESLx.Events.events(esl, "ALL")
      iex> flush().
      ...

  ### Execute api
      iex> ESLx.api(URI.parse("esl://:ClueCon@localhost:8021"), "uptime", [])
      ...
  """

  alias ESLx.ConnectionDetails

  defmodule Events do
    @moduledoc """
    Continually receive events.
    """

    def start_link(connection_details, events, timeout) do
      # ESLx.LibESL.Events.start_
      {:ok,
       ESLx.FreeswitchESLRs.Events.start_link(
         self(),
         ConnectionDetails.host(connection_details),
         ConnectionDetails.port(connection_details),
         ConnectionDetails.password(connection_details),
         events,
         timeout
       )}
    end
  end

  @doc """
  executes api once and closes connection
  """
  @spec api(ConnectionDetails.t(), cmd :: String.t(), arg :: String.t(), timeout :: pos_integer()) ::
          {:ok, String.t()} | :error
  def api(connection_details, cmd, arg, opts) do
    connection_timeout = Keyword.get(opts, :connect_timeout, 1_000)
    command_timeout = Keyword.get(opts, :command_timeout, 1_000)

    esl =
      ESLx.FreeswitchESLRs.API.start_link(
        ConnectionDetails.host(connection_details),
        ConnectionDetails.port(connection_details),
        ConnectionDetails.password(connection_details),
        connection_timeout
      )

    case ESLx.FreeswitchESLRs.API.api(esl, cmd, arg, command_timeout) do
      {:ok, data} ->
        ESLx.FreeswitchESLRs.API.close(esl)
        data

      {:error, _error} ->
        ESLx.FreeswitchESLRs.API.close(esl)
        :error
    end
  end
end
