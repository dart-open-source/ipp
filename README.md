A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://gitee.com/darto/ipp/blob/master/LICENSE).

## Usage

This package used to IPP  printing, in flutter also work.

## Tested
- Epson IPP printers;
- HP IPP printers;
- Cannon IPP printers;
- if you need other printers contact with Email.


A simple usage example:

```dart
import 'package:ipp/ipp.dart';

main() {
  //Change your printer ip

  IppPack.ip='192.168.199.232';


  //Print file and Get Job Status
    var pack = IppPack(sendFile: File('/Users/alm/assets/test.pdf'));
    var res=await pack.request();
    print('response $res');
  
    //Get print job status see IppCodec.JOB_* has different Code;
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
```

## References

[wikipedia/Internet_Printing_Protocol](https://en.wikipedia.org/wiki/Internet_Printing_Protocol) 

[HPInc/jipp](https://github.com/HPInc/jipp)

[www.iana.org](https://www.iana.org/assignments/ipp-registrations/ipp-registrations.xml)

[IPP Guide](https://istopwg.github.io/ipp/ippguide.html)
