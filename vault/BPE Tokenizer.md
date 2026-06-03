---
title: BPE Tokenizer
tags: [#zero-to-hero, tokenization, bpe, preprocessing]
source: Karpathy "Let's build the GPT Tokenizer" (YouTube, 2024); minbpe repo
---

# BPE Tokenizer

> Byte Pair Encoding (BPE) is a compression-based algorithm that iteratively merges the most frequent pair of tokens in a corpus to build a vocabulary, turning raw text into integer sequences a language model can consume.

## The core idea

Text cannot go directly into a neural network — we need integers. The simplest option is to tokenize at the byte level (256 tokens), but that creates very long sequences and forces the model to learn character composition from scratch. BPE finds a middle ground.

Start with the 256 raw bytes as your initial vocabulary. Scan the training corpus and find the pair of adjacent tokens that appears most often. Merge that pair into a single new token, add it to the vocabulary, and replace every occurrence of the pair. Repeat until you reach a target vocabulary size (GPT-2 uses 50,257; GPT-4 uses ~100k).

The result is a vocabulary where common English words ("the", "ing") become single tokens, while rare or invented words are split into smaller pieces. The merge table — the ordered list of pair → new-token rules — is all you need to encode any future string deterministically.

Decoding is the reverse: replace each token ID with its byte sequence, recursively unpacking merges, then UTF-8 decode the bytes.

A crucial subtlety: GPT-2 pre-tokenizes with a regex (splitting on spaces, punctuation, digits) before applying BPE, so "dog" and " dog" (with a leading space) always become different tokens and never merge across that boundary.

## Why it matters / where it fits

Tokenization is the very first stage of an LLM pipeline and has outsized downstream effects. Vocabulary size sets the embedding table dimension and the size of the final unembedding (lm\_head) layer. Token boundaries affect arithmetic, spelling tasks, and non-English language quality. Many "weird" LLM failure modes (can't count letters, stumbles on code) trace back to tokenization artifacts.

## Related

- [[Embeddings]] — each token ID maps to a learned embedding vector
- [[Lets Build GPT — Self-Attention]] — the token sequence produced by BPE is what the transformer attends over
- [[Reproducing GPT-2]] — nanoGPT uses the same BPE vocabulary (tiktoken) as GPT-2/GPT-4
- [[Inference, Sampling, and Context Window]] — context length is measured in tokens, making efficient tokenization critical for long contexts

## Source

- Karpathy, "Let's build the GPT Tokenizer," YouTube (2024) — full walkthrough building minbpe from scratch
- minbpe repo: github.com/karpathy/minbpe
