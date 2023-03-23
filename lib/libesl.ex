defmodule LibESL do
  require Unifex.CNode

  def start_link do
    Unifex.CNode.start_link(:libesl)
  end

  def set_default_logger(cnode, level) when is_atom(level) do
    Unifex.CNode.call(cnode, :global_set_default_logger, [level])
  end
end
