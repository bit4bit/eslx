defmodule Toxico.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      libs: libs()
    ]
  end

  defp libs() do
    freeswitch_esl_sources =
      File.ls!("c_src/esl/freeswitch_esl")
      |> Enum.filter(&(String.ends_with?(&1, [".c", ".h"])))

    [
      freeswitch_esl: [
        sources: freeswitch_esl_sources,
        includes: ["c_src/esl/freeswitch_esl/include"],
        src_base: "esl/freeswitch_esl"
      ]
    ]
  end
end
