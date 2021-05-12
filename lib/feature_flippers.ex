defmodule FeatureFlippers do
  @moduledoc """
  Provides a mechanism to turn features on and off within your application.

  Declare a module where you'll define the available FFs and just declare them all:

      defmodule Flags do
          use FeatureFlippers, otp_app: :my_app

          feature_flipper :foo?
          feature_flipper :bar?, expires: "2000-01-01"
          feature_flipper :baz?, disabled: true
      end

  Each `feature_flipper/2` declaration defines a function returning boolean in
  the containing module. So, in your code, use them as follows:

      if Flags.foo? do
          # new feature
      else
          # original code
      end

  It means that if you remove a feature flipper declaration, your code won't
  compile and `mix` will also indicate where the missing feature flippers are
  being used. This may be useful when decommissioning feature flippers.

  You can turn them on/off in compile time setting them in your
  `config/config.exs` (or in runtime through `config/runtime.exs`):

      config :my_app, Flags,
        foo?: true
        bar?: false
        baz: true

  You can also set them later by updating the application environment:

      Application.get_env(:my_app, Flags)
      |> Keyword.update(:bar?, true, fn _ -> true end)
      |> (&Application.put_env(:my_app, Flags, &1)).()

  While running unit tests, you might want to enable them all:

      Flags.all()
      |> Enum.map(fn key -> {key, true} end)
      |> (&Application.put_env(:my_app, Flags, &1)).()

  At any moment, you can discover which feature flippers have expired calling
  `expired/0`.
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)

      @feature_flippers []
      @otp_app unquote(opts)[:otp_app]

      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def all() do
        @feature_flippers
        |> Enum.map(fn {name, _options} ->
          name
        end)
      end

      @doc false
      def expired() do
        @feature_flippers
        |> Enum.flat_map(fn {name, {expires, _default, _disabled}} ->
          if FeatureFlippers.past_due?(expires) do
            [name]
          else
            []
          end
        end)
      end

      for {name, {_expires, default, disabled}} <- @feature_flippers do
        quote do
          if unquote(disabled) do
            @doc false
            def unquote(name)(), do: false
          else
            @doc false
            def unquote(name)() do
              FeatureFlippers.on?(@otp_app, __MODULE__, unquote(name), unquote(default))
            end
          end
        end
      end
      |> Enum.map(fn definition ->
        definition
        |> Code.eval_quoted([], __ENV__)
      end)
      |> Code.eval_quoted()
    end
  end

  @doc """
  Defines a feature flipper.

  The `name` must end with `?`.

  ## Examples

      feature_flipper :foo?
      feature_flipper :bar?, expires: ~D[2000-01-01]
      feature_flipper :baz?, disabled: true

  ## Options

  `feature_flipper/2` accepts the following options:

    * `:expires` - a string in `YYYY-MM-DD` format representing the date when
      it should expire or a `Date` struct. `FeatureFlippers` does not alter any
      feature flipper flag in execution when they expire; this works as
      informational indication to developers when the respective flag should be
      decommissioned.  The function `expired/0` will also show the expired flag
      names.

    * `:disabled` - a boolean indicating if the feature flipper should be
      forcefully disabled. This is defined in compile time, so if a feature
      flipper has `disabled: true`, it means that no application configuration
      will be read; the developer should reenable it and recompile the code if
      they need to turn it on again. It can be used when new features are not
      prepared for production yet, therefore they should never have the
      capability to be turned on.

    * `:default` - if the feature flipper flag is not present in the
      `Application.get_env/3`, assume this boolean as default. If not set,
      `false` is the default.
  """
  defmacro feature_flipper(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      {expires, disabled, default} = FeatureFlippers.compile_feature_flipper(name, options)

      if FeatureFlippers.past_due?(expires) do
        FeatureFlippers.warn(__MODULE__, name, "is past due")
      end

      @feature_flippers [{name, {expires, disabled, default}} | @feature_flippers]
    end
  end

  @doc false
  def compile_feature_flipper(name, options) do
    unless is_list(options) do
      raise ArgumentError, "Feature flipper options must be a keyword list"
    end

    unless valid_name?(name) do
      raise ArgumentError, "Feature flipper name must be atoms and end with ?"
    end

    default = Keyword.get(options, :default, false)
    disabled = Keyword.get(options, :disabled, false)
    expires = Keyword.get(options, :expires, :infinity)

    unless is_boolean(default) do
      raise ArgumentError, "Feature flipper :default must be boolean"
    end

    unless is_boolean(disabled) do
      raise ArgumentError, "Feature flipper :disabled must be boolean"
    end

    unless valid_expires?(expires) do
      raise ArgumentError, "Feature flipper :expired must be a valid date or string"
    end

    {expires, default, disabled}
  end

  @doc false
  def warn(module, name, message) do
    IO.puts(
      :stderr,
      IO.ANSI.format([
        :red,
        module |> Atom.to_string() |> String.replace("Elixir.", ""),
        ".",
        name |> Atom.to_string(),
        " ",
        message
      ])
    )
  end

  @doc false
  def on?(otp_app, module_name, name, default) do
    otp_app
    |> Application.get_env(module_name, [])
    |> Keyword.get(name, default)
  end

  @doc false
  def valid_name?(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> String.ends_with?("?")
  end

  def valid_name?(_), do: false

  @doc false
  def valid_expires?(:infinity), do: true

  def valid_expires?(expires) when is_binary(expires) do
    with {:ok, _} <- Date.from_iso8601(expires) do
      true
    else
      _ -> false
    end
  end

  def valid_expires?(%Date{}), do: true

  def valid_expires?(_), do: false

  @doc false
  def past_due?(:infinity), do: false

  def past_due?(date_string) when is_binary(date_string) do
    date_string
    |> Date.from_iso8601!()
    |> past_due?()
  end

  def past_due?(%Date{} = date) do
    date
    |> Date.compare(Date.utc_today())
    |> case do
      :lt -> true
      _ -> false
    end
  end
end
