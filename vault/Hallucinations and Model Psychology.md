---
title: Hallucinations and Model Psychology
tags: [#llm-overview, #hallucinations, #model-psychology, #alignment]
source: Karpathy "Intro to Large Language Models" (Nov 2023) and "Deep Dive into LLMs like ChatGPT" (2024) — hallucination and model behavior sections
---

# Hallucinations and Model Psychology

> LLMs hallucinate because they are trained to produce fluent, plausible token sequences — not to know what they do not know.

## The core idea

A language model assigns probability to the next token given everything before it. It has no explicit "uncertainty signal" and no mechanism to refuse to guess; the training objective rewards confident, grammatically coherent completions, not epistemic caution. So when it lacks the right answer it fills the gap with the most probable-sounding tokens — a fabrication that feels authoritative.

Karpathy frames this as a consequence of pretraining on internet text: the model learned to *simulate* a knowledgeable author. That simulation is very good at surface plausibility but cannot distinguish between something it genuinely "knows" versus a pattern it's reconstructing from noisy training data.

RLHF partially addresses this. Human raters reward helpful, accurate answers and penalize obvious nonsense, which nudges the model toward hedging phrases ("I'm not sure") and source caveats. But RLHF does not fix the root cause — it only changes the behavioral surface.

Karpathy also introduces the idea of the model as a character or persona. After supervised fine-tuning and RLHF the base model's distribution is shaped into an "assistant character." That character can be jailbroken because it is a statistical artifact, not a rule system. The model's apparent psychology (helpfulness, caution, tone) is an emergent property of the fine-tuning data distribution, not hardcoded logic.

## Why it matters / where it fits

Hallucinations set a practical ceiling on how much raw LLM output can be trusted without retrieval, tool use, or human verification. Understanding their statistical origin helps calibrate when to add grounding (RAG, tool calls) and when model confidence is meaningful.

## Related
- [[RLHF and RL]] — RLHF is the primary lever used to reduce hallucination rate at the behavioral level
- [[Base vs Instruct Models]] — base models hallucinate differently than fine-tuned assistants; the persona is absent
- [[Pretraining]] — the root cause lives here: next-token training on noisy web data
- [[Tool Use and Agents]] — agents add retrieval and code execution to ground model outputs and reduce hallucination
- [[Inference, Sampling, and Context Window]] — temperature and sampling strategies affect how confidently (or randomly) hallucinations surface

## Source
- Karpathy, "Intro to Large Language Models," Nov 2023 (YouTube) — "hallucination" segment ~28 min mark
- Karpathy, "Deep Dive into LLMs like ChatGPT," 2024 — model psychology, jailbreaking, and the assistant character discussion
