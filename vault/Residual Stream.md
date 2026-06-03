---
title: Residual Stream
tags: [#concept, #transformer, #architecture, #residual-connections]
source: Karpathy "Let's build GPT" (nanoGPT walkthrough) — Block class and residual additions; also "Deep Dive into LLMs like ChatGPT" — transformer internals section
---

# Residual Stream

> The residual stream is the running vector that flows through every layer of a transformer, with each attention and MLP block adding its contribution rather than replacing the previous state.

## The core idea

In a standard transformer, each block does not transform the input wholesale — it computes a *delta* and adds it back: `x = x + attention(x)` and `x = x + mlp(x)`. The evolving `x` at any depth is the residual stream.

Think of it as a shared highway. Every block reads from it and writes a correction back onto it. No block owns the representation; they all collaborate by accumulating small updates.

The formula for each sub-layer is simply:

`x ← x + sublayer(LayerNorm(x))`

Here `x` is the stream vector (shape `[T, C]` for T tokens, C channels), `sublayer` is either multi-head self-attention or the feedforward MLP, and `LayerNorm` normalizes before the operation.

This additive structure is what makes deep networks trainable. Gradients can flow directly from the loss all the way back to the embedding layer through the skip connection, bypassing the non-linearities in every block. Without residuals, deep transformers suffer vanishing gradients and fail to train.

In nanoGPT's `Block` class, you can see this literally: two lines, each adding the sublayer output back onto `x`.

## Why it matters / where it fits

The residual stream is the central data structure of the transformer. Understanding it clarifies why LayerNorm is applied *before* each sublayer (pre-norm), why depth helps (each layer refines the stream), and why attention heads are interpretable as independent additive contributions.

## Related
- [[Attention]] — each attention block writes deltas into the stream
- [[LayerNorm]] — applied to the stream before each sublayer
- [[Lets Build GPT — Self-Attention]] — nanoGPT Block shows the pattern directly
- [[Activations and Gradients]] — skip connections solve vanishing gradient problem
- [[Embeddings]] — the initial value placed into the residual stream

## Source
- Karpathy, "Let's build GPT from scratch" (YouTube / nanoGPT repo) — `model.py` `Block` class, residual additions at each sub-layer; "Deep Dive into LLMs like ChatGPT" — transformer block walkthrough
