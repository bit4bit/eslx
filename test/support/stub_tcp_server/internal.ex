defmodule StubTCPServer.Internal do
  def handle_opened(server, conn) do
    send(server, {:opened, conn})
  end

  def handle_data(server, conn, data) do
    send(server, {:data, conn, data})
  end
end
