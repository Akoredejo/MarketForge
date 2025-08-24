MarketForge
===========

A sophisticated price discovery and automated market making contract for decentralized marketplaces. This Stacks smart contract, written in Clarity, provides real-time pricing, order book management, and dynamic liquidity provision to create a robust, decentralized trading environment.

* * * * *

📖 Table of Contents
--------------------

-   Introduction

-   Features

-   Getting Started

-   Contract Architecture

-   Functions

-   Public Functions

-   Private Functions

-   Read-Only Functions

-   Error Codes

-   Constants & Parameters

-   Data Structures

-   Testing

-   Contribution

-   License

-   Related Projects

-   Acknowledgments

* * * * *

🚀 Introduction
---------------

**MarketForge** is a core component for building decentralized exchanges (DEXs) and financial applications on the Stacks blockchain. It addresses the fundamental challenge of price discovery in a transparent and automated manner. By implementing a traditional order book model combined with a dynamic automated market making (AMM) function, the contract ensures deep liquidity and accurate, real-time pricing without relying on centralized oracles.

This contract enables users to:

-   Place limit orders to buy or sell assets.

-   Execute trades directly from the order book.

-   Provide liquidity as a market maker with dynamic spreads.

-   Track real-time market data, including price and volume.

* * * * *

✨ Features
----------

-   **Order Book Management**: A classic, on-chain order book that stores active buy and sell orders, enabling efficient and transparent trade matching.

-   **Dynamic Price Discovery**: The contract's `current-prices` map is updated with every executed trade, providing a real-time price feed for each token pair.

-   **Automated Market Making (AMM)**: The `provide-market-liquidity` function allows users to automatically create a series of buy and sell orders with a specified spread, acting as a dynamic liquidity provider.

-   **Risk Management**: The AMM function includes built-in volatility adjustments and exposure checks to help protect liquidity providers.

-   **Error Handling**: A comprehensive set of error codes ensures that all invalid or unauthorized actions are handled gracefully and securely.

* * * * *

🛠️ Getting Started
-------------------

To deploy and interact with the **MarketForge** contract, you will need the Stacks CLI or a compatible development environment such as the Clarinet suite.

### Prerequisites

