defmodule LibESLTest do
  use ExUnit.Case

  test "esl_global_set_default_logger/1" do
    {:ok, esl} = LibESL.start_link()

    assert :ok = LibESL.set_default_logger(esl, :info)
  end

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

    assert {:ok, _} =
             LibESL.Inbound.start_link(
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
      LibESL.Inbound.start_link(
        StubTCPServer.host(server),
        StubTCPServer.port(server),
        "password",
        1000
      )

    StubTCPServer.wait_for(server, :logged_in, 1000)

    assert {:ok, "123456"} = LibESL.Inbound.send_recv(esl, "api uptime\n\n", 1000)
  end

  test "event" do
    server = start_supervised!(StubTCPServer)

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
    end)

    StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
    end)

    event_content = ~s(Event-Name: API
Core-UUID: 5a0226ce-e06e-4235-9627-1834fc204408
FreeSWITCH-Hostname: 076d7ff313e4
FreeSWITCH-Switchname: 16.20.0.9
FreeSWITCH-IPv4: 16.20.0.9
FreeSWITCH-IPv6: %3A%3A1
Event-Date-Local: 2023-03-24%2001%3A58%3A51
Event-Date-GMT: Fri,%2024%20Mar%202023%2001%3A58%3A51%20GMT
Event-Date-Timestamp: 1679623131893736
Event-Calling-File: switch_loadable_module.c
Event-Calling-Function: switch_api_execute
Event-Calling-Line-Number: 2949
Event-Sequence: 742
API-Command: show
API-Command-Argument: calls%20as%20json)

    StubTCPServer.stub(server, :event, "api faked-event\n\n", fn conn ->
      event_data = ~s(Content-Length: 525
Content-Type: text/event-plain

#{event_content}

)

      StubTCPServer.Conn.resp(
        conn,
        "Content-Type: api/response\nContent-Length: 6\n\n123456"
      )

      StubTCPServer.Conn.resp(conn, event_data)
    end)

    {:ok, esl} =
      LibESL.Inbound.start_link(
        StubTCPServer.host(server),
        StubTCPServer.port(server),
        "password",
        1000
      )

    {:ok, _} = LibESL.Inbound.send_recv(esl, "api faked-event\n\n", 1000)
    StubTCPServer.wait_for(server, :event, 1000)

    {:ok, event_json} = LibESL.Inbound.recv_event(esl, 1000)

    assert %{
             "Event-Name" => "API"
           } = Jason.decode!(event_json)
  end
end
