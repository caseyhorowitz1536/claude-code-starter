---
title: Activations and Gradients
tags: [zero-to-hero, activations, gradients, training-dynamics, initialization]
source: Neural Networks: Zero to Hero — "Building makemore Part 3: Activations & Gradients, BatchNorm" (Karpathy, 2022)
---

# Activations and Gradients

> The values that flow forward through a network (activations) and the error signals that flow backward (gradients) must be kept in a healthy numerical range throughout training or learning collapses.

## The core idea

Every layer in a neural network produces **activations** — the outputs of neurons after applying a nonlinearity like tanh or ReLU. These activations are then used to compute the loss, and during backpropagation, **gradients** flow in reverse, telling each parameter how to change.

The danger: if activations are too large, tanh saturates (output ≈ ±1, gradient ≈ 0), killing the gradient signal — this is called **vanishing gradients**. If they're too small, the network learns nothing either. Karpathy demonstrates this vividly by plotting activation and gradient histograms across layers before and after fixes.

Proper weight initialization is the first line of defense. Scaling weights by roughly `1/sqrt(fan_in)` (Kaiming/He init) keeps activations at unit variance at initialization, preventing immediate saturation. Karpathy shows that naive initialization (`W = torch.randn(...)` with no scaling) causes immediate tanh saturation and near-zero gradients deep in the network.

The **update-to-data ratio** — the size of gradient updates relative to parameter magnitudes — should stay around `1e-3`. Karpathy tracks this ratio as a training diagnostic; values that are too large or too small signal a misconfigured learning rate or bad init.

## Why it matters / where it fits

Healthy activations and gradients are a prerequisite for any deep network to train. BatchNorm was invented largely to solve this problem automatically. Understanding these dynamics is essential before reasoning about more complex architectures like Transformers.

## Related
- [[BatchNorm and Initialization]] — directly solves the saturation problem by normalizing activations per mini-batch
- [[Micrograd and Backpropagation]] — builds the gradient machinery these activations depend on
- [[Makemore — MLP]] — the MLP context where these training pathologies first appear
- [[Gradient Descent]] — gradients are only useful if they reach parameters cleanly
- [[Residual Stream]] — residual connections in GPT help gradients flow across many layers

## Source
- Karpathy, "Building makemore Part 3: Activations & Gradients, BatchNorm", Neural Networks: Zero to Hero (YouTube, 2022) — activation/gradient histograms, Kaiming init, update ratio diagnostics
