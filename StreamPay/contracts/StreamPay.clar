;; StreamPay - Seamless. Automated. Predictable.
;; A decentralized subscription payment platform for recurring services
;; Features: Auto-billing, subscription management, payment streaming

;; ===================================
;; CONSTANTS AND ERROR CODES
;; ===================================

(define-constant ERR-NOT-AUTHORIZED (err u30))
(define-constant ERR-SUBSCRIPTION-NOT-FOUND (err u31))
(define-constant ERR-SUBSCRIPTION-INACTIVE (err u32))
(define-constant ERR-INSUFFICIENT-BALANCE (err u33))
(define-constant ERR-PAYMENT-NOT-DUE (err u34))
(define-constant ERR-ALREADY-CANCELLED (err u35))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-PAYMENT-AMOUNT u100000) ;; 0.1 STX minimum
(define-constant MAX-PAYMENT-INTERVAL u4320) ;; ~30 days max interval
(define-constant PLATFORM-FEE u25) ;; 0.25% fee

;; ===================================
;; DATA VARIABLES
;; ===================================

(define-data-var platform-active bool true)
(define-data-var subscription-counter uint u0)
(define-data-var total-payments uint u0)
(define-data-var platform-revenue uint u0)

;; ===================================
;; DATA MAPS
;; ===================================

;; Active subscriptions
(define-map subscriptions
  uint
  {
    subscriber: principal,
    recipient: principal,
    amount: uint,
    interval-blocks: uint,
    next-payment: uint,
    payments-made: uint,
    total-paid: uint,
    active: bool
  }
)

;; User subscription stats
(define-map user-stats
  principal
  {
    active-subscriptions: uint,
    total-subscriptions: uint,
    total-paid: uint,
    total-received: uint
  }
)

;; ===================================
;; PRIVATE HELPER FUNCTIONS
;; ===================================

(define-private (is-contract-owner (user principal))
  (is-eq user CONTRACT-OWNER)
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount PLATFORM-FEE) u10000)
)

(define-private (is-payment-due (subscription-id uint))
  (match (map-get? subscriptions subscription-id)
    sub-data
    (>= burn-block-height (get next-payment sub-data))
    false
  )
)

(define-private (is-subscription-participant (subscription-id uint) (user principal))
  (match (map-get? subscriptions subscription-id)
    sub-data
    (or (is-eq user (get subscriber sub-data)) (is-eq user (get recipient sub-data)))
    false
  )
)

;; ===================================
;; READ-ONLY FUNCTIONS
;; ===================================

(define-read-only (get-platform-info)
  {
    active: (var-get platform-active),
    total-subscriptions: (var-get subscription-counter),
    total-payments: (var-get total-payments),
    platform-revenue: (var-get platform-revenue)
  }
)

(define-read-only (get-subscription (subscription-id uint))
  (map-get? subscriptions subscription-id)
)

(define-read-only (get-user-stats (user principal))
  (map-get? user-stats user)
)

(define-read-only (get-subscription-status (subscription-id uint))
  (match (map-get? subscriptions subscription-id)
    sub-data
    (if (get active sub-data)
      (if (is-payment-due subscription-id)
        (some "payment-due")
        (some "active")
      )
      (some "cancelled")
    )
    none
  )
)

(define-read-only (calculate-next-payment-amount (subscription-id uint))
  (match (map-get? subscriptions subscription-id)
    sub-data
    (let (
      (base-amount (get amount sub-data))
      (platform-fee (calculate-platform-fee base-amount))
    )
      (some (+ base-amount platform-fee))
    )
    none
  )
)

;; ===================================
;; ADMIN FUNCTIONS
;; ===================================

(define-public (toggle-platform (active bool))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (var-set platform-active active)
    (print { action: "platform-toggled", active: active })
    (ok true)
  )
)

(define-public (withdraw-platform-revenue (amount uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (var-get platform-revenue)) ERR-INSUFFICIENT-BALANCE)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (var-set platform-revenue (- (var-get platform-revenue) amount))
    (print { action: "revenue-withdrawn", amount: amount })
    (ok true)
  )
)

;; ===================================
;; SUBSCRIPTION FUNCTIONS
;; ===================================

