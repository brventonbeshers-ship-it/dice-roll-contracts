;; dice-roll-v2
;; Core game contract for the Dice Roll dApp on Stacks

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_INVALID_BET (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_NOT_AUTHORIZED (err u102))
(define-constant ERR_GAME_PAUSED (err u103))
(define-constant MIN_BET u1000)
(define-constant MAX_BET u10000000)
(define-constant SIDES u6)

;; Data variables
(define-data-var total-rolls uint u0)
(define-data-var total-wins uint u0)
(define-data-var game-paused bool false)

;; Data maps
(define-map user-stats principal
  {
    rolls: uint,
    wins: uint,
    last-roll: uint,
    last-result: uint,
  }
)

;; Read-only functions
(define-read-only (get-total-rolls)
  (ok (var-get total-rolls))
)

(define-read-only (get-total-wins)
  (ok (var-get total-wins))
)

(define-read-only (get-user-stats (user principal))
  (ok (default-to
    { rolls: u0, wins: u0, last-roll: u0, last-result: u0 }
    (map-get? user-stats user)
  ))
)

(define-read-only (is-game-active)
  (ok (not (var-get game-paused)))
)

;; Private functions
(define-private (generate-roll (seed uint))
  (let (
    (block-hash (unwrap-panic (get-block-info? id-header-hash (- block-height u1))))
    (hash-val (keccak256 (concat block-hash (unwrap-panic (to-consensus-buff? seed)))))
    (roll (+ (mod (buff-to-uint-be (unwrap-panic (slice? hash-val u0 u16))) SIDES) u1))
  )
    roll
  )
)

;; Public functions
(define-public (roll-dice (guess uint))
  (let (
    (roller tx-sender)
    (current-stats (default-to
      { rolls: u0, wins: u0, last-roll: u0, last-result: u0 }
      (map-get? user-stats roller)
    ))
    (result (generate-roll (get rolls current-stats)))
    (is-win (is-eq guess result))
  )
    (asserts! (not (var-get game-paused)) ERR_GAME_PAUSED)
    (asserts! (and (>= guess u1) (<= guess SIDES)) ERR_INVALID_BET)

    (var-set total-rolls (+ (var-get total-rolls) u1))

    (if is-win
      (var-set total-wins (+ (var-get total-wins) u1))
      false
    )

    (map-set user-stats roller {
      rolls: (+ (get rolls current-stats) u1),
      wins: (+ (get wins current-stats) (if is-win u1 u0)),
      last-roll: block-height,
      last-result: result,
    })

    (ok { result: result, win: is-win })
  )
)

;; Admin functions
(define-public (set-game-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set game-paused paused)
    (ok true)
  )
)
