import 'package:flutter/material.dart';

import '../primitives/tu_button.dart';
import '../primitives/tu_textfield.dart';
import '../theme/tu_extensions.dart';

/// Confirm dialog. [show] returns `true` on confirm, otherwise `false`/`null`.
class TuConfirmDialog extends StatefulWidget {
  const TuConfirmDialog({
    super.key,
    this.title,
    this.content,
    this.contentAlign,
    required this.confirmButton,
    this.tentativeButton,
    this.cancelButton,
    this.textField,
    this.buttonLayout = Axis.horizontal,
    this.isDestructive = false,
    this.canConfirm = true,
    this.closesOnConfirm = true,
    this.canPop = true,
    this.onConfirm,
    this.onTentative,
    this.onCancel,
  });

  final String? title;
  final String? content;
  final TextAlign? contentAlign;
  final String confirmButton;
  final String? tentativeButton;
  final String? cancelButton;
  final TuTextField? textField;
  final Axis buttonLayout;
  final bool isDestructive;
  final bool canConfirm;
  final bool closesOnConfirm;
  final bool canPop;
  final VoidCallback? onConfirm;
  final VoidCallback? onTentative;
  final VoidCallback? onCancel;

  /// Simplified confirm dialog.
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? content,
    TextAlign? contentAlign,
    String confirmButton = 'OK',
    String? tentativeButton,
    String? cancelButton,
    Axis buttonLayout = Axis.horizontal,
    bool isDestructive = false,
    bool canDismiss = true,
    bool closesOnConfirm = true,
    bool useRootNavigator = false,
    TextEditingController? textController,
    FocusNode? textFocusNode,
    String? hintText,
    VoidCallback? onConfirm,
    VoidCallback? onTentative,
    VoidCallback? onCancel,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    assert(
      (title?.isNotEmpty ?? false) ||
          (content?.isNotEmpty ?? false) ||
          textController != null,
      'At least one of title, content, or text field must be provided',
    );

    final hasTextField = textController != null;
    final controller = textController;

    if (hasTextField && controller != null) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: canDismiss,
        useRootNavigator: useRootNavigator,
        builder: (context) => ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) => TuConfirmDialog(
            title: title,
            content: content,
            contentAlign: contentAlign,
            confirmButton: confirmButton,
            tentativeButton: tentativeButton,
            cancelButton: cancelButton,
            textField: TuTextField.primary(
              controller: controller,
              focusNode: textFocusNode,
              hintText: hintText,
              textInputAction: TextInputAction.done,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: (submitted) {
                if (submitted.isEmpty) {
                  return;
                }
                Navigator.of(context).maybePop(true);
                onSubmitted?.call(submitted);
                onConfirm?.call();
              },
            ),
            canConfirm: value.text.isNotEmpty,
            buttonLayout: buttonLayout,
            isDestructive: isDestructive,
            closesOnConfirm: closesOnConfirm,
            canPop: canDismiss,
            onConfirm: onConfirm,
            onTentative: onTentative,
            onCancel: onCancel,
          ),
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: canDismiss,
      useRootNavigator: useRootNavigator,
      builder: (context) => TuConfirmDialog(
        title: title,
        content: content,
        contentAlign: contentAlign,
        confirmButton: confirmButton,
        tentativeButton: tentativeButton,
        cancelButton: cancelButton,
        buttonLayout: buttonLayout,
        isDestructive: isDestructive,
        closesOnConfirm: closesOnConfirm,
        canPop: canDismiss,
        onConfirm: onConfirm,
        onTentative: onTentative,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<TuConfirmDialog> createState() => _TuConfirmDialogState();
}

class _TuConfirmDialogState extends State<TuConfirmDialog> {
  late final ScrollController _contentScrollController;

  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController();
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final shouldAlignToKeyboard = widget.textField != null && keyboardInset > 0;

