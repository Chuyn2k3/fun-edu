import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/core/theme/app_themes.dart';
import 'package:fun_edu/data/term/constants.dart';


class InputTextFieldV2 extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  final String? label;
  final String? errorText;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? hintText;
  final Widget? suffixIcon;
  final int? maxLine;
  final TextEditingController? textController;
  final bool enabled;
  final String? Function(String?)? validator;
  final Function(String?)? onSaved;
  final VoidCallback? onTap;
  final bool? isVisiable;
  final TextAlign? textAlign;
  final FocusNode? forcusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired;
  // final bool? isDense;

  const InputTextFieldV2({
    Key? key,
    this.textAlign,
    this.onChanged,
    this.obscureText = false,
    this.prefixIcon,
    this.errorText,
    this.textController,
    this.suffixIcon,
    this.hintText,
    this.maxLine,
    this.label,
    this.enabled = true,
    this.validator,
    this.initialValue,
    this.isVisiable,
    this.onSaved,
    this.onTap,
    this.forcusNode,
    this.keyboardType,
    this.inputFormatters,
    this.isRequired = false,
    // this.isDense,
  }) : super(key: key);

  factory InputTextFieldV2.number({
    ValueChanged<String>? onChanged,
    String? label,
    String? hintText,
    TextEditingController? textController,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    bool enabled = true,
    bool isRequired = true,
    int? maxLine,
  }) {
    return InputTextFieldV2(
      onChanged: onChanged,
      label: label,
      hintText: hintText,
      textController: textController,
      validator: validator,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          return text.isEmpty
              ? newValue
              : double.tryParse(text) == null
                  ? oldValue
                  : newValue;
        }),
      ],
      prefixIcon: prefixIcon,
      enabled: enabled,
      isRequired: isRequired,
      maxLine: maxLine,
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFD8DDE4);
    const double borderRadius = 8;

    const normalBorder = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.all(
        Radius.circular(borderRadius),
      ),
    );

    return Visibility(
      visible: isVisiable ?? true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((label ?? "").isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label ?? "",
                    style: style15grey.copyWith(
                      color: const Color(0xFF17181C),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Visibility(
                    visible: isRequired,
                    child: Text(
                      "*",
                      style: style15grey.copyWith(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          TextFormField(
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            focusNode: forcusNode,
            controller: textController,
            initialValue: initialValue,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppThemes.of(context).appColors.neutral[950],
            ),
            maxLines: maxLine,
            enabled: enabled,
            textAlign: textAlign ?? TextAlign.start,
            validator: validator,
            onSaved: onSaved,
            obscureText: obscureText,
            onTap: onTap,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              hintText: hintText,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFE9ECF1),
              focusColor: Colors.white,
              hoverColor: Colors.white,
              hintStyle: styleHintText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              errorText: errorText,
              errorMaxLines: 2,
              focusedErrorBorder: normalBorder,
              errorBorder: normalBorder,
              focusedBorder: normalBorder,
              enabledBorder: normalBorder,
              disabledBorder: normalBorder,
              // isDense: isDense,
            ),
          ),
        ],
      ),
    );
  }

  static TextFormField create({
    Key? key,
    TextAlign? textAlign,
    ValueChanged<String>? onChanged,
    bool obscureText = false,
    Icon? icon,
    String? errorText,
    TextEditingController? textController,
    IconButton? iconButton,
    String? hintText,
    int? maxLine,
    String? label,
    bool enabled = true,
    String? Function(String?)? validator,
    String? initialValue,
    bool? isVisiable,
    Function(String?)? onSaved,
    VoidCallback? onTap,
    FocusNode? forcusNode,
    Color? fillColor,
  }) {
    return TextFormField(
      focusNode: forcusNode,
      controller: textController,
      initialValue: initialValue,
      onChanged: onChanged,
      style: styleHintText,
      maxLines: maxLine,
      enabled: enabled,
      textAlign: textAlign ?? TextAlign.left,
      validator: validator,
      onSaved: onSaved,
      obscureText: obscureText,
      onTap: onTap,
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: hintText,
          filled: true,
          fillColor: fillColor ?? Colors.white,
          hintStyle: styleHintText,
          prefixIcon: icon,
          label: label == null
              ? null
              : Text(
                  label,
                  style: styleHeadingRow,
                ),
          suffixIcon: iconButton,
          errorText: errorText,
          focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.all(Radius.circular(1))),
          errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.all(Radius.circular(1))),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.all(Radius.circular(1))),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(1))),
          disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(1)))),
    );
  }
}
