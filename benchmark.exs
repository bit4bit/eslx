defmodule FakeFreeswitch do
  def start_link do
    {:ok, server} = StubTCPServer.start_link([])

    StubTCPServer.stub_open(server, :opened, fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: auth/request\n\n")
    end)

    StubTCPServer.stub(server, :logged_in, "auth password\n\n", fn conn ->
      StubTCPServer.Conn.resp(conn, "Content-Type: command/reply\nReply-Text: +OK accepted\n\n")
    end)

    StubTCPServer.stub(server, :events, "event plain", fn conn ->
      data = ~s(Content-Type: command/reply
      Reply-Text: +OK event listener enabled plain

)
      StubTCPServer.Conn.resp(conn, data)
    end)

    {:ok, server}
  end

  def send_event(server) do
    StubTCPServer.connections(server, fn conn ->
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
      StubTCPServer.Conn.resp(conn, event_data)
    end)
  end
end

Benchee.run(
  %{
    "send event" => fn {_input, srv} ->
      for _ <- 1..2 do
        FakeFreeswitch.send_event(srv)

        receive do
          _ ->
            nil
        after
          100 ->
            nil
        end
      end
    end
  },
  inputs: %{"ESLx" => ESLx, "FSModEvent" => FSModEvent, "SwitchX" => SwitchX},
  before_scenario: fn input ->
    {:ok, fs} = FakeFreeswitch.start_link()

    case input do
      ESLx ->
        # start ESLX
        esl_url = URI.parse("esl://:password@#{StubTCPServer.host(fs)}:#{StubTCPServer.port(fs)}")

        {:ok, _esl} = ESLx.Events.start_link(esl_url, "ALL", 1000)
        StubTCPServer.wait_for(fs, :opened, 1_000)
        {input, fs}

      FSModEvent ->
        # start FSModEvent
        fsid = :erlang.unique_integer() |> to_string |> String.to_atom()

        FSModEvent.Connection.start(
          fsid,
          StubTCPServer.host(fs),
          StubTCPServer.port(fs),
          "password"
        )

        StubTCPServer.wait_for(fs, :opened, 1_000)
        FSModEvent.Connection.event(fsid, "ALL")
        FSModEvent.Connection.start_listening(fsid)

        {input, fs}

      SwitchX ->
        # start SwitchX
        {:ok, conn} =
          SwitchX.Connection.Inbound.start_link(
            host: StubTCPServer.host(fs),
            port: StubTCPServer.port(fs)
          )

        StubTCPServer.wait_for(fs, :opened, 1_000)
        SwitchX.auth(conn, "password")
        SwitchX.listen_event(conn, "ALL")
        {input, fs}
    end
  end,
  time: 10,
  profile_after: false
)
