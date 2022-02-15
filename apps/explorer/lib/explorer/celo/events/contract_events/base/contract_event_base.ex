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

  defmacro __before_compile__(_env) do
    #query methods

    quote do
      alias Explorer.Celo.ContractEvents.EventTransformer

      # define event struct based on event params
      common_event_properties = [
        :transaction_hash,
        :block_hash,
        :contract_address_hash,
        :log_index,
        name: @name
      ]

      specific_event_properties = @params |> Enum.map(&(&1.name))

      defstruct common_event_properties ++ specific_event_properties

      # Implement EventTransformer protocol to convert between CeloContractEvent, Chain.Log, and this generated type
      event_module = __MODULE__
      defimpl EventTransformer do
        @event event_module
        import Explorer.Celo.ContractEvents.Common
        alias Explorer.Chain.{CeloContractEvent, Log}

        def from_log(_, %Log{} = log) do
          params = log |> Map.from_struct()
          from_params(nil, params)
        end

        def from_params(_, params) do
          [value] = decode_data(params.data, [{:uint, 256}])
          group = decode_event(params.second_topic, :address)

          %@event{
            transaction_hash: params.transaction_hash,
            block_hash: params.block_hash,
            contract_address_hash: params.address_hash,
            log_index: params.index,
            group: group,
            value: value
          }
        end

        def from_celo_contract_event(_, %CeloContractEvent{params: params} = contract) do
          %{group: group, value: value} = params |> normalise_map()

          %@event{
            transaction_hash: contract.transaction_hash,
            block_hash: contract.block_hash,
            contract_address_hash: contract.contract_address_hash,
            log_index: contract.log_index,
            group: group |> ca(),
            value: value
          }
        end

        def to_celo_contract_event_params(event) do
          event_params = %{params: %{group: event.group |> fa(), value: event.value}}

          event
          |> extract_common_event_params()
          |> Map.merge(event_params)
        end
      end
    end
  end
end
