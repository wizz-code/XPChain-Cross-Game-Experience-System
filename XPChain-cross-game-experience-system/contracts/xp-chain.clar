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

  (define-public (register-game
  (game-title (string-ascii 50))
  (game-category (string-ascii 30))
  (xp-multiplier uint))
  (let 
    ((game-id (var-get next-game-id))
     (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1)))))
    (begin
      (asserts! (not (var-get platform-paused)) err-unauthorized)
      (asserts! (and (> xp-multiplier u0) (<= xp-multiplier u500)) err-invalid-parameters)
      (map-set registered-games { game-id: game-id }
        {
          game-title: game-title,
          developer: tx-sender,
          game-category: game-category,
          xp-multiplier: xp-multiplier,
          is-verified: false,
          registration-date: current-time,
          total-players: u0
        })
      (var-set next-game-id (+ game-id u1))
      (ok game-id))))

(define-public (verify-game (game-id uint))
  (let ((game-info (unwrap! (map-get? registered-games { game-id: game-id }) err-game-not-registered)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (map-set registered-games { game-id: game-id }
        (merge game-info { is-verified: true }))
      (ok true))))

(define-public (mint-xp-nft (player principal) (game-id uint) (initial-xp uint))
  (let 
    ((game-info (unwrap! (map-get? registered-games { game-id: game-id }) err-game-not-registered))
     (nft-id (var-get next-xp-nft-id))
     (adjusted-xp (* initial-xp (get xp-multiplier game-info)))
     (calculated-level (/ adjusted-xp u100))
     (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
     (milestone-tier (calculate-milestone-tier adjusted-xp)))
    (begin
      (asserts! (not (var-get platform-paused)) err-unauthorized)
      (asserts! (is-eq tx-sender (get developer game-info)) err-unauthorized)
      (asserts! (get is-verified game-info) err-game-not-registered)
      (asserts! (> initial-xp u0) err-invalid-xp-amount)
      
      (try! (nft-mint? xp-nft nft-id player))
      
      (map-set xp-nfts { nft-id: nft-id }
        {
          player: player,
          game-id: game-id,
          total-xp: adjusted-xp,
          level: calculated-level,
          achievements-unlocked: u0,
          last-updated: current-time,
          milestone-tier: milestone-tier
        })
      
      (map-set player-game-progress { player: player, game-id: game-id }
        { nft-id: nft-id, current-xp: adjusted-xp, session-count: u1 })
      
      ;; Update cross-game stats
      (let ((player-stats (default-to 
                           { total-games-played: u0, total-xp-earned: u0, highest-level: u0, global-rank: u0, total-achievements: u0 }
                           (map-get? cross-game-stats { player: player }))))
        (map-set cross-game-stats { player: player }
          {
            total-games-played: (+ (get total-games-played player-stats) u1),
            total-xp-earned: (+ (get total-xp-earned player-stats) adjusted-xp),
            highest-level: (if (> calculated-level (get highest-level player-stats)) calculated-level (get highest-level player-stats)),
            global-rank: u0,
            total-achievements: (get total-achievements player-stats)
          }))
      
      (var-set next-xp-nft-id (+ nft-id u1))
      (ok nft-id))))

(define-public (update-xp (nft-id uint) (additional-xp uint) (achievements-gained uint))
  (let 
    ((nft-info (unwrap! (map-get? xp-nfts { nft-id: nft-id }) err-nft-not-found))
     (game-info (unwrap! (map-get? registered-games { game-id: (get game-id nft-info) }) err-game-not-registered))
     (adjusted-xp (* additional-xp (get xp-multiplier game-info)))
     (new-total-xp (+ (get total-xp nft-info) adjusted-xp))
     (new-level (/ new-total-xp u100))
     (new-milestone-tier (calculate-milestone-tier new-total-xp))
     (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1)))))
    (begin
      (asserts! (not (var-get platform-paused)) err-unauthorized)
      (asserts! (is-eq tx-sender (get developer game-info)) err-unauthorized)
      (asserts! (> additional-xp u0) err-invalid-xp-amount)
      
      (map-set xp-nfts { nft-id: nft-id }
        (merge nft-info {
          total-xp: new-total-xp,
          level: new-level,
          achievements-unlocked: (+ (get achievements-unlocked nft-info) achievements-gained),
          last-updated: current-time,
          milestone-tier: new-milestone-tier
        }))
      
      ;; Update player progress
      (let ((progress-info (unwrap-panic (map-get? player-game-progress { player: (get player nft-info), game-id: (get game-id nft-info) }))))
        (map-set player-game-progress { player: (get player nft-info), game-id: (get game-id nft-info) }
          (merge progress-info {
            current-xp: new-total-xp,
            session-count: (+ (get session-count progress-info) u1)
          })))
      
      ;; Update cross-game stats
      (let ((player-stats (unwrap-panic (map-get? cross-game-stats { player: (get player nft-info) }))))
        (map-set cross-game-stats { player: (get player nft-info) }
          (merge player-stats {
            total-xp-earned: (+ (get total-xp-earned player-stats) adjusted-xp),
            highest-level: (if (> new-level (get highest-level player-stats)) new-level (get highest-level player-stats)),
            total-achievements: (+ (get total-achievements player-stats) achievements-gained)
          })))
      
      (ok new-total-xp))))

