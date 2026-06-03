---
title: Inference, Sampling, and Context Window
tags: [#llm-overview, #inference, #sampling, #context-window, #autoregressive]
source: Karpathy "Intro to Large Language Models" (2023) — inference walkthrough; "Let's Build GPT" — generate() function and context window
---

# Inference, Sampling, and Context Window

> At inference time, an LLM autoregressively samples one token at a time from a probability distribution conditioned on all prior context, until it fills or exceeds its context window.

## The core idea

After training is done, inference is the process of actually generating text. The model takes a sequence of tokens as input and produces a probability distribution over the entire vocabulary for the *next* token. You then sample one token from that distribution, append it, and repeat.

The distribution is shaped by a softmax over the final logits: `p = softmax(logits / T)`, where `T` is temperature. High `T` flattens the distribution (more random); low `T` sharpens it (more deterministic). Top-k and nucleus (top-p) sampling further constrain which tokens are even considered.

The **context window** is the maximum number of tokens the model can attend to at once — hard-coded by the positional encoding scheme and the attention mask. In nanoGPT this is the `block_size` hyperparameter. Tokens outside the window are invisible; the model has no memory of them.

During a single forward pass, every token in the context attends to every earlier token (causal masking), so inference cost scales as O(n²) in sequence length per pass, and each new token requires a new forward pass.

## Why it matters / where it fits

Sampling strategy is where model behavior becomes user-visible. The same weights produce wildly different outputs depending on temperature and top-k. Understanding the context window explains why long conversations degrade or why models "forget" early instructions.

## Related
- [[Temperature and Top-k]] — directly controls the sampling distribution
- [[Lets Build GPT — Self-Attention]] — the generate() loop and block_size live here
- [[Attention]] — causal masking enforces the autoregressive constraint
- [[Positional Encoding]] — determines how context position is represented, bounds window
- [[The LLM OS Analogy]] — context window as RAM: finite, precious working memory

## Source
- Karpathy, "Intro to Large Language Models" (youtube, Nov 2023) — token generation and context window section
- Karpathy, "Let's Build GPT from Scratch" — `generate()` method and `block_size` in nanoGPT
