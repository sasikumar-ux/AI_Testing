**FREE
 Dcl-s wkState  Char(2)      Inz('CA');
 Dcl-s Str1     Varchar(500) Inz;
 Dcl-s RowCount Int(10) Inz;

 Dcl-ds Pgmds PSDS;
    Proc_Name *proc;
 End-ds;
 Dcl-ds *n Dtaara(*AUTO);
    Pgmname   Char(10)   Pos(21);
    Rows      Zoned(7:0) Pos(31);
  End-ds;

 Pgmname = Proc_Name;
 Str1    = 'DELETE FROM ACCFILE WHERE ACCSTT = ''' + wkState + '''';
 Exec sql SET OPTION COMMIT = *NONE,
    Compileopt = 'DBGVIEW(*SOURCE)';
 Exec sql Execute Immediate :Str1;
 Exec Sql Get Diagnostics :RowCount = ROW_COUNT;
 Rows   =  RowCount;

 *Inlr  =  *On;
