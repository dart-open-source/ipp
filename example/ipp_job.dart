import 'dart:io';
import 'package:ipp/ipp.dart';

Future<void> main() async {
  IppPack.ip='192.168.199.124';
//  Print file and Get Job Status

  //get jobs
  var packJobs = IppPack(code: IppCodec.OPERATION_GET_JOBS);
  print('response ${packJobs.attrs}');
  var res=await packJobs.request();
  if(res.code==IppCodec.successfulOk){

    var jobUrl=res.attr['job-uri'];
    var jobUrls=[];
    if(jobUrl is List){
      jobUrls=jobUrl;
    }else{
      jobUrls=[jobUrl];
    }

    for(var jobUrlNew in jobUrls){
      await Future.delayed(Duration(seconds: 1));
      //cancel job
      var jobRes=await IppPack(jobUrl: jobUrlNew,code: IppCodec.OPERATION_CANCEL_JOB).request();
      if(jobRes.code==IppCodec.successfulOk){
        print('jobRes: $jobUrlNew canceled now.');
      }else{
        print('jobRes: $jobUrlNew already canceled.');
      }
      break;
    }

  }

}