-   [Stacks CLI](https://www.google.com/search?q=https://github.com/blockstack/stacks-cli)

-   [Clarinet](https://github.com/hirosystems/clarinet)

### Deployment

1.  Clone the repository: `git clone https://github.com/your-username/marketforge.git`

2.  Navigate to the contract directory.

3.  Deploy the contract to the Stacks blockchain using the Stacks CLI.

### Interaction

You can interact with the contract's public functions using the Stacks CLI or a front-end application.

**Example: Placing an Order**

```
$ stacks-cli contract call ST000000000000000000002S661M.market-forge place-order '("STX-USDC" "buy" u1000000 u5000000)'

```

This command places a buy order for 1 STX at a price of 5 USDC.

* * * * *

🏗️ Contract Architecture
-------------------------

The contract is structured to be modular and secure, with a clear separation of concerns.

* * * * *

📚 Functions
------------

A detailed breakdown of the contract's key functions.

* * * * *

🔓 Public Functions
-------------------

### `place-order`

`(define-public (place-order (token-pair (string-ascii 20)) (order-type (string-ascii 4)) (quantity uint) (price uint)))`

-   **Purpose**: Places a new limit order in the order book.

-   **Parameters**:

    -   `token-pair`: The trading pair (e.g., "STX-USDC").

    -   `order-type`: The type of order ("buy" or "sell").

    -   `quantity`: The amount of the asset to trade.

    -   `price`: The desired price for the trade.

-   **Returns**: `(ok order-id)` on success, or an error code on failure.

### `execute-trade`

`(define-public (execute-trade (buy-order-id uint) (sell-order-id uint)))`

-   **Purpose**: Executes a trade between a buyer and a seller.

-   **Parameters**:

    -   `buy-order-id`: The unique ID of the buy order.

    -   `sell-order-id`: The unique ID of the sell order.

-   **Returns**: `(ok trade-quantity)` on success, or an error code on failure.

### `cancel-order`

`(define-public (cancel-order (order-id uint)))`

-   **Purpose**: Allows a trader to cancel their own active order.

-   **Parameters**:

    -   `order-id`: The unique ID of the order to cancel.

-   **Returns**: `(ok true)` on success, or an error code on failure.

### `provide-market-liquidity`

`(define-public (provide-market-liquidity (token-pair (string-ascii 20)) (base-quantity uint) (spread-percentage uint) (max-exposure uint)))`

-   **Purpose**: Creates a series of buy and sell orders to provide dynamic liquidity.

-   **Parameters**:

    -   `token-pair`: The trading pair.

    -   `base-quantity`: The total quantity of tokens to be split across the order levels.

    -   `spread-percentage`: The desired spread around the market price.

    -   `max-exposure`: The maximum allowed exposure for the market maker.

-   **Returns**: `(ok { ... })` with a summary of the created orders on success, or an error code on failure.

* * * * *

🔒 Private Functions
--------------------

-   `calculate-weighted-price`: A private function to calculate a price based on order book depth, with a specific adjustment for large orders.

-   `min-uint`: A simple helper function to determine the minimum of two unsigned integers.

-   `validate-order`: Ensures that all order parameters meet the minimum requirements before being processed.

-   `update-market-depth`: An internal function that updates the `market-depth` map after an order is placed or executed, which is crucial for real-time market analysis.

* * * * *

🔍 Read-Only Functions
----------------------

### `get-current-price`

`(define-read-only (get-current-price (token-pair (string-ascii 20))))`

-   **Purpose**: Allows anyone to query the latest market price for a given token pair without incurring a transaction fee.

-   **Parameters**:

    -   `token-pair`: The trading pair.

-   **Returns**: `(some { ... })` with the current price data, or `(none)` if no data exists.

* * * * *

🚨 Error Codes
--------------

-   `ERR-NOT-AUTHORIZED` (`u100`): The transaction sender is not authorized to perform the action.

-   `ERR-INSUFFICIENT-BALANCE` (`u101`): The sender has an insufficient balance for the transaction.

-   `ERR-INVALID-ORDER` (`u102`): The order parameters are invalid.

-   `ERR-ORDER-NOT-FOUND` (`u103`): The specified order ID does not exist.

-   `ERR-INVALID-PRICE` (`u104`): The provided price is invalid.

-   `ERR-MARKET-CLOSED` (`u105`): The market is currently inactive.

-   `ERR-SLIPPAGE-EXCEEDED` (`u106`): The trade's slippage is greater than the allowed maximum.

* * * * *

📊 Constants & Parameters
-------------------------

-   `MIN-ORDER-SIZE`: `u1000000` (1 token)

-   `MAX-SLIPPAGE`: `u500` (5%)

-   `MARKET-FEE`: `u25` (0.25%)

-   `PRICE-PRECISION`: `u1000000` (6 decimals)

-   `CONTRACT-OWNER`: `tx-sender` (the deployer of the contract)

* * * * *

💾 Data Structures
------------------

### `orders` map

-   **Key**: `{ order-id: uint }`

-   **Value**: `{ trader: principal, token-pair: (string-ascii 20), order-type: (string-ascii 4), quantity: uint, price: uint, timestamp: uint, status: (string-ascii 10) }`

### `current-prices` map

-   **Key**: `{ token-pair: (string-ascii 20) }`

-   **Value**: `{ price: uint, last-updated: uint, volume-24h: uint, price-change-24h: int }`

### `market-depth` map

-   **Key**: `{ token-pair: (string-ascii 20), price-level: uint }`

-   **Value**: `{ buy-volume: uint, sell-volume: uint }`

* * * * *

✅ Testing
---------

Comprehensive testing is crucial for smart contracts. This contract is designed to be tested using the Clarinet testing framework, ensuring that all functions, especially `execute-trade` and `provide-market-liquidity`, behave as expected under various conditions.

* * * * *

🤝 Contribution
---------------

We welcome contributions from the community. If you find a bug or have an idea for an enhancement, please open an issue or submit a pull request.

* * * * *

📜 License
----------

This project is licensed under the MIT License - see the `LICENSE` file for details.

* * * * *

🔗 Related Projects
-------------------

This contract can be integrated with:

-   Front-end decentralized application (dApp) frameworks.

-   On-chain oracles for external price feeds (although this contract provides its own).

-   Other Clarity contracts for token transfers and asset management.

* * * * *

🙏 Acknowledgments
------------------

-   The Stacks community for their support and valuable resources.

-   The Clarity language and its commitment to security and predictability.
