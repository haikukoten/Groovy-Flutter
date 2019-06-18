import 'package:Groovy/providers/ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'dart:math' as math;

Widget showCircularProgress(BuildContext context) {
  var uiProvider = Provider.of<UIProvider>(context);
  if (uiProvider.isLoading) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.grey[100].withOpacity(0.8),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
  return Container(
    height: 0.0,
    width: 0.0,
  );
}

Widget onBottom(Widget child) {
  return Positioned.fill(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: child,
    ),
  );
}

Future<void> showInputDialog(BuildContext context, Color color, Text title,
    String message, FlatButton submit,
    [Widget inputs, Function func]) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: new ImageFilter.blur(
          sigmaX: 5.0,
          sigmaY: 5.0,
        ),
        child: AlertDialog(
          backgroundColor: color,
          title: title,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                message != "" ? Text(message) : SizedBox.shrink(),
                inputs,
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          actions: <Widget>[
            FlatButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            submit,
          ],
        ),
      );
    },
  );
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange})
      : assert(decimalRange == null || decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    if (decimalRange != null) {
      String value = newValue.text;

      if (value.contains(".") &&
          value.substring(value.indexOf(".") + 1).length > decimalRange) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      } else if (value == ".") {
        truncated = "0.";

        newSelection = newValue.selection.copyWith(
          baseOffset: math.min(truncated.length, truncated.length + 1),
          extentOffset: math.min(truncated.length, truncated.length + 1),
        );
      }

      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}
