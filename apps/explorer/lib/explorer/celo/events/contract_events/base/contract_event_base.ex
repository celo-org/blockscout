defmodule Explorer.Celo.ContractEvents.Base do
  defmacro __using__(opts) do
    name = Keyword.get(opts, :name)
    topic = Keyword.get(opts, :topic)

    quote do
      import Explorer.Celo.ContractEvents.Base
      @before_compile unquote(__MODULE__)

      Module.register_attribute unquote(__MODULE__), :event_param, accumulate: true

      alias Explorer.Celo.ContractEvents.EventTransformer
      alias Explorer.Chain.{CeloContractEvent, Log}
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

  defmacro __before_compile__(env) do
    IO.inspect(env)
    #defstruct
    common_struct_properties = [
      :transaction_hash,
      :block_hash,
      :contract_address_hash,
      :log_index,
      name: quote(@name)
    ]

    specific_struct_properties = [
    ]
    #transformation methods
    #query methods
    #protocol implementation

    quote do
      defstruct unquote(common_struct_properties)

      defimpl EventTransformer do
        import Explorer.Celo.ContractEvents.Common

        def from_log(_, %Log{} = log) do
          params = log |> Map.from_struct()
          from_params(nil, params)
        end

        def from_params(_, params) do
          [value] = decode_data(params.data, [{:uint, 256}])
          group = decode_event(params.second_topic, :address)

          %unquote(__MODULE__){
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

          %unquote(__MODULE__){
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
