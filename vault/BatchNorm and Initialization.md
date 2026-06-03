---
title: BatchNorm and Initialization
tags: [#zero-to-hero, #batch-normalization, #initialization, #training-stability]
source: Karpathy "Neural Networks: Zero to Hero" — makemore Part 3 (MLP with BatchNorm), YouTube lecture ~2:00–3:30 hr mark
---

# BatchNorm and Initialization

> BatchNorm normalizes layer inputs to zero mean and unit variance during training, and careful weight initialization prevents activations from exploding or vanishing from the very first forward pass.

## The core idea

Before training stabilizes, raw pre-activations can be wildly large or small depending on how weights are set at random. If inputs to a `tanh` are huge, the outputs saturate to ±1 and gradients vanish — learning stops before it starts. Good initialization (e.g. scaling weights by `1/sqrt(fan_in)`) keeps activations in a healthy range at step zero.

BatchNorm adds a learned normalization layer between the linear transform and the nonlinearity. For a mini-batch of pre-activations `x`, it computes: `x_hat = (x - mean) / sqrt(var + eps)`, then applies learnable scale and shift: `y = gamma * x_hat + beta`. This forces each feature to be roughly Gaussian during training regardless of how weights evolve.

A subtle but important detail Karpathy emphasizes: BatchNorm introduces a dependency between examples in the same batch. At inference you switch to running statistics (tracked during training) so the output is deterministic per example.

BatchNorm also has a surprising regularization effect — the noise from estimating statistics on small batches acts like dropout, slightly. This is a side effect, not the purpose.

## Why it matters / where it fits

BatchNorm was a key enabler of deep networks in the pre-LayerNorm era. Modern Transformers use [[LayerNorm]] instead (normalizes across features, not batch), but understanding BatchNorm builds the intuition for why any normalization is needed and what it costs (train/eval asymmetry, batch-size sensitivity).

## Related
- [[Activations and Gradients]] — BatchNorm directly tames bad activation distributions
- [[LayerNorm]] — the Transformer-era replacement for BatchNorm
- [[Makemore — MLP]] — the lecture where Karpathy adds BatchNorm step by step
- [[Gradient Descent]] — initialization and normalization exist to keep gradients alive

## Source
- Karpathy, "Neural Networks: Zero to Hero," makemore Part 3: Activations, Gradients, BatchNorm (YouTube, ~2023); makemore repo `mlp.py`
