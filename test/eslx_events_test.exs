defmodule ESLx.EventsTest do
  use ExUnit.Case

  test "event" do
    server = start_supervised!(StubTCPServer)

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
    end)

    StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
    end)

    StubTCPServer.stub(server, :events, "event plain ALL", fn conn ->
      data = ~s(Content-Type: command/reply
Reply-Text: +OK event listener enabled plain

)
      StubTCPServer.Conn.resp(conn, data)
    end)

    Process.sleep(300)

    esl_url =
      URI.parse("esl://:password@#{StubTCPServer.host(server)}:#{StubTCPServer.port(server)}")

    {:ok, esl} = ESLx.Events.start_link(esl_url, 1000)
    assert :ok = ESLx.Events.events(esl, "ALL")
  end

  test "notify events" do
    server = start_supervised!(StubTCPServer)
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

    event_data = ~s(Content-Length: 525
Content-Type: text/event-plain

#{event_content}

)

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
    end)

    StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
    end)

    esl_url =
      URI.parse("esl://:password@#{StubTCPServer.host(server)}:#{StubTCPServer.port(server)}")

    {:ok, _esl} = ESLx.Events.start_link(esl_url, 1000)

    StubTCPServer.wait_for(server, :logged_in, 1_000)

    StubTCPServer.connections(server, fn conn ->
      StubTCPServer.Conn.resp(conn, event_data)
    end)

    receive do
      {:esl_event, data} ->
        assert %{
                 "Event-Name" => "API"
               } = data
    after
      1_000 ->
        raise "timeout"
    end
  end
end