(define-public (create-subscription
  (recipient principal)
  (amount uint)
  (interval-blocks uint)
)
  (let (
    (subscription-id (+ (var-get subscription-counter) u1))
    (first-payment (+ burn-block-height interval-blocks))
    (subscriber-stats (default-to { active-subscriptions: u0, total-subscriptions: u0, total-paid: u0, total-received: u0 }
                                  (map-get? user-stats tx-sender)))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (>= amount MIN-PAYMENT-AMOUNT) ERR-INSUFFICIENT-BALANCE)
    (asserts! (<= interval-blocks MAX-PAYMENT-INTERVAL) ERR-PAYMENT-NOT-DUE)
    
    ;; Create subscription
    (map-set subscriptions subscription-id {
      subscriber: tx-sender,
      recipient: recipient,
      amount: amount,
      interval-blocks: interval-blocks,
      next-payment: first-payment,
      payments-made: u0,
      total-paid: u0,
      active: true
    })
    
    ;; Update subscriber stats
    (map-set user-stats tx-sender (merge subscriber-stats {
      active-subscriptions: (+ (get active-subscriptions subscriber-stats) u1),
      total-subscriptions: (+ (get total-subscriptions subscriber-stats) u1)
    }))
    
    ;; Update counter
    (var-set subscription-counter subscription-id)
    
    (print { action: "subscription-created", subscription-id: subscription-id, subscriber: tx-sender, recipient: recipient, amount: amount })
    (ok subscription-id)
  )
)

(define-public (process-payment (subscription-id uint))
  (let (
    (sub-data (unwrap! (map-get? subscriptions subscription-id) ERR-SUBSCRIPTION-NOT-FOUND))
    (payment-amount (get amount sub-data))
    (platform-fee (calculate-platform-fee payment-amount))
    (recipient-amount (- payment-amount platform-fee))
    (subscriber-stats (default-to { active-subscriptions: u0, total-subscriptions: u0, total-paid: u0, total-received: u0 }
                                  (map-get? user-stats (get subscriber sub-data))))
    (recipient-stats (default-to { active-subscriptions: u0, total-subscriptions: u0, total-paid: u0, total-received: u0 }
                                 (map-get? user-stats (get recipient sub-data))))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (get active sub-data) ERR-SUBSCRIPTION-INACTIVE)
    (asserts! (is-payment-due subscription-id) ERR-PAYMENT-NOT-DUE)
    
    ;; Transfer payment from subscriber to recipient
    (try! (stx-transfer? recipient-amount (get subscriber sub-data) (get recipient sub-data)))
    
    ;; Transfer platform fee
    (try! (stx-transfer? platform-fee (get subscriber sub-data) (as-contract tx-sender)))
    
    ;; Update subscription
    (map-set subscriptions subscription-id (merge sub-data {
      next-payment: (+ burn-block-height (get interval-blocks sub-data)),
      payments-made: (+ (get payments-made sub-data) u1),
      total-paid: (+ (get total-paid sub-data) payment-amount)
    }))
    
    ;; Update user stats
    (map-set user-stats (get subscriber sub-data) (merge subscriber-stats {
      total-paid: (+ (get total-paid subscriber-stats) payment-amount)
    }))
    
    (map-set user-stats (get recipient sub-data) (merge recipient-stats {
      total-received: (+ (get total-received recipient-stats) recipient-amount)
    }))
    
    ;; Update global stats
    (var-set total-payments (+ (var-get total-payments) u1))
    (var-set platform-revenue (+ (var-get platform-revenue) platform-fee))
    
    (print { action: "payment-processed", subscription-id: subscription-id, amount: payment-amount, fee: platform-fee })
    (ok true)
  )
)

(define-public (cancel-subscription (subscription-id uint))
  (let (
    (sub-data (unwrap! (map-get? subscriptions subscription-id) ERR-SUBSCRIPTION-NOT-FOUND))
    (subscriber-stats (default-to { active-subscriptions: u0, total-subscriptions: u0, total-paid: u0, total-received: u0 }
                                  (map-get? user-stats tx-sender)))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (is-subscription-participant subscription-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get active sub-data) ERR-ALREADY-CANCELLED)
    
    ;; Mark subscription as inactive
    (map-set subscriptions subscription-id (merge sub-data { active: false }))
    
    ;; Update subscriber stats if cancelled by subscriber
    (if (is-eq tx-sender (get subscriber sub-data))
      (map-set user-stats tx-sender (merge subscriber-stats {
        active-subscriptions: (- (get active-subscriptions subscriber-stats) u1)
      }))
      true
    )
    
    (print { action: "subscription-cancelled", subscription-id: subscription-id, cancelled-by: tx-sender })
    (ok true)
  )
)

(define-public (update-subscription-amount (subscription-id uint) (new-amount uint))
  (let (
    (sub-data (unwrap! (map-get? subscriptions subscription-id) ERR-SUBSCRIPTION-NOT-FOUND))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq tx-sender (get subscriber sub-data)) ERR-NOT-AUTHORIZED)
    (asserts! (get active sub-data) ERR-SUBSCRIPTION-INACTIVE)
    (asserts! (>= new-amount MIN-PAYMENT-AMOUNT) ERR-INSUFFICIENT-BALANCE)
    
    ;; Update subscription amount
    (map-set subscriptions subscription-id (merge sub-data { amount: new-amount }))
    
    (print { action: "subscription-updated", subscription-id: subscription-id, new-amount: new-amount })
    (ok true)
  )
)

;; ===================================
;; INITIALIZATION
;; ===================================

(begin
  (print { action: "streampay-initialized", owner: CONTRACT-OWNER })
)