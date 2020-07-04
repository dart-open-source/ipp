import 'package:ipp/ipp.dart';

Future<void> main() async {
  IppPack.ip='192.168.199.232';
  var pack = IppPack(code: IppCodec.OPERATION_GET_PRINTER_ATTRIBUTES);
  var res = await pack.request();
  print('response ${res.attr}');

//  Print file and Get Job Status
//  var pack = IppPack(sendFile: File('/Users/alm/StudioProjects/bbys/java/assets/test.pdf'));
//  var res=await pack.request();
//  print('response $res');
//  if(res.code==IppCodec.successfulOk){
//    var jobUrl=res.attr['job-uri'];
//    while(true){
//      await Future.delayed(Duration(seconds: 1));
//      var jobRes=await IppPack(jobUrl: jobUrl).request();
//      if(jobRes.code==IppCodec.successfulOk){
//        var jobState=int.parse(jobRes.attr['job-state'].toString());
//        print('jobState: $jobState');
//        if(jobState>5) break;
//      }else{
//        break;
//      }
//    }
//  }

}
