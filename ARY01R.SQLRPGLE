**FREE
 Dcl-Ds Data Extname('WORKFILE') qualified dim(*auto : 9999) ;
 End-Ds;
 Dcl-s  String    Varchar(2048) ;
 Dcl-s  MyArray   Varchar(30)  Dim(*auto : 99) ;
 Dcl-s  Separator Char(3) Inz(''',''') ;
 Dcl-s  Rows      Int(5) Inz(10);

 MyArray = %list('CA' : 'NY') ;
 String  = 'SELECT ACCNUM, ACCNAM, ACCSTT, ACCBAL +
            FROM WORKFILE WHERE ACCSTT IN (''' +
            %Concatarr(Separator : MyArray) +
            ''') FOR READ ONLY' ;
 Exec sql SET OPTION COMMIT = *NONE,Compileopt = 'DBGVIEW(*SOURCE)';
 Exec sql PREPARE S0 FROM :String ;
 Exec sql DECLARE READ_ACC CURSOR FOR S0 ;
 Exec sql OPEN READ_ACC ;
 Exec sql FETCH READ_ACC FOR :Rows ROWS INTO :Data ;
 Exec sql CLOSE READ_ACC ;

 *Inlr   =  *On;
