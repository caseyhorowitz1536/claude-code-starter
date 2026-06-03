---
title: Positional Encoding
tags: [concept, transformer, attention, positional-encoding]
source: Karpathy "Let's build GPT from scratch" — positional embedding section; nanoGPT repo (model.py)
---

# Positional Encoding

> A mechanism that injects token-order information into a Transformer because self-attention, by itself, is permutation-invariant.

## The core idea

Self-attention computes relationships between all tokens simultaneously — it has no built-in notion of which token came first, second, or last. If you shuffled the input sequence, the attention weights would shuffle identically. To fix this, we add a positional signal to each token's embedding before it enters the attention layers.

In nanoGPT, Karpathy uses learned positional embeddings: a simple `nn.Embedding(block_size, n_embd)` table. Position `t` (0-indexed) looks up a vector of the same dimension as the token embedding, and the two are summed: `x = token_emb + pos_emb`. The model learns what each position should mean during training.

The original "Attention Is All You Need" paper instead used fixed sinusoidal encodings — alternating `sin` and `cos` at geometrically spaced frequencies — so the model could generalize to sequence lengths not seen during training. Karpathy notes both approaches work; learned embeddings are simpler to implement and perform comparably within the training context length.

Because positional and token embeddings live in the same vector space and are simply added, the residual stream carries both "what this token is" and "where it sits" from the very first layer onward.

## Why it matters / where it fits

Without positional information, a Transformer would treat "the dog bit the man" identically to "the man bit the dog." Positional encoding is what makes sequence modeling possible, enabling the model to distinguish subject from object and learn syntax.

## Related
- [[Lets Build GPT — Self-Attention]] — where positional encoding is introduced in the build
- [[Attention]] — attention is position-blind without this fix
- [[Embeddings]] — token embeddings are summed with positional embeddings
- [[Residual Stream]] — combined embedding enters and flows through the residual stream

## Source
- Karpathy, "Let's build GPT from scratch" (YouTube, 2023) — ~1:00:00 mark, positional embedding table; nanoGPT `model.py` lines defining `self.transformer.wpe`
