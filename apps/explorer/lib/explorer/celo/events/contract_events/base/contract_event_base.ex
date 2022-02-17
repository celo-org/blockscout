defmodule Explorer.Celo.ContractEvents.Base do
  defmacro __using__(opts) do
    name = Keyword.get(opts, :name)
    topic = Keyword.get(opts, :topic)

    quote do
      import Explorer.Celo.ContractEvents.Base
      @before_compile unquote(__MODULE__)

      Module.register_attribute __MODULE__, :params, accumulate: true

      alias Explorer.Chain.CeloContractEvent
      import Ecto.Query

      @name unquote(name)
      @topic unquote(topic)

      def name, do: @name
      def topic, do: @topic

      def query do
        from(c in CeloContractEvent, where: c.name == ^@name)
      end
    end
  end

  defmacro event_param(name, type, indexed) do
    quote do
      @params %{name: unquote(name), type: unquote(type), indexed: unquote(indexed)}
      :ok
    end
  end

  defmacro __before_compile__(env) do

    #retrieve event properties at compile time
    #reverse as elixir module attributes are pushed to top of list and we rely on defined event property order
    properties = Module.get_attribute(env.module, :params) |> Enum.reverse()

    #finding all properties for the event struct
    common_event_properties = [
      :transaction_hash,
      :block_hash,
      :contract_address_hash,
      :log_index,
      name: Module.get_attribute(env.module, :name)
    ]

    struct_properties = properties
      |> Enum.map(&(&1.name))
      |> Enum.concat(common_event_properties)

    #referencing module within derived methods of protocol implementation
    event_module = env.module

    unindexed_properties = properties
                           |> Enum.filter(&(&1.indexed == :unindexed))

    unindexed_types = unindexed_properties
                      |> Enum.map(&(&1.type))

    indexed_types_with_topics = properties
                                |> Enum.filter(&(&1.indexed == :indexed))
                                |> Enum.zip([:second_topic, :third_topic, :fourth_topic])

    #Define a struct based on declared event properties
    struct_def = quote do
      defstruct unquote(struct_properties)
    end

    # Implement EventTransformer protocol to convert between CeloContractEvent, Chain.Log, and this generated type
    protocol_impl = quote do
      alias Explorer.Celo.ContractEvents.EventTransformer

      defimpl EventTransformer do
        import Explorer.Celo.ContractEvents.Common
        alias Explorer.Chain.{CeloContractEvent, Log}

        # coerce an Explorer.Chain.Log instance into a Map and treat the same as EthereumJSONRPC log params
        def from_log(_, %Log{} = log) do
          params = log |> Map.from_struct()
          from_params(nil, params)
        end

        # decode blockchain log data into event relevant properties
        def from_params(_, params) do
          #creating a map of unindexed (appear in event data) event properties %{name => value}
          unindexed_event_properties =
            decode_data(params.data, unquote(Macro.escape(unindexed_types)))
            |> Enum.zip(unquote(Macro.escape(unindexed_properties)))
            |> Enum.map(fn {data, %{name: name}} -> {name, data} end)
            |> Enum.into(%{})

          #creating a map of indexed (appear in event topics) event properties %{name => value}
          indexed_event_properties = unquote(Macro.escape(indexed_types_with_topics))
            |> Enum.map( fn  {%{name: name, type: type}, topic} ->
              {name, decode_event(params[topic], type)}
            end)
            |> Enum.into(%{})

          #mapping common event properties
          common_event_properties = %{
            transaction_hash: params.transaction_hash,
            block_hash: params.block_hash,
            contract_address_hash: params.address_hash,
            log_index: params.index
          }

          #instantiate a struct from properties
          common_event_properties
          |> Map.merge(indexed_event_properties)
          |> Map.merge(unindexed_event_properties)
          |> then(&(struct(unquote(event_module), &1)))
        end

        # create a concrete event instance from a CeloContractEvent
        def from_celo_contract_event(_, %CeloContractEvent{params: params} = contract) do
          event_params = params
             |> normalise_map()
             |> Map.take(unquote(Macro.escape(struct_properties)))
             |> Enum.map( fn
                {k, v = "\\x" <> _rest} ->
                  {k, cast_address(v)}
                {k, v} -> {k, v}
             end)
            |> Enum.into(%{})

          %{
            transaction_hash: contract.transaction_hash,
            block_hash: contract.block_hash,
            contract_address_hash: contract.contract_address_hash,
            log_index: contract.log_index
          }
          |> Map.merge(event_params)
          |> then(&(struct(unquote(event_module), &1)))
        end

        # params to be provided to CeloContractEvent changeset
        def to_celo_contract_event_params(event) do
          event_params = unquote(Macro.escape(properties))
          |> Enum.map(fn
            %{name: name, type: :address} -> {name, Map.get(event,name) |> format_address_for_postgres_json()}
            %{name: name} -> {name, Map.get(event, name)}
          end)
          |> Enum.into(%{})

          event
          |> extract_common_event_params()
          |> Map.merge(%{params: event_params})
        end
      end
    end


    #define queries for address types
    dynamic_queries = properties
    |> Enum.filter(&( &1.type == :address))
    |> Enum.map(fn %{name: name}->
      import Ecto.Query
      alias Explorer.Celo.ContractEvents.Common
      quote do
        def unquote(:"query_by_#{name}")(query, address) do
          address = Common.format_address_for_postgres_json(address)

          from(c in query,
            where: fragment("? ->> ? = ?", c.params, unquote(Atom.to_string(name)), ^address)
          )
        end
      end
    end)

    # return multiple generated AST nodes - merge all the above `quote` statements into the module definition
    [struct_def, protocol_impl, dynamic_queries] |> List.flatten()
  end
end
