import 'package:alm/alm.dart';
import 'package:html/parser.dart';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import 'codec.dart';

// ignore: non_constant_identifier_names
final NetPrinter = _NetPrinter();

class _NetPrinter {

  bool debug = false;

  Duration timeout=Duration(seconds: 5);

  String listName = 'EPSON:CANON:HP:ERROR';

  List<String> get brandList => listName.split(':');

  Map requestStatusMap = {
    'CANON': 'JS_MDL/model.js?ver=1.110-1791-005',
    'EPSON': 'PRESENTATION/ADVANCED/INFO_PRTINFO/TOP',
    'HP': 'DevMgmt/ProductStatusDyn.xml',
  };

  String brand = 'ERROR';
  String reason = 'UnAvailable';

  String get status => '$brand-$code-$reason';
  int code = IppCodec.PRINT_UNKNOWN;

  Map<String, int> pairCodes = {
    'UnAvailable': IppCodec.PRINT_OFFLINE,
    'Available': IppCodec.PRINT_IDLE,
    'Busy': IppCodec.PRINT_PROCESSING,
    'Paperout': IppCodec.PRINT_ERROR,
    'ready': IppCodec.PRINT_IDLE,
    'inPowerSave': IppCodec.PRINT_IDLE,
    'trayClosed': IppCodec.PRINT_IDLE,
    'processing': IppCodec.PRINT_PROCESSING,
    'initializing': IppCodec.PRINT_PROCESSING,
    'inkSystemInitializing': IppCodec.PRINT_PROCESSING,
    'jamInPrinter': IppCodec.PRINT_JAM,
    'closeDoorOrCover': IppCodec.PRINT_ERROR,
    'insertOrCloseTray': IppCodec.PRINT_ERROR,
    'trayEmptyOrOpen': IppCodec.PRINT_ERROR,
    'shuttingDown': IppCodec.PRINT_ERROR,
    'cartridgeMissing': IppCodec.PRINT_ERROR,
    'IDLE': IppCodec.PRINT_IDLE,
    'DWS_ETC': IppCodec.PRINT_IDLE,
    'DOC_ETC': IppCodec.PRINT_IDLE,
    'DOC_1300_ETC': IppCodec.PRINT_JAM,
    'DOC_1008': IppCodec.PRINT_ERROR,
    'DOC_1200': IppCodec.PRINT_ERROR,
    'DOC_1600': IppCodec.PRINT_ERROR,
  };

  bool get isEpson => brand == 'EPSON';

  bool get isCanon => brand == 'CANON';

  bool get isHp => brand == 'HP';

  bool get hasPrinter => (isHp || isEpson || isCanon) ? true : false;

  String ip = '192.168.8.8';

