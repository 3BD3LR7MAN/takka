import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'ai_service.dart';
import 'ai_models.dart';

enum AiProviderKind { gemini, groq, openRouter, mistral, deepseek, together, compatible }

class AiConfig {
  final AiProviderKind kind;
  final String apiKey;
  final String model;
  final String baseUrl;

  const AiConfig({
    required this.kind,
    required this.apiKey,
    required this.model,
    required this.baseUrl,
  });

  static AiConfig defaultFor(AiProviderKind k) => defaultsFor(k);

  static AiConfig defaultsFor(AiProviderKind k) => AiConfig(
        kind: k, apiKey: '',
        model: switch (k) {
          AiProviderKind.gemini => 'gemini-2.5-flash',
          AiProviderKind.groq => 'llama-3.3-70b-versatile',
          AiProviderKind.openRouter => 'auto',
          AiProviderKind.mistral => 'mistral-small-latest',
          AiProviderKind.deepseek => 'deepseek-chat',
          AiProviderKind.together => 'meta-llama/Llama-3.3-70B-Instruct-Turbo',
          AiProviderKind.compatible => '',
        },
        baseUrl: switch (k) {
          AiProviderKind.gemini => 'https://generativelanguage.googleapis.com/v1beta/openai/',
          AiProviderKind.groq => 'https://api.groq.com/openai/v1/',
          AiProviderKind.openRouter => 'https://openrouter.ai/api/v1/',
          AiProviderKind.mistral => 'https://api.mistral.ai/v1/',
          AiProviderKind.deepseek => 'https://api.deepseek.com/v1/',
          AiProviderKind.together => 'https://api.together.xyz/v1/',
          AiProviderKind.compatible => '',
        },
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'apiKey': apiKey,
        'model': model,
        'baseUrl': baseUrl,
      };

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind'] as String?;
    final kind = switch (rawKind) {
      'openai' || 'openaiCompatible' => AiProviderKind.compatible,
      _ => AiProviderKind.values.firstWhere(
          (k) => k.name == rawKind,
          orElse: () => AiProviderKind.gemini,
        ),
    };
    final defaults = defaultsFor(kind);
    return AiConfig(
      kind: kind,
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? defaults.model,
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
    );
  }

  static const _storage = FlutterSecureStorage();

  static Future<AiConfig?> load() async {
    final raw = await _storage.read(key: 'ai_config');
    if (raw == null) return null;
    try {
      return AiConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save() =>
      _storage.write(key: 'ai_config', value: jsonEncode(toJson()));

  bool get isReady => apiKey.trim().isNotEmpty && baseUrl.trim().isNotEmpty;
}

String providerDisplayName(AiProviderKind k) => switch (k) {
      AiProviderKind.gemini => 'Google Gemini', AiProviderKind.groq => 'Groq',
      AiProviderKind.openRouter => 'OpenRouter', AiProviderKind.mistral => 'Mistral',
      AiProviderKind.deepseek => 'DeepSeek', AiProviderKind.together => 'Together',
      AiProviderKind.compatible => 'OpenAI-Compatible API',
    };

AiService createAiService(AiConfig cfg) => OpenAiCompatibleProvider(
      apiKey: cfg.apiKey, model: cfg.model, baseUrl: cfg.baseUrl);

// ─────── OpenAI-compatible (OpenAI / Groq / OpenRouter / Ollama) ──────

class OpenAiCompatibleProvider implements AiService {
  OpenAiCompatibleProvider({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
  });
  final String apiKey;
  final String model;
  final String baseUrl;

  @override
  String get providerName => 'OpenAI-compatible';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (apiKey.trim().isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

  Future<String> _complete(String system, String user,
      {bool jsonMode = true}) async {
    final uri =
        Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions');
    final body = <String, dynamic>{
      'model': model,
      'temperature': 0.1,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      if (jsonMode) 'response_format': {'type': 'json_object'},
    };

    var res = await http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    // النماذج المحلية قد ترفض response_format → إعادة محاولة بدونه.
    if (res.statusCode == 400 &&
        jsonMode &&
        res.body.contains('response_format')) {
      body.remove('response_format');
      res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    }
    if (res.statusCode != 200) {
      throw AiProviderException('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['choices'][0]['message']['content'] as String;
  }

  @override
  Future<AiExtractionResult> extractEvents(AiRequest request) async {
    final raw = await _complete(buildSystemPrompt(request), request.text);
    return validateAiJson(raw);
  }

  @override
  Future<String> chat(String message) =>
      _complete('You are a helpful scheduling assistant.', message,
          jsonMode: false);
}

// ───────────────────────────── Anthropic ──────────────────────────────

class AnthropicProvider implements AiService {
  AnthropicProvider({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
  });
  final String apiKey;
  final String model;
  final String baseUrl;

  @override
  String get providerName => 'Anthropic';

  @override
  Future<AiExtractionResult> extractEvents(AiRequest request) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/messages');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 2048,
        'system': buildSystemPrompt(request),
        'messages': [
          {'role': 'user', 'content': request.text},
        ],
      }),
    ).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw AiProviderException('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    final text = (data['content'] as List).first['text'] as String;
    return validateAiJson(text);
  }

  @override
  Future<String> chat(String message) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/messages');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': message},
        ],
      }),
    ).timeout(const Duration(seconds: 60));
    final data = jsonDecode(res.body);
    return (data['content'] as List).first['text'] as String;
  }
}
