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

(define-map registered-games
  { game-id: uint }
  {
    game-title: (string-ascii 50),
    developer: principal,
    game-category: (string-ascii 30),
    xp-multiplier: uint,
    is-verified: bool,
    registration-date: uint,
    total-players: uint
  })

(define-map xp-nfts
  { nft-id: uint }
  {
    player: principal,
    game-id: uint,
    total-xp: uint,
    level: uint,
    achievements-unlocked: uint,
    last-updated: uint,
    milestone-tier: (string-ascii 20)
  })

(define-map player-game-progress
  { player: principal, game-id: uint }
  { nft-id: uint, current-xp: uint, session-count: uint })

(define-map cross-game-stats
  { player: principal }
  {
    total-games-played: uint,
    total-xp-earned: uint,
    highest-level: uint,
    global-rank: uint,
    total-achievements: uint
  })

(define-map xp-milestones
  { tier: (string-ascii 20) }
  { min-xp: uint, level-threshold: uint, rewards-multiplier: uint })

(define-map seasons
  { season-id: uint }
  {
    season-name: (string-ascii 30),
    start-time: uint,
    end-time: uint,
    is-active: bool,
    total-participants: uint,
    prize-pool: uint
  })

(define-map season-leaderboards
  { season-id: uint, rank: uint }
  { player: principal, total-season-xp: uint, games-participated: uint })

(define-map daily-rewards-claimed
  { player: principal, day: uint }
  { claimed: bool, reward-amount: uint })

(define-map player-referrals
  { referrer: principal }
  { total-referrals: uint, bonus-xp-earned: uint })

(define-map game-tournaments
  { game-id: uint, tournament-id: uint }
  {
    tournament-name: (string-ascii 40),
    entry-fee: uint,
    prize-pool: uint,
    max-participants: uint,
    current-participants: uint,
    start-time: uint,
    end-time: uint,
    is-active: bool
  })

;; Initialize XP milestones
(map-set xp-milestones { tier: "bronze" } 
  { min-xp: u1000, level-threshold: u10, rewards-multiplier: u100 })
(map-set xp-milestones { tier: "silver" } 
  { min-xp: u5000, level-threshold: u25, rewards-multiplier: u150 })
(map-set xp-milestones { tier: "gold" } 
  { min-xp: u15000, level-threshold: u50, rewards-multiplier: u200 })
(map-set xp-milestones { tier: "platinum" } 
  { min-xp: u50000, level-threshold: u100, rewards-multiplier: u300 })