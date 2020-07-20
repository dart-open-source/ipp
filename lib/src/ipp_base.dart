import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/io_client.dart';
import 'package:convert/convert.dart';

/// Author AlmPazel
/// Copyright 2020 Alm.Pazel
/// License-Identifier: MIT
/// https://www.iana.org/assignments/ipp-registrations/ipp-registrations.xml, updated on 2020-02-20
/// used References:
/// ipp.codec
/// ipp.pwg
/// https://github.com/HPInc/jipp
/// https://en.wikipedia.org/wiki/Internet_Printing_Protocol

class IppPack {
  String _hex;

  static String ip = '192.168.8.8';
  static String url = 'http://$ip:631/ipp/print';

  static Map headerUtf8 = {'tag': 71, 'key': 'attributes-charset', 'val': 'utf-8'};
  static Map headerLang = {'tag': 72, 'key': 'attributes-natural-language', 'val': 'en-us'};
  static Map headerContentType = {'tag': 73, 'key': 'document-format', 'val': 'application/octet-stream'};
  static Map headerUrl = {'tag': 69, 'key': 'printer-uri', 'val': 'ipp://$ip:631/ipp/print'};

  int version = 0x200;
  int code = IppCodec.DEFAULT_CODE;
  int requestId = IppCodec.DEFAULT_REQUEST_ID;

  String reason = '';

  @override
  String toString() {
    return 'IppPack{version: ${version.toRadixString(16)}, code: $code,reason: $reason, requestId: $requestId, attr: $attr}';
  }

  Map<int, List<Map>> attrs = {};
  Map<String, dynamic> attr = {};

  int currentTag = 0;
  String currentKey;

  Uint8List _body;

  IppPack({String decode, String jobUrl, File sendFile, int code}) {
    if (decode != null) {
      _decode(decode);
    } else {

      if (jobUrl != null) {
        this.code = IppCodec.OPERATION_GET_JOB_ATTRIBUTES;
      } else if (sendFile != null) {
        this.code = IppCodec.OPERATION_PRINT_JOB;
        _body = sendFile.readAsBytesSync();
      }

      if (code != null) {
        this.code = code;
      }

      switch (this.code) {
        case IppCodec.OPERATION_GET_PRINTER_ATTRIBUTES:
        case IppCodec.OPERATION_GET_JOBS:
          attrs = {
            1: [headerUtf8, headerLang, headerUrl]
          };
          break;
        case IppCodec.OPERATION_GET_JOB_ATTRIBUTES:
          attrs = {
            1: [
              headerUtf8,
              headerLang,
              {'tag': 69, 'key': 'job-uri', 'val': jobUrl}
            ]
          };
          break;
          case IppCodec.OPERATION_CANCEL_JOB:
          attrs = {
            1: [
              headerUtf8,
              headerLang,
              {'tag': 69, 'key': 'job-uri', 'val': jobUrl}
            ]
          };
          break;
        case IppCodec.OPERATION_PRINT_JOB:
          attrs = {
            1: [headerUtf8, headerLang, headerUrl,headerContentType]
          };
          break;
      }
    }
  }




  void _decode(String d) {
    _hex = d;
    if (_hex.isEmpty) return;
    version = readShort();
    code = readShort();
    reason = IppCodec.reason[code] ?? 'none';
    requestId = readInt();
    while (_hex.isNotEmpty) {
      var res = readAttributes();
      if (res is int) {
        if (res == 0x03) {
          break;
        }
        currentTag = res;
      }
      if (res is Map) {
        if (attrs[currentTag] == null) attrs[currentTag] = [];
        attrs[currentTag].add(res);
      }
    }
  }

  bool isDelimiter(int tag) {
    return 0x01 <= tag && 0x0f >= tag;
  }

  bool isOutOfBand(int tag) {
    return 0x10 <= tag && 0x1f >= tag;
  }

