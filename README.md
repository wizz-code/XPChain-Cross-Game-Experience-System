# XPChain Cross-Game Experience System

A blockchain-based experience point system that tracks player progress across multiple gaming titles using transferable NFTs, enabling universal gaming achievement recognition.

## Features

- **Cross-Game XP**: Universal experience points that work across multiple games
- **NFT-Based Progress**: Each game progress is a unique, transferable NFT
- **Milestone Tiers**: Bronze, Silver, Gold, and Platinum achievement levels  
- **Developer Integration**: Easy API for game developers to award XP
- **Global Rankings**: Cross-game player statistics and leaderboards
- **Achievement Tracking**: Comprehensive achievement unlock system

## Milestone Tiers

| Tier | Min XP | Level Threshold | Rewards Multiplier |
|------|--------|-----------------|-------------------|
| Bronze | 1,000 | Level 10 | 100% |
| Silver | 5,000 | Level 25 | 150% |
| Gold | 15,000 | Level 50 | 200% |
| Platinum | 50,000 | Level 100 | 300% |

## Smart Contract Functions

### Public Functions
- `register-game`: Register new game title for XP integration
- `verify-game`: Admin verification of registered games (owner only)
- `mint-xp-nft`: Create XP NFT for player's game progress
- `update-xp`: Add experience points and achievements to existing NFT

### Read-Only Functions
- `get-xp-nft-info`: Retrieve detailed NFT progress information
- `get-game-info`: Get registered game details and statistics
- `get-player-progress`: Check player's progress in specific game
- `get-cross-game-stats`: View player's overall gaming statistics
- `get-milestone-info`: Get tier requirements and multipliers
- `get-nft-owner`: Find current owner of XP NFT

## Game Categories

- **MMORPG**: Massive multiplayer online role-playing games
- **FPS**: First-person shooter games
- **Strategy**: Real-time and turn-based strategy games
- **Racing**: Racing and driving simulation games
- **Sports**: Sports simulation and competitive games
- **Puzzle**: Puzzle and brain-training games

## Use Cases

### For Players
- **Universal Progress**: XP earned in one game contributes to overall profile
- **Achievement Recognition**: Cross-game achievement showcasing
- **NFT Trading**: Transfer or sell game progress to other players
- **Skill Validation**: Blockchain-verified gaming accomplishments
- **Community Status**: Global ranking based on combined game performance

### For Developers
- **Player Retention**: Incentivize continued play with persistent XP
- **Cross-Promotion**: Players discover new games through XP system
- **Analytics**: Track player engagement across gaming ecosystem
- **Monetization**: Revenue sharing from XP NFT trading
- **Community Building**: Connect players across multiple titles

## Benefits

- **Persistence**: Gaming achievements persist beyond individual games
- **Interoperability**: Universal system works across any integrated game
- **Ownership**: Players truly own their gaming progress as NFTs
- **Transparency**: All XP and achievements verifiable on blockchain
- **Transferability**: Trade gaming progress and achievements

## Integration Example

```clarity
;; Award XP to player
(contract-call? .xp-chain update-xp nft-id additional-xp achievements-count)

;; Check player's milestone tier
(contract-call? .xp-chain get-xp-nft-info nft-id)