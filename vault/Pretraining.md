---
title: Pretraining
tags: [llm-overview, pretraining, self-supervised-learning, next-token-prediction]
source: Karpathy — "Intro to Large Language Models" (Nov 2023 talk); "Deep Dive into LLMs like ChatGPT" (2024); nanoGPT repo
---

# Pretraining

> Pretraining is the stage where a language model learns the statistical structure of text by training on vast internet-scale corpora to predict the next token.

## The core idea

The training objective is deceptively simple: given a sequence of tokens, predict the next one. Concretely, the model maximizes `log P(x_t | x_1, …, x_{t-1})` over every position in every document. This is self-supervised — the labels come free from the raw text; no human annotation is needed.

The model processes each training context through its transformer layers, produces a probability distribution over the vocabulary via a final linear head and softmax, and the cross-entropy loss measures how far that distribution is from the true next token. Gradients flow back through the entire network via backpropagation, nudging billions of parameters.

Because the model must predict coherently across domains — code, math, fiction, Wikipedia — it is forced to compress world knowledge into its weights. Karpathy describes the resulting weights as a "lossy compression of the internet." The model doesn't memorize; it learns abstract patterns that generalize.

Scale is the decisive lever. Compute, data, and parameters must grow together — the [[Scaling Laws]] paper quantified how loss falls predictably as each increases.

## Why it matters / where it fits

Pretraining produces the **base model** — a document-completion engine that knows an enormous amount but has no notion of being an assistant. Every downstream capability (instruction following, tool use, safety) is built on top of this foundation. Without a well-pretrained base, fine-tuning cannot compensate.

## Related
- [[Base vs Instruct Models]] — pretraining produces the base; fine-tuning transforms it
- [[Scaling Laws]] — govern how pretraining loss improves with compute
- [[Cross-Entropy Loss]] — the exact training signal used during pretraining
- [[BPE Tokenizer]] — the tokenization step that converts raw text into the token stream pretraining operates on
- [[Reproducing GPT-2]] — Karpathy's nanoGPT walkthrough is a live pretraining run

## Source
- Karpathy, "Intro to Large Language Models," Nov 2023 (YouTube) — pretraining / data / base-model sections
- Karpathy, "Deep Dive into LLMs like ChatGPT," 2024 — Stage 1 pretraining walkthrough
- nanoGPT repo (`train.py`) — minimal pretraining loop on FineWeb/OpenWebText
