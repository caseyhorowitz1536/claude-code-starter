---
title: What Is an LLM
tags: [#llm-overview, #transformers, #pretraining, #next-token-prediction]
source: Karpathy — "Intro to Large Language Models" (Nov 2023 talk) + "Deep Dive into LLMs like ChatGPT" (Feb 2025)
---

# What Is an LLM

> A large language model is a neural network trained to predict the next token in a sequence, whose billions of parameters compress a lossy but surprisingly general model of the world.

## The core idea

At its heart an LLM is a next-token predictor. Given a sequence of tokens it outputs a probability distribution over the vocabulary for what comes next. That's the entire training objective — nothing more exotic than "predict the next word."

The "large" part matters: scale in parameters and in training data is what pushes a simple prediction task toward general reasoning. Karpathy's 2023 talk makes this vivid by framing the weights as a 70 GB file that has "compressed the internet" — the model's weights are literally all it knows.

The network itself is a Transformer. Tokens are converted to vectors (embeddings), processed through stacked self-attention + MLP blocks, and finally projected back to vocabulary logits. A softmax turns those logits into probabilities, and cross-entropy loss measures how wrong the prediction was.

Training is just gradient descent on that loss over trillions of tokens scraped from the web (pretraining), producing a base model. The base model is not yet a useful assistant — it is a document-completion engine.

## Why it matters / where it fits

Understanding next-token prediction as the sole training signal explains both the power and the limits of LLMs. It's why hallucinations happen (the model learned to produce plausible text, not verified facts) and why fine-tuning is necessary to turn a base model into an assistant.

## Related
- [[Pretraining]] — the data pipeline and objective that produces the base model
- [[Base vs Instruct Models]] — what changes after pretraining
- [[Embeddings]] — how tokens become vectors the network can process
- [[Softmax]] — final layer turning raw scores into probabilities
- [[Hallucinations and Model Psychology]] — direct consequence of the prediction objective

## Source
- Karpathy, "Intro to Large Language Models" (YouTube, Nov 2023) — full talk
- Karpathy, "Deep Dive into LLMs like ChatGPT" (YouTube, Feb 2025) — pretraining + fine-tuning pipeline walkthrough