  Map<String, String> headers = {
    'Accept': '*/*',
    'Connection': 'keep-alive',
    'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 Alm/1.0 (AlmPazel@Gmail)',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  String get basicUrl => 'https://$ip';

  HttpClient httpClient = HttpClient()..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

  IOClient get ioClient => IOClient(httpClient..idleTimeout = Duration(seconds: 1));

  Future<Response> request(url, {dynamic body}) async {
    headers['Client-Time'] = DateTime.now().toString();
    if (isEpson) headers['Cookie'] = 'EPSON_COOKIE_LANG=lang_b&1/lang_a&1';
    Response response;
    if (body != null) {
      response = await ioClient.post('$basicUrl/$url', body: body, headers: headers).timeout(timeout, onTimeout: () => null);
    } else {
      response = await ioClient.get('$basicUrl/$url', headers: headers).timeout(timeout, onTimeout: () => null);
    }
    try {
      if (debug) print('${url}->response.statusCode:${response.statusCode} $status');
      response.headers.forEach((key, value) {
        if (key.toUpperCase() == 'SERVER') {
          var serverName = value.toUpperCase().replaceAll('KS_HTTP', 'KS_HTTP CANON ');
          for (var b in brandList) {
            if (serverName.split(' ').contains(b)) {
              brand = b;
            }
          }
        }
      });
    } catch (e) {
      brand = 'ERROR';
    }
    return response;
  }

  Future<String> statusCheck() async {
    try {
      if (!hasPrinter) await request('index.html');

      if (!hasPrinter) throw Exception();

      var response = (await request(requestStatusMap[brand])) ?? (await request(requestStatusMap[brand]));
      if (response == null) throw Exception();

      if (isCanon) {
        var list = response.body.split('\n');
        for (var element in list) {
          var i = element.indexOf('g_err_msg_id');
          if (i != -1) {
            element = element.replaceAll('g_err_msg_id', '');
            element = element.replaceAll('var', '');
            element = element.replaceAll('=', '');
            element = element.replaceAll('\'', '');
            element = element.replaceAll(';', '');
            element = element.replaceAll('HTTP_ERR_DISP_', '');
            element = element.trim();
            reason = element;
            break;
          }
        }
      }
      if (isEpson) {
        var document = parse(response.body);
        var sd = document.getElementsByTagName('fieldset');
        var element = sd[2].nodes[1].text.replaceAll(' ', '').replaceAll('.', '').trim();
        //use simpler both hp and epson printers
        element = element.replaceAll('Thepapercassetteisnotsetcorrectly', 'Papercase');
        element = element.replaceAll('Papercase', 'insertOrCloseTray');
        element = element.replaceAll('AnerrorhasoccurredPleaseconfirmtheindicatorormessageontheproduct', 'closeDoorOrCover');
        reason = element.replaceAll('Paperjam', 'jamInPrinter');
      }
      if (isHp) {
        final alphanumeric = RegExp(r'<(\w+:\w+)>(.*)</\1>', multiLine: true, caseSensitive: true).allMatches(response.body);
        var info = <String, String>{};
        alphanumeric.forEach((element) {
          info[element.group(1)] = element.group(2);
        });
        reason = info['pscat:StatusCategory'];
      }
    } catch (e) {
      reason = 'UnAvailable';
    }
    code = pairCodes[reason];
    return reason;
  }

  ///============================== Epson ==============================

  Future<dynamic> config({bool isDuplex = false, bool isGray = false, int copies = 1}) async {
    var body = {
      'INPUTT_TOPOFFSET': '0.0',
      'INPUTT_LEFTOFFSET': '0.0',
      'INPUTT_TOPOFFSETBACK': '0.0',
      'INPUTT_LEFTOFFSETBACK': '0.0',
      'INPUTR_CHECKPAPERWIDTH': 'OFF',
      'INPUTR_SKIPBLANKPAGE': 'OFF',
      'INPUTD_PAPERSIZE': 'A4',
      'INPUTD_PAPERTYPE': 'PLANE',
      'INPUTD_ORIENTATION': 'PORTRAIT',
      'INPUTD_QUALITY': 'STANDARD',
      'INPUTR_INKSAEMODE': 'OFF',
      'INPUTD_PRINTORDER': 'LASTTOP',
      'INPUTT_NUMOFCOPY': '$copies',
      'INPUTD_BINDINGMARGIN': 'LEFT',
      'INPUTR_AUTOPAPEREJECT': 'OFF',
      'INPUTR_TWOSIDEPRINT': isDuplex ? 'ON' : 'OFF',
      'INPUTD_FONTSOURCE': 'RESIDENT',
      'INPUTT_FONTNUMBER': '0',
      'INPUTT_FONTPITCHINT': '10',
      'INPUTT_FONTPITCHDEC': '00',
      'INPUTT_POINTSIZEINT': '12',
      'INPUTD_POINTSIZEDEC': '00',
      'INPUTD_SYMBOLSET': 'IBM_US',
      'INPUTT_FORM': '64',
      'INPUTD_CRFUNCTION': 'CR',
      'INPUTD_LFFUNCTION': 'LF',
      'INPUTD_TRAYASSIGN': 'TRAYASSIGN4K',
      'INPUTR_PS3ERRORSHEET': 'OFF',
      'INPUTD_COLORATION': isGray ? 'MONO' : 'COLOR',
      'INPUTR_BINARY': 'OFF',
      'INPUTD_PDFPAGESIZE': 'A4',
    };

    Future<dynamic> responseCall() async {
      var list = [];
      final response = await request('PRESENTATION/ADVANCED/PRINTER_UNIVERSAL/POLL', body: body);
      var document = parse(response.body);
      var lists = document.getElementsByTagName('input');
      lists.forEach((element) {
        var map = Map.from(element.attributes);
        var elementBody = map.toString();
        if (elementBody.contains('INPUTT_NUMOFCOPY') || elementBody.contains('INPUTR_TWOSIDEPRINT') || elementBody.contains('INPUTD_COLORATION')) {
          list.add(map);
        }
      });
      return list;
    }

    await responseCall();
    await Alm.delaySecond(3);
    return await responseCall();
  }

  Future<String> snapshot([String path = '/sdcard/panel_snapshot.jpg']) async {
    final response = await request('PRESENTATION/ADVANCED/INFO_PANELSNAPSHOT/TOP', body: {});
    var document = parse(response.body);
    if (debug) print('document:$document');
    await Alm.delaySecond(3);
    final res = await request('PRESENTATION/ADVANCED/INFO_PANELSNAPSHOT/PANELIMAGE.JPG');
    var file = File(path);
    file.writeAsBytesSync(res.bodyBytes);
    if (debug) print('INFO_PANELSNAPSHOT ${file.path}');
    return file.path;
  }

  Future<bool> _ippProtocolAllow() async {
    try {
      final response = await request('PRESENTATION/ADVANCED/NW_SERVICE_PRTCL/TOP');
      if (response == null) throw Exception();
      var document = parse(response.body);
      var inputs = document.getElementById('INPUTR_IPPNONSECUREALLOW-ALLOWED');
      var res = inputs != null && inputs.attributes.keys.contains('checked');
      return res;
    } catch (e) {}
    return false;
  }

  Future<bool> openIppProtocol() async {
    try {
      var isOpen = await _ippProtocolAllow();
      if (isOpen) return true;
      await request('PRESENTATION/ADVANCED/NW_SERVICE_PRTCL/SET', body: {'INPUTR_IPPNONSECUREALLOW': 'ALLOWED'});
      var timerCounter = 0;
      while (true) {
        timerCounter++;
        if (timerCounter > 10) break;
        await Alm.delaySecond();
        var isOpen = await _ippProtocolAllow();
        if (isOpen) return true;
      }
    } catch (e) {}
    return false;
  }
}
