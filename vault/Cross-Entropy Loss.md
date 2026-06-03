---
title: Cross-Entropy Loss
tags: [#concept, #loss, #training, #probability]
source: Neural Networks: Zero to Hero — "The spelled-out intro to language modeling" (makemore Part 1 & 2); "Let's build GPT" — training loop section
---

# Cross-Entropy Loss

> A measure of how surprised the model is by the correct answer, averaged over training examples.

## The core idea

A language model outputs a probability distribution over its vocabulary for each next token. Cross-entropy quantifies how well those probabilities match reality. If the model assigns probability *p* to the correct token, its loss for that example is **−log(p)**. Because log(1) = 0, a confident correct prediction contributes zero loss; as *p* → 0, the loss → ∞.

Over a batch of *N* examples the loss is the average negative log-likelihood:

**L = −(1/N) Σ log(p_correct)**

In PyTorch this is `F.cross_entropy(logits, targets)`, which fuses a softmax over the raw logits with the negative log-likelihood in one numerically stable call. Karpathy emphasizes this fusion in both makemore and nanoGPT — never apply softmax before passing to `cross_entropy`.

A useful sanity check: with a vocabulary of *V* tokens and a randomly initialized model, the expected loss is **log(V)**. For a 65-token character model that's ~4.17; for GPT-2's 50,257-token vocab it's ~10.8. Seeing this number at step 0 confirms the model is initialized correctly.

Minimizing cross-entropy is equivalent to maximizing the likelihood of the training data, so gradient descent on this loss is the engine that drives all of pretraining.

## Why it matters / where it fits

Cross-entropy is the universal training signal for LLMs. Backpropagation flows gradients of this scalar through every parameter in the network. Better calibration — tighter probability mass on correct tokens — is what pretraining, SFT, and RLHF all ultimately optimize.

## Related
- [[Softmax]] — converts logits to probabilities that cross-entropy consumes
- [[Gradient Descent]] — optimizer that minimizes the cross-entropy signal
- [[Makemore — Bigram Model]] — first place Karpathy derives this loss from scratch
- [[Neuron, MLP, and Loss]] — loss sits at the top of the compute graph
- [[Pretraining]] — cross-entropy on next-token prediction is the pretraining objective

## Source
- Karpathy, *Neural Networks: Zero to Hero* — makemore Part 1 ("The spelled-out intro to language modeling: building makemore") and Part 2 (MLP); "Let's build GPT" training loop; micrograd `Value` demo showing log-likelihood by hand
