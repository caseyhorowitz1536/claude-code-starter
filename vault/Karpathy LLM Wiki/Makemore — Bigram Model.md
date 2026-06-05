---
title: Makemore — Bigram Model
tags: [zero-to-hero, language-model, bigram, probability, makemore]
source: Karpathy "Neural Networks: Zero to Hero" — makemore Part 1 (YouTube + makemore repo)
---

# Makemore — Bigram Model

> A bigram model predicts the next character given only the single preceding character, using empirical character-pair counts as probabilities.

## The core idea

The simplest possible character-level language model asks: given the last character, what should come next? A bigram model answers this by counting every consecutive character pair in the training data, then normalizing those counts into a probability distribution over the next character.

Concretely, build a 27×27 matrix `N` (26 letters + a special start/end token `.`). `N[i, j]` is the count of times character `j` follows character `i` in the training corpus. Dividing each row by its row sum gives a probability matrix `P` where `P[i]` is a valid probability distribution over all possible next characters.

To sample a name: start at the `.` token, sample the next character from `P['.']`, then from `P[c1]`, and so on until `.` is sampled again.

To train with gradient descent instead of counting, represent `P` as a single linear layer with no hidden units: `logits = W[i]`, then apply `softmax` to get probabilities, then minimize cross-entropy loss. This reframes the lookup table as a one-layer neural net — bridging raw counting to the neural approach used in all later makemore parts.

The negative log-likelihood loss quantifies model quality: `loss = -mean(log P[correct next char])`. A uniform model scores `log(27) ≈ 3.3`; a well-trained bigram model does modestly better.

## Why it matters / where it fits

Bigrams are the pedagogical baseline Karpathy uses to motivate richer models. Every improvement — MLP context windows, attention, transformers — is measured against the bigram's inherent ceiling: you cannot predict well using only one character of context.

## Related
- [[Makemore — MLP]] — extends context from 1 char to n chars using an MLP
- [[Cross-Entropy Loss]] — the loss function optimized during neural bigram training
- [[Softmax]] — converts raw logits into the probability distribution over next characters
- [[Embeddings]] — the lookup-table view of the input token is the seed of embedding tables
- [[Gradient Descent]] — used to optimize the neural formulation of the bigram model

## Source
- Karpathy, "Neural Networks: Zero to Hero," makemore Part 1: "The spelled-out intro to language modeling" — YouTube (2022) and `karpathy/makemore` repo, `makemore.py` bigram section
