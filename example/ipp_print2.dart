import 'dart:io';
import 'package:ipp/ipp.dart';

Future<void> main() async {
  IppPack.ip='192.168.199.226';
//  Print file and Get Job Status
  var pack = IppPack(sendFile: File('/Users/alm/StudioProjects/bbys/java/assets/test.pdf'));
  var res=await pack.request();
  print('response $res');
  if(res.code==IppCodec.successfulOk){
    var jobUrl=res.attr['job-uri'];
    while(true){
      await Future.delayed(Duration(seconds: 1));
      var jobRes=await IppPack(jobUrl: jobUrl).request();
      if(jobRes.code==IppCodec.successfulOk){
        var jobState=int.parse(jobRes.attr['job-state'].toString());
        print('jobState: $jobState');
        if(jobState>IppCodec.JOB_PROCESSING) break;
      }else{
        break;
      }
    }
  }

}
