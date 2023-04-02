# Eslx (WIP)

A layer for Freeswitch Event Socket Protocol.

Why i doing this?

When we have a Freeswitch with high concurrency, Erlang VM or the library
can't get all events (i it tested only connecting a vm and waiting to reach max queue size)
using event socket, so freeswitch starts throws "..Max queue size reached.."
or "killing to many lost events..".

I testing if using a thread out of the vm can handle more events..

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