  dynamic readAttributes() {
    var tag = readTag();
    if (isDelimiter(tag)) return tag;
    var key = readStr(readLen());
    if (key.isNotEmpty) currentKey = key;
    var val;

    switch (tag) {
      case 0x21: //int value
        val = readInt(readLen());
        break;
      case 0x22: //bool value
        val = readInt(readLen()) == 1;
        break;
      case 0x23: //enum value
        val = readInt(readLen()).toRadixString(16);
        break;
      case 0x30: //octetString
        val = readStr(readLen());
        break;
      case 0x41: //textWithoutLanguage
      case 0x42: //nameWithoutLanguage
      case 0x44: //keyword
      case 0x45: //uri
      case 0x46: //uriScheme
      case 0x47: //charset
      case 0x48: //naturalLanguage
      case 0x49: //mimeMediaType
      case 0x4A: //memberAttributeName
        val = readStr(readLen());
        break;

      default:
        val = read(readLen());
    }
    if (attr.containsKey(currentKey)) {
      var o = attr[currentKey];
      if (o is List) {
        o.add(val);
        attr[currentKey] = o;
      } else {
        attr[currentKey] = [o, val];
      }
    } else {
      attr[currentKey] = val;
    }
    return {'tag': tag, 'key': currentKey, 'val': val};
  }

  String readHead() {
    return read(16);
  }

  int readShort([int radix = 16]) {
    return int.parse(read(4), radix: radix);
  }

  int readTag() {
    return int.parse(read(2), radix: 16);
  }

  int readLen() {
    return int.parse(read(4), radix: 16) * 2;
  }

  int readInt([int len = 8]) {
    return int.parse(read(len), radix: 16);
  }

  String readStr(int len) {
    return String.fromCharCodes(Uint8List.fromList(hex.decode(read(len))));
  }

  String read(int len) {
    var inf = _hex.substring(0, len);
    _hex = _hex.substring(len);
    return inf;
  }

  String buildHex() {
    _hex = '';
    _hex += version.toRadixString(16).padLeft(4, '0');
    _hex += code.toRadixString(16).padLeft(4, '0');
    _hex += requestId.toRadixString(16).padLeft(8, '0');

    attrs.forEach((key, value) {
      _hex += key.toRadixString(16).padLeft(2, '0');
      if (value is List<Map>) {
        value.forEach((element) {
          element.forEach((key, value) {
            if (key == 'tag') {
              _hex += value.toRadixString(16).padLeft(2, '0');
            }
            if (key == 'key') {
              var ub = value.toString().codeUnits;
              _hex += (ub.length).round().toRadixString(16).padLeft(4, '0');
              _hex += hex.encode(ub);
            }
            if (key == 'val') {
              var ub = value.toString().codeUnits;
              _hex += (ub.length).round().toRadixString(16).padLeft(4, '0');
              _hex += hex.encode(ub);
            }
          });
        });
      }
    });
    return (_hex + '03').toUpperCase();
  }

  Uint8List build() {
    var byteList = hex.decode(buildHex());
    if (_body != null) byteList = byteList + _body.toList();
    return Uint8List.fromList(byteList);
  }

  static var ioClient = IOClient(HttpClient()..idleTimeout = Duration(milliseconds: 600));

  Future<IppPack> request({Map<String, String> headers}) async {
    var headersMap=headers??{};
    headersMap['Content-type']='application/ipp';
    headersMap['connection']='keep-alive';
    headersMap['transfer-encoding']='chunked';

    final response = await ioClient.post(url, body: build(), headers: headersMap);
    if (response.statusCode == 200) {
      return IppPack(decode: hex.encode(response.bodyBytes));
    } else {
      return IppPack(code: IppCodec.clientErrorBadRequest);
    }
  }
}

class IppCodec {
  static const int DEFAULT_VERSION_NUMBER = 0x0200;
  static const int DEFAULT_REQUEST_ID = 1;
  static const int DEFAULT_CODE = 0;

  //status code
  static const int successfulOk = 0x0000;
  static const int successfulOkIgnoredOrSubstitutedAttributes = 0x0001;
  static const int successfulOkConflictingAttributes = 0x0002;
  static const int successfulOkIgnoredSubscriptions = 0x0003;
  static const int successfulOkTooManyEvents = 0x0005;
  static const int successfulOkEventsComplete = 0x0007;

