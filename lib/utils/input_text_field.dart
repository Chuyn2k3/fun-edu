import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputTextField extends StatelessWidget {
  final bool autoFocus;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? label;
  final String? errorText;
  final bool obscureText;
  final Icon? prefixIcon;
  final String? hintText;
  final TextAlign? textAlign;
  final IconButton? iconButton;
  final int? maxLine;
  final int? maxLength;
  final TextEditingController? textController;
  final bool enabled;
  final String? Function(String?)? validator;
  final Function(String?)? onSaved;
  final InputDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? ontap;
  const InputTextField(
      {Key? key,
      this.autoFocus=false,
      this.onChanged,
      this.focusNode,
      this.obscureText = false,
      this.prefixIcon,
      this.errorText,
      this.textController,
      this.iconButton,
      this.hintText,
      this.maxLine,
      this.label,
      this.enabled = true,
      this.validator,
      this.inputFormatters,
      this.onSaved,
      this.ontap,
      this.textAlign,
      this.decoration,
      this.padding,
      this.maxLength})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: autoFocus,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      onTap: ontap,
      controller: textController,
      onChanged: onChanged,
      style: const TextStyle(
          color: Color(0XFF033544), fontSize: 16, fontWeight: FontWeight.w500),
      maxLines: maxLine,
      enabled: enabled,
      textAlign: textAlign ?? TextAlign.center,
      validator: validator,
      maxLength: maxLength,
      onSaved: onSaved,
      obscureText: obscureText,
      decoration: decoration ??
          InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: hintText,
              filled: true,
              fillColor: Colors.white,
              hintStyle:
                  const TextStyle(color: Color.fromARGB(255, 110, 107, 107)),
              prefixIcon: prefixIcon,
              // label: label == null
              //     ? null
              //     : Text(
              //         label ?? '',
              //         style: PrimaryFont.medium(15)
              //             .copyWith(color: AppColors.greyColor),
              //       ),
              suffixIcon: iconButton,
              errorText: errorText,
              focusedErrorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 233, 231, 231), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8)))),
    );
  }
}
