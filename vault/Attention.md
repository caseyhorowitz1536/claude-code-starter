---
title: Attention
tags: [concept, transformer, self-attention, mechanism]
source: Karpathy "Let's build GPT" (YouTube, 2023) — self-attention walkthrough; nanoGPT repo (model.py CausalSelfAttention class)
---

# Attention

> Attention is a learned, input-dependent weighting scheme that lets every position in a sequence gather information from other positions selectively.

## The core idea

Before attention, sequence models had to compress all prior context into a single hidden state — a severe bottleneck. Attention fixes this by letting each token directly query all other tokens and pull in exactly what it needs.

The mechanism works in three steps. Each token produces three vectors: a **query** Q (what am I looking for?), a **key** K (what do I contain?), and a **value** V (what do I emit if selected?). Compatibility between position i and position j is the dot product Q_i · K_j, scaled by 1/√d_k to keep magnitudes stable regardless of dimension size. Those raw scores are passed through a softmax to get a probability distribution (the attention weights), which then weight-sum the values: output = softmax(QK^T / √d_k) · V.

In a decoder (GPT-style) this is **causal** (masked) self-attention: position i can only attend to positions ≤ i. Future tokens are masked to −∞ before the softmax, so they contribute zero weight.

**Multi-head attention** runs h independent attention heads in parallel on lower-dimensional projections, then concatenates and projects back. Different heads learn to attend to different relationship types simultaneously.

## Why it matters / where it fits

Attention is the computational heart of the transformer. Every capability of GPT — in-context learning, long-range coherence, instruction following — traces back to attention's ability to route information dynamically across the sequence. Without it, scale alone cannot save a model.

## Related
- [[Lets Build GPT — Self-Attention]] — the direct code walkthrough Karpathy builds step by step
- [[Residual Stream]] — attention outputs are added into the residual stream
- [[Softmax]] — converts raw attention scores into a proper distribution
- [[Positional Encoding]] — injects position info since attention itself is permutation-invariant
- [[Embeddings]] — Q, K, V projections operate on token embedding vectors

## Source
- Karpathy, "Let's build GPT: from scratch, in code, spelled out" (YouTube 2023), ~1:00–2:30 self-attention section
- nanoGPT `model.py`, `CausalSelfAttention` class: https://github.com/karpathy/nanoGPT
