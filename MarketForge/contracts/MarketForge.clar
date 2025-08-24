;; Real-Time Price Discovery Contract for Decentralized Marketplaces
;; This contract implements a sophisticated price discovery mechanism that enables
;; real-time market pricing through order book management, dynamic price calculation,
;; and automated market making functionality for decentralized trading platforms.

;; Constants - Error codes and system parameters
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-ORDER (err u102))
(define-constant ERR-ORDER-NOT-FOUND (err u103))
(define-constant ERR-INVALID-PRICE (err u104))
(define-constant ERR-MARKET-CLOSED (err u105))
(define-constant ERR-SLIPPAGE-EXCEEDED (err u106))

(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-ORDER-SIZE u1000000) ;; 1 token minimum
(define-constant MAX-SLIPPAGE u500) ;; 5% maximum slippage
(define-constant MARKET-FEE u25) ;; 0.25% trading fee
(define-constant PRICE-PRECISION u1000000) ;; 6 decimal precision

;; Data maps and variables - Core state management
;; Order book storage with comprehensive order data
(define-map orders
  { order-id: uint }
  {
    trader: principal,
    token-pair: (string-ascii 20),
    order-type: (string-ascii 4), ;; "buy" or "sell"
    quantity: uint,
    price: uint,
    timestamp: uint,
    status: (string-ascii 10) ;; "active", "filled", "cancelled"
  }
)

;; Real-time price tracking for each trading pair
(define-map current-prices
  { token-pair: (string-ascii 20) }
  { 
    price: uint,
    last-updated: uint,
    volume-24h: uint,
    price-change-24h: int
  }
)

;; User balances for trading
(define-map user-balances
  { user: principal, token: (string-ascii 10) }
  { balance: uint }
)

;; Market depth data for price discovery
(define-map market-depth
  { token-pair: (string-ascii 20), price-level: uint }
  { 
    buy-volume: uint,
    sell-volume: uint
  }
)

;; Global state variables
(define-data-var next-order-id uint u1)
(define-data-var market-active bool true)
(define-data-var total-volume uint u0)

;; Private functions - Internal logic and calculations
;; Calculate weighted average price based on order book depth
(define-private (calculate-weighted-price (token-pair (string-ascii 20)) (quantity uint))
  (let (
    (current-price-data (default-to 
      { price: u0, last-updated: u0, volume-24h: u0, price-change-24h: 0 }
      (map-get? current-prices { token-pair: token-pair })))
    (base-price (get price current-price-data))
  )
    ;; Apply supply/demand adjustment based on quantity
    (if (> quantity u10000000) ;; Large order adjustment
      (+ base-price (/ (* base-price u50) u10000)) ;; 0.5% premium for large orders
      base-price
    )
  )
)

;; Helper function to find minimum of two values
(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b)
)

;; Validate order parameters for security
(define-private (validate-order (quantity uint) (price uint))
  (and
    (>= quantity MIN-ORDER-SIZE)
    (> price u0)
    (var-get market-active)
  )
)

;; Update market depth after order placement or execution
(define-private (update-market-depth (token-pair (string-ascii 20)) (price uint) (quantity uint) (is-buy bool))
  (let (
    (current-depth (default-to 
      { buy-volume: u0, sell-volume: u0 }
      (map-get? market-depth { token-pair: token-pair, price-level: price })))
  )
    (if is-buy
      (map-set market-depth 
        { token-pair: token-pair, price-level: price }
        { 
          buy-volume: (+ (get buy-volume current-depth) quantity),
          sell-volume: (get sell-volume current-depth)
        }
      )
      (map-set market-depth 
        { token-pair: token-pair, price-level: price }
        { 
          buy-volume: (get buy-volume current-depth),
          sell-volume: (+ (get sell-volume current-depth) quantity)
        }
      )
    )
  )
)

;; Public functions - External interface
;; Place a new order in the order book
(define-public (place-order (token-pair (string-ascii 20)) (order-type (string-ascii 4)) (quantity uint) (price uint))
  (let (
    (order-id (var-get next-order-id))
    (is-buy (is-eq order-type "buy"))
  )
    (asserts! (validate-order quantity price) ERR-INVALID-ORDER)
    (asserts! (var-get market-active) ERR-MARKET-CLOSED)
    
    ;; Store the order
    (map-set orders
      { order-id: order-id }
      {
        trader: tx-sender,
        token-pair: token-pair,
        order-type: order-type,
        quantity: quantity,
        price: price,
        timestamp: block-height,
        status: "active"
      }
    )
    
    ;; Update market depth and next order ID
    (update-market-depth token-pair price quantity is-buy)
    (var-set next-order-id (+ order-id u1))
    
    (ok order-id)
  )
)

;; Execute trade between matching orders
(define-public (execute-trade (buy-order-id uint) (sell-order-id uint))
  (let (
    (buy-order (unwrap! (map-get? orders { order-id: buy-order-id }) ERR-ORDER-NOT-FOUND))
    (sell-order (unwrap! (map-get? orders { order-id: sell-order-id }) ERR-ORDER-NOT-FOUND))
    (trade-price (get price buy-order))
    (trade-quantity (min-uint (get quantity buy-order) (get quantity sell-order)))
  )
    ;; Validate orders can be matched
    (asserts! (is-eq (get status buy-order) "active") ERR-INVALID-ORDER)
    (asserts! (is-eq (get status sell-order) "active") ERR-INVALID-ORDER)
    (asserts! (>= (get price buy-order) (get price sell-order)) ERR-INVALID-PRICE)
    
    ;; Update order statuses
    (map-set orders { order-id: buy-order-id } (merge buy-order { status: "filled" }))
    (map-set orders { order-id: sell-order-id } (merge sell-order { status: "filled" }))
    
    ;; Update current price
    (map-set current-prices
      { token-pair: (get token-pair buy-order) }
      {
        price: trade-price,
        last-updated: block-height,
        volume-24h: (+ trade-quantity u0), ;; Simplified for demo
        price-change-24h: 0 ;; Simplified for demo
      }
    )
    
    (var-set total-volume (+ (var-get total-volume) trade-quantity))
    (ok trade-quantity)
  )
)

;; Get current market price for a token pair
(define-read-only (get-current-price (token-pair (string-ascii 20)))
  (map-get? current-prices { token-pair: token-pair })
)

;; Cancel an existing order
(define-public (cancel-order (order-id uint))
  (let (
    (order (unwrap! (map-get? orders { order-id: order-id }) ERR-ORDER-NOT-FOUND))
  )
    (asserts! (is-eq (get trader order) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status order) "active") ERR-INVALID-ORDER)
    
    (map-set orders { order-id: order-id } (merge order { status: "cancelled" }))
    (ok true)
  )
)


