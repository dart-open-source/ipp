import 'dart:io';
import 'package:ipp/ipp.dart';

Future<void> main() async {
  IppPack.ip='192.168.199.124';

  //  Print file and Get Job Status
  var pack = IppPack(sendFile: File('/Users/alm/StudioProjects/bbys/java/assets/test.pdf'));

  //Job Attributes *** Warning *** ; Some printers not accept
  pack.putJobAttributes({'tag': 68, 'key': 'sides', 'val': 'two-sided-long-edge'});
  pack.putJobAttributes({'tag': 68, 'key': 'print-scaling', 'val': 'fill'});
  pack.putJobAttributes({'tag': 68, 'key': 'print-color-mode', 'val': 'color'});
  pack.putJobAttributes({'tag': 51, 'key': 'page-ranges', 'val': '0000000100000002'});

  print('req ${pack.buildHex()}');
  print('req ${pack}');
  var res=await pack.request();
  print('res $res');
  if(IppCodec.reqSuccessful(res.code)){
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
