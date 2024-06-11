import Config

config :block_scout_web,
  defi: [
    %{title: "Moola", url: "https://moola.market/"},
    %{title: "Revo", url: "https://revo.market/"}
  ],
  swap: [
    %{title: "Ubeswap", url: "https://ubeswap.org/"},
    %{title: "Symmetric", url: "https://symmetric.finance/"},
    %{title: "Mobius", url: "https://www.mobius.money/"},
    %{title: "Mento-fi", url: "https://mento.finance/"},
    %{title: "Swap Bitssa", url: "https://swap.bitssa.com/"}
  ],
  wallet_list: [
    %{title: "Valora", url: "https://valoraapp.com/"},
    %{title: "Celo Terminal", url: "https://celoterminal.com/"},
    %{title: "Celo Wallet", url: "https://celowallet.app/"}
  ],
  nft_list: [
    %{title: "NFT Viewer", url: "https://nfts.valoraapp.com/"},
    %{title: "Nomspace", url: "https://nom.space/"}
  ],
  connect_list: [
    %{title: "impactMarket", url: "https://impactmarket.com/"},
    %{title: "Talent Protocol", url: "https://talentprotocol.com/"},
    %{title: "Doni", url: "https://doni.app/"}
  ],
  spend_list: [
    %{title: "Bidali", url: "https://giftcards.bidali.com/"},
    %{title: "Flywallet", url: "https://flywallet.io/"},
    %{title: "ChiSpend", url: "https://chispend.com/"}
  ],
  finance_tools_list: [
    %{title: "Celo Tracker", url: "https://celotracker.com/"}
  ],
  derivates_platforms_list: [
    %{title: "ImmortalX", url: "https://www.immortalx.io/"}
  ],
  resources: [
    %{title: "Celo Vote", url: "https://celovote.com/"},
    %{title: "Celo Forum", url: "https://forum.celo.org/"},
    %{title: "TheCelo", url: "https://thecelo.com/"},
    %{title: "Celo Reserve", url: "https://celoreserve.org/"},
    %{title: "Celo Docs", url: "https://docs.celo.org/"}
  ],
  learning: [
    %{title: "Celo Whitepaper", url: "https://celo.org/papers/whitepaper"},
    %{title: "Coinbase Earn", url: "https://www.coinbase.com/price/celo"}
  ],
  other_networks: [
    %{title: "Celo Mainnet", url: "https://explorer.celo.org/mainnet", test_net?: false},
    %{title: "Celo Alfajores", url: "https://explorer.celo.org/alfajores", test_net?: true},
    %{title: "Celo Baklava", url: "https://explorer.celo.org/baklava", test_net?: true}
  ]
