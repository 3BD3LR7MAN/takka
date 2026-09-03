# Evaluation Protocol

The repository currently contains seven Flutter tests focused on deterministic event-engine behavior. It does not yet contain an executable multi-provider AI benchmark. The protocol below is a test plan, not a claim of measured provider accuracy.

## Recommended benchmark

Use a fixed set of Arabic and English inputs covering simple events, multi-event input, missing times, ambiguity, importance, reminders, and tasks. Store golden JSON fixtures with the current prompt version and run each provider with a fixed temperature and repeated trials.

## Metrics

Measure title, date, time, category, importance, reminder precision/recall, task precision/recall, `timeMissing` recall, ambiguity recall, invalid JSON rate, and hallucination rate. Record provider, model, prompt hash, date, and commit hash for every run.

## Change gate

Do not publish baseline percentages until a real run exists. A prompt or validator change should run the deterministic unit tests and the provider benchmark. Investigate any safety regression, especially invented times, hallucinated reminders, and silently accepted malformed dates.

## Known gaps

Recurring-event parsing, attendee fields, timezone abbreviations, and an executable provider matrix are future work. These gaps should remain visible rather than being presented as implemented functionality.

## References

[1]: https://docs.flutter.dev/testing "Flutter testing documentation"
