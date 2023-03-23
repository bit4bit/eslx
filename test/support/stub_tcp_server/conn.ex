defmodule StubTCPServer.Conn do
  defstruct [:socket, :transport]

  def new(socket, transport) do
    %__MODULE__{socket: socket, transport: transport}
  end

  def resp(conn, data) do
    conn.transport.send(conn.socket, data |> to_charlist())
  end

  def close(conn) do
    conn.transport.close(conn.socket)
  end
end
