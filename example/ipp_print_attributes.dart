import 'dart:io';
import 'package:ipp/ipp.dart';

Future<void> main() async {
  IppPack.ip='192.168.199.232';
  //  Printer attributes
  var pack = IppPack(code: IppCodec.OPERATION_GET_PRINTER_ATTRIBUTES);

  var res=await pack.request();
  print('response ${res.code} ${res.reason}');
  // res.attr has a lot keys
  print('response ${res.attr['printer-device-id']}');

  res.attr.forEach((key, value) {
    print('$key:$value');
  });


}
