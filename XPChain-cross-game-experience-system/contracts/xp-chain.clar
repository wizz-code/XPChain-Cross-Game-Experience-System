;; XPChain - Cross-Game Experience Point NFT System
;; Tracks player progress across multiple gaming titles

(define-non-fungible-token xp-nft uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-game-not-registered (err u101))
(define-constant err-invalid-xp-amount (err u102))
(define-constant err-nft-not-found (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-already-claimed (err u105))
(define-constant err-insufficient-xp (err u106))
(define-constant err-transfer-failed (err u107))
(define-constant err-invalid-parameters (err u108))
(define-constant err-season-not-active (err u109))
(define-constant err-leaderboard-not-found (err u110))

(define-data-var next-xp-nft-id uint u1)
(define-data-var next-game-id uint u1)
(define-data-var next-season-id uint u1)
(define-data-var contract-fee-rate uint u250) ;; 2.5% fee in basis points
(define-data-var total-contract-fees uint u0)
(define-data-var platform-paused bool false)