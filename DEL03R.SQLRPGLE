**FREE
 Dcl-s wkState          Char(2)      Inz('TX');
 Dcl-s Str1             Varchar(500) Inz;
 Dcl-s MessageId        Char(10) ;
 Dcl-s MessageId1       Varchar(7) ;
 Dcl-s MessageId2       Like(MessageId1) ;
 Dcl-s MessageLength    Int(5) ;
 Dcl-s MessageText      Varchar(32740) ;
 Dcl-s ReturnedSQLCode  Char(5) ;
 Dcl-s ReturnedSQLState Char(5) ;
 Dcl-s RowCount         Int(10) ;

 Dcl-ds Pgmds PSDS;
    Proc_Name *proc;
 End-ds;
 Dcl-ds *n Dtaara(*AUTO);
    Pgmname   Char(10)   Pos(21);
    Rows      Zoned(7:0) Pos(31);
  End-ds;

 Pgmname = Proc_Name;
 Str1    = 'DELETE FROM ACCFILE WHERE ACCSTT = ''' + wkState + '''';

 Exec sql SET OPTION COMMIT = *NONE, Compileopt = 'DBGVIEW(*SOURCE)';
 Exec sql Execute Immediate :Str1;

 Exec sql GET DIAGNOSTICS CONDITION 1
          :ReturnedSqlCode  = DB2_RETURNED_SQLCODE,
          :ReturnedSQLState = RETURNED_SQLSTATE,
          :MessageLength    = MESSAGE_LENGTH,
          :MessageText      = MESSAGE_TEXT,
          :MessageId        = DB2_MESSAGE_ID,
          :MessageId1       = DB2_MESSAGE_ID1,
          :MessageId2       = DB2_MESSAGE_ID2,
          :RowCount         = DB2_SQLERRD3;
 *Inlr  =  *On;
