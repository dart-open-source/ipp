import 'package:ipp/ipp.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () async {

    IppPack.ip='192.168.199.232';
    var pack = IppPack(code: IppCodec.OPERATION_GET_PRINTER_ATTRIBUTES);
    var res = await pack.request();
    print('response ${res.attr}');
    test('First Test', () {
      expect(res.code, IppCodec.successfulOk);
    });
  });
}
