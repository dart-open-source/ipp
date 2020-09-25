
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

  static bool reqSuccessful(int code) => [
    successfulOk,
    successfulOkIgnoredOrSubstitutedAttributes,
    successfulOkConflictingAttributes,
    successfulOkIgnoredSubscriptions,
    successfulOkTooManyEvents,
    successfulOkEventsComplete,
  ].contains(code);

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

  /// "print-state" is custom from job-state;
  static const int PRINT_IDLE = 2;
  static const int PRINT_PENDING = 3;
  static const int PRINT_PENDING_HELD = 4;
  static const int PRINT_PROCESSING = 5;
  static const int PRINT_STOPPED = 6;
  static const int PRINT_CANCELED = 7;
  static const int PRINT_ABORTED = 8;
  static const int PRINT_COMPLETED = 9;
  static const int PRINT_JAM = 10;
  static const int PRINT_OFFLINE = 11;
  static const int PRINT_ERROR = 12;
  static const int PRINT_UNKNOWN = 13;
  static const int PRINT_TIMEOUT = 14;
}
