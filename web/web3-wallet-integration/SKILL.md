---
name: web3-wallet-integration
description: Integrate Ethereum/EVM wallets into a dApp the safe way — connect via WalletConnect, read chain/account state and send transactions with wagmi + viem (React), handle the three signature standards (ECDSA tx, EIP-191 personal_sign, EIP-712 typed data), and defend against the wallet threat model (phishing, unlimited approvals, clipboard address swaps, blind signing). Covers EOAs vs. smart-contract wallets and where ERC-4337 account abstraction fits. Security-first: always show the user exactly what they're signing, scope token approvals, and warn on unknown domains. Use when building wallet connect/sign/send flows, choosing a web3 client library, or reviewing a dApp's signing UX for safety. Triggers include "connect wallet", "WalletConnect", "wagmi viem", "EIP-712 sign", "token approval", "account abstraction ERC-4337", "sign transaction dApp".
---

# Web3 wallet integration — safe connect, sign, send

Wallet UX is a **security surface first**, a feature second: every connect and signature is a chance
to lose the user's funds. Build the happy path with the standard stack, but design around the threat
model from the start.

> ⚠️ **Security note.** The dApp never holds keys — the wallet signs. Your job is to make signing
> *legible*: show exactly what will happen before the user approves, scope approvals to the minimum,
> and never encourage blind signing. Library/bridge security depends on versions — pin and audit.

## Account types

| Type | What it is | Trade-off |
|---|---|---|
| **EOA** (Externally Owned Account) | Controlled by a private key | Simplest, maximal compatibility, no smart features; key loss = funds loss |
| **Smart-contract wallet** | Account *is* a contract | Social recovery, multisig, spending limits, batching — but security depends on the contract implementation |
| **ERC-4337 account abstraction** | Smart accounts without protocol changes, via a separate mempool (UserOperations, bundlers, paymasters) | Gasless / sponsored tx, session keys, better UX — added moving parts (bundler/paymaster trust) |

Support EOAs as the baseline; smart/AA wallets are increasingly common and improve onboarding, but
you inherit their contract-level assumptions.

## The standard stack (React)

- **WalletConnect** — open protocol connecting dApp ↔ wallet over QR / deep link, chain-agnostic.
  The default for mobile and non-injected wallets.
- **wagmi** — React hooks for account/chain state, connection, and sending transactions. Manages the
  reactive plumbing so you don't hand-roll it.
- **viem** — the low-level TypeScript Ethereum client wagmi is built on. Use it directly when you need
  fine control (encoding, custom RPC, simulation). Modern successor to ethers.js-style clients.

Typical shape: **viem** for the transport/primitives, **wagmi** for React state, **WalletConnect**
(often via a connect-kit) for the connector. Reach for viem directly for anything wagmi doesn't wrap.

## Signatures — three kinds, know which you're using

| Standard | Use | UX requirement |
|---|---|---|
| **ECDSA transaction** | On-chain state changes | Show value, target, gas, and what the call does |
| **EIP-191** `personal_sign` | Sign a human-readable string (login / "sign-in with Ethereum") | Display the exact message text |
| **EIP-712** typed structured data | Structured, typed payloads (permits, orders) | **Render the decoded fields** — this is the whole point of 712 |

Always **decode and display** what's being signed. An opaque hash the user can't read is how
phishing drains wallets — "blind signing" is the core danger. Not every wallet fully supports 712;
degrade gracefully but never hide the payload.

## Threat model & defenses

| Attack | Defense |
|---|---|
| **Phishing** — fake site prompts a malicious signature | Verify domain against a whitelist, warn on unknown/lookalike domains, never auto-prompt signing on load |
| **Unlimited (`approve` max) allowances** — compromised contract drains the token later | Request the **exact amount** needed, not `MAX_UINT256`; surface existing allowances; support revoke |
| **Replay** | Rely on nonces / EIP-712 domain separators; never reuse a signed payload across chains |
| **Clipboard / address swap malware** | Show and let the user verify the **full** destination address; consider checksummed display and ENS confirmation |
| **Blind signing** | Human-readable tx preview with cost + asset changes; simulate the tx (viem/`eth_call` or a simulation API) and show the effect before signing |

**Practical rules:**

- Preview every transaction: what it does, what it costs, what assets move — ideally from a
  **simulation**, not just calldata.
- Scope approvals; prefer `Permit2`-style or exact-amount approvals over infinite.
- Warn clearly, in plain language, before any signature; explain the risk, don't just show a hash.
- Keep the connector/bridge and libraries **pinned and updated** — supply-chain and bridge bugs are
  real; verify the WalletConnect project config and RPC endpoints you trust.

## Verify

- **Testnet first** — run connect → sign (191 + 712) → send on a testnet before mainnet.
- Confirm the **signing UI shows decoded content** for each signature type, not a raw hash.
- Confirm approvals request the **intended amount** (inspect the calldata) and that revoke works.
- Simulate a representative transaction and confirm the **displayed effect matches** the on-chain
  result.
- Test **wrong-chain** and **rejected-signature** paths — the unhappy paths are where dApps mislead
  users.

## Honest limits

- Security depends on **implementation and versions** — smart-wallet contracts, the WalletConnect
  bridge, and library releases all carry their own risk; pin and audit, don't assume.
- The ecosystem moves fast: connection protocols, AA tooling (bundlers/paymasters), and best
  practices shift — verify against current wagmi/viem/WalletConnect and EIP docs.
- This skill covers **integration and signing safety**, not smart-contract auditing, key custody
  infrastructure, or MEV/front-running protection — each is its own domain.
- Phishing defense is **defense-in-depth**, never complete — user attention is still a factor; make
  the safe path the easy path.
