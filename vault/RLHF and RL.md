---
title: RLHF and RL
tags: [llm-overview, rlhf, reinforcement-learning, alignment, fine-tuning]
source: Karpathy "Intro to Large Language Models" (Nov 2023) — RLHF section; "Deep Dive into LLMs like ChatGPT" (2024) — alignment stage
---

# RLHF and RL

> Reinforcement Learning from Human Feedback is the training stage that teaches a language model to be helpful, harmless, and honest — converting a raw base model into a model that actually follows instructions and produces responses humans prefer.

## The core idea

After pretraining, the model knows language but not how to be useful. Supervised Fine-Tuning (SFT) gives it a starting shape: show it (prompt, ideal-response) pairs and fine-tune. But human preference is hard to fully capture with labeled examples alone.

RLHF goes a step further. Human raters compare pairs of model outputs and label which is better. These preference judgments train a **reward model** — a separate neural network that learns to score any response. The reward model becomes a stand-in for "what humans want."

The language model is then fine-tuned with RL — specifically PPO (Proximal Policy Optimization) — to maximize the reward model's score. The model is the **policy**; each token it samples is an **action**; the reward model provides the **reward** at the end of the response.

A KL-divergence penalty keeps the RL-trained model from drifting too far from the SFT checkpoint (which would cause reward hacking — gaming the proxy metric without actually being good).

The result is the shift from a base model that completes text to an assistant model that helps, refuses harmful requests, and matches user intent.

## Why it matters / where it fits

RLHF is what separates GPT-3 (base) from ChatGPT (instruct). Karpathy frames it as the final "assistant token" stage of the three-stage pipeline: pretrain → SFT → RLHF. Without it, the model has knowledge but no alignment to human values or task structure.

## Related
- [[Supervised Fine-Tuning]] — the SFT stage that precedes RLHF and provides the starting policy
- [[Base vs Instruct Models]] — RLHF is the key transformation between the two
- [[Pretraining]] — provides the world-knowledge foundation RLHF refines
- [[Hallucinations and Model Psychology]] — RLHF affects how the model handles uncertainty and refusals

## Source
- Karpathy, "Intro to Large Language Models" (Nov 2023), ~18:00–28:00 — RLHF walkthrough
- Karpathy, "Deep Dive into LLMs like ChatGPT" (2024) — alignment pipeline section
