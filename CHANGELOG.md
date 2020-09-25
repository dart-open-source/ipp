## 1.0.7
- add net-printer status include only canon epson hp printers;
- epson printer can auto open [IPP NON SECURE ALLOW] 

## 1.0.6
- add Future<IppPack> request.timeout param. return never null !!;

## 1.0.5
- add putOperationAttributes and putJobAttributes function and improve code logic

## 1.0.4

- open to public _body Byte Arrays, can directly set;

## 1.0.3

- open to public some private variables for more accessibility,
  HP printer request need add header connection and transform-encoding chunk type,
  Epson and Canon can directly detected this type 
  

## 1.0.2

- add get jobs and cancel jobs, more information see example folder.

## 1.0.1

- first version release

## 1.0.0

- Initial version, created by Stagehand