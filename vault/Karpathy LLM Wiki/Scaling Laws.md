---
title: Scaling Laws
tags: [llm-overview, scaling, pretraining, compute]
source: Karpathy "Intro to Large Language Models" (2023) + "Deep Dive into LLMs like ChatGPT" (2024) — scaling section
---

# Scaling Laws

> Predictable power-law relationships govern how LLM loss decreases as model size, dataset size, and compute increase.

## The core idea

Scaling laws are empirical findings (first rigorously characterized in the Chinchilla / Kaplan et al. papers) showing that language model loss follows smooth power laws with respect to three independent axes: the number of model parameters N, the number of training tokens D, and the total compute budget C ≈ 6ND.

The key insight is that these curves are remarkably smooth and predictable — you can fit a small run and extrapolate to a large one with surprising accuracy. Karpathy emphasizes this in his "Intro to LLMs" talk: loss is not a noisy function of scale; it behaves more like a physics law.

The Chinchilla finding (Hoffmann et al. 2022) showed that most labs were under-training large models. For a fixed compute budget C, the optimal allocation is roughly equal scaling of N and D — i.e., train a model with ~C/6 parameters on ~C/6 tokens. GPT-3's 175 B parameters were "compute-optimal" only if trained on far more tokens than OpenAI used.

Below a given compute budget there is an irreducible Bayes error — the entropy of natural language itself — so loss plateaus asymptotically. This floor motivates ever-larger datasets as much as larger models.

## Why it matters / where it fits

Scaling laws are the scientific backbone behind the decision to invest billions in pretraining runs. They connect directly to the [[Pretraining]] process: knowing the loss curve in advance lets engineers budget compute, choose model size, and set training duration before a single large run starts.

## Related
- [[Pretraining]] — scaling laws determine how long and how big to pretrain
- [[Reproducing GPT-2]] — Karpathy's nanoGPT run illustrates the compute-optimal regime at small scale
- [[Base vs Instruct Models]] — scaling applies to the base model; fine-tuning is a separate regime
- [[Cross-Entropy Loss]] — the metric that scaling laws track
- [[What Is an LLM]] — broader context for why scale drives capability

## Source
- Karpathy, "Intro to Large Language Models" (Nov 2023 YouTube) — slides on scaling + emergent capabilities
- Karpathy, "Deep Dive into LLMs like ChatGPT" (Feb 2024 YouTube) — pretraining compute budget discussion
