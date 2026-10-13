/// Opcao de filtro/combo com rotulo: `Choice(value: 80, label: 'Bloqueado')`.
/// `value` null representa "todos" / "nenhum". Igualdade pelo valor.
class Choice<T> {
  const Choice({required this.value, required this.label, this.subtitle});

  final T? value;
  final String label;
  final String? subtitle;

  @override
  bool operator ==(Object other) => other is Choice<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
