     DDEL01R           PR                  ExtPgm('DEL01R')
     DDEL02R           PR                  ExtPgm('DEL02R')
     DPARM01R          PR                  ExtPgm('PARM01R')
      /Free
          Parm01R();
          Del01R();
          Parm01R();
          Del02R();
          *Inlr = *On;
      /End-Free
