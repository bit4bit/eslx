defmodule Toxico.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: native(Bundlex.platform()),
      libs: libs()
    ]
  end

  defp native(_platform) do
    [
      libesl: [
        sources: ["libesl.c"],
        src_base: "libesl",
        interface: [:cnode],
        deps: [
          {:eslx, :freeswitch_esl}
        ],
        preprocessor: Unifex
      ]
    ]
  end

  defp libs() do
    freeswitch_esl_sources =
      File.ls!("c_src/freeswitch_esl")
      |> Enum.filter(&(String.ends_with?(&1, [".c", ".h"])))

    [
      freeswitch_esl: [
        sources: freeswitch_esl_sources,
        includes: ["c_src/freeswitch_esl/include"],
        src_base: "freeswitch_esl"
      ]
    ]
  end
end
