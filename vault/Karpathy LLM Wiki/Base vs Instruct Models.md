---
title: Base vs Instruct Models
tags: [llm-overview, fine-tuning, alignment, pretraining]
source: Karpathy "Intro to Large Language Models" (Nov 2023) + "Deep Dive into LLMs like ChatGPT" (Feb 2025), token prediction framing and SFT/RLHF sections
---

# Base vs Instruct Models

> A base model predicts the next token on raw internet text; an instruct model is fine-tuned to follow user instructions and behave like a helpful assistant.

## The core idea

After pretraining, a model is a powerful next-token predictor but it has no concept of "being an assistant." Ask it a question and it may just continue generating plausible internet text — perhaps more questions — rather than answering you.

Instruction tuning (also called supervised fine-tuning, or SFT) reshapes that behavior. Humans write thousands of (prompt, ideal-response) pairs, and the model is trained on them with the same cross-entropy loss used in pretraining. The weights already contain world knowledge; SFT teaches the model *how to surface that knowledge* in a helpful format.

RLHF (Reinforcement Learning from Human Feedback) goes further: human raters compare model outputs and a reward model is trained on those preferences. The base model is then fine-tuned via RL to maximize that reward, pushing it toward responses humans prefer — less hallucination, better tone, safer refusals.

Karpathy emphasizes that this is a relatively thin layer on top of a very large pretrained base. The base model's capabilities dominate; alignment stages steer *access and style*, not raw knowledge.

## Why it matters / where it fits

Understanding the base/instruct split explains why ChatGPT-style models exist as separate artifacts from raw pretrained checkpoints. It also clarifies jailbreaking: instruct fine-tuning is a behavioral overlay, not an architectural constraint — the base distribution is still underneath.

## Related
- [[Pretraining]] — builds the base model whose weights SFT then steers
- [[Supervised Fine-Tuning]] — the direct mechanism that converts base → instruct
- [[RLHF and RL]] — second alignment stage layered on top of SFT
- [[Hallucinations and Model Psychology]] — instruct tuning affects but does not eliminate hallucination
- [[Scaling Laws]] — base model capability (and thus instruct quality) scales predictably with compute

## Source
- Karpathy, "Intro to Large Language Models" (YouTube, Nov 2023) — "Base model vs assistant model" segment
- Karpathy, "Deep Dive into LLMs like ChatGPT" (YouTube, Feb 2025) — SFT and RLHF pipeline walkthrough
