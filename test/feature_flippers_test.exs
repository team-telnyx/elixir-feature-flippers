defmodule FeatureFlippersTest do
  use ExUnit.Case
  doctest FeatureFlippers

  defmodule Flags do
    use FeatureFlippers, otp_app: :feature_flippers

    feature_flipper :foo?
    feature_flipper :bar?, expires: "2000-01-01"
    feature_flipper :baz?, disabled: true
    feature_flipper :foobar?, default: true
    feature_flipper :qux?, expires: ~D[2100-01-01]
  end

  test "put true in application env, Flags.foo? becomes true" do
    assert Flags.foo?() == false

    Application.put_env(:feature_flippers, Flags, foo?: true)

    assert Flags.foo?()
  end

  test "put true in application env, Flags.bar? becomes true even having expired" do
    assert Flags.bar?() == false

    Application.put_env(:feature_flippers, Flags, bar?: true)

    assert Flags.bar?()
  end

  test "put true in application env, Flags.baz? never gets true" do
    assert Flags.baz?() == false

    Application.put_env(:feature_flippers, Flags, baz?: true)

    assert Flags.baz?() == false
  end

  test "only :bar? has expired" do
    assert Flags.expired() == [:bar?]
    assert :qux? not in Flags.expired()
  end

  test "default of Flags.foobar? is true" do
    assert Flags.foobar?() == true
  end
end
