# AI Providers

The app currently exposes seven OpenAI-compatible presets. The implementation is one HTTP client; presets provide defaults only.

| Preset | Base URL | Default model |
|---|---|---|
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai/` | `gemini-2.5-flash` |
| Groq | `https://api.groq.com/openai/v1/` | `llama-3.3-70b-versatile` |
| OpenRouter | `https://openrouter.ai/api/v1/` | `auto` |
| Mistral | `https://api.mistral.ai/v1/` | `mistral-small-latest` |
| DeepSeek | `https://api.deepseek.com/v1/` | `deepseek-chat` |
| Together | `https://api.together.xyz/v1/` | `meta-llama/Llama-3.3-70B-Instruct-Turbo` |
| OpenAI-Compatible API | User-provided | User-provided |

For presets, Base URL is auto-filled and locked while the model remains editable. The custom option unlocks Base URL and starts with an empty model. The API key is required for the service to be considered ready.

## Local endpoints

For Ollama on an Android emulator use `http://10.0.2.2:11434/v1`. For a physical device use the host computer's LAN IP and ensure the service is reachable from the device. Local endpoints may reject `response_format`; the client retries once without that field when the response indicates that it is unsupported.

## Adding a preset

Add one enum value, one entry to `AiConfig.defaultsFor()`, and one display name to `providerDisplayName()`. The settings dropdown is generated from the enum values.

## References

[1]: https://platform.openai.com/docs/api-reference/chat "Chat completions protocol"
[2]: https://ollama.com/blog/openai-compatibility "Ollama OpenAI compatibility"
