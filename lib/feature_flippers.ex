defmodule FeatureFlippers do
  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)

      @feature_flippers []
      @otp_app unquote(opts)[:otp_app]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def all() do
        @feature_flippers
        |> Enum.map(fn {feature_flipper_name, _options} ->
          feature_flipper_name
        end)
      end

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
            def unquote(feature_flipper_name)(), do: false
          else
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

  def on?(otp_app, module_name, feature_flipper_name) do
    otp_app
    |> Application.get_env(module_name, [])
    |> Keyword.get(feature_flipper_name, false)
  end

  def valid_name?(feature_flipper_name) when is_atom(feature_flipper_name) do
    feature_flipper_name
    |> Atom.to_string()
    |> String.ends_with?("?")
  end

  def valid_name?(_), do: false

  def past_due?(nil), do: false

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
