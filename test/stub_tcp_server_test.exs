defmodule StubTCPServerTest do
  use ExUnit.Case

  describe "events" do
    test "opened" do
      server = start_supervised!(StubTCPServer)

      StubTCPServer.stub_open(server, :opened, fn conn ->
        StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
      end)

      send_data(server, "Hola")

      assert [:opened] = StubTCPServer.events(server)
    end

    test "stub" do
      server = start_supervised!(StubTCPServer)

      StubTCPServer.stub(server, :response, "hola\n\n", fn conn ->
        StubTCPServer.Conn.resp(conn, "+OK")
      end)

      send_data(server, "hola\n\n")

      assert [:response] = StubTCPServer.events(server)
    end
  end

  defp send_data(server, data) do
    {:ok, client} =
      :gen_tcp.connect(
        StubTCPServer.host(server) |> to_charlist(),
        StubTCPServer.port(server),
        [:binary, active: false]
      )

    :ok = :gen_tcp.send(client, data |> to_charlist())
  end
end
