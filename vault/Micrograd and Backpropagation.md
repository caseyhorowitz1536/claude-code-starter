---
title: Micrograd and Backpropagation
tags: [#zero-to-hero, #backpropagation, #autograd, #calculus]
source: Karpathy "Neural Networks: Zero to Hero" — Lecture 1 "The spelled-out intro to neural networks and backpropagation: building micrograd" (YouTube, 2022); github.com/karpathy/micrograd
---

# Micrograd and Backpropagation

> Backpropagation is the repeated application of the chain rule through a computational graph to compute how each parameter affects the loss.

## The core idea

Every forward pass through a neural network is a chain of mathematical operations: additions, multiplications, tanh calls, etc. Karpathy's `micrograd` library represents each operation as a `Value` node in a directed acyclic graph (DAG), storing both the output value and a `.grad` field that will accumulate that node's contribution to the final loss.

The key insight is the **chain rule**: if `L` depends on `c`, and `c` depends on `a`, then `dL/da = (dL/dc) * (dc/da)`. Backprop just walks this DAG in reverse topological order, multiplying local gradients together until every leaf (a parameter weight) has its gradient.

Each operation type defines its own backward pass. For multiplication `c = a * b`, the local gradients are simply `dc/da = b` and `dc/db = a` — so each input's gradient is the other input's value, scaled by the gradient flowing back from `c`.

Karpathy builds this from scratch in ~150 lines of Python, then shows that PyTorch's `Tensor.backward()` is doing the exact same thing at scale and in C++. The pedagogy is: understand the micro case, trust the macro.

## Why it matters / where it fits

Every large language model is trained by running backprop through billions of parameters. Without an efficient, correct implementation of this algorithm there is no learning. Micrograd is the conceptual foundation for everything upstream — MLPs, attention, transformers.

## Related
- [[Gradient Descent]] — backprop computes the gradients; gradient descent uses them to update weights
- [[Neuron, MLP, and Loss]] — the network backprop runs through
- [[Activations and Gradients]] — pathologies (vanishing/exploding) that backprop reveals
- [[Cross-Entropy Loss]] — the scalar `L` that backprop differentiates from

## Source
- Karpathy, "The spelled-out intro to neural networks and backpropagation: building micrograd," *Neural Networks: Zero to Hero*, YouTube (Jan 2023); github.com/karpathy/micrograd
