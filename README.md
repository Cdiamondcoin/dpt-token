# Diamond network  DPT token ERC20 Smart Contract

One of the main purposes of [Diamond Network Project](https://cdiamondcoin.com/) is to create a diamond backed stable coin. To use the services of the platform you will need a utility token called DPT - Diamond Platform Token. Current repository contains the [ERC20](https://github.com/ethereum/EIPs/issues/20) compatible smart contract of DPT token, and also the smart contract supporting the ICO of DPT.

## Prerequisities 

In order to compile smart contracts you need to install [Dapphub](https://dapphub.com/)'s utilities. Namely: [dapp](https://dapp.tools/dapp/), [seth](https://dapp.tools/seth/), [solc](https://github.com/ethereum/solidity), [hevm](https://dapp.tools/hevm/), and [ethsign](https://github.com/dapphub/dapptools/tree/master/src/ethsign). 

| Command | Description |
| --- | --- |
|`bash <(curl https://nixos.org/nix/install)` | install `nix` package manager.|
|`. "$HOME/.nix-profile/etc/profile.d/nix.sh"`| load config for `nix`|
|`git clone --recursive https://github.com/dapphub/dapptools $HOME/.dapp/dapptools` | download `dapp seth solc hevm ethsign` utilities|
|`nix-env -f $HOME/.dapp/dapptools -iA dapp seth solc hevm ethsign` | install `dapp seth solc hevm ethsign`. This will install utilities for current user only!!|

## Installing smart contracts 

As a result of installation .abi and .bin files will be created in `dpt-token/out/` folder. These files can be installed later on mainnet.

| Command | Description |
| --- | --- |
|`git clone https://github.com/trialine/dpt-token.git` | Clone the smart contract code.|
|`cd dpt-token && git submodule update --init --recursive` | Update libraries to the latest version.|
|`dapp test` | Compile and test the smart contracts.|

## Deploying smart contracts

In order to deploy smart contracts you need to do the followings.
- Deploy `dpt-token/out/DPT.abi` `dpt-token/out/DPT.bin` to install DPT token.
- Deploy `dpt-token/out/DPTICO.abi` `dpt-token/out/DPTICO.bin` to install DPT ICO smart contract.
- Lets assume `dpt` is the address of DPT token, and `ico` is the address of ICO smart contract. Execute as owner `(dpt).approve(ico, uint(-1))` to enable for ICO smart contract to manipulate dpt tokens.

## Authors

- [Vital Belikov](https://github.com/Brick85)
- [Aleksejs Osovitnijs](https://github.com/alexxxxey)
- [Vitālijs Gaičuks](https://github.com/vgaicuks)

## License

This project is licensed under the GPL v3 License - see the [LICENSE](LICENSE) for details.
