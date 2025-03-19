**FREE

// Programa de validación de tarjetas
// Definición de campos de entrada

// Estructura para el JSON addl
Dcl-Ds JsonAddl Qualified;
  cmr_id    Zoned(10);
  cmr_bra   Zoned(3);
  service   Char(8);
End-Ds;

// Estructura para la respuesta de autenticación
Dcl-Ds AuthenticateResponse Qualified;
  auth_CardBin        Char(6);
  auth_ThreeDSVersion Char(10);
  auth_SignatureVerif Char(1);
  auth_ErrorDesc      Char(100);
  auth_ThreeDSServerId Char(50);
  auth_Cavv           Char(50);
  auth_Amount         Char(10);
  auth_ErrorNo        Char(5);
  auth_EciFlag        Char(2);
  auth_TransactionId  Char(50);
  auth_CurrencyCode   Char(3);
  auth_DSTransactionId Char(50);
  auth_ACSTransactionId Char(50);
  auth_CardBrand      Char(10);
  auth_PAResStatus    Char(1);
End-Ds;

// Estructura para el JSON 3DS
Dcl-Ds Json3ds Qualified;
  tid                     Char(50);
  cavv                    Char(50);
  // Lookup Response
  Dcl-Ds lookup_response;
    ACSOperatorID        Char(10);
    ErrorNo             Char(5);
    TransactionId       Char(50);
    Payload             Char(500);
    StepUpUrl           Char(100);
    ErrorDesc           Char(100);
    Warning             Char(200);
    Cavv                Char(50);
    PAResStatus         Char(1);
    Enrolled            Char(1);
    ACSTransactionId    Char(50);
    EciFlag             Char(2);
    ACSUrl              Char(100);
    ThreeDSServerTransId Char(50);
    CardBin             Char(6);
    ACSReferenceNumber  Char(50);
    CardBrand           Char(10);
    DSTransactionId     Char(50);
    ThreeDSVersion      Char(10);
    OrderId             Char(20);
    ChallengeRequired   Char(1);
    SignatureVerification Char(1);
  End-Ds;
End-Ds;

Dcl-Pr tJsonExt01 ExtPgm('TJSONEXT01');
  p_Id             Zoned(15);
  p_Pan            Char(19);
  p_Cvv            Char(4);
  p_ExpDate        Char(4);
  p_UserCi         Char(11);
  p_Addl           Char(100);    // JSON string
  p_CellNumber     Char(10);
  p_CardType       Char(10);
  p_CardAddl       Char(8);
  p_3ds            Char(100);    // Campo amplio para manejar diferentes formatos
  p_VisaToken      Char(50);     // Campo para token opcional
End-Pr;

// Variables de trabajo
Dcl-S w_Result     Char(1);
Dcl-S w_Message    Char(50);
Dcl-S w_JsonPos    Int(10);
Dcl-S w_TempVal    Varchar(50);
Dcl-S w_JsonStr    Varchar(1000);
Dcl-S w_StartPos   Int(10);
Dcl-S w_EndPos     Int(10);
Dcl-S w_FieldValue Varchar(500);

// Prototipos de subrutinas
Dcl-PR ExtractJsonValue Varchar(500);
  p_JsonStr Varchar(1000) Const;
  p_FieldName Varchar(50) Const;
End-PR;

Dcl-PR ProcessJsonAddl;
  p_JsonStr Varchar(1000) Const;
End-PR;

Dcl-PR ProcessJson3ds;
  p_JsonStr Varchar(1000) Const;
End-PR;

Dcl-PR ProcessLookupResponse;
  p_JsonStr Varchar(1000) Const;
End-PR;

Dcl-PR ProcessAuthResponse;
  p_JsonStr Varchar(1000) Const;
End-PR;

// Definición del procedimiento principal
Dcl-Pi tJsonExt01;
  p_Id             Zoned(15);
  p_Pan            Char(19);
  p_Cvv            Char(4);
  p_ExpDate        Char(4);
  p_UserCi         Char(11);
  p_Addl           Char(100);    // JSON string
  p_CellNumber     Char(10);
  p_CardType       Char(10);
  p_CardAddl       Char(8);
  p_3ds            Char(100);
  p_VisaToken      Char(50);
End-Pi;

