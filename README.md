# 💰 StreamPay - Seamless. Automated. Predictable.

A decentralized subscription payment platform built on Stacks blockchain that enables automated recurring payments for services and memberships.

## 📋 Overview

StreamPay simplifies recurring payments by automating subscription billing between users. Service providers can set up predictable revenue streams while subscribers enjoy seamless automatic payments for their favorite services.

## ✨ Key Features

### 🔄 Automated Subscriptions
- Create recurring payment schedules (up to 30 days intervals)
- Automatic payment processing when due
- Flexible payment amounts (minimum 0.1 STX)
- Real-time subscription status tracking

### 💳 Payment Streaming
- Set-and-forget payment automation
- Transparent fee structure (0.25% platform fee)
- Direct peer-to-peer payments
- Payment history and analytics

### 📊 Subscription Management
- Update subscription amounts anytime
- Cancel subscriptions by either party
- Track total payments and statistics
- User-friendly status indicators

### 🎯 Simple Experience
- One-click subscription creation
- Automatic payment notifications
- Clear payment due indicators
- Comprehensive user dashboards

## 🏗️ Architecture

### Core Components
```clarity
subscriptions -> Active recurring payment schedules
user-stats    -> Payment history and statistics
```

### Payment Flow
1. **Create**: Subscriber sets up recurring payment
2. **Schedule**: Next payment automatically calculated
3. **Process**: Anyone can trigger due payments
4. **Repeat**: Cycle continues until cancelled

## 🚀 Getting Started

### For Service Providers

1. **Receive Subscriptions**: Users create subscriptions to pay you
2. **Monitor Payments**: Track incoming recurring revenue
3. **Process Payments**: Trigger payment processing when due

### For Subscribers

1. **Create Subscription**: Set up recurring payments
   ```clarity
   (create-subscription recipient amount interval-blocks)
   ```

2. **Monitor Status**: Track payment schedules and history
3. **Update/Cancel**: Modify or stop subscriptions anytime
   ```clarity
   (update-subscription-amount subscription-id new-amount)
   (cancel-subscription subscription-id)
   ```

## 📈 Example Scenarios

### Monthly Service Subscription
```
1. Alice subscribes to Bob's newsletter: 5 STX every 30 days
2. Payment automatically processes every month
3. Bob receives 4.9875 STX (5 STX - 0.25% fee)
4. Continues until Alice or Bob cancels
```

### Flexible Payment Updates
```
1. Charlie creates 10 STX weekly subscription to Dave's service
2. After 3 payments, Charlie updates to 15 STX weekly
3. Next payment processes 15 STX instead of 10 STX
4. Payment history tracks both amounts
```

### Subscription Cancellation
```
1. Eve subscribes to Frank's premium service: 20 STX bi-weekly
2. After 2 months, Eve cancels subscription
3. No further payments are processed
4. Frank can see final payment statistics
```

## ⚙️ Configuration

### Payment Parameters
- **Minimum Amount**: 0.1 STX per payment
- **Maximum Interval**: 30 days between payments
- **Platform Fee**: 0.25% of each payment
- **Processing**: Anyone can trigger due payments

### Subscription States
- **Active**: Subscription running, payments processing
- **Payment Due**: Next payment is ready to process
- **Cancelled**: Subscription stopped by either party

## 🔒 Security Features

### Access Control
- Only subscribers can create/update their subscriptions
- Both parties (subscriber/recipient) can cancel
- Payment processing open to any user (incentivized)

### Payment Protection
- Payments only process when actually due
- Automatic fee calculation and distribution
- Clear payment history and audit trail

### Error Handling
```clarity
ERR-NOT-AUTHORIZED (u30)        -> Insufficient permissions
ERR-SUBSCRIPTION-NOT-FOUND (u31) -> Invalid subscription ID
ERR-SUBSCRIPTION-INACTIVE (u32)  -> Subscription already cancelled
ERR-INSUFFICIENT-BALANCE (u33)   -> Invalid amount parameters
ERR-PAYMENT-NOT-DUE (u34)       -> Payment not ready to process
ERR-ALREADY-CANCELLED (u35)     -> Subscription already inactive
```

## 📊 Analytics

### Platform Metrics
- Total subscriptions created
- Total payments processed
- Platform revenue collected
- System activity status

### User Statistics
- Active and total subscriptions
- Total amounts paid and received
- Payment history per user
- Subscription performance metrics

### Subscription Details
- Payment schedules and amounts
- Next payment due dates
- Total payments made per subscription
- Cancellation and update history

## 🛠️ Development

### Prerequisites
- Clarinet CLI installed
- STX tokens for payments
- Stacks blockchain access

### Local Testing
```bash
# Validate contract
clarinet check

# Run comprehensive tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

### Integration Examples
```clarity
;; Create monthly subscription
(contract-call? .streampay create-subscription
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  u5000000
  u4320)

;; Process due payment
(contract-call? .streampay process-payment u1)

;; Update subscription amount
(contract-call? .streampay update-subscription-amount u1 u7500000)

;; Cancel subscription
(contract-call? .streampay cancel-subscription u1)

;; Check subscription status
(contract-call? .streampay get-subscription-status u1)
```

## 🎯 Use Cases

### Content Creators
- Newsletter subscriptions
- Premium content access
- Exclusive community memberships
- Educational course access

### Service Providers
- SaaS application billing
- Professional service retainers
- Maintenance and support contracts
- Recurring consultation fees

### Community Applications
- DAO membership dues
- Community pool contributions
- Shared resource funding
- Collective investment plans

## 📋 Quick Reference

### Core Functions
```clarity
;; Subscription Management
create-subscription(recipient, amount, interval) -> subscription-id
update-subscription-amount(subscription-id, new-amount) -> success
cancel-subscription(subscription-id) -> success

;; Payment Processing
process-payment(subscription-id) -> success

;; Information Queries
get-subscription(subscription-id) -> subscription-data
get-subscription-status(subscription-id) -> status
get-user-stats(user) -> statistics
calculate-next-payment-amount(subscription-id) -> amount
```

## 🚦 Deployment Guide

1. Deploy contract to target network
2. Configure platform parameters
3. Test with small subscription amounts
4. Launch with service provider onboarding
5. Monitor payment processing and user adoption

## 🤝 Contributing

StreamPay welcomes community contributions:
- Payment processing optimizations
- User experience improvements
- Security enhancements
- Documentation updates

---

**⚠️ Disclaimer**: StreamPay is subscription payment software for recurring transactions. Ensure sufficient balance for automatic payments and understand cancellation policies before subscribing.
