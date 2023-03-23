defmodule LibESL do
  require Unifex.CNode

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link do
    with {:ok, esl} = r <- Unifex.CNode.start_link(:libesl) do
      Unifex.CNode.call(esl, :init)
      r
    end
  end

  def set_default_logger(cnode, level) when is_atom(level) do
    Unifex.CNode.call(cnode, :global_set_default_logger, [level])
  end
end

defmodule LibESL.Inbound do
  def start_link(host, port, password, timeout) when is_integer(timeout) do
    with {:ok, esl} = r <- LibESL.start_link,
         :ok <- Unifex.CNode.call(esl, :connect_timeout, [host, port, "", password, timeout]) do
      r
    end
  end
end
