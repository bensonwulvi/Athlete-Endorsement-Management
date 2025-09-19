# Athlete Endorsement Management

A blockchain-based system for managing athlete endorsement deals through transparent performance tracking and milestone verification.

## Overview

This project provides smart contracts built on Stacks blockchain using Clarity to create trust between athletes and sponsors through verifiable performance milestones. The system enables transparent tracking of athlete achievements and automated endorsement deal management.

## Features

### Performance Milestone Tracker

The core feature of this system is the Performance Milestone Tracker contract (`performance-milestone-tracker.clar`) that provides:

- **Milestone Creation**: Sponsors can create performance milestones for athletes with specific targets, rewards, and deadlines
- **Achievement Tracking**: Athletes can report milestone completions with proof of achievement
- **Sponsor Verification**: Sponsors can verify and validate completed milestones
- **Performance Analytics**: Comprehensive stats tracking for both athletes and sponsors
- **Transparent History**: Immutable record of all milestone activities on-chain

## Smart Contracts

### performance-milestone-tracker.clar

Main contract handling athlete performance milestone management.

**Key Functions:**

#### Public Functions
- `create-milestone`: Create a new milestone (sponsor)
- `complete-milestone`: Mark milestone as achieved (athlete) 
- `verify-milestone`: Verify milestone completion (sponsor)

#### Read-Only Functions
- `get-milestone`: Retrieve milestone details
- `get-athlete-milestones`: Get all milestones for an athlete
- `get-sponsor-milestones`: Get all sponsored milestones
- `get-athlete-stats`: Calculate athlete performance statistics
- `get-milestone-achievement`: Get achievement details
- `milestone-exists`: Check if milestone exists

### ⭐ athlete-reputation-system.clar

**NEW!** Transparent reputation and rating system enabling sponsors to rate athletes after milestone completion.

**Key Features:**
- 🌟 **Star Ratings**: 1-5 star rating system for athlete performance
- 📊 **Aggregate Reputation**: Real-time calculation of average ratings
- 🏆 **Tier System**: Bronze/Silver/Gold/Platinum reputation tiers
- 📝 **Feedback System**: Optional written feedback with ratings
- 🔒 **Anti-Gaming**: One rating per milestone per sponsor
- 📈 **Analytics**: Historical rating data and trends

#### Public Functions
- `rate-athlete`: Rate an athlete (1-5 stars) with optional feedback

#### Read-Only Functions
- `get-athlete-reputation`: Get aggregate reputation data
- `get-reputation-tier`: Get athlete's reputation tier (Bronze/Silver/Gold/Platinum)
- `get-reputation-summary`: Complete reputation overview with tier
- `get-rating`: Get specific rating details
- `is-milestone-rated`: Check if milestone has been rated
- `meets-reputation-threshold`: Check if athlete meets minimum standards

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet/getting-started) - Stacks smart contract development environment
- Node.js and npm (for running tests)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Athlete-Endorsement-Management
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
npm test
```

### Usage Examples

#### Creating a Milestone

```clarity
(contract-call? .performance-milestone-tracker create-milestone 
  'ST1ATHLETE-ADDRESS
  "Score 25 points in next game"
  u25    ;; target value
  u1000  ;; reward amount
  u1000) ;; deadline block
```

#### Completing a Milestone

```clarity
(contract-call? .performance-milestone-tracker complete-milestone 
  u1     ;; milestone-id
  u27    ;; achieved value
  (some "Scored 27 points in championship game")) ;; notes
```

#### Verifying a Milestone

```clarity
(contract-call? .performance-milestone-tracker verify-milestone u1)
```

#### Rating an Athlete (New! ⭐)

```clarity
(contract-call? .athlete-reputation-system rate-athlete 
  'ST1ATHLETE-ADDRESS
  u1     ;; milestone-id
  u5     ;; rating (1-5 stars)
  (some "Outstanding performance, exceeded expectations!")) ;; feedback
```

#### Checking Athlete Reputation

```clarity
(contract-call? .athlete-reputation-system get-reputation-summary 
  'ST1ATHLETE-ADDRESS)
;; Returns: { total-ratings: u10, average-rating: u425, tier: "Gold", last-updated: u1000 }
```

#### Finding Athletes by Reputation

```clarity
(contract-call? .athlete-reputation-system meets-reputation-threshold 
  'ST1ATHLETE-ADDRESS
  u400   ;; minimum average rating (4.0 stars)
  u5)    ;; minimum number of ratings
;; Returns: true/false
```

## Architecture

### Data Structure

The system uses several maps to efficiently store and retrieve data:

- **milestones**: Core milestone information
- **athlete-milestones**: Athlete-specific milestone tracking
- **sponsor-milestones**: Sponsor-specific milestone tracking  
- **milestone-achievements**: Detailed achievement records

### Security Features

- **Access Control**: Only authorized users can perform specific actions
- **Input Validation**: All inputs are validated before processing
- **Deadline Enforcement**: Milestones cannot be completed after deadline
- **Completion Protection**: Completed milestones cannot be modified

## Development

### Project Structure

```
Athlete-Endorsement-Management/
├── contracts/
│   ├── Endorse.clar                        # Base contract template
│   ├── performance-milestone-tracker.clar  # Milestone tracking contract
│   └── athlete-reputation-system.clar      # ⭐ NEW: Rating & reputation system
├── tests/
│   └── Endorse.test.ts                     # Test suites
├── settings/
│   ├── Devnet.toml                         # Development network config
│   ├── Testnet.toml                        # Testnet configuration
│   └── Mainnet.toml                        # Mainnet configuration  
├── Clarinet.toml                           # Clarinet configuration
└── README.md                               # Project documentation
```

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please open an issue on the repository.