// Inicio de la lógica del programa
Monitor;
  // Procesar JSON addl
  If %Trim(p_Addl) <> *Blanks;
    ProcessJsonAddl(p_Addl);
  EndIf;

  // Procesar JSON 3ds
  If %Trim(p_3ds) <> *Blanks;
    ProcessJson3ds(p_3ds);
  EndIf;

  // Validaciones básicas
  If %Trim(p_Pan) = *Blanks;
    w_Result = 'E';
    w_Message = 'Número de tarjeta requerido';
  EndIf;

  // Validar campos obligatorios del JSON addl
  If JsonAddl.cmr_id = 0;
    w_Result = 'E';
    w_Message = 'CMR ID es requerido';
  EndIf;

  If JsonAddl.cmr_bra = 0;
    w_Result = 'E';
    w_Message = 'CMR BRA es requerido';
  EndIf;

  If %Trim(JsonAddl.service) = *Blanks;
    w_Result = 'E';
    w_Message = 'Service es requerido';
  EndIf;

On-Error;
  w_Result = 'E';
  w_Message = 'Error en el procesamiento del JSON';
EndMon;

*InLr = *On;
Return;

// Implementación de subrutinas
Dcl-Proc ExtractJsonValue;
  Dcl-Pi ExtractJsonValue Varchar(500);
    p_JsonStr Varchar(1000) Const;
    p_FieldName Varchar(50) Const;
  End-Pi;

  w_StartPos = %Scan('"' + p_FieldName + '":': p_JsonStr);
  If w_StartPos > 0;
    // Avanzar hasta después de los dos puntos
    w_StartPos = w_StartPos + %Len(p_FieldName) + 3;

    // Buscar el siguiente valor
    If %Subst(p_JsonStr: w_StartPos: 1) = '"';
      // Es un string
      w_StartPos += 1;
      w_EndPos = %Scan('"': p_JsonStr: w_StartPos);
      If w_EndPos > 0;
        Return %Subst(p_JsonStr: w_StartPos: w_EndPos - w_StartPos);
      EndIf;
    Else;
      // Es un número
      w_EndPos = %Scan(',': p_JsonStr: w_StartPos);
      If w_EndPos = 0;
        w_EndPos = %Scan('}': p_JsonStr: w_StartPos);
      EndIf;
      If w_EndPos > 0;
        Return %Trim(%Subst(p_JsonStr: w_StartPos: w_EndPos - w_StartPos));
      EndIf;
    EndIf;
  EndIf;
  Return '';
End-Proc;

Dcl-Proc ProcessJsonAddl;
  Dcl-Pi ProcessJsonAddl;
    p_JsonStr Varchar(1000) Const;
  End-Pi;

  w_FieldValue = ExtractJsonValue(p_JsonStr: 'cmr_id');
  If w_FieldValue <> '';
    JsonAddl.cmr_id = %Int(w_FieldValue);
  EndIf;

  w_FieldValue = ExtractJsonValue(p_JsonStr: 'cmr_bra');
  If w_FieldValue <> '';
    JsonAddl.cmr_bra = %Int(w_FieldValue);
  EndIf;

  w_FieldValue = ExtractJsonValue(p_JsonStr: 'service');
  If w_FieldValue <> '';
    JsonAddl.service = w_FieldValue;
  EndIf;
End-Proc;

Dcl-Proc ProcessJson3ds;
  Dcl-Pi ProcessJson3ds;
    p_JsonStr Varchar(1000) Const;
  End-Pi;

  // Extraer campos principales
  Json3ds.tid = ExtractJsonValue(p_JsonStr: 'tid');
  Json3ds.cavv = ExtractJsonValue(p_JsonStr: 'cavv');

  // Procesar lookup_response y authenticate_response
  ProcessLookupResponse(p_JsonStr);
  ProcessAuthResponse(p_JsonStr);
End-Proc;

