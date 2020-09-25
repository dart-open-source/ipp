import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/io_client.dart';
import 'package:convert/convert.dart';

import 'codec.dart';

///
/// About:->
/// Copyright 2020 Alm.Pazel
/// License-Identifier: MIT
///
///
/// Refrences:->
/// https://www.iana.org/assignments/ipp-registrations/ipp-registrations.xml, updated on 2020-02-20
/// https://github.com/HPInc/jipp
/// https://en.wikipedia.org/wiki/Internet_Printing_Protocol
///

class IppPack {
  String _hex;

  static String ip = '192.168.8.8';
  static String url = 'http://$ip:631/ipp/print';

  ///
  /// Example attributes
  ///It need same tag at IPP protocol document, each tag code and name has different values
  ///
  static Map headerUtf8 = {'tag': 71, 'key': 'attributes-charset', 'val': 'utf-8'};
  static Map headerLang = {'tag': 72, 'key': 'attributes-natural-language', 'val': 'en-us'};
  static Map headerContentType = {'tag': 73, 'key': 'document-format', 'val': 'application/octet-stream'};
  static Map headerUrl = {'tag': 69, 'key': 'printer-uri', 'val': 'ipp://$ip:631/ipp/print'};
  static Map headerReqUser = {'tag': 66, 'key': 'requesting-user-name', 'val': 'almpazel@gmail.com'};

  static List hexTags = [51];

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
  String msg='';

  Uint8List body;

  IppPack({String decode, String jobUrl, File sendFile, int code, String msg=''}) {
    this.msg=msg;
    if (decode != null) {
      _decode(decode);
    } else {
      if (jobUrl != null) {
        this.code = IppCodec.OPERATION_GET_JOB_ATTRIBUTES;
      } else if (sendFile != null) {
        this.code = IppCodec.OPERATION_PRINT_JOB;
        body = sendFile.readAsBytesSync();
      }
      if (code != null) this.code = code;

      switch (this.code) {
        case IppCodec.OPERATION_GET_PRINTER_ATTRIBUTES:
        case IppCodec.OPERATION_GET_JOBS:
          putOperationAttributes(headerUtf8);
          putOperationAttributes(headerLang);
          putOperationAttributes(headerUrl);
          break;
        case IppCodec.OPERATION_GET_JOB_ATTRIBUTES:
        case IppCodec.OPERATION_CANCEL_JOB:
          putOperationAttributes(headerUtf8);
          putOperationAttributes(headerLang);
          putOperationAttributes({'tag': 69, 'key': 'job-uri', 'val': jobUrl});
          break;
        case IppCodec.OPERATION_PRINT_JOB:
          putOperationAttributes(headerUtf8);
          putOperationAttributes(headerLang);
          putOperationAttributes(headerUrl);
          putOperationAttributes(headerContentType);
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
        if (res == 0x03) break;
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

    if (operationAttributes.isNotEmpty) attrs[1] = operationAttributes;
    if (jobAttributes.isNotEmpty) attrs[2] = jobAttributes;

    attrs.forEach((key, value) {
      _hex += key.toRadixString(16).padLeft(2, '0');
      if (value is List<Map>) {
        value.forEach((element) {
          var tagCode = 0;
          element.forEach((key, value) {
            if (key == 'tag') {
              tagCode = value;
              _hex += value.toRadixString(16).padLeft(2, '0');
            }
            if (key == 'key') {
              var ub = value.toString().codeUnits;
              _hex += (ub.length).round().toRadixString(16).padLeft(4, '0');
              _hex += hex.encode(ub);
            }
            if (key == 'val') {
              if (hexTags.contains(tagCode)) {
                _hex += (value.length / 2).round().toRadixString(10).padLeft(4, '0');
                _hex += value;
              } else {
                var ub = value.toString().codeUnits;
                _hex += (ub.length).round().toRadixString(16).padLeft(4, '0');
                _hex += hex.encode(ub);
              }
            }
          });
        });
      }
    });
    return (_hex + '03').toUpperCase();
  }

  Uint8List build() {
    var byteList = hex.decode(buildHex());
    if (body != null) byteList = byteList + body.toList();
    return Uint8List.fromList(byteList);
  }

  static IOClient get ioClient => IOClient(HttpClient()..idleTimeout = Duration(milliseconds: 600));

  Future<IppPack> request({Map<String, String> headers, Duration timeout}) async {
    var error='';
    try{
      var headersMap = headers ?? {};
      headersMap['Content-type'] = 'application/ipp';
      headersMap['connection'] = 'keep-alive';
      headersMap['transfer-encoding'] = 'chunked';

      var timeOuted = false;
      final response = await ioClient.post(url, body: build(), headers: headersMap).timeout(timeout??Duration(seconds: 6), onTimeout: () {
        timeOuted = true;
        return null;
      });
      if (response == null) {
        return IppPack(code: timeOuted ? IppCodec.clientErrorTimeout : IppCodec.clientErrorBadRequest);
      }
      if (response.statusCode == 200) {
        return IppPack(decode: hex.encode(response.bodyBytes));
      }
    }catch(e){
      error=e.toString();
    }
    return IppPack(code: IppCodec.clientErrorBadRequest,msg:error);
  }

  List<Map> operationAttributes = [];
  List<Map> jobAttributes = [];

  ///** Get the [Tag.operationAttributes] group and add or replace [attributes] in it.
  ///It need same tag at IPP protocol document, each tag code and name has different values
  IppPack putOperationAttributes(Map value) {
    operationAttributes.add(value);
    return this;
  }

  ///** Get or create the [Tag.jobAttributes] group and add or replace [attributes] in it.
  ///It need same tag at IPP protocol document, each tag code and name has different values
  IppPack putJobAttributes(Map value) {
    jobAttributes.add(value);
    return this;
  }
}

