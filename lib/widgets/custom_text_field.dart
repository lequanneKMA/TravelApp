// // lib/widgets/custom_text_field.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Để dùng FilteringTextInputFormatter

// class CustomTextField extends StatelessWidget {
//   final TextEditingController? controller;
//   final String labelText;
//   final String? hintText;
//   final bool obscureText;
//   final TextInputType? keyboardType;
//   final String? Function(String?)? validator;
//   final Widget? prefixIcon;
//   final Widget? suffixIcon;
//   final Function(String)? onChanged;
//   final Function(String)? onFieldSubmitted;
//   final bool enabled;
//   final int? maxLines;
//   final int? minLines;
//   final List<TextInputFormatter>? inputFormatters;
//   final TextCapitalization textCapitalization;
//   final AutovalidateMode? autovalidateMode;

//   const CustomTextField({
//     super.key,
//     this.controller,
//     required this.labelText,
//     this.hintText,
//     this.obscureText = false,
//     this.keyboardType,
//     this.validator,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.onChanged,
//     this.onFieldSubmitted,
//     this.enabled = true,
//     this.maxLines = 1,
//     this.minLines,
//     this.inputFormatters,
//     this.textCapitalization = TextCapitalization.none,
//     this.autovalidateMode,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: labelText,
//         hintText: hintText,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(color: Colors.grey[400]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: const BorderSide(color: Colors.red, width: 2.0),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
//         ),
//         prefixIcon: prefixIcon,
//         suffixIcon: suffixIcon,
//         contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
//         filled: true,
//         fillColor: enabled ? Colors.white : Colors.grey[100],
//       ),
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       validator: validator,
//       onChanged: onChanged,
//       onFieldSubmitted: onFieldSubmitted,
//       enabled: enabled,
//       maxLines: maxLines,
//       minLines: minLines,
//       inputFormatters: inputFormatters,
//       textCapitalization: textCapitalization,
//       autovalidateMode: autovalidateMode,
//       style: TextStyle(color: Colors.grey[800]),
//       cursorColor: Theme.of(context).primaryColor,
//     );
//   }
// }