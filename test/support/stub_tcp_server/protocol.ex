defmodule StubTCPServer.Protocol do
  alias StubTCPServer.Conn
  alias StubTCPServer.Internal

  def start_link(ref, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  def init(ref, transport, opts) do
    [server] = opts
    {:ok, socket} = :ranch.handshake(ref)

    conn = Conn.new(socket, transport)
    Internal.handle_opened(server, conn)

    loop(socket, transport, server, conn)
  end

  def loop(socket, transport, server, conn) do
    case transport.recv(socket, 0, 5000) do
      {:ok, data} ->
        Internal.handle_data(server, conn, data)
        loop(socket, transport, server, conn)

      _ ->
        :ok = transport.close(socket)
    end
  end
end
