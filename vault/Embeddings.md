---
title: Embeddings
tags: [#concept, #embeddings, #representations, #tokens]
source: Karpathy "Neural Networks: Zero to Hero" — makemore MLP lecture; "Let's build GPT" — token embedding table; nanoGPT repo (model.py wte/wpe)
---

# Embeddings

> An embedding is a learned lookup table that maps a discrete token ID to a dense, fixed-size vector of real numbers.

## The core idea

Every token in the vocabulary gets an integer ID (e.g., "cat" → 4821). A neural network cannot do arithmetic on integers directly, so the first step is to swap each ID for a trainable vector — the embedding. You can think of it as a matrix `C` of shape `(vocab_size, d_model)` where `C[i]` is the vector for token `i`.

The magic is that this lookup is differentiable. During backprop, gradients flow into `C` and nudge each token's vector so that semantically similar tokens end up nearby in the high-dimensional space. The network learns the geometry of meaning from scratch.

In Karpathy's makemore MLP, he builds this from scratch: a `C` matrix of shape `(27, 2)` is initialized randomly, then trained by gradient descent. Even with only 2 dimensions you can visualize vowels clustering together — a vivid demonstration that the geometry emerges from the data.

In nanoGPT, `wte` (word token embeddings, shape `(vocab_size, n_embd)`) and `wpe` (positional embeddings, shape `(block_size, n_embd)`) are both `nn.Embedding` layers. Their sum is the input to every transformer block.

The dimensionality `d_model` (e.g., 768 in GPT-2 small) is a hyperparameter balancing capacity against compute. Bigger models use larger embedding dimensions to give the residual stream more room to carry information.

## Why it matters / where it fits

Embeddings are the entry point for every token. They initialize the residual stream that attention and MLP layers will read and write throughout the network. Without a good embedding space the downstream layers have no meaningful signal to build on.

## Related
- [[BPE Tokenizer]] — tokenizer produces the integer IDs that embeddings look up
- [[Positional Encoding]] — positional embeddings are added to token embeddings before the first block
- [[Residual Stream]] — embeddings seed the residual stream that flows through all layers
- [[Makemore — MLP]] — Karpathy builds a 2-D embedding table by hand, showing geometry emerges from training
- [[Lets Build GPT — Self-Attention]] — wte + wpe are the first ops in nanoGPT's forward pass

## Source
- Karpathy "Neural Networks: Zero to Hero" — makemore MLP video (embedding matrix `C` walkthrough)
- nanoGPT `model.py` — `self.transformer.wte` and `self.transformer.wpe`
- "Let's build GPT from scratch" — token + positional embedding setup, ~first 20 min
