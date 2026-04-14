**FREE
//---------------------------------------------------------
// Program/Object : RRORDNJSN
// Description    : Read ORDHDR and ORDDTL, construct a
//                  nested JSON array (orders with embedded
//                  detail lines) and persist the result
//                  as a single CLOB row in QTEMP.ORDJSNTMP
// Author         : Developer Name
// Creation Date  : 2026-04-13
//---------------------------------------------------------
// Modification History
// Date        Author        Description
// ----------  ------------  ----------------------------
// 2026-04-13  Developer     Initial creation
//---------------------------------------------------------
// Compilation Instruction
// ---------------------------------------------------------
// CRTSQLRPGI OBJ(*LIBL/RRORDNJSN) SRCFILE(*LIBL/QRPGLESRC)
//            SRCMBR(RRORDNJSN)    COMMIT(*NONE)
//            DBGVIEW(*SOURCE)
// ---------------------------------------------------------

Ctl-Opt DftActGrp(*No)
        ActGrp(*Caller)
        Option(*Srcstmt: *NoDebugIO)
        Main(mainProcess);

//=== Constants ===
Dcl-C wc_sqlOk       0;
Dcl-C wc_sqlNotFound 100;
Dcl-C wc_tblExists   -601;    // SQL object already exists
Dcl-C wc_tblMissing  -204;    // SQL object not found (DROP)

//=== Host Variables (SQL) ===
Dcl-S WV_ROW_COUNT      Int(10);

//=== Working Variables ===
Dcl-S wk_errorMsg_CHAR  VarChar(200) Inz('');
Dcl-S wk_rowCount_NUM   Int(10)      Inz(0);
Dcl-S wk_found_IND      Ind          Inz(*Off);
Dcl-S wk_hasError_IND   Ind          Inz(*Off);

//=========================================================
// Procedure : mainProcess
// Purpose   : Entry point \Z set SQL options, create target
//             table in QTEMP, then build and insert JSON.
// Parms     : None
// Returns   : N/A
//=========================================================
Dcl-Proc mainProcess;

  Exec SQL SET OPTION
      COMMIT     = *NONE,
      CLOSQLCSR  = *ENDMOD;

  callP createJsonTable();

  If NOT wk_hasError_IND;
    callP buildAndInsertJson();
  EndIf;

  Return;

End-Proc mainProcess;

//=========================================================
// Procedure : createJsonTable
// Purpose   : Drop QTEMP.ORDJSNTMP if it already exists,
//             then create it fresh to hold JSON output.
//             Sets wk_hasError_IND on unrecoverable failure.
// Parms     : None
// Returns   : N/A
//=========================================================
Dcl-Proc createJsonTable;

  //--- Drop existing table; ignore "not found" (-204) ---
  Exec SQL DROP TABLE IF EXISTS QTEMP.ORDJSNTMP;

  If SQLCODE <> wc_sqlOk
     And SQLCODE <> wc_sqlNotFound
     And SQLCODE <> wc_tblMissing;
    // Drop failed for an unexpected reason \Z log but continue;
    // the CREATE below will expose the real problem.
    wk_errorMsg_CHAR = 'DROP TABLE QTEMP.ORDJSNTMP warning. SQLCODE: '
                       + %Char(SQLCODE);
  EndIf;

  //--- Recreate the JSON staging table ---
  Exec SQL
    CREATE TABLE QTEMP.ORDJSNTMP (
        JSONSEQ   INTEGER          NOT NULL
                                   GENERATED ALWAYS AS IDENTITY,
        CREATETS  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
        JSONDATA  CLOB(1 M)        NOT NULL
    );

  Select;
    When SQLCODE = wc_sqlOk;
      wk_errorMsg_CHAR = '';           // Table created \Z all good

    Other;
      wk_hasError_IND  = *On;
      wk_errorMsg_CHAR = 'CREATE TABLE QTEMP.ORDJSNTMP failed. SQLCODE: '
                         + %Char(SQLCODE);
  EndSl;

End-Proc createJsonTable;

//=========================================================
// Procedure : buildAndInsertJson
// Purpose   : Join ORDHDR to ORDDTL, aggregate all rows
//             into a single nested JSON array using DB2
//             JSON scalar functions, and INSERT the result
//             into QTEMP.ORDJSNTMP.
//
//             JSON shape produced:
//             [
//               {
//                 "orderId"     : <orhid>,
//                 "customerId"  : <ORDCUS>,
//                 "orderDate"   : <ORDDAT>,
//                 "orderAmount" : <ORDAMT>,
//                 "details"     : [
//                   {
//                     "detailId" : <ordid>,
//                     "itemId"   : <ORDITM>,
//                     "quantity" : <ORDQTY>,
//                     "price"    : <ORDPRC>,
//                     "shipDate" : <ORDDAT>
//                   }, ...
//                 ]
//               }, ...
//             ]
//
// Parms     : None
// Returns   : N/A
//=========================================================
Dcl-Proc buildAndInsertJson;

  //--- Build nested JSON and insert as a single CLOB row ---
  Exec SQL
    INSERT INTO QTEMP.ORDJSNTMP (JSONDATA)
    SELECT COALESCE(
             JSON_ARRAYAGG(
               JSON_OBJECT(
                 'orderId'     VALUE H.ORHID,
                 'customerId'  VALUE H.ORHCUS ,
                 'orderDate'   VALUE H.ORHDAT,
                 'details'     VALUE (
                   SELECT COALESCE(
                            JSON_ARRAYAGG(
                              JSON_OBJECT(
                                'detailId' VALUE D.ORDID,
                                'itemId'   VALUE D.ORDITM,
                                'quantity' VALUE D.ORDQTY,
                                'price'    VALUE D.ORDPRC,
                                'shipDate' VALUE D.ORDDAT
                              )
                              ORDER BY D.ORDITM ASC
                            ),
                            JSON_ARRAY()
                          )
                     FROM ORDDTL D
                    WHERE D.ORDID  = H.ORHID
                 )
               )
               ORDER BY H.orhid  ASC
             ),
             JSON_ARRAY()
           )
      FROM ORDHDR H;

  Select;
    When SQLCODE = wc_sqlOk;
      //--- Retrieve number of rows inserted into staging table ---
      Exec SQL GET DIAGNOSTICS :WV_ROW_COUNT = ROW_COUNT;

      If SQLCODE = wc_sqlOk;
        wk_rowCount_NUM  = WV_ROW_COUNT;
      Else;
        wk_errorMsg_CHAR = 'GET DIAGNOSTICS failed. SQLCODE: '
                           + %Char(SQLCODE);
      EndIf;

      wk_found_IND = *On;

    When SQLCODE = wc_sqlNotFound;
      //--- No rows in ORDHDR; an empty JSON array was still inserted ---
      wk_found_IND     = *Off;
      wk_errorMsg_CHAR = 'No records found in ORDHDR.';

    Other;
      wk_hasError_IND  = *On;
      wk_found_IND     = *Off;
      wk_errorMsg_CHAR = 'INSERT INTO QTEMP.ORDJSNTMP failed. SQLCODE: '
                         + %Char(SQLCODE);
  EndSl;

End-Proc buildAndInsertJson;