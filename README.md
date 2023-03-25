# Eslx (WIP)

A layer for Freeswitch Event Socket Protocol.

## Usage
### Execute api

~~~iex
case ESLx.api(URI.parse("esl://:ClueCon@localhost:8021"), "uptime", 3_000) do
  {:ok, response} ->
   ...
  {:error, error} ->
    ...
end
~~~

### Listening events

~~~iex
{:ok, esl} = ESLx.Events.start_link(URI.parse("esl://:ClueCon@localhost:8021"), 3_000)
ESLx.Events.events(esl, "ALL")

# receive the serialized event
receive do
  {:esl_event, event_data} ->
    event = Jason.decode!(event_data)
    ...
    
~~~

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eslx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eslx, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/eslx>.

