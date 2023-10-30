# Eslx (WIP)

A layer for Freeswitch Event Socket Protocol.

Why am I doing this?

When we have a Freeswitch with high concurrency, the Erlang VM
can't get all events (i tested it only connecting a VM and waiting to reach max queue size)
using event socket, so Freeswitch starts throwing "..Max queue size reached.."
or "killing to many lost events..".

I am testing if using a thread out of the VM can handle more events..

## Usage

API documentation is available at <https://hexdocs.pm/eslx>.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eslx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eslx, "~> 0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/eslx>.