  static const int clientErrorBadRequest = 0x0400;
  static const int clientErrorForbidden = 0x0401;
  static const int clientErrorNotAuthenticated = 0x0402;
  static const int clientErrorNotAuthorized = 0x0403;
  static const int clientErrorNotPossible = 0x0404;
  static const int clientErrorTimeout = 0x0405;
  static const int clientErrorNotFound = 0x0406;
  static const int clientErrorGone = 0x0407;

  static const int clientErrorRequestEntityTooLarge = 0x0408;
  static const int clientErrorRequestValueTooLong = 0x0409;
  static const int clientErrorDocumentFormatNotSupported = 0x040A;
  static const int clientErrorAttributesOrValuesNotSupported = 0x040B;
  static const int clientErrorUriSchemeNotSupported = 0x040C;
  static const int clientErrorCharsetNotSupported = 0x040D;
  static const int clientErrorConflictingAttributes = 0x040E;
  static const int clientErrorCompressionNotSupported = 0x040F;
  static const int clientErrorCompressionError = 0x0410;
  static const int clientErrorDocumentFormatError = 0x0411;
  static const int clientErrorDocumentAccessError = 0x0412;
  static const int clientErrorAttributesNotSettable = 0x0413;
  static const int clientErrorIgnoredAllSubscriptions = 0x0414;
  static const int clientErrorTooManySubscriptions = 0x0415;
  static const int clientErrorDocumentPasswordError = 0x0418;
  static const int clientErrorDocumentPermissionError = 0x0419;
  static const int clientErrorDocumentSecurityError = 0x041A;
  static const int clientErrorDocumentUnprintableError = 0x041B;
  static const int clientErrorAccountInfoNeeded = 0x041C;
  static const int clientErrorAccountClosed = 0x041D;
  static const int clientErrorAccountLimitReached = 0x041E;
  static const int clientErrorAccountAuthorizationFailed = 0x041F;
  static const int clientErrorNotFetchable = 0x0420;
  static const int serverErrorInternalError = 0x0500;
  static const int serverErrorOperationNotSupported = 0x0501;
  static const int serverErrorServiceUnavailable = 0x0502;
  static const int serverErrorVersionNotSupported = 0x0503;
  static const int serverErrorDeviceError = 0x0504;
  static const int serverErrorTemporaryError = 0x0505;
  static const int serverErrorNotAcceptingJobs = 0x0506;
  static const int serverErrorBusy = 0x0507;
  static const int serverErrorJobCanceled = 0x0508;
  static const int serverErrorMultipleDocumentJobsNotSupported = 0x0509;
  static const int serverErrorPrinterIsDeactivated = 0x050A;
  static const int serverErrorTooManyJobs = 0x050B;
  static const int serverErrorTooManyDocuments = 0x050C;