Dcl-Proc ProcessLookupResponse;
  Dcl-Pi ProcessLookupResponse;
    p_JsonStr Varchar(1000) Const;
  End-Pi;

  Json3ds.lookup_response.ACSOperatorID =
    ExtractJsonValue(p_JsonStr: 'ACSOperatorID');
  Json3ds.lookup_response.ErrorNo =
    ExtractJsonValue(p_JsonStr: 'ErrorNo');
  Json3ds.lookup_response.TransactionId =
    ExtractJsonValue(p_JsonStr: 'TransactionId');
  Json3ds.lookup_response.Payload =
    ExtractJsonValue(p_JsonStr: 'Payload');
  Json3ds.lookup_response.StepUpUrl =
    ExtractJsonValue(p_JsonStr: 'StepUpUrl');
  Json3ds.lookup_response.ErrorDesc =
    ExtractJsonValue(p_JsonStr: 'ErrorDesc');
  Json3ds.lookup_response.Warning =
    ExtractJsonValue(p_JsonStr: 'Warning');
  Json3ds.lookup_response.Cavv =
    ExtractJsonValue(p_JsonStr: 'Cavv');
  Json3ds.lookup_response.PAResStatus =
    ExtractJsonValue(p_JsonStr: 'PAResStatus');
  Json3ds.lookup_response.Enrolled =
    ExtractJsonValue(p_JsonStr: 'Enrolled');
  Json3ds.lookup_response.ACSTransactionId =
    ExtractJsonValue(p_JsonStr: 'ACSTransactionId');
  Json3ds.lookup_response.EciFlag =
    ExtractJsonValue(p_JsonStr: 'EciFlag');
  Json3ds.lookup_response.ACSUrl =
    ExtractJsonValue(p_JsonStr: 'ACSUrl');
  Json3ds.lookup_response.ThreeDSServerTransId =
    ExtractJsonValue(p_JsonStr: 'ThreeDSServerTransactionId');
  Json3ds.lookup_response.CardBin =
    ExtractJsonValue(p_JsonStr: 'CardBin');
  Json3ds.lookup_response.ACSReferenceNumber =
    ExtractJsonValue(p_JsonStr: 'ACSReferenceNumber');
  Json3ds.lookup_response.CardBrand =
    ExtractJsonValue(p_JsonStr: 'CardBrand');
  Json3ds.lookup_response.DSTransactionId =
    ExtractJsonValue(p_JsonStr: 'DSTransactionId');
  Json3ds.lookup_response.ThreeDSVersion =
    ExtractJsonValue(p_JsonStr: 'ThreeDSVersion');
  Json3ds.lookup_response.OrderId =
    ExtractJsonValue(p_JsonStr: 'OrderId');
  Json3ds.lookup_response.ChallengeRequired =
    ExtractJsonValue(p_JsonStr: 'ChallengeRequired');
  Json3ds.lookup_response.SignatureVerification =
    ExtractJsonValue(p_JsonStr: 'SignatureVerification');
End-Proc;

Dcl-Proc ProcessAuthResponse;
  Dcl-Pi ProcessAuthResponse;
    p_JsonStr Varchar(1000) Const;
  End-Pi;

  AuthenticateResponse.auth_CardBin =
    ExtractJsonValue(p_JsonStr: 'CardBin');
  AuthenticateResponse.auth_ThreeDSVersion =
    ExtractJsonValue(p_JsonStr: 'ThreeDSVersion');
  AuthenticateResponse.auth_SignatureVerif =
    ExtractJsonValue(p_JsonStr: 'SignatureVerification');
  AuthenticateResponse.auth_ErrorDesc =
    ExtractJsonValue(p_JsonStr: 'ErrorDesc');
  AuthenticateResponse.auth_ThreeDSServerId =
    ExtractJsonValue(p_JsonStr: 'ThreeDSServerTransactionId');
  AuthenticateResponse.auth_Cavv =
    ExtractJsonValue(p_JsonStr: 'Cavv');
  AuthenticateResponse.auth_Amount =
    ExtractJsonValue(p_JsonStr: 'Amount');
  AuthenticateResponse.auth_ErrorNo =
    ExtractJsonValue(p_JsonStr: 'ErrorNo');
  AuthenticateResponse.auth_EciFlag =
    ExtractJsonValue(p_JsonStr: 'EciFlag');
  AuthenticateResponse.auth_TransactionId =
    ExtractJsonValue(p_JsonStr: 'TransactionId');
  AuthenticateResponse.auth_CurrencyCode =
    ExtractJsonValue(p_JsonStr: 'CurrencyCode');
  AuthenticateResponse.auth_DSTransactionId =
    ExtractJsonValue(p_JsonStr: 'DSTransactionId');
  AuthenticateResponse.auth_ACSTransactionId =
    ExtractJsonValue(p_JsonStr: 'ACSTransactionId');
  AuthenticateResponse.auth_CardBrand =
    ExtractJsonValue(p_JsonStr: 'CardBrand');
  AuthenticateResponse.auth_PAResStatus =
    ExtractJsonValue(p_JsonStr: 'PAResStatus');
End-Proc;
