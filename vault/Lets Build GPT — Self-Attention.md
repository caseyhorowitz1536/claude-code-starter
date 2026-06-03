---
title: Lets Build GPT — Self-Attention
tags: [zero-to-hero, transformers, attention, self-attention, gpt]
source: Karpathy "Let's build GPT: from scratch, in code, spelled out" (YouTube 2023) — self-attention block walkthrough
---

# Lets Build GPT — Self-Attention

> Self-attention lets every token in a sequence gather information from other tokens via learned, data-dependent weights.

## The core idea

In a standard language model each token needs context from the past. A naive approach averages all previous token embeddings equally — but equal weighting ignores which tokens are actually relevant. Self-attention replaces the equal average with a *learned* weighted average.

For each token position, three vectors are derived from its embedding: a **Query** (q, "what am I looking for?"), a **Key** (k, "what do I advertise?"), and a **Value** (v, "what do I actually send?"). The attention weight between position i and j is the dot product q_i · k_j, scaled by 1/√d_k to prevent softmax saturation, then masked so future positions score −∞ (decoder-style causal mask). Softmax converts those scores into a probability distribution; values are then aggregated: `out = softmax(QK^T / √d_k) V`.

Multiple attention heads run in parallel, each learning different relational patterns (syntax, coreference, proximity), then their outputs are concatenated and projected — this is **multi-head attention**.

In the nanoGPT build Karpathy implements a single `Head` class first, then wraps it in `MultiHeadAttention`. The causal mask is registered as a buffer (`tril`) so no future token can influence the present one during training.

## Why it matters / where it fits

Self-attention is the engine of every transformer. It replaces recurrence (RNNs) with a fully parallelizable operation, enabling training on massive corpora. Understanding it is the prerequisite to reading any modern LLM architecture paper.

## Related
- [[Attention]] — mathematical generalization of the mechanism
- [[Residual Stream]] — self-attention writes into the residual stream
- [[Positional Encoding]] — required because self-attention is position-agnostic
- [[Softmax]] — converts raw dot-product scores to weights

## Source
- Karpathy, "Let's build GPT: from scratch, in code, spelled out," YouTube (Jan 2023), ~1h10m–2h mark (self-attention and multi-head attention sections); companion repo: `karpathy/nanoGPT`, `model.py` — `CausalSelfAttention` class.
