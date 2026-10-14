import '../../l10n/strings.dart';

/// Erro de negocio ou de infraestrutura ja traduzivel para o usuario.
///
/// [key] e a chave do backend (`ad.fn_message`) ou uma chave interna do app
/// (`AUTH_*`, `NETWORK`, `UNKNOWN`). [parameters] substitui `{Nome}` no texto.
class AppError implements Exception {
  AppError({required this.key, this.parameters = const {}, this.fallback});

  factory AppError.unexpected(Object error) {
    final text = error.toString();
    final isNetwork =
        text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest');
    return AppError(
      key: isNetwork ? 'NETWORK' : 'UNKNOWN',
      fallback: isNetwork ? null : text,
    );
  }

  final String key;
  final Map<String, dynamic> parameters;
  final String? fallback;

  /// Texto pronto para mostrar ao usuario.
  String get message => Strings.errorMessage(key, parameters, fallback);

  @override
  String toString() => 'AppError($key): $message';
}

/// Texto para o usuario a partir de qualquer erro capturado na UI.
String describeError(Object error) =>
    error is AppError ? error.message : AppError.unexpected(error).message;
