defmodule StubTCPServer do
  @moduledoc """
  A gentle server for faking tcp
  """

  use GenServer
  alias StubTCPServer.Protocol

  def start_link([]) do
    Application.start(:ranch)

    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init([]) do
    name = "stub-tcp-server-#{:erlang.monotonic_time()}" |> String.to_atom()
    {:ok, listener} = :ranch.start_listener(
      name,
      :ranch_tcp,
      %{},
      Protocol,
      [self()]
    )

    {:ok, %{
        name: name,
        listener: listener,
        stubs: [],
        stubs_open: [],
        wait_fors: [],
        connections: MapSet.new(),
        events: []
     }}
  end

  def host(_server) do
    "127.0.0.1"
  end

  def port(server) do
    GenServer.call(server, :port)
  end

  def events(server) do
    Process.sleep(500)
    GenServer.call(server, :events)
  end

  def stub(server, label, req, responser) do
    GenServer.call(server, {{:stub, :data}, label, req, responser})
  end

  def stub_open(server, label, responser) do
    GenServer.call(server, {{:stub, :open}, label, responser})
  end

  def connections(server, responser) do
    GenServer.call(server, {:connections, responser})
  end

  def wait_for(server, label, timeout) do
    GenServer.call(server, {:wait_for, label}, timeout)
  end

  @impl true
  def handle_call({:connections, responser}, _from, state) do
    for conn <- state.connections do
      responser.(conn)
    end

    {:reply, :ok, state}
  end
  def handle_call({:wait_for, label}, from, state) do
    wait_fors = state.wait_fors ++ [{label, from}]
    schedule_wait_for(100)
    {:noreply, %{state | wait_fors: wait_fors}}
  end
  def handle_call({{:stub, :open}, label, responser}, _from, state) do
    stubs = state.stubs_open ++ [{label, responser}]
    {:reply, :ok, %{state | stubs_open: stubs}}
  end
  def handle_call({{:stub, :data}, label, req, responser}, _from, state) do
    stubs = state.stubs ++ [{label, req, responser}]
    {:reply, :ok, %{state | stubs: stubs}}
  end
  def handle_call(:port, _from, %{name: name} = state) do
    {:reply, :ranch.get_port(name), state}
  end
  def handle_call(:events, _from, state) do
    {:reply, state.events, state}
  end

  @impl true
  def handle_info(:wait_for, state) do
    handle_wait_for(state)
    schedule_wait_for(100)
    {:noreply, state}
  end
  def handle_info({:data, conn, data}, state) do
    new_state =
      state
      |> handle_stubs(:data, conn, data)
      |> cache_connection(conn)

    {:noreply, new_state}
  end
  def handle_info({:opened, conn}, state) do
    new_state =
            state
      |> handle_stubs(:opened, conn)
      |> cache_connection(conn)

    {:noreply, new_state}
  end

  defp handle_stubs(state, :opened, conn) do
    handle_mocks(state, state.stubs_open, :open, conn)
  end
  defp handle_stubs(state, :data, conn, data) do
    handle_mocks(state, state.stubs, :data, conn, data)
  end

  defp handle_mocks(state, doubles, :open, conn) do
    doubles
    |> Enum.map(fn {label, responser} ->
      responser.(conn)
      label
    end)
    |> Enum.reduce(state, fn label, state ->
      add_event(state, label)
    end)
  end
  defp handle_mocks(state, doubles, :data, conn, data) do
    doubles
    |> Enum.map(fn {label, req, responser} ->
      if String.starts_with?(data, req) do
        {label, responser}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(state, fn {label, responser}, state ->
      responser.(conn)
      add_event(state, label)
    end)
  end

  defp handle_wait_for(state) do
    for {label, from} <- state.wait_fors do
      case List.last(state.events) do
        nil -> state
        event ->
          if event == label do
            GenServer.reply(from, :ok)
          end
      end
    end

    state
  end

  defp cache_connection(state, conn) do
    connections = MapSet.put(state.connections, conn)
    %{state | connections: connections}
  end

  defp add_event(state, event) do
    %{state | events: state.events ++ [event]}
  end

  defp schedule_wait_for(timeout) do
    Process.send_after(self(), :wait_for, timeout)
  end
end
