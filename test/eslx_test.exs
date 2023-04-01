defmodule EslxTest do
  use ExUnit.Case

  test "api" do
    server = start_supervised!(StubTCPServer)

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
    end)

    StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
    end)

    StubTCPServer.stub(server, :api, "api uptime \n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: api/response\nContent-Length: 6\n\n123456")
    end)

    url = "esl://:password@#{StubTCPServer.host(server)}:#{StubTCPServer.port(server)}"
    assert "123456" == ESLx.api(URI.parse(url), "uptime", "", [])
  end
end
