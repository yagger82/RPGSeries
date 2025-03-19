**free
ctl-opt pgminfo(*pcml:*module:*dclcase) DFTNAME(TJSONEXT00);

// Prototipo del programa
dcl-pi TJSONEXT00;
   p_id zoned(15:0);        // ID
   p_pan varchar(19);       // PAN
   p_cvv varchar(4);        // CVV
   p_exp_date varchar(4);   // Expiration Date
   p_user_ci varchar(11);   // User CI
   p_addl varchar(1000);    // JSON string
   p_cell_number varchar(10); // Cell Number
   p_card_type varchar(10); // Card Type
   p_card_addl varchar(8);  // Card Additional Info
   p_three_ds varchar(2000); // 3DS JSON string
   p_visa_token varchar(2000); // Visa Token JSON string
end-pi;

// Estructura para datos adicionales
dcl-ds addl_info qualified;
   cmr_id   zoned(10:0);
   cmr_bra  zoned(3:0);
   service  varchar(8);
end-ds;

// Estructura para datos 3DS
dcl-ds three_ds_info qualified;
   tid                        varchar(50);
   cavv                       varchar(100);
   acs_operator_id            varchar(10);
   error_no                   varchar(10);
   transaction_id             varchar(50);
   payload                    varchar(2000);
   step_up_url                varchar(200);
   error_desc                 varchar(200);
   warning                    varchar(200);
   pa_res_status              varchar(1);
   enrolled                   varchar(1);
   acs_transaction_id         varchar(50);
   eci_flag                   varchar(2);
   acs_url                    varchar(200);
   threeDSServerTransactionId varchar(50);
   card_bin                   varchar(6);
   acs_reference_number       varchar(50);
   card_brand                 varchar(10);
   amount                     varchar(10);
   ds_transaction_id          varchar(50);
   three_ds_version           varchar(10);
   currency_code              varchar(3);
   order_id                   varchar(20);
   challenge_required         varchar(1);
   signature_verification     varchar(1);
end-ds;

// Estructura para datos Visa Token
dcl-ds visa_token_info qualified;
   return_code               varchar(10);
   error_description         varchar(200);
   tracking_id               varchar(100);
   error_response            varchar(200);
   provisioned_token_id      varchar(50);
   token                     varchar(19);
   token_expiration_date     varchar(6);
   cryptogram                varchar(50);
   cryptogram_eci            varchar(2);
end-ds;

// Ejecutar la sentencia SQL para extraer los datos del JSON `addl`
exec sql
   select cmr_id,
          cmr_bra,
          service
   into :addl_info.cmr_id,
        :addl_info.cmr_bra,
        :addl_info.service
   from JSON_TABLE(:p_addl, '$'
      COLUMNS(
         cmr_id VARCHAR(10) PATH '$.cmr_id',
         cmr_bra VARCHAR(3) PATH '$.cmr_bra',
         service VARCHAR(8) PATH '$.service'
      )
   ) AS JT;

if sqlcode <> 0;
   *inlr = *on;
   return;
endif;

// Verificar si el parámetro `p_three_ds` tiene valor
if %len(%trim(p_three_ds)) > 0;
   exec sql
      select JSON_VALUE(:p_three_ds, '$.tid'),
             JSON_VALUE(:p_three_ds, '$.cavv'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ACSOperatorID'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ErrorNo'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.TransactionId'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.Payload'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.StepUpUrl'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ErrorDesc'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.Warning'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.PAResStatus'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.Enrolled'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ACSTransactionId'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.EciFlag'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ACSUrl'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ThreeDSServerTransactionId'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.CardBin'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ACSReferenceNumber'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.CardBrand'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.Amount'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.DSTransactionId'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ThreeDSVersion'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.CurrencyCode'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.OrderId'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.ChallengeRequired'),
             JSON_VALUE(:p_three_ds, '$.lookup_response.SignatureVerification')
      into :three_ds_info.tid,
           :three_ds_info.cavv,
           :three_ds_info.acs_operator_id,
           :three_ds_info.error_no,
           :three_ds_info.transaction_id,
           :three_ds_info.payload,
           :three_ds_info.step_up_url,
           :three_ds_info.error_desc,
           :three_ds_info.warning,
           :three_ds_info.pa_res_status,
           :three_ds_info.enrolled,
           :three_ds_info.acs_transaction_id,
           :three_ds_info.eci_flag,
           :three_ds_info.acs_url,
           :three_ds_info.threeDSServerTransactionId,
           :three_ds_info.card_bin,
           :three_ds_info.acs_reference_number,
           :three_ds_info.card_brand,
           :three_ds_info.amount,
           :three_ds_info.ds_transaction_id,
           :three_ds_info.three_ds_version,
           :three_ds_info.currency_code,
           :three_ds_info.order_id,
           :three_ds_info.challenge_required,
           :three_ds_info.signature_verification
      from SYSIBM.SYSDUMMY1;

   if sqlcode <> 0;
      *inlr = *on;
      return;
   endif;
endif;

// Procesar el JSON `p_visa_token`
if %len(%trim(p_visa_token)) > 0;
   exec sql
      select JSON_VALUE(:p_visa_token, '$.returnCode'),
             JSON_VALUE(:p_visa_token, '$.errorDescription'),
             JSON_VALUE(:p_visa_token, '$.vaultDetails.trackingID'),
             JSON_VALUE(:p_visa_token, '$.vaultDetails.errorResponse'),
             JSON_VALUE(:p_visa_token, '$.provisionedTokenID'),
             JSON_VALUE(:p_visa_token, '$.tokenInfo.token'),
             JSON_VALUE(:p_visa_token, '$.tokenInfo.expirationDate'),
             JSON_VALUE(:p_visa_token, '$.cryptogramInfo.cryptogram'),
             JSON_VALUE(:p_visa_token, '$.cryptogramInfo.eci')
      into :visa_token_info.return_code,
           :visa_token_info.error_description,
           :visa_token_info.tracking_id,
           :visa_token_info.error_response,
           :visa_token_info.provisioned_token_id,
           :visa_token_info.token,
           :visa_token_info.token_expiration_date,
           :visa_token_info.cryptogram,
           :visa_token_info.cryptogram_eci
      from SYSIBM.SYSDUMMY1;

   if sqlcode <> 0;
      *inlr = *on;
      return;
   endif;
endif;

// Limpiar estructuras después de su uso
clearStructures();

*inlr = *on;

// Procedimiento para limpiar estructuras
dcl-proc clearStructures;
   clear addl_info;
   clear three_ds_info;
   clear visa_token_info;
end-proc;

