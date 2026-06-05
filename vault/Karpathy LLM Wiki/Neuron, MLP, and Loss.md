---
title: Neuron, MLP, and Loss
tags: [zero-to-hero, mlp, neuron, loss, forward-pass]
source: Neural Networks: Zero to Hero — "The spelled-out intro to neural networks and backpropagation: building micrograd" (micrograd repo); "Let's build makemore Part 2: MLP"
---

# Neuron, MLP, and Loss

> A neuron is a weighted sum of its inputs passed through a nonlinearity; stack them in layers to get an MLP; measure how wrong the outputs are with a loss function.

## The core idea

A single neuron computes `output = activation(w·x + b)`: each input `x_i` is scaled by a learned weight `w_i`, everything is summed, a bias `b` is added, then a nonlinearity like `tanh` or `ReLU` squashes the result. Without that squash, stacking neurons would collapse to a single linear transformation.

An MLP (Multi-Layer Perceptron) is neurons arranged in layers. The output of one layer feeds as input to the next. The first layer receives raw features; intermediate "hidden" layers learn abstract representations; the final layer produces logits — raw unnormalized scores over possible outputs.

Loss quantifies badness. For classification, **cross-entropy loss** is standard: `L = -log(p_correct)`. When the model assigns high probability to the right class, `log(p)` is near zero and loss is small. Assign near-zero probability and loss explodes. Minimizing loss over a dataset is the entire training objective.

Karpathy constructs this bottom-up in micrograd: a `Value` object that holds a scalar and its gradient, then neurons built from `Value` operations, then a tiny MLP — making the full forward pass completely transparent before introducing autograd.

## Why it matters / where it fits

MLPs are the backbone of every transformer's feed-forward sublayer. Understanding how a neuron fires, how layers compose, and how loss measures error is the prerequisite for everything else: backprop, gradient descent, and ultimately attention.

## Related
- [[Micrograd and Backpropagation]] — backprop computes gradients through these exact neuron operations
- [[Gradient Descent]] — loss gradient drives weight updates
- [[Cross-Entropy Loss]] — the loss function used in classification MLPs
- [[Makemore — MLP]] — applies this MLP blueprint to character-level language modeling
- [[Activations and Gradients]] — what happens inside neurons at scale

## Source
- Karpathy, *Neural Networks: Zero to Hero* — "The spelled-out intro to neural networks and backpropagation: building micrograd" (YouTube + github.com/karpathy/micrograd)
- Karpathy, *Neural Networks: Zero to Hero* — "Let's build makemore Part 2: MLP" (YouTube)
