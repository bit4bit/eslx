defmodule LibESL.Events do
  @moduledoc """
  When freeswitch generate a lot events and we pull too slow,
  we can easily overflow the internal queue, this implementation uses esl.c
  for pulling in faster way (not tested in production yet).
  """
  require Unifex.CNode

  def start_link(host, port, password, timeout) when is_integer(timeout) do
    with {:ok, esl} = r <- Unifex.CNode.start_link(:libesl_events),
         :ok <-
           Unifex.CNode.call(esl, :connect_timeout, [host, port, "", password, timeout], timeout) do
      r
    end
  end

  def events(cnode, events) do
    Unifex.CNode.call(cnode, :events, [events], 1_000)
  end
end
