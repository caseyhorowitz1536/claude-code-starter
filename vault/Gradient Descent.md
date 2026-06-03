---
title: Gradient Descent
tags: [zero-to-hero, optimization, training, backpropagation]
source: Karpathy "Neural Networks: Zero to Hero" — micrograd series (lectures 1-2), makemore series (lecture 3)
---

# Gradient Descent

> An iterative optimization algorithm that nudges a model's parameters in the direction that reduces loss the most, guided by the gradient of the loss with respect to those parameters.

## The core idea

Every neural network has parameters (weights and biases). The **loss** measures how wrong the network's predictions are. Gradient descent asks: which direction should each parameter move to reduce the loss?

The gradient ∇L tells you the direction of steepest *increase* in loss — so you move *opposite* to it. The update rule is simple:

`w ← w − η · ∂L/∂w`

Here `w` is any parameter, `η` (eta) is the **learning rate** (a small positive number like 0.01), and `∂L/∂w` is the partial derivative of the loss with respect to that weight — how much the loss changes when `w` wiggles slightly.

You repeat this for every parameter, every step. Over thousands of steps the network climbs down the loss landscape toward a valley where predictions improve.

The tricky part is computing all those partial derivatives efficiently. That is exactly what **backpropagation** does — it applies the chain rule recursively from the loss back through every operation to every parameter in O(n) time.

In practice, you compute gradients on a small random **minibatch** of examples rather than the full dataset. This is *stochastic* gradient descent (SGD) — noisier but much faster per step.

## Why it matters / where it fits

Gradient descent is the engine of all modern deep learning. Without it, backpropagation is just a formula; with it, the formula drives every weight update that makes language models capable.

## Related
- [[Micrograd and Backpropagation]] — backprop computes the gradients that gradient descent consumes
- [[Neuron, MLP, and Loss]] — the loss landscape gradient descent navigates lives here
- [[BatchNorm and Initialization]] — poor initialization makes the gradient landscape hard to descend; BatchNorm stabilizes it
- [[Activations and Gradients]] — saturated activations kill gradients, stalling descent
- [[Cross-Entropy Loss]] — the most common loss surface gradient descent minimizes in language models

## Source
- Karpathy, "Neural Networks: Zero to Hero," Lecture 1 (micrograd walkthrough) and Lecture 2 (backprop deep-dive); makemore Lecture 3 (MLP training loop with SGD and learning-rate tuning). micrograd repo: github.com/karpathy/micrograd.
