---
title: Softmax
tags: [#concept, #activation, #probability, #attention]
source: Neural Networks Zero to Hero — "makemore" series (MLP lecture); "Let's build GPT" (attention softmax); nanoGPT source
---

# Softmax

> Softmax converts a vector of arbitrary real numbers (logits) into a valid probability distribution that sums to 1.

## The core idea

Given logits `z = [z₁, z₂, ..., zₙ]`, softmax produces:

`softmax(zᵢ) = exp(zᵢ) / Σⱼ exp(zⱼ)`

Each element gets exponentiated — this enforces positivity — then everything is normalized by the total so the outputs sum to exactly 1. The result is interpretable as a probability distribution over `n` classes or tokens.

The exponential is not arbitrary. It amplifies differences: a logit that is 2 units larger than another will have `e² ≈ 7×` higher probability weight. This "winner-take-more" effect is central to how the model assigns confident predictions.

Temperature (a scalar `T`) modulates sharpness: `softmax(zᵢ / T)`. Low `T` → near-one-hot (confident). High `T` → flat/uniform (exploratory). Karpathy demonstrates this in the sampling sections of makemore and nanoGPT.

In the attention mechanism, softmax is applied to scaled dot-product scores — `softmax(QKᵀ / √dₖ)` — to produce attention weights over value vectors. The `/ √dₖ` prevents extremely large logits from making softmax saturate and killing gradients.

## Why it matters / where it fits

Softmax is the bridge between raw model output and interpretable probabilities. It appears at two critical points in a transformer: at the final output head (next-token prediction) and inside every attention layer (routing information across the sequence). Without it, logits cannot be turned into a training loss via cross-entropy, and attention weights cannot be normalized.

## Related

- [[Cross-Entropy Loss]] — softmax outputs feed directly into cross-entropy loss during training
- [[Temperature and Top-k]] — temperature rescales logits before softmax to control generation sharpness
- [[Attention]] — scaled dot-product attention uses softmax to normalize score matrices
- [[Activations and Gradients]] — softmax saturation causes vanishing gradients; key initialization concern
- [[Makemore — MLP]] — Karpathy first introduces softmax explicitly in the MLP character-level model

## Source

- Andrej Karpathy, *Neural Networks: Zero to Hero* — makemore MLP lecture (softmax + cross-entropy walkthrough); "Let's build GPT" (attention softmax, temperature sampling); nanoGPT `model.py` (`F.softmax` in attention and output head)