    final contentBlocks = <Widget>[
      if (widget.title case final text? when text.isNotEmpty)
        Align(
          alignment: Alignment.center,
          child: Text(
            text,
            style: styles.title[4],
            textAlign: TextAlign.center,
          ),
        ),
      if (widget.content case final text? when text.isNotEmpty) ...[
        if (widget.title?.isNotEmpty ?? false) SizedBox(height: 16.aw),
        Flexible(
          child: Scrollbar(
            controller: _contentScrollController,
            child: SingleChildScrollView(
              controller: _contentScrollController,
              child: Align(
                alignment: switch (widget.contentAlign) {
                  TextAlign.center => Alignment.center,
                  TextAlign.right => Alignment.centerRight,
                  _ => Alignment.centerLeft,
                },
                child: Text(
                  text,
                  style: styles.body[2],
                  textAlign: widget.contentAlign,
                ),
              ),
            ),
          ),
        ),
      ],
      if (widget.textField case final field?) ...[
        if ((widget.title?.isNotEmpty ?? false) ||
            (widget.content?.isNotEmpty ?? false))
          SizedBox(height: 24.aw),
        field,
      ],
    ];

    assert(
      contentBlocks.isNotEmpty,
      'At least one of title, content or textField must be provided',
    );

    final actions = _buildActions();
    final layout = _resolveButtonLayout(actions.length);
    final buttonHorizontalPadding = switch (layout) {
      Axis.vertical => 90.aw,
      Axis.horizontal => actions.length == 1 ? 90.aw : 0.0,
    };

    return Material(
      type: MaterialType.transparency,
      child: PopScope(
        canPop: widget.canPop,
        child: SafeArea(
          child: Align(
            alignment: shouldAlignToKeyboard
                ? Alignment.bottomCenter
                : Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(
                left: 32.aw,
                right: 32.aw,
                bottom: shouldAlignToKeyboard ? keyboardInset + 100.aw : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 500.aw,
                  maxWidth: 500.aw,
                  maxHeight: 700.aw,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.bg.secondary,
                    borderRadius: BorderRadius.circular(20.aw),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 48.aw,
                            bottom: 0,
                            left: 36.aw,
                            right: 36.aw,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: contentBlocks,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 36.aw,
                          bottom: 36.aw,
                          left: buttonHorizontalPadding,
                          right: buttonHorizontalPadding,
                        ),
                        child: _buildButtonsContainer(layout, actions),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Axis _resolveButtonLayout(int buttonCount) {
    if (buttonCount <= 1) {
      return Axis.vertical;
    }
    if (widget.buttonLayout == Axis.horizontal && buttonCount > 2) {
      return Axis.vertical;
    }
    return widget.buttonLayout;
  }

  List<_DialogActionButton> _buildActions() {
    return [
      if (widget.cancelButton case final label? when label.isNotEmpty)
        _DialogActionButton(
          label: label,
          onPressed: _handleCancel,
          tone: TuButtonTone.secondary,
        ),
      if (widget.tentativeButton case final label? when label.isNotEmpty)
        _DialogActionButton(
          label: label,
          onPressed: _handleTentative,
          tone: TuButtonTone.secondary,
        ),
      _DialogActionButton(
        label: widget.confirmButton,
        onPressed: _handleConfirm,
        tone: widget.isDestructive ? TuButtonTone.error : TuButtonTone.neutral,
        isDisabled: !widget.canConfirm,
      ),
    ];
  }

  Widget _buildButtonsContainer(
    Axis layout,
    List<_DialogActionButton> actions,
  ) {
    if (layout == Axis.horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 32.aw,
        children: actions
            .map((action) => _buildButton(action, layout))
            .toList(growable: false),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 24.aw,
      children: actions.reversed
          .map((action) => _buildButton(action, layout))
          .toList(growable: false),
    );
  }

  Widget _buildButton(_DialogActionButton action, Axis layout) {
    return TuButton.builder(
      (builder) => builder.small
        ..tone = action.tone
        ..width = switch (layout) {
          Axis.horizontal => TuButtonWidth.fixedWidth,
          Axis.vertical => TuButtonWidth.wide,
        },
      onPressed: action.onPressed,
      label: action.label,
      isDisabled: action.isDisabled,
    );
  }

  void _handleCancel() {
    Navigator.of(context).maybePop(false);
    widget.onCancel?.call();
  }

  void _handleTentative() {
    Navigator.of(context).maybePop(false);
    widget.onTentative?.call();
  }

  void _handleConfirm() {
    if (widget.closesOnConfirm) {
      Navigator.of(context).maybePop(true);
    }
    widget.onConfirm?.call();
  }
}

class _DialogActionButton {
  const _DialogActionButton({
    required this.label,
    required this.onPressed,
    required this.tone,
    this.isDisabled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final TuButtonTone tone;
  final bool isDisabled;
}
