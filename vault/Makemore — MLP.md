---
title: Makemore — MLP
tags: [zero-to-hero, mlp, language-model, embeddings, neural-network]
source: Karpathy "Neural Networks: Zero to Hero" — makemore Part 3 (MLP), https://youtu.be/TCH_1BHY58I
---

# Makemore — MLP

> Replace the bigram lookup table with a proper multi-layer perceptron that predicts the next character from a fixed-length context window of learned embeddings.

## The core idea

The bigram model looks at exactly one previous character. The MLP (following Bengio et al. 2003) extends this to a **context window** of `n` previous characters. Each character is mapped to a low-dimensional embedding vector; the context vectors are concatenated into a single flat input.

That concatenated vector is fed through one or more hidden layers: `h = tanh(W1 · x + b1)`, then a linear output layer `logits = W2 · h + b2`. Applying softmax to the logits and minimising cross-entropy loss trains everything end-to-end via backprop.

The **embedding table** `C` is a learnable `(vocab_size × embed_dim)` matrix. Looking up a character is just an integer index into `C` — no one-hot multiplication needed. Gradients flow straight into `C`, so embeddings are shaped by the training signal automatically.

Because the hidden layer mixes information across the full context window, the model can learn multi-character patterns invisible to a bigram. Karpathy walks through every tensor shape explicitly, making this the clearest possible demonstration of how raw index lookups become differentiable.

## Why it matters / where it fits

This is the conceptual bridge between a shallow n-gram and a deep language model. The same pattern — embed tokens, run through layers, predict next token with cross-entropy — scales directly to Transformers. Understanding embedding tables here demystifies the token embedding matrix in GPT.

## Related
- [[Makemore — Bigram Model]] — the simpler predecessor this MLP replaces
- [[Embeddings]] — the lookup table `C` is exactly this concept
- [[Cross-Entropy Loss]] — the training objective used throughout
- [[BatchNorm and Initialization]] — the next makemore episode addresses poor initialisation exposed here
- [[Neuron, MLP, and Loss]] — foundational MLP mechanics underlying this model

## Source
- Karpathy, "Neural Networks: Zero to Hero", makemore Part 3 — Building a MLP language model: https://youtu.be/TCH_1BHY58I; companion repo: https://github.com/karpathy/makemore
