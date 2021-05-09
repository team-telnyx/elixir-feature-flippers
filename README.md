# FeatureFlippers

A helpful and simple way to use feature toggles/flippers/flags on your Elixir code, built around `Application` configurations. It is intended to allow developers to push code to production in a disabled state and carefully control whether or not the code is enabled or disabled without doing additional releases.

## How to use

Declare a module where you'll define the available FFs and just declare them all:

```elixir
defmodule Flags do
  use FeatureFlippers, otp_app: :my_app

  feature_flipper :foo?
  feature_flipper :bar?, expires: "2000-01-01"
  feature_flipper :baz?, always_disabled: true
end
```

In your code, you can use the example module `Flags` as in:

```elixir
if Flags.foo? do
  ... new code ...
else
  ... original code ...
end
```

In order to turn them on/off, just declare them in your `config/config.exs`:

```elixir
config :my_app, Flags,
  foo?: true
  bar?: false
  baz: true
```

You can also set them in runtime by updating the corresponding config key `Flags`:

```elixir
Application.get_env(:my_app, Flags)
|> Keyword.update(:bar?, true, fn _ -> true end)
|> (&Application.put_env(:my_app, Flags, &1)).()
```

While running unit tests, you might want to enable them all:

```elixir
Flags.all()
|> Enum.map(fn key -> {key, true} end)
|> (&Application.put_env(:my_app, Flags, &1)).()
```

You can discover which feature flippers have expired calling:

```elixir
iex> Flags.expired()
[:bar]
```

## Installation

The package can be installed by adding `feature_flippers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:feature_flippers, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/feature_flippers](https://hexdocs.pm/feature_flippers).

