**FREE
 Dcl-s wkState          Char(2)      Inz('AP');
 Dcl-s Str1             Varchar(500) Inz;
 Dcl-s DB2_MESSAGEID        Char(10) ;
 Dcl-s DB2_MESSAGEID1       Varchar(7) ;
 Dcl-s DB2_MESSAGEID2       Like(DB2_MessageId1) ;
 Dcl-s MESSAGE_LENGTH       Int(5) ;
 Dcl-s MESSAGE_TEXT         Varchar(32740) ;
 Dcl-s RETURNED_SQLSTATE    Char(5) ;
 Dcl-s DB2_RETURNED_SQLCODE Char(5) ;
 Dcl-s RowCount             Int(10) ;

 Dcl-ds Pgmds PSDS;
    Proc_Name *proc;
 End-ds;

 Dcl-ds *n Dtaara(*AUTO);
    Pgmname   Char(10)   Pos(21);
    Rows      Zoned(7:0) Pos(31);
  End-ds;

  Dcl-ds *N       ;
     SQL_00000  Bindec(4) INZ(128) Pos(1);
     SQL_00001  Bindec(4) INZ(5)   Pos(3);
     SQL_00002  Uns(10)   INZ(0)   Pos(5);
     SQL_00003  Char(1)   INZ('0') CCSID(*JOBRUNMIX) Pos(9);
     SQL_00004  Char(119) CCSID(*JOBRUNMIX)  Pos(10);
     SQL_00005  Int(10)   Pos(129);
  End-ds;

  Dcl-ds *N       ;
     SQL_00006    Bindec(4)      INZ(128)                   Pos(1);
     SQL_00007    Bindec(4)      INZ(6)                     Pos(3);
     SQL_00008    Uns(10)        INZ(0)                     Pos(5);
     SQL_00009    Char(1)        INZ('0') CCSID(*JOBRUNMIX) Pos(9);
     SQL_00010    Char(119)      CCSID(*JOBRUNMIX)          Pos(10);
     SQL_00011    Char(5)        CCSID(*JOBRUNMIX)          Pos(129);
     SQL_00012    Char(5)        CCSID(*JOBRUNMIX)          Pos(134);
     SQL_00013    Int(5)                                    Pos(139);
     SQL_00014    Varchar(32740) CCSID(*JOBRUNMIX)          Pos(141);
     SQL_00015    Char(10)       CCSID(*JOBRUNMIX)          Pos(32883);
     SQL_00016    Varchar(7)     CCSID(*JOBRUNMIX)          Pos(32893);
     SQL_00017    Varchar(7)     CCSID(*JOBRUNMIX)          Pos(32902);
  End-ds;

 Pgmname = Proc_Name;
 Str1    = 'DELETE FROM ACCFILE WHERE ACCSTT = ''' + wkState + '''';
 Exec sql SET OPTION COMMIT = *NONE,
    Compileopt = 'DBGVIEW(*SOURCE)';
 Exec sql Execute Immediate :Str1;

 If SQL_00003 = '1';
    RowCount  = SQL_00005;
 Endif;

 If SQL_00009 = '1';
    DB2_RETURNED_SQLCODE = SQL_00011;
    RETURNED_SQLSTATE    = SQL_00012;
    MESSAGE_LENGTH       = SQL_00013;
    MESSAGE_TEXT         = SQL_00014;
    DB2_MESSAGEID        = SQL_00015;
    DB2_MESSAGEID1       = SQL_00016;
    DB2_MESSAGEID2       = SQL_00017;
 Endif;

 *Inlr  =  *On;
