# AI Layer

## Contract

`AiService` exposes `extractEvents(AiRequest)` and `chat(String)`. The current extraction client sends an OpenAI-compatible `chat/completions` request and validates the returned JSON before producing proposals.

## Prompt rules

The current prompt requires the model to resolve relative dates using the supplied date and timezone, avoid invented times, separate untimed todos from timed events, return explicit reminders only when requested, and return JSON matching the schema. The authoritative implementation is `lib/features/ai/ai_service.dart`; this document is descriptive and must be updated when that prompt changes.

## Validation

Validation strips markdown fences, parses JSON, rejects untitled events, parses dates, marks missing times, repairs an end earlier than its start, clamps reminders to positive values up to 4,320 minutes, normalizes importance, and parses tasks. Invalid JSON becomes an ambiguity result rather than a crash.

## Provider implementation

All configured providers use `OpenAiCompatibleProvider`. Provider selection changes the default model and Base URL. The selected model remains editable. A custom OpenAI-Compatible API requires both a Base URL and model. The API key and configuration are stored with `flutter_secure_storage`.

## Privacy and limitations

Only the text, timezone, current date, and context supplied by the caller are sent to the selected endpoint. The current architecture does not provide a backend proxy, so a determined attacker can extract a key from a distributed mobile binary. Production deployments should use a server-side proxy with rate limiting and key rotation.

## Change protocol

Any prompt, schema, validation, or provider change should be accompanied by unit tests for the affected behavior. Provider quality claims must not be published without a dated, reproducible evaluation run. See [EVALS.md](EVALS.md).

## References

[1]: https://platform.openai.com/docs/api-reference/chat "OpenAI-compatible chat API reference"
[2]: https://developer.android.com/privacy-and-security/keystore "Android Keystore documentation"
