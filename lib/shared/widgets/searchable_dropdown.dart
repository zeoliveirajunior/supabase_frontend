import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Combo com campo de pesquisa. No desktop abre um dialogo; no mobile, uma
/// folha inferior. A pesquisa ignora acentos e caixa.
///
/// ```dart
/// SearchableDropdown<CompanyAccess>(
///   label: 'Empresa',
///   items: companies,
///   value: selected,
///   itemLabel: (c) => c.vcName,
///   itemSubtitle: (c) => c.vcCnpj,
///   onChanged: (c) => setState(() => selected = c),
/// )
/// ```
class SearchableDropdown<T> extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
    this.itemSubtitle,
    this.itemLeading,
    this.hint,
    this.prefixIcon,
    this.enabled = true,
    this.emptyText,
    this.validator,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? Function(T item)? itemSubtitle;
  final Widget Function(T item)? itemLeading;
  final String? hint;
  final IconData? prefixIcon;
  final bool enabled;
  final String? emptyText;
  final FormFieldValidator<T>? validator;

  Future<void> _open(BuildContext context) async {
    final list = _SearchList<T>(
      title: label,
      items: items,
      selected: value,
      itemLabel: itemLabel,
      itemSubtitle: itemSubtitle,
      itemLeading: itemLeading,
      emptyText: emptyText,
    );

    final T? result;
    if (context.isMobile) {
      result = await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: list),
      );
    } else {
      result = await showDialog<T>(
        context: context,
        builder: (_) =>
            Dialog(child: SizedBox(width: 480, height: 520, child: list)),
      );
    }
    if (result != null) onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = enabled && items.isNotEmpty && onChanged != null;
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: canOpen ? () => _open(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              enabled: enabled,
              errorText: field.errorText,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
              suffixIcon: const Icon(Icons.expand_more_rounded),
            ),
            isEmpty: value == null,
            child: value == null
                ? null
                : Text(
                    itemLabel(value as T),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        );
      },
    );
  }
}

class _SearchList<T> extends StatefulWidget {
  const _SearchList({
    required this.title,
    required this.items,
    required this.itemLabel,
    this.selected,
    this.itemSubtitle,
    this.itemLeading,
    this.emptyText,
  });

  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T item) itemLabel;
  final String? Function(T item)? itemSubtitle;
  final Widget Function(T item)? itemLeading;
  final String? emptyText;

  @override
  State<_SearchList<T>> createState() => _SearchListState<T>();
}

class _SearchListState<T> extends State<_SearchList<T>> {
  final _search = TextEditingController();
  late List<T> _filtered = widget.items;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = normalizeForSearch(query);
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((item) {
              final label = normalizeForSearch(widget.itemLabel(item));
              final subtitle = normalizeForSearch(
                widget.itemSubtitle?.call(item) ?? '',
              );
              return label.contains(q) || subtitle.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: Strings.cancel,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: _search,
            autofocus: true,
            onChanged: _filter,
            onSubmitted: (_) {
              if (_filtered.isNotEmpty) {
                Navigator.of(context).pop(_filtered.first);
              }
            },
            decoration: InputDecoration(
              hintText: Strings.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _search.clear();
                        _filter('');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    widget.emptyText ?? Strings.noResults,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    final isSelected = item == widget.selected;
                    final subtitle = widget.itemSubtitle?.call(item);
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.mint,
                      leading: widget.itemLeading?.call(item),
                      title: Text(
                        widget.itemLabel(item),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: subtitle == null || subtitle.isEmpty
                          ? null
                          : Text(subtitle),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

const _accents = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
const _plain = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';

/// Minusculas e sem acentos, para comparar texto digitado com rotulos.
String normalizeForSearch(String value) {
  final out = StringBuffer();
  for (final rune in value.runes) {
    final ch = String.fromCharCode(rune);
    final i = _accents.indexOf(ch);
    out.write(i >= 0 ? _plain[i] : ch);
  }
  return out.toString().toLowerCase().trim();
}
