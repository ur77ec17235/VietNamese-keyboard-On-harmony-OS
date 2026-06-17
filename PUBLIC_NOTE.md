This public copy is intentionally reduced.

Disabled / stripped on purpose:
- Emoji panel UI
- Clipboard panel UI
- Some docs/test/dev-only folders removed

Purpose:
- Shareable public variant
- Keeps core typing flow while withholding some non-essential features

Known weak area:
- Candidate suggestion currently uses a tiny local prefix list plus engine candidates.
- It is intentionally not a full dictionary or RNN language model yet.
- Good next step: load a Vietnamese word-frequency dictionary and rank prefix/fuzzy matches locally before trying an RNN.
