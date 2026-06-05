---
title: Tool Use and Agents
tags: [llm-overview, agents, tool-use, inference]
source: Karpathy "Intro to Large Language Models" (2023) — agent/tool-use section; "Deep Dive into LLMs like ChatGPT" (2024) — System 2 thinking and multi-step inference
---

# Tool Use and Agents

> An LLM becomes an *agent* when it is placed in a loop that lets it call external tools and act on the results rather than producing a single one-shot completion.

## The core idea

A bare LLM is a one-shot function: tokens in → tokens out. Tool use breaks that linearity. The model is given descriptions of callable tools (web search, a calculator, a code interpreter, an API) formatted as text — usually in the system prompt or a special schema — and is trained or prompted to emit a structured "call" token sequence instead of prose when it needs one.

The runtime intercepts that call, executes the real tool, and injects the result back into the context. The model then continues generating with the new information. This read-execute-observe loop is the minimal agent loop.

Karpathy frames this as the model gaining **System 2** capability: slow, deliberate, multi-step reasoning rather than the fast associative pattern-matching of a single forward pass. Each tool call is a chance to "think out loud" and ground the next step in real evidence.

Agents extend the loop further — the model can spawn subagents, write and run code, browse the web, or manipulate files across many turns. The context window becomes a working-memory scratchpad recording the full trajectory of calls and results.

## Why it matters / where it fits

Tool use transforms an LLM from a read-only knowledge store into an active system that can gather fresh data, verify claims, and take actions. It is central to how post-training (RLHF, SFT) shapes the model to follow structured output schemas reliably, and it explains why context-window length matters so much for complex tasks.

## Related
- [[Inference, Sampling, and Context Window]] — the context window is the working memory for the agent loop
- [[The LLM OS Analogy]] — Karpathy's OS framing treats tool use as the kernel syscall layer
- [[RLHF and RL]] — RL fine-tunes the model to call tools correctly and act on rewards
- [[Base vs Instruct Models]] — instruct models are specifically trained to emit structured tool calls
- [[Hallucinations and Model Psychology]] — tool use is a key mitigation: ground answers in retrieved facts

## Source
- Karpathy, "Intro to Large Language Models" (Nov 2023) — slides on LLM as the kernel of an emerging OS, tool/agent discussion ~40-55 min mark
- Karpathy, "Deep Dive into LLMs like ChatGPT" (Feb 2024) — System 1 vs System 2, multi-step "thinking" via tool loops
