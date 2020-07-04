A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/almpazel/ipp/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:ipp/ipp.dart';

main() {
  IppPack.ip='192.168.199.232';
  //  Print file and Get Job Status
    var pack = IppPack(sendFile: File('/Users/alm/assets/test.pdf'));
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
          if(jobState>IppCodec) break;
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
