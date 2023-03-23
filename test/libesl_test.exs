# Copyright 2022 Picallex Holding Group. All rights reserved.
#
# @author (2022) Jovany Leandro G.C <jovany@picallex.com>
defmodule LibESLTest do
  use ExUnit.Case

  test "esl_global_set_default_logger/1" do
    {:ok, esl} = LibESL.start_link

    assert :ok = LibESL.set_default_logger(esl, :info)
  end
end
