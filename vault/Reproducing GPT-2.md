---
title: Reproducing GPT-2
tags: [#zero-to-hero, #gpt, #transformer, #pretraining, #nanoGPT]
source: Karpathy "Let's reproduce GPT-2 (124M)" video + nanoGPT repo
---

# Reproducing GPT-2

> A ground-up implementation of the 124 M-parameter GPT-2 model that trains to match OpenAI's published validation loss using only PyTorch and publicly available data.

## The core idea

Karpathy walks through building GPT-2 (the smallest publicly released checkpoint) from scratch, making it the concrete endpoint of the Zero-to-Hero series. The architecture is a standard decoder-only transformer: token embeddings + positional embeddings fed through N stacked blocks, each containing causal self-attention and a feed-forward MLP, separated by LayerNorm and connected via residual streams.

The training objective is next-token prediction with cross-entropy loss. Given a sequence of tokens, the model predicts the probability of the next token at every position simultaneously — a single forward pass produces N labels of supervision for an N-token sequence, which is why pretraining is so data-efficient compared to supervised learning.

Key engineering details Karpathy emphasizes: weight tying between the token embedding matrix and the final projection head (halves parameters with no accuracy cost), using `torch.compile` and mixed-precision (bfloat16) for significant speed-ups, gradient accumulation to simulate large batch sizes on consumer hardware, and the cosine learning-rate schedule with warmup that OpenAI used.

The target metric is the validation loss on HellaSwag or the OpenWebText split. Matching OpenAI's reported numbers confirms the implementation is correct end to end.

## Why it matters / where it fits

This exercise cements every upstream concept — embeddings, attention, residual streams, LayerNorm, BPE tokenization — into one runnable system. It also bridges the gap to real industrial pretraining: the same code patterns (with more hardware) produce GPT-3, Llama, etc.

## Related
- [[Lets Build GPT — Self-Attention]] — the attention mechanism implemented here
- [[Pretraining]] — what this training run is doing at a high level
- [[BPE Tokenizer]] — how raw text is converted to token ids before training
- [[Residual Stream]] — the architectural backbone of every transformer block
- [[LayerNorm]] — placed before attention and MLP in the GPT-2 pre-norm style

## Source
- Karpathy, "Let's reproduce GPT-2 (124M)" (YouTube, 2024) — full video walkthrough
- `nanoGPT` repo: `train_gpt2.py` — the reference implementation
