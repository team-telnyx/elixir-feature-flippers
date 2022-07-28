defmodule FeatureFlippersCallbackTest do
  use ExUnit.Case

  defmodule Flags do
    use FeatureFlippers, callback: &FeatureFlippersCallbackTest.on?/1

    feature_flipper :foo?
  end

  test "check if the callback actually works" do
    assert Flags.foo?() == true
  end

  def on?(:foo?), do: true
end