(define-public (create-season 
  (season-name (string-ascii 30))
  (start-time uint)
  (end-time uint)
  (prize-pool uint))
  (let ((season-id (var-get next-season-id)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (asserts! (> end-time start-time) err-invalid-parameters)
      (asserts! (> prize-pool u0) err-invalid-parameters)
      
      (map-set seasons { season-id: season-id }
        {
          season-name: season-name,
          start-time: start-time,
          end-time: end-time,
          is-active: true,
          total-participants: u0,
          prize-pool: prize-pool
        })
      
      (var-set next-season-id (+ season-id u1))
      (ok season-id))))

(define-public (claim-daily-reward (day uint))
  (let 
    ((current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
     (daily-key { player: tx-sender, day: day })
     (player-stats (unwrap! (map-get? cross-game-stats { player: tx-sender }) err-unauthorized))
     (reward-amount (calculate-daily-reward (get total-xp-earned player-stats))))
    (begin
      (asserts! (not (var-get platform-paused)) err-unauthorized)
      (asserts! (is-none (map-get? daily-rewards-claimed daily-key)) err-already-claimed)
      (asserts! (>= (get total-xp-earned player-stats) u100) err-insufficient-xp)
      
      (map-set daily-rewards-claimed daily-key
        { claimed: true, reward-amount: reward-amount })
      
      (ok reward-amount))))

(define-public (add-referral-bonus (referrer principal) (referred-player principal) (bonus-xp uint))
  (let 
    ((referral-info (default-to { total-referrals: u0, bonus-xp-earned: u0 }
                                 (map-get? player-referrals { referrer: referrer }))))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (asserts! (> bonus-xp u0) err-invalid-xp-amount)
      
      (map-set player-referrals { referrer: referrer }
        {
          total-referrals: (+ (get total-referrals referral-info) u1),
          bonus-xp-earned: (+ (get bonus-xp-earned referral-info) bonus-xp)
        })
      
      (ok true))))

(define-public (create-tournament 
  (game-id uint)
  (tournament-name (string-ascii 40))
  (entry-fee uint)
  (max-participants uint)
  (start-time uint)
  (end-time uint))
  (let 
    ((game-info (unwrap! (map-get? registered-games { game-id: game-id }) err-game-not-registered))
     (tournament-id u1))
    (begin
      (asserts! (is-eq tx-sender (get developer game-info)) err-unauthorized)
      (asserts! (> max-participants u0) err-invalid-parameters)
      (asserts! (> end-time start-time) err-invalid-parameters)
      
      (map-set game-tournaments { game-id: game-id, tournament-id: tournament-id }
        {
          tournament-name: tournament-name,
          entry-fee: entry-fee,
          prize-pool: u0,
          max-participants: max-participants,
          current-participants: u0,
          start-time: start-time,
          end-time: end-time,
          is-active: true
        })
      
      (ok tournament-id))))

(define-public (transfer-xp-nft (nft-id uint) (recipient principal))
  (let ((nft-info (unwrap! (map-get? xp-nfts { nft-id: nft-id }) err-nft-not-found)))
    (begin
      (asserts! (not (var-get platform-paused)) err-unauthorized)
      (asserts! (is-eq tx-sender (get player nft-info)) err-unauthorized)
      (try! (nft-transfer? xp-nft nft-id tx-sender recipient))
      
      (map-set xp-nfts { nft-id: nft-id }
        (merge nft-info { player: recipient }))
      
      (ok true))))

(define-public (burn-xp-nft (nft-id uint))
  (let ((nft-info (unwrap! (map-get? xp-nfts { nft-id: nft-id }) err-nft-not-found)))
    (begin
      (asserts! (not (var-get platform-paused)) err-unauthorized)
      (asserts! (is-eq tx-sender (get player nft-info)) err-unauthorized)
      (try! (nft-burn? xp-nft nft-id tx-sender))
      
      (map-delete xp-nfts { nft-id: nft-id })
      (map-delete player-game-progress { player: tx-sender, game-id: (get game-id nft-info) })
      
      (ok true))))

(define-public (set-platform-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-paused paused)
    (ok paused)))

(define-public (update-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u1000) err-invalid-parameters) ;; Max 10%
    (var-set contract-fee-rate new-rate)
    (ok new-rate)))

(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (var-get total-contract-fees)) err-insufficient-xp)
    (var-set total-contract-fees (- (var-get total-contract-fees) amount))
    (ok amount)))

(define-private (calculate-milestone-tier (xp-amount uint))
  (if (>= xp-amount u50000) "platinum"
    (if (>= xp-amount u15000) "gold"
      (if (>= xp-amount u5000) "silver" "bronze"))))

(define-private (calculate-daily-reward (total-xp uint))
  (let ((base-reward u10))
    (if (>= total-xp u50000) (* base-reward u5)
      (if (>= total-xp u15000) (* base-reward u3)
        (if (>= total-xp u5000) (* base-reward u2) base-reward)))))