# NIF for Elixir.ESLx.FreeswitchESLRs.API

## To build the NIF module:

- Your NIF will now build along with your project.

## To load the NIF:

```elixir
defmodule ESLx.FreeswitchESLRs.API do
  use Rustler, otp_app: :eslx, crate: "eslx_freeswitcheslrs_api"

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
```

## Examples

[This](https://github.com/rusterlium/NifIo) is a complete example of a NIF written in Rust.
