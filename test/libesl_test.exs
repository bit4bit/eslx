defmodule ESLx.LibESLTest do
  use ExUnit.Case

  test "esl_global_set_default_logger/1" do
    {:ok, esl} = ESLx.LibESL.start_link()

    assert :ok = ESLx.LibESL.set_default_logger(esl, :info)
  end

  test "open tcp" do
    server = start_supervised!(StubTCPServer)

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.close(conn)
    end)

    ESLx.LibESL.Inbound.start_link(
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

    assert {:ok, _} =
             ESLx.LibESL.Inbound.start_link(
               StubTCPServer.host(server),
               StubTCPServer.port(server),
               "password",
               1000
             )
  end

  test "api" do
    server = start_supervised!(StubTCPServer)

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
    end)

    StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
    end)

    StubTCPServer.stub(server, :api, "api uptime\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: api/response\nContent-Length: 6\n\n123456")
    end)

    {:ok, esl} =
      ESLx.LibESL.Inbound.start_link(
        StubTCPServer.host(server),
        StubTCPServer.port(server),
        "password",
        1000
      )

    StubTCPServer.wait_for(server, :logged_in, 1000)

    assert {:ok, "123456"} = ESLx.LibESL.Inbound.send_recv(esl, "api uptime\n\n", 1000)
  end
end
