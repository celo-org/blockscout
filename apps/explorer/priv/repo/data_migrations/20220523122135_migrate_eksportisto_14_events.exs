defmodule Explorer.Repo.Migrations.MigrateEksportisto14Events do
  @moduledoc """
    Migrating eksportisto events from logs table to celo_contract_events, will upsert existing events.
  """

  @topics [
    "0xbdf7e616a6943f81e07a7984c9d4c00197dc2f481486ce4ffa6af52a113974ad",
    "0xab64f92ab780ecbf4f3866f57cee465ff36c89450dcce20237ca7a8d81fb7d13",
    "0xbae2f33c70949fbc7325c98655f3039e5e1c7f774874c99fd4f31ec5f432b159",
    "0x213377eec2c15b21fa7abcbb0cb87a67e893cdb94a2564aa4bb4d380869473c8",
    "0xa9981ebfc3b766a742486e898f54959b050a66006dbce1a4155c1f84a08bcf41",
    "0x0f0f2fc5b4c987a49e1663ce2c2d65de12f3b701ff02b4d09461421e63e609e7",
    "0x27fe5f0c1c3b1ed427cc63d0f05759ffdecf9aec9e18d31ef366fc8a6cb5dc3b",
    "0xb690f84efb1d9039c2834effb7bebc792a85bfec7ef84f4b269528454f363ccf",
    "0x805996f252884581e2f74cf3d2b03564d5ec26ccc90850ae12653dc1b72d1fa2",
    "0x7cebb17173a9ed273d2b7538f64395c0ebf352ff743f1cf8ce66b437a6144213",
    "0xedf9f87e50e10c533bf3ae7f5a7894ae66c23e6cbbe8773d7765d20ad6f995e9",
    "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0",
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
    "0xddfdbe55eaaa70fe2b8bc82a9b0734c25cabe7cb6f1457f9644019f0b5ff91fc",
    "0xa6e2c5a23bb917ba0a584c4b250257ddad698685829b66a8813c004b39934fe4",
    "0x4dd1abe16ad3d4f829372dc77766ca2cce34e205af9b10f8cc1fab370425864f",
    "0x90290eb9b27055e686a69fb810bada5381e544d07b8270021da2d355a6c96ed6",
    "0x38819cc49a343985b478d72f531a35b15384c398dd80fd191a14662170f895c6",
    "0x92a16cb9e1846d175c3007fc61953d186452c9ea1aa34183eb4b7f88cd3f07bb",
    "0x71bccdb89fff4d914e3d2e472b327e3debaf4c4d6f1dfe528f430447e4cbcf5f",
    "0x55b488abd19ae7621712324d3d42c2ef7a9575f64f5503103286a1161fb40855",
    "0x0fc2463e82c3b8a7868e75b68a76a144816d772687e5b09f45c02db37eedf4f6",
    "0x3e069fb74dcf5fbc07740b0d40d7f7fc48e9c0ca5dc3d19eb34d2e05d74c5543",
    "0xaab5f8a189373aaa290f42ae65ea5d7971b732366ca5bf66556e76263944af28",
    "0x3139419c41cdd7abca84fa19dd21118cd285d3e2ce1a9444e8161ce9fa62fdcd",
    "0xae7458f8697a680da6be36406ea0b8f40164915ac9cc40c0dad05a2ff6e8c6a8",
    "0x91ef92227057e201e406c3451698dd780fe7672ad74328591c88d281af31581d",
    "0xa823fc38a01c2f76d7057a79bb5c317710f26f7dbdea78634598d5519d0f7cb0",
    "0x337b24e614d34558109f3dee80fbcb3c5a4b08a6611bee45581772f64d1681e5",
    "0x4166d073a7a5e704ce0db7113320f88da2457f872d46dc020c805c562c1582a0",
    "0xe5d4e30fb8364e57bc4d662a07d0cf36f4c34552004c4c3624620a2c1d1c03dc",
    "0x43fdefe0a824cb0e3bbaf9c4bc97669187996136fe9282382baf10787f0d808d",
    "0x414ff2c18c092697c4b8de49f515ac44f8bebc19b24553cf58ace913a6ac639d",
    "0x119a23392e161a0bc5f9d5f3e2a6040c45b40d43a36973e10ea1de916f3d8a8a",
    "0xb3ae64819ff89f6136eb58b8563cb32c6550f17eaf97f9ecc32f23783229f6de",
    "0x815d292dbc1a08dfb3103aabb6611233dd2393903e57bdf4c5b3db91198a826c",
    "0x51131d2820f04a6b6edd20e22a07d5bf847e265a3906e85256fca7d6043417c5",
    "0xa18ec663cb684011386aa866c4dacb32d2d2ad859a35d3440b6ce7200a76bad8",
    "0x36a1aabe506bbe8802233cbb9aad628e91269e77077c953f9db3e02d7092ee33",
    "0xe296227209b47bb8f4a76768ebd564dcde1c44be325a5d262f27c1fd4fd4538b",
    "0x557d39a57520d9835859d4b7eda805a7f4115a59c3a374eeed488436fc62a152",
    "0xc7666a52a66ff601ff7c0d4d6efddc9ac20a34792f6aa003d1804c9d4d5baa57",
    "0x484a24d7faca8c4330aaf9ba5f131e6bd474ed6877a555511f39d16a1d71d15a",
    "0x08523596abc266fb46d9c40ddf78fdfd3c08142252833ddce1a2b46f76521035",
    "0x6f184ec313435b3307a4fe59e2293381f08419a87214464c875a2a247e8af5e0",
    "0x0aa96aa275a5f936eed2a6a01f082594744dcc2510f575101366f8f479f03235",
    "0x148075455e24d5cf538793db3e917a157cbadac69dd6a304186daf11b23f76fe",
    "0xf6d22d0b43a6753880b8f9511b82b86cd0fe349cd580bbe6a25b6dc063ef496f",
    "0xae7e034b0748a10a219b46074b20977a9170bf4027b156c797093773619a8669",
    "0xd09501348473474a20c772c79c653e1fd7e8b437e418fe235d277d2c88853251",
    "0xe21a44017b6fa1658d84e937d56ff408501facdb4ff7427c479ac460d76f7893",
    "0xc3293b70d45615822039f6f13747ece88efbbb4e645c42070413a6c3fd21d771",
    "0x716dc7c34384df36c6ccc5a2949f2ce9b019f5d4075ef39139a80038a4fdd1c3",
    "0x49d8cdfe05bae61517c234f65f4088454013bafe561115126a8fe0074dc7700e",
    "0x152c3fc1e1cd415804bc9ae15876b37e62d8909358b940e6f4847ca927f46637",
    "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
    "0x6e53b2f8b69496c2a175588ad1326dbabe2f66df4d82f817aeca52e3474807fb",
    "0x402ac9185b4616422c2794bf5b118bfcc68ed496d52c0d9841dfa114fdeb05ba",
    "0x9dfbc5a621c3e2d0d83beee687a17dfc796bbce2118793e5e254409bb265ca0b",
    "0x91ba34d62474c14d6c623cd322f4256666c7a45b7fdaa3378e009d39dfcec2a7",
    "0x60c5b4756af49d7b071b00dbf0f87af605cce11896ecd3b760d19f0f9d3fbcef",
    "0x292d39ba701489b7f640c83806d3eeabe0a32c9f0a61b49e95612ebad42211cd",
    "0x90c0a4a142fbfbc2ae8c21f50729a2f4bc56e85a66c1a1b6654f1e85092a54a6",
    "0x55311ae9c14427b0863f38ed97a2a5944c50d824bbf692836246512e6822c3cf",
    "0x50146d0e3c60aa1d17a70635b05494f864e86144a2201275021014fbf08bafe2",
    "0x2717ead6b9200dd235aad468c9809ea400fe33ac69b5bfaa6d3e90fc922b6398",
    "0xd78793225285ecf9cf5f0f84b1cdc335c2cb4d6810ff0b9fd156ad6026c89cea",
    "0xab4f92d461fdbd1af5db2375223d65edb43bcb99129b19ab4954004883e52025",
    "0x45aac85f38083b18efe2d441a65b9c1ae177c78307cb5a5d4aec8f7dbcaeabfe",
    "0xf81d74398fd47e35c36b714019df15f200f623dde569b5b531d6a0b4da5c5f26",
    "0x8f21dc7ff6f55d73e4fca52a4ef4fcc14fbda43ac338d24922519d51455d39c1",
    "0x6f5937add2ec38a0fa4959bccd86e3fcc2aafb706cd3e6c0565f87a7b36b9975",
    "0x7abcb995a115c34a67528d58d5fc5ce02c22cb835ce1685046163f7d366d7111",
    "0x1b76e38f3fdd1f284ed4d47c9d50ff407748c516ff9761616ff638c233107625",
    "0x708a7934acb657a77a617b1fcd5f6d7d9ad592b72934841bff01acefd10f9b63",
    "0xb1a3aef2a332070da206ad1868a5e327f5aa5144e00e9a7b40717c153158a588",
    "0xd3532f70444893db82221041edb4dc26c94593aeb364b0b14dfc77d5ee905152",
    "0x28ec9e38ba73636ceb2f6c1574136f83bd46284a3c74734b711bf45e12f8d929",
    "0x71815121f0622b31a3e7270eb28acb9fd10825ff418c9a18591f617bb8a31a6c",
    "0x51407fafe7ef9bec39c65a12a4885a274190991bf1e9057fcc384fc77ff1a7f0",
    "0x1bfe527f3548d9258c2512b6689f0acfccdd0557d80a53845db25fc57e93d8fe",
    "0x5c8cd4e832f3a7d79f9208c2acf25a412143aa3f751cfd3728c42a0fea4921a8",
    "0x8946f328efcc515b5cc3282f6cd95e87a6c0d3508421af0b52d4d3620b3e2db3",
    "0x828d2be040dede7698182e08dfa8bfbd663c879aee772509c4a2bd961d0ed43f",
    "0x0b5629fec5b6b5a1c2cfe0de7495111627a8cf297dced72e0669527425d3f01b",
    "0xd19965d25ef670a1e322fbf05475924b7b12d81fd6b96ab718b261782efb3d62",
    "0xf3709dc32cf1356da6b8a12a5be1401aeb00989556be7b16ae566e65fef7a9df",
    "0x36bc158cba244a94dc9b8c08d327e8f7e3c2ab5f1925454c577527466f04851f",
    "0xaf7f470b643316cf44c1f2898328a075e7602945b4f8584f48ba4ad2d8a2ea9d",
    "0x6c464fad8039e6f09ec3a57a29f132cf2573d166833256960e2407eefff8f592",
    "0x4fbe976a07a9260091c2d347f8780c4bc636392e34d5b249b367baf8a5c7ca69",
    "0xbf4b45570f1907a94775f8449817051a492a676918e38108bb762e991e6b58dc",
    "0x16e382723fb40543364faf68863212ba253a099607bf6d3a5b47e50a8bf94943",
    "0x784c8f4dbf0ffedd6e72c76501c545a70f8b203b30a26ce542bf92ba87c248a4",
    "0x381545d9b1fffcb94ffbbd0bccfff9f1fb3acd474d34f7d59112a5c9973fee49",
    "0x229d63d990a0f1068a86ee5bdce0b23fe156ff5d5174cc634d5da8ed3618e0c9",
    "0x712ae1383f79ac853f8d882153778e0260ef8f03b504e2866e0593e04d2b291f",
    "0x7dc46237a819c9171a9c037ec98928e563892905c4d23373ca0f3f500f4ed114"
  ]

  use Explorer.Repo.Migrations.DataMigration
  import Ecto.Query
  require Logger

  @doc "Undo the data migration"
  def down, do: :ok

  @doc "Returns an ecto query that gives the next batch / page of source rows to be processed"
  def page_query({last_block_number, last_index}) do
    from(
      l in "logs",
      inner_join: ccc in "celo_core_contracts",
      on: ccc.address_hash == l.address_hash,
      select: %{
        first_topic: l.first_topic,
        second_topic: l.second_topic,
        third_topic: l.third_topic,
        fourth_topic: l.fourth_topic,
        data: l.data,
        address_hash: l.address_hash,
        transaction_hash: l.transaction_hash,
        block_number: l.block_number,
        index: l.index
      },
      where: l.first_topic in ^@topics and {l.block_number, l.index} > {^last_block_number, ^last_index},
      order_by: [asc: l.block_number, asc: l.index],
      limit: @batch_size
    )
  end

  def event_changee(to_change) do
    params =
      to_change
      |> EventMap.rpc_to_event_params()
      # explicitly set timestamps as insert_all doesn't do this automatically
      |> then(fn events ->
        t = Timex.now()

        events
        |> Enum.map(fn event ->
          {:ok, contract_address_hash} = Address.dump(event.contract_address_hash)

          event =
            case event.transaction_hash do
              nil ->
                event

              hash ->
                {:ok, transaction_hash} = Full.dump(hash)
                event |> Map.put(:transaction_hash, transaction_hash)
            end

          event
          |> Map.put(:inserted_at, t)
          |> Map.put(:updated_at, t)
          |> Map.put(:contract_address_hash, contract_address_hash)
        end)
      end)

    {inserted_count, results} =
      Explorer.Repo.insert_all("celo_contract_events", params,
        returning: [:block_number, :log_index],
        on_conflict: CeloContractEvent.schemaless_upsert(),
        conflict_target: CeloContractEvent.conflict_target()
      )

    Logger.info("Inserted #{inserted_count} rows")

    if inserted_count != length(to_change) do
      not_inserted =
        to_change
        |> Enum.map(&Map.take(&1, [:block_number, :index]))
        |> MapSet.new()
        |> MapSet.difference(MapSet.new(results))
        |> MapSet.to_list()

      not_inserted |> handle_non_insert()
    end

    last_key =
      to_change
      |> Enum.map(fn %{block_number: block_number, index: index} -> {block_number, index} end)
      |> Enum.max()

    [last_key]
  end

  @doc "Perform the transformation with the list of source rows to operate upon, returns a list of inserted / modified ids"
  def do_change(ids) do
    event_changee(ids)
  end

  # we simply log here, as postgres does not inform us of upserts we cannot consider non insertions as errors
  # https://hexdocs.pm/ecto/Ecto.Repo.html#c:insert_all/3-return-values
  @doc "Handle unsuccessful insertions"
  def handle_non_insert(ids), do: Logger.info("Failed to insert - #{inspect(ids)}")
end
