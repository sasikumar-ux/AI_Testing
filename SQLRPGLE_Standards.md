# SQLRPGLE Full Free Format — Coding Standards

---

## Table of Contents

1. [Program Structure](#1-program-structure)
2. [Variable Naming Conventions](#2-variable-naming-conventions)
3. [Constants](#3-constants)
4. [Data Structures](#4-data-structures)
5. [Procedures](#5-procedures)
6. [Host Variables (Embedded SQL)](#6-host-variables-embedded-sql)
7. [Embedded SQL Guidelines](#7-embedded-sql-guidelines)
8. [Complete Program Template](#8-complete-program-template)

---

## 1. Program Structure

Every SQLRPGLE program in full free format must begin with `**FREE` on the very first line (no leading spaces).

```rpgle
**FREE
```

### Standard Program Layout

```
**FREE
//---------------------------------------------------------------
// Program   : PGMNAME
// Description: Brief description of the program
// Author    : Author Name
// Date      : YYYY-MM-DD
//---------------------------------------------------------------
// Modification History
// Date        Author      Description
// ----------  ----------  ------------------------------------
// YYYY-MM-DD  Name        Initial creation
//---------------------------------------------------------------

Ctl-Opt DftActGrp(*No)
        ActGrp(*Caller)
        Option(*SrcStmt : *NoDebugIO)
        BndDir('QC2LE')
        Main(mainProcess);

//--- Main Procedure ---
Dcl-Proc mainProcess;
  ...
End-Proc mainProcess;
```

> **Rules:**
> - Always use `**FREE` on line 1.
> - Use `Ctl-Opt` for compile options.
> - Specify `Main()` for linear-main programs.
> - Group declarations before executable code.
> - Indent consistently with **2 spaces**.

---

## 2. Variable Naming Conventions

### Format

```
wk_<descriptiveName>_<TYPE>
```

| Suffix | Data Type         | RPG Type         |
|--------|-------------------|------------------|
| `NUM`  | Numeric           | Packed / Zoned / Binary / Integer |
| `CHAR` | Character/String  | Char / Varchar   |
| `IND`  | Indicator/Boolean | Ind (`*On`/`*Off`) |

### Examples

```rpgle
// Numeric Variables
Dcl-S wk_empId_NUM        Packed(7:0);
Dcl-S wk_salary_NUM       Packed(11:2);
Dcl-S wk_recordCount_NUM  Int(10);
Dcl-S wk_taxRate_NUM      Packed(5:3);

// Character Variables
Dcl-S wk_empName_CHAR     Char(50);
Dcl-S wk_deptCode_CHAR    Char(5);
Dcl-S wk_errorMsg_CHAR    VarChar(200);
Dcl-S wk_statusCode_CHAR  Char(2);

// Indicator Variables
Dcl-S wk_found_IND        Ind;
Dcl-S wk_isValid_IND      Ind;
Dcl-S wk_endOfFile_IND    Ind;
Dcl-S wk_hasError_IND     Ind;
```

### Rules

- Use **camelCase** for the descriptive part between the prefix and suffix.
- Use meaningful, self-documenting names — avoid abbreviations unless commonly understood (e.g., `emp`, `dept`).
- Declare all variables at the **top** of the procedure or program.
- Never reuse variables for different logical purposes within the same scope.

---

## 3. Constants

### Format

```
wc_<descriptiveName>
```

### Examples

```rpgle
// Status Codes
Dcl-C wc_statusActive    'A';
Dcl-C wc_statusInactive  'I';
Dcl-C wc_statusPending   'P';

// Numeric Constants
Dcl-C wc_maxRetries      5;
Dcl-C wc_taxRateDefault  0.18;
Dcl-C wc_zeroAmount      0;

// Message Constants
Dcl-C wc_msgSuccess      'Process completed successfully';
Dcl-C wc_msgNotFound     'Record not found';
Dcl-C wc_msgDuplicate    'Duplicate record exists';

// Boolean-style Constants
Dcl-C wc_true            *On;
Dcl-C wc_false           *Off;
```

### Rules

- All constants are prefixed with `wc_`.
- Use **camelCase** for the descriptive part.
- Prefer constants over hard-coded literals throughout the program.
- Group related constants together with a comment header.

---

## 4. Data Structures

### Format

```
<descriptiveName>_DS
```

### Examples

```rpgle
// Employee Data Structure
Dcl-DS employee_DS        Qualified;
  empId                   Packed(7:0);
  empName                 Char(50);
  deptCode                Char(5);
  salary                  Packed(11:2);
  hireDate                Date;
  activeStatus            Char(1);
End-DS employee_DS;

// Error Handling Data Structure
Dcl-DS error_DS           Qualified;
  msgId                   Char(7);
  msgText                 VarChar(256);
  pgmName                 Char(10);
  severity                Int(5);
End-DS error_DS;

// Database Row Data Structure (externally described)
Dcl-DS empRecord_DS       ExtName('EMPTABLE') Qualified;
End-DS empRecord_DS;

// Parameter Data Structure
Dcl-DS param_DS           Qualified;
  inputEmpId              Packed(7:0);
  inputDeptCode           Char(5);
  outputStatus            Char(2);
  outputMessage           VarChar(100);
End-DS param_DS;

// SQLCA (SQL Communication Area)
Dcl-DS sqlca_DS           SQLCA;
```

### Rules

- All data structure names end with `_DS`.
- Use `Qualified` keyword so subfields are accessed via `dsName.subfield`.
- End the DS declaration with `End-DS <dsName>` for clarity.
- For externally described DSes, always use `ExtName()` with the physical file name.
- Use DS for grouping related fields logically.

---

## 5. Procedures

### Naming Convention

- Names must reflect the **purpose or action** of the procedure.
- Use **camelCase** format.
- `End-Proc` must include the **procedure name**.

### Examples

```rpgle
//---------------------------------------------------------------
// Procedure : validateEmployeeData
// Purpose   : Validates employee input fields before processing
// Parameters: None (uses module-level variables)
// Returns   : Indicator - *On if valid, *Off if invalid
//---------------------------------------------------------------
Dcl-Proc validateEmployeeData;
  Dcl-Pi *N Ind;
  End-Pi;

  Dcl-S wk_isValid_IND  Ind   Inz(*On);

  // Validate Employee ID
  If wk_empId_NUM <= wc_zeroAmount;
    wk_isValid_IND  = *Off;
    wk_errorMsg_CHAR = 'Employee ID must be greater than zero';
  EndIf;

  // Validate Department Code
  If wk_deptCode_CHAR = *Blanks;
    wk_isValid_IND   = *Off;
    wk_errorMsg_CHAR = 'Department Code cannot be blank';
  EndIf;

  Return wk_isValid_IND;

End-Proc validateEmployeeData;


//---------------------------------------------------------------
// Procedure : fetchEmployeeDetails
// Purpose   : Retrieves employee record from database by ID
// Parameters: Input - Employee ID
// Returns   : Indicator - *On if found, *Off if not found
//---------------------------------------------------------------
Dcl-Proc fetchEmployeeDetails;
  Dcl-Pi *N Ind;
    pi_empId_NUM  Packed(7:0) Const;
  End-Pi;

  Dcl-S wk_found_IND  Ind  Inz(*Off);

  EXEC SQL
    SELECT EMPID, EMPNAME, DEPTCODE, SALARY, HIREDATE
      INTO :WV_EMPID, :WV_EMPNAME, :WV_DEPTCODE,
           :WV_SALARY, :WV_HIREDATE
      FROM EMPTABLE
     WHERE EMPID = :pi_empId_NUM;

  If SQLCODE = 0;
    wk_found_IND = *On;
  EndIf;

  Return wk_found_IND;

End-Proc fetchEmployeeDetails;


//---------------------------------------------------------------
// Procedure : calculateNetSalary
// Purpose   : Calculates net salary after tax deduction
// Parameters: Input - Gross Salary, Tax Rate
// Returns   : Net Salary (Numeric)
//---------------------------------------------------------------
Dcl-Proc calculateNetSalary;
  Dcl-Pi *N Packed(11:2);
    pi_grossSalary_NUM  Packed(11:2) Const;
    pi_taxRate_NUM      Packed(5:3)  Const;
  End-Pi;

  Dcl-S wk_netSalary_NUM   Packed(11:2) Inz(0);
  Dcl-S wk_taxAmount_NUM   Packed(11:2) Inz(0);

  wk_taxAmount_NUM = pi_grossSalary_NUM * pi_taxRate_NUM;
  wk_netSalary_NUM = pi_grossSalary_NUM - wk_taxAmount_NUM;

  Return wk_netSalary_NUM;

End-Proc calculateNetSalary;


//---------------------------------------------------------------
// Procedure : logErrorMessage
// Purpose   : Logs error to error log table
// Parameters: Input - Error message, Program name
// Returns   : None
//---------------------------------------------------------------
Dcl-Proc logErrorMessage;
  Dcl-Pi *N;
    pi_errorMsg_CHAR  VarChar(200) Const;
    pi_pgmName_CHAR   Char(10)     Const;
  End-Pi;

  EXEC SQL
    INSERT INTO ERRORLOG
           (ERRORMSG, PGMNAME, LOGTIME)
    VALUES (:pi_errorMsg_CHAR,
            :pi_pgmName_CHAR,
             CURRENT_TIMESTAMP);

End-Proc logErrorMessage;
```

### Rules

- Begin each procedure with a **comment block** describing purpose, parameters, and return value.
- `End-Proc` always includes the **procedure name**.
- Declare procedure-local variables inside `Dcl-Pi ... End-Pi`.
- Use `pi_` prefix for procedure **interface (parameter)** variables.
- Parameters should also follow the `_NUM`, `_CHAR`, `_IND` suffix convention.

---

## 6. Host Variables (Embedded SQL)

### Format

```
:WV_<COLUMN_NAME>
```

- Prefix is always **`WV_`** (uppercase).
- The column name portion must **exactly match** the database column name (uppercase).
- Declared as `Dcl-S` variables in the appropriate scope.

### Declaration Examples

```rpgle
// Host Variables matching table EMPTABLE columns
// Column: EMPID        → WV_EMPID
// Column: EMPNAME      → WV_EMPNAME
// Column: DEPTCODE     → WV_DEPTCODE
// Column: SALARY       → WV_SALARY
// Column: HIREDATE     → WV_HIREDATE
// Column: STATUS       → WV_STATUS

Dcl-S WV_EMPID         Packed(7:0);
Dcl-S WV_EMPNAME       Char(50);
Dcl-S WV_DEPTCODE      Char(5);
Dcl-S WV_SALARY        Packed(11:2);
Dcl-S WV_HIREDATE      Date;
Dcl-S WV_STATUS        Char(1);
```

### Usage in SQL Statements

```rpgle
// SELECT INTO
EXEC SQL
  SELECT EMPID, EMPNAME, DEPTCODE, SALARY, HIREDATE, STATUS
    INTO :WV_EMPID, :WV_EMPNAME, :WV_DEPTCODE,
         :WV_SALARY, :WV_HIREDATE, :WV_STATUS
    FROM EMPTABLE
   WHERE EMPID = :WV_EMPID;

// INSERT
EXEC SQL
  INSERT INTO EMPTABLE
         (EMPID, EMPNAME, DEPTCODE, SALARY, HIREDATE, STATUS)
  VALUES (:WV_EMPID, :WV_EMPNAME, :WV_DEPTCODE,
          :WV_SALARY, :WV_HIREDATE, :WV_STATUS);

// UPDATE
EXEC SQL
  UPDATE EMPTABLE
     SET EMPNAME  = :WV_EMPNAME,
         DEPTCODE = :WV_DEPTCODE,
         SALARY   = :WV_SALARY,
         STATUS   = :WV_STATUS
   WHERE EMPID = :WV_EMPID;
```

### Rules

- Host variables are **always uppercase** — `WV_EMPID`, never `wv_empId`.
- One host variable per database column — do not reuse across different tables.
- Declare host variables **near the top** of the procedure or main program, clearly separated from working variables.
- Null indicator variables should follow: `WV_<COLUMN_NAME>_NI` (e.g., `WV_SALARY_NI`).

```rpgle
// Null Indicator Example
Dcl-S WV_SALARY_NI    Int(5);   // Null indicator for SALARY column

EXEC SQL
  SELECT SALARY
    INTO :WV_SALARY :WV_SALARY_NI
    FROM EMPTABLE
   WHERE EMPID = :WV_EMPID;

If WV_SALARY_NI < 0;
  // SALARY is NULL
  WV_SALARY = wc_zeroAmount;
EndIf;
```

---

## 7. Embedded SQL Guidelines

### SQLCODE Checking

Always check `SQLCODE` after every SQL statement.

```rpgle
EXEC SQL
  SELECT EMPNAME
    INTO :WV_EMPNAME
    FROM EMPTABLE
   WHERE EMPID = :WV_EMPID;

Select;
  When SQLCODE = 0;
    // Successful fetch
    wk_found_IND = *On;

  When SQLCODE = 100;
    // Row not found
    wk_found_IND = *Off;
    wk_errorMsg_CHAR = wc_msgNotFound;

  Other;
    // SQL Error
    wk_hasError_IND  = *On;
    wk_errorMsg_CHAR = 'SQL Error: ' + %Char(SQLCODE);
    callP logErrorMessage(wk_errorMsg_CHAR : 'PGMNAME');
EndSl;
```

### Cursor Declaration

```rpgle
// Declare cursor
EXEC SQL
  DECLARE empCursor CURSOR FOR
    SELECT EMPID, EMPNAME, DEPTCODE, SALARY
      FROM EMPTABLE
     WHERE STATUS = :WV_STATUS
     ORDER BY EMPNAME;

// Open cursor
EXEC SQL OPEN empCursor;

// Fetch loop
wk_endOfFile_IND = *Off;
DoW NOT wk_endOfFile_IND;

  EXEC SQL
    FETCH NEXT FROM empCursor
     INTO :WV_EMPID, :WV_EMPNAME,
          :WV_DEPTCODE, :WV_SALARY;

  If SQLCODE = 100;
    wk_endOfFile_IND = *On;
    Iter;
  EndIf;

  If SQLCODE <> 0;
    wk_hasError_IND  = *On;
    Leave;
  EndIf;

  // Process fetched row here

EndDo;

// Close cursor
EXEC SQL CLOSE empCursor;
```

### SQL Options (Ctl-Opt)

```rpgle
// Recommended SQL precompiler options (in source or binder)
Ctl-Opt  DftActGrp(*No)
         ActGrp(*Caller)
         Option(*SrcStmt : *NoDebugIO);

// In the SQL compile command, use:
// COMMIT(*NONE)       — for read-only programs
// COMMIT(*CHG)        — for programs that update data
// CLOSQLCSR(*ENDMOD)  — close cursors at module end
// ALWBLK(*ALLREAD)    — allow blocking for read-only cursors
```
EXEC SQL SET OPTION COMMIT = *NONE;
---

## 8. Complete Program Template

```rpgle
**FREE
//---------------------------------------------------------------
// Program    : EMPPROC
// Description: Employee processing program
// Author     : Developer Name
// Date       : YYYY-MM-DD
//---------------------------------------------------------------
// Modification History
// Date        Author       Description
// ----------  -----------  -----------------------------------
// YYYY-MM-DD  Dev Name     Initial creation
//---------------------------------------------------------------

Ctl-Opt DftActGrp(*No)
        ActGrp(*Caller)
        Option(*SrcStmt : *NoDebugIO)
        Main(mainProcess);

//=== Constants ================================================
Dcl-C wc_statusActive    'A';
Dcl-C wc_statusInactive  'I';
Dcl-C wc_zeroAmount      0;
Dcl-C wc_maxRetries      5;
Dcl-C wc_msgNotFound     'Record not found';
Dcl-C wc_msgSuccess      'Process completed successfully';

//=== Data Structures ==========================================
Dcl-DS param_DS           Qualified;
  inputEmpId              Packed(7:0);
  inputDeptCode           Char(5);
  outputStatus            Char(2);
  outputMessage           VarChar(100);
End-DS param_DS;

Dcl-DS error_DS           Qualified;
  msgId                   Char(7);
  msgText                 VarChar(256);
  severity                Int(5);
End-DS error_DS;

//=== Host Variables (SQL) =====================================
Dcl-S WV_EMPID            Packed(7:0);
Dcl-S WV_EMPNAME          Char(50);
Dcl-S WV_DEPTCODE         Char(5);
Dcl-S WV_SALARY           Packed(11:2);
Dcl-S WV_HIREDATE         Date;
Dcl-S WV_STATUS           Char(1);
Dcl-S WV_SALARY_NI        Int(5);            // Null indicator

//=== Working Variables ========================================
Dcl-S wk_empId_NUM        Packed(7:0);
Dcl-S wk_salary_NUM       Packed(11:2);
Dcl-S wk_netSalary_NUM    Packed(11:2);
Dcl-S wk_deptCode_CHAR    Char(5);
Dcl-S wk_errorMsg_CHAR    VarChar(200);
Dcl-S wk_statusCode_CHAR  Char(2);
Dcl-S wk_found_IND        Ind;
Dcl-S wk_isValid_IND      Ind;
Dcl-S wk_hasError_IND     Ind;
Dcl-S wk_endOfFile_IND    Ind;

//=== Procedure Prototypes =====================================
Dcl-Pr validateEmployeeData Ind;
End-Pr;

Dcl-Pr fetchEmployeeDetails Ind;
  pi_empId_NUM  Packed(7:0) Const;
End-Pr;

Dcl-Pr calculateNetSalary Packed(11:2);
  pi_grossSalary_NUM  Packed(11:2) Const;
  pi_taxRate_NUM      Packed(5:3)  Const;
End-Pr;

Dcl-Pr logErrorMessage;
  pi_errorMsg_CHAR  VarChar(200) Const;
  pi_pgmName_CHAR   Char(10)     Const;
End-Pr;


//=================================================================
// MAIN PROCEDURE
//=================================================================
Dcl-Proc mainProcess;

  // Initialize
  wk_hasError_IND  = *Off;
  wk_found_IND     = *Off;
  wk_empId_NUM     = param_DS.inputEmpId;
  wk_deptCode_CHAR = param_DS.inputDeptCode;

  // Validate input
  wk_isValid_IND = validateEmployeeData();

  If NOT wk_isValid_IND;
    param_DS.outputStatus  = 'ER';
    param_DS.outputMessage = wk_errorMsg_CHAR;
    Return;
  EndIf;

  // Fetch employee
  WV_EMPID      = wk_empId_NUM;
  wk_found_IND  = fetchEmployeeDetails(wk_empId_NUM);

  If NOT wk_found_IND;
    param_DS.outputStatus  = 'NF';
    param_DS.outputMessage = wc_msgNotFound;
    Return;
  EndIf;

  // Calculate net salary
  wk_netSalary_NUM = calculateNetSalary(WV_SALARY : 0.18);

  // Set success response
  param_DS.outputStatus  = 'OK';
  param_DS.outputMessage = wc_msgSuccess;

  Return;

End-Proc mainProcess;


//=================================================================
// Procedure : validateEmployeeData
// Purpose   : Validates employee input before processing
// Returns   : *On = Valid, *Off = Invalid
//=================================================================
Dcl-Proc validateEmployeeData;
  Dcl-Pi *N Ind;
  End-Pi;

  Dcl-S wk_isValid_IND  Ind  Inz(*On);

  If wk_empId_NUM <= wc_zeroAmount;
    wk_isValid_IND   = *Off;
    wk_errorMsg_CHAR = 'Employee ID must be greater than zero';
  EndIf;

  If wk_deptCode_CHAR = *Blanks;
    wk_isValid_IND   = *Off;
    wk_errorMsg_CHAR = 'Department Code cannot be blank';
  EndIf;

  Return wk_isValid_IND;

End-Proc validateEmployeeData;


//=================================================================
// Procedure : fetchEmployeeDetails
// Purpose   : Fetch employee record by ID
// Parameters: pi_empId_NUM - Employee ID to look up
// Returns   : *On = Found, *Off = Not Found
//=================================================================
Dcl-Proc fetchEmployeeDetails;
  Dcl-Pi *N Ind;
    pi_empId_NUM  Packed(7:0) Const;
  End-Pi;

  Dcl-S wk_found_IND  Ind  Inz(*Off);

  WV_EMPID = pi_empId_NUM;

  EXEC SQL
    SELECT EMPID, EMPNAME, DEPTCODE,
           SALARY, HIREDATE, STATUS
      INTO :WV_EMPID, :WV_EMPNAME, :WV_DEPTCODE,
           :WV_SALARY :WV_SALARY_NI,
           :WV_HIREDATE, :WV_STATUS
      FROM EMPTABLE
     WHERE EMPID   = :WV_EMPID
       AND STATUS  = :wc_statusActive;

  Select;
    When SQLCODE = 0;
      wk_found_IND = *On;
    When SQLCODE = 100;
      wk_found_IND = *Off;
    Other;
      wk_hasError_IND  = *On;
      wk_errorMsg_CHAR = 'SQL Error: ' + %Char(SQLCODE);
      callP logErrorMessage(wk_errorMsg_CHAR : 'EMPPROC');
  EndSl;

  Return wk_found_IND;

End-Proc fetchEmployeeDetails;


//=================================================================
// Procedure : calculateNetSalary
// Purpose   : Calculates net salary after tax
// Parameters: pi_grossSalary_NUM, pi_taxRate_NUM
// Returns   : Net salary as Packed(11:2)
//=================================================================
Dcl-Proc calculateNetSalary;
  Dcl-Pi *N Packed(11:2);
    pi_grossSalary_NUM  Packed(11:2) Const;
    pi_taxRate_NUM      Packed(5:3)  Const;
  End-Pi;

  Dcl-S wk_netSalary_NUM   Packed(11:2) Inz(0);
  Dcl-S wk_taxAmount_NUM   Packed(11:2) Inz(0);

  wk_taxAmount_NUM = pi_grossSalary_NUM * pi_taxRate_NUM;
  wk_netSalary_NUM = pi_grossSalary_NUM - wk_taxAmount_NUM;

  Return wk_netSalary_NUM;

End-Proc calculateNetSalary;


//=================================================================
// Procedure : logErrorMessage
// Purpose   : Logs error details to error log table
// Parameters: pi_errorMsg_CHAR, pi_pgmName_CHAR
// Returns   : None
//=================================================================
Dcl-Proc logErrorMessage;
  Dcl-Pi *N;
    pi_errorMsg_CHAR  VarChar(200) Const;
    pi_pgmName_CHAR   Char(10)     Const;
  End-Pi;

  EXEC SQL
    INSERT INTO ERRORLOG
           (ERRORMSG, PGMNAME, LOGTIME)
    VALUES (:pi_errorMsg_CHAR,
            :pi_pgmName_CHAR,
             CURRENT_TIMESTAMP);

End-Proc logErrorMessage;
```

---

## Quick Reference Summary

| Element          | Convention                         | Example                        |
|------------------|------------------------------------|--------------------------------|
| **Variable**     | `wk_<name>_NUM`                    | `wk_salary_NUM`                |
| **Variable**     | `wk_<name>_CHAR`                   | `wk_empName_CHAR`              |
| **Variable**     | `wk_<name>_IND`                    | `wk_found_IND`                 |
| **Constant**     | `wc_<name>`                        | `wc_statusActive`              |
| **Data Struct**  | `<name>_DS`                        | `employee_DS`, `param_DS`      |
| **Procedure**    | camelCase, action-based            | `fetchEmployeeDetails`         |
| **End-Proc**     | Must include procedure name        | `End-Proc fetchEmployeeDetails`|
| **Host Variable**| `WV_<COLUMN_NAME>` (uppercase)     | `WV_EMPID`, `WV_SALARY`        |
| **Null Indicator**| `WV_<COLUMN_NAME>_NI`             | `WV_SALARY_NI`                 |
| **Proc Param**   | `pi_<name>_<TYPE>`                 | `pi_empId_NUM`                 |