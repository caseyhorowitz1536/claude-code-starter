---
title: Temperature and Top-k
tags: [#concept, #sampling, #inference, #decoding]
source: Karpathy "Let's build GPT" (sampling section); "Intro to Large Language Models" (inference walkthrough)
---

# Temperature and Top-k

> Temperature and top-k are knobs that control how the model samples the next token from the probability distribution produced by the final softmax.

## The core idea

After the forward pass, the model produces a vector of **logits** — one raw score per token in the vocabulary. A softmax converts those into probabilities. By default you'd just pick the highest-probability token (greedy decoding), but that produces flat, repetitive text.

**Temperature** rescales the logits before softmax. The formula is: `p_i = softmax(z_i / T)`. When `T < 1` the distribution sharpens — the model becomes more confident and picks likely tokens almost exclusively. When `T > 1` the distribution flattens — low-probability tokens get a real chance, producing more creative (and riskier) outputs. At `T = 1` you get the raw model distribution.

**Top-k sampling** truncates the distribution to only the `k` most probable tokens, zeroes out the rest, renormalizes, then samples. This prevents the model from ever emitting a very unlikely token, even at high temperature. Common values are `k = 40` or `k = 200`.

In practice the two are combined: first apply temperature to reshape the distribution, then apply top-k to clip the tail. Karpathy demonstrates this directly in the nanoGPT sampling loop where `logits = logits / temperature` precedes the topk mask.

## Why it matters / where it fits

Sampling hyperparameters are the primary lever at **inference time** — after training is done. They determine whether a model feels creative or deterministic without touching weights. Understanding them requires knowing how softmax works and how logits map to probabilities.

## Related
- [[Softmax]] — temperature acts directly on inputs to softmax
- [[Inference, Sampling, and Context Window]] — temperature/top-k live inside the sampling loop
- [[Lets Build GPT — Self-Attention]] — nanoGPT repo contains the canonical sampling implementation
- [[Cross-Entropy Loss]] — training minimizes this over the same probability distribution sampling draws from

## Source
- Karpathy, "Let's build GPT from scratch" — sampling/generation section (nanoGPT `generate()`)
- Karpathy, "Intro to Large Language Models" — inference walkthrough, token sampling discussion
