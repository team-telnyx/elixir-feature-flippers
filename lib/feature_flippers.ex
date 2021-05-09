defmodule FeatureFlippers do
  @moduledoc """
  Provides a mechanism to turn features on and off within your application.

  Declare a module where you'll define the available FFs and just declare them all:

      defmodule Flags do
          use FeatureFlippers, otp_app: :my_app

          feature_flipper :foo?
          feature_flipper :bar?, expires: "2000-01-01"
          feature_flipper :baz?, always_disabled: true
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
        |> Enum.map(fn {feature_flipper_name, _options} ->
          feature_flipper_name
        end)
      end

      @doc false
      def expired() do
        @feature_flippers
        |> Enum.flat_map(fn {feature_flipper_name, options} ->
          if FeatureFlippers.past_due?(options[:expires]) do
            [feature_flipper_name]
          else
            []
          end
        end)
      end

      for {feature_flipper_name, options} <- @feature_flippers do
        quote do
          if Keyword.get(unquote(options), :always_disabled, false) do
            @doc false
            def unquote(feature_flipper_name)(), do: false
          else
            @doc false
            def unquote(feature_flipper_name)(),
              do: FeatureFlippers.on?(@otp_app, __MODULE__, unquote(feature_flipper_name))
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

  The `feature_flipper_name` must end with `?`.

  ## Examples

      feature_flipper :foo?
      feature_flipper :bar?, expires: "2000-01-01"
      feature_flipper :baz?, always_disabled: true

  ## Options

  `feature_flipper/2` accepts the following options:

    * `:expires` - a string in `YYYY-MM-DD` format representing the date when
      it should expire. `FeatureFlippers` does not alter any feature flipper
      flag in execution when they expire; this works as informational
      indication to developers when the respective flag should be
      decommissioned.  The function `expired/0` will also show the expired flag
      names.

    * `:always_disabled` - a boolean indicating if the feature flipper should
      be forcefully disabled. This is defined in compile time, so if a feature
      flipper has `always_disabled: true`, it means that no application
      configuration will be read; the developer should reenable it and
      recompile the code if they need to turn it on again. It can be used when
      new features are not prepared for production yet, therefore they should
      never have the capability to be turned on.
  """
  defmacro feature_flipper(feature_flipper_name, options \\ []) do
    quote do
      if not FeatureFlippers.valid_name?(unquote(feature_flipper_name)) do
        raise ArgumentError, "Feature flippers must be atoms and end with ?"
      end

      if FeatureFlippers.past_due?(unquote(options)[:expires]) do
        IO.puts(
          :stderr,
          IO.ANSI.format([
            :red,
            "#{__MODULE__ |> Atom.to_string() |> String.replace("Elixir.", "")}",
            ".#{unquote(feature_flipper_name)} is past due"
          ])
        )
      end

      @feature_flippers [{unquote(feature_flipper_name), unquote(options)} | @feature_flippers]
    end
  end

  @doc false
  def on?(otp_app, module_name, feature_flipper_name) do
    otp_app
    |> Application.get_env(module_name, [])
    |> Keyword.get(feature_flipper_name, false)
  end

  @doc false
  def valid_name?(feature_flipper_name) when is_atom(feature_flipper_name) do
    feature_flipper_name
    |> Atom.to_string()
    |> String.ends_with?("?")
  end

  @doc false
  def valid_name?(_), do: false

  @doc false
  def past_due?(nil), do: false

  @doc false
  def past_due?(date_string) do
    date_string
    |> Date.from_iso8601!()
    |> Date.compare(Date.utc_today())
    |> case do
      :lt -> true
      _ -> false
    end
  end
end
