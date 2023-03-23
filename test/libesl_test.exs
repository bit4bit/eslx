defmodule LibESLTest do
  use ExUnit.Case

  test "esl_global_set_default_logger/1" do
    {:ok, esl} = LibESL.start_link

    assert :ok = LibESL.set_default_logger(esl, :info)
  end

  describe "esl_connect_timeout/6" do
    test "open tcp" do
      server = start_supervised!(StubTCPServer)

      StubTCPServer.stub_open(server, :opened, fn conn ->
        StubTCPServer.Conn.close(conn)
      end)

      LibESL.Inbound.start_link(
        StubTCPServer.host(server),
        StubTCPServer.port(server),
        "password",
        1000
      )

      assert [:opened] = StubTCPServer.events(server)
    end

    test "logged in" do
      server = start_supervised!(StubTCPServer)
      StubTCPServer.stub_open(server, :opened, fn conn ->
        StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
      end)
      StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
        StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
      end)

      assert {:ok, _} = LibESL.Inbound.start_link(
        StubTCPServer.host(server),
        StubTCPServer.port(server),
        "password",
        1000
      )
    end
  end
end