  static Map reason = {
    successfulOk: 'successfulOk',
    successfulOkIgnoredOrSubstitutedAttributes: 'successfulOkIgnoredOrSubstitutedAttributes',
    successfulOkConflictingAttributes: 'successfulOkConflictingAttributes',
    successfulOkIgnoredSubscriptions: 'successfulOkIgnoredSubscriptions',
    successfulOkTooManyEvents: 'successfulOkTooManyEvents',
    successfulOkEventsComplete: 'successfulOkEventsComplete',
    clientErrorBadRequest: 'clientErrorBadRequest',
    clientErrorForbidden: 'clientErrorForbidden',
    clientErrorNotAuthenticated: 'clientErrorNotAuthenticated',
    clientErrorNotAuthorized: 'clientErrorNotAuthorized',
    clientErrorNotPossible: 'clientErrorNotPossible',
    clientErrorTimeout: 'clientErrorTimeout',
    clientErrorNotFound: 'clientErrorNotFound',
    clientErrorGone: 'clientErrorGone',
    clientErrorRequestEntityTooLarge: 'clientErrorRequestEntityTooLarge',
    clientErrorRequestValueTooLong: 'clientErrorRequestValueTooLong',
    clientErrorDocumentFormatNotSupported: 'clientErrorDocumentFormatNotSupported',
    clientErrorAttributesOrValuesNotSupported: 'clientErrorAttributesOrValuesNotSupported',
    clientErrorUriSchemeNotSupported: 'clientErrorUriSchemeNotSupported',
    clientErrorCharsetNotSupported: 'clientErrorCharsetNotSupported',
    clientErrorConflictingAttributes: 'clientErrorConflictingAttributes',
    clientErrorCompressionNotSupported: 'clientErrorCompressionNotSupported',
    clientErrorCompressionError: 'clientErrorCompressionError',
    clientErrorDocumentFormatError: 'clientErrorDocumentFormatError',
    clientErrorDocumentAccessError: 'clientErrorDocumentAccessError',
    clientErrorAttributesNotSettable: 'clientErrorAttributesNotSettable',
    clientErrorIgnoredAllSubscriptions: 'clientErrorIgnoredAllSubscriptions',
    clientErrorTooManySubscriptions: 'clientErrorTooManySubscriptions',
    clientErrorDocumentPasswordError: 'clientErrorDocumentPasswordError',
    clientErrorDocumentPermissionError: 'clientErrorDocumentPermissionError',
    clientErrorDocumentSecurityError: 'clientErrorDocumentSecurityError',
    clientErrorDocumentUnprintableError: 'clientErrorDocumentUnprintableError',
    clientErrorAccountInfoNeeded: 'clientErrorAccountInfoNeeded',
    clientErrorAccountClosed: 'clientErrorAccountClosed',
    clientErrorAccountLimitReached: 'clientErrorAccountLimitReached',
    clientErrorAccountAuthorizationFailed: 'clientErrorAccountAuthorizationFailed',
    clientErrorNotFetchable: 'clientErrorNotFetchable',
    serverErrorInternalError: 'serverErrorInternalError',
    serverErrorOperationNotSupported: 'serverErrorOperationNotSupported',
    serverErrorServiceUnavailable: 'serverErrorServiceUnavailable',
    serverErrorVersionNotSupported: 'serverErrorVersionNotSupported',
    serverErrorDeviceError: 'serverErrorDeviceError',
    serverErrorTemporaryError: 'serverErrorTemporaryError',
    serverErrorNotAcceptingJobs: 'serverErrorNotAcceptingJobs',
    serverErrorBusy: 'serverErrorBusy',
    serverErrorJobCanceled: 'serverErrorJobCanceled',
    serverErrorMultipleDocumentJobsNotSupported: 'serverErrorMultipleDocumentJobsNotSupported',
    serverErrorPrinterIsDeactivated: 'serverErrorPrinterIsDeactivated',
    serverErrorTooManyJobs: 'serverErrorTooManyJobs',
    serverErrorTooManyDocuments: 'serverErrorTooManyDocuments',
  };

  //operation
  static const int OPERATION_PRINT_JOB = 0x0002;
  static const int OPERATION_PRINT_URI = 0x0003;
  static const int OPERATION_VALIDATE_JOB = 0x0004;
  static const int OPERATION_CREATE_JOB = 0x0005;
  static const int OPERATION_SEND_DOCUMENT = 0x0006;
  static const int OPERATION_SEND_URI = 0x0007;
  static const int OPERATION_CANCEL_JOB = 0x0008;
  static const int OPERATION_GET_JOB_ATTRIBUTES = 0x0009;
  static const int OPERATION_GET_JOBS = 0x000A;
  static const int OPERATION_GET_PRINTER_ATTRIBUTES = 0x000B;
  static const int OPERATION_HOLD_JOB = 0x000C;
  static const int OPERATION_DECODE = 0xFFFF;


  /// "job-state" enum as defined in:
  /// [RFC8011](http://www.iana.org/go/rfc8011).

  static const int JOB_PENDING = 3;
  static const int JOB_PENDING_HELD = 4;
  static const int JOB_PROCESSING = 5;
  static const int JOB_PROCESSING_STOPPED = 6;
  static const int JOB_CANCELED = 7;
  static const int JOB_ABORTED = 8;
  static const int JOB_COMPLETED = 9;

}