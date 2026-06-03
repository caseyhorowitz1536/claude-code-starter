---
title: LayerNorm
tags: [#concept, #normalization, #transformer, #training-stability]
source: Karpathy "Let's build GPT from scratch" (nanoGPT walkthrough) — LayerNorm placement discussion; also covered in makemore MLP context for BatchNorm contrast
---

# LayerNorm

> Layer Normalization re-centers and re-scales each token's feature vector independently, so activations stay well-conditioned throughout training.

## The core idea

LayerNorm normalizes across the *feature* dimension of a single sample rather than across the *batch* dimension. For a vector **x** of length d, it computes:

`y = γ · (x − μ) / (σ + ε) + β`

where μ and σ are the mean and standard deviation of **x** itself, ε is a tiny stability constant, and γ / β are learned scale and bias parameters (same shape as x).

Because each token is normalized using only its own values, LayerNorm has no dependency on batch size or on what other samples are in the batch. This makes it far easier to reason about and stable at batch size 1 — something BatchNorm cannot offer.

In nanoGPT, Karpathy places LayerNorm *before* the self-attention and MLP sub-layers (the "Pre-LN" or "Pre-Norm" arrangement). This differs from the original "Attention Is All You Need" paper, which placed it after. Pre-LN empirically trains more stably, especially at depth, because gradients flow through the residual stream without passing through a normalization bottleneck on the way back.

The learned γ (gain) starts at 1 and β (bias) starts at 0, so early in training LayerNorm is nearly an identity — it doesn't interfere with initialization strategies.

## Why it matters / where it fits

Every transformer block in GPT-style models runs two LayerNorms per layer — one before attention, one before the MLP. Without them, deep residual networks suffer exploding or vanishing activations. LayerNorm is the normalization primitive that makes GPT training tractable.

## Related
- [[BatchNorm and Initialization]] — BatchNorm normalizes over the batch; LayerNorm normalizes over features; understanding both clarifies why transformers use LayerNorm
- [[Residual Stream]] — Pre-LN sits at the entry of each residual branch, protecting gradient flow through the stream
- [[Lets Build GPT — Self-Attention]] — the nanoGPT build where Karpathy adds and explains LayerNorm placement
- [[Activations and Gradients]] — LayerNorm directly tames the activation statistics that drive vanishing/exploding gradient problems

## Source
- Karpathy, "Let's build GPT from scratch" (YouTube, 2023) — LayerNorm cell in nanoGPT, Pre-LN vs Post-LN discussion
- nanoGPT repo (`model.py`) — `nn.LayerNorm` applied before each sub-layer in `Block`
