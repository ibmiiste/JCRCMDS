       //---------------------------------------------------------
       ctl-opt copyright('This program is free software, you can redistribute +
       it and/or modify it under the terms of the GNU General Public License +
       as published by the Free Software Foundation. See GNU General Public +
       License for detail.    Craig Rutledge      < www.jcrcmds.com > ');
       //---------------------------------------------------------
       // JCRSUBRR1 - Subroutines List - build work file
       // Read through RPGLE source loading work file
       // with Parent subroutine / Child subroutine names.  Subroutines executed
       // from main line code (ie not in subroutine) will have *** as subsr name.
       //---------------------------------------------------------
       /define ControlStatements
       /define Constants
       /define f_GetQual
       /define SrcDS
       /define f_RunCmd
       /define f_IsIgnoreLine
       /define f_IsCompileTimeArray
       /define f_DisplayLastSplf
       /COPY JCRCMDS,JCRCMDSCPY

       dcl-f RPGSRC disk(112) extfile(extifile) extmbr(p_srcmbr) usropn;
       dcl-f JCRSUBRPF usage(*output) usropn;

       dcl-s UpperSrc like(SrcDS.Src80);
       dcl-s WrkA like(SrcDS.OpCode);
       dcl-s OpcodeExtract like(SrcDS.OpCode);
       dcl-s IsFree ind;
       dcl-s IsInsideSubroutine ind;
       dcl-s string varchar(94);

       // print report
       dcl-pr p_JCRSUBRR2 extpgm('JCRSUBRR2');
        *n char(10);  // src mbr
        *n char(20);  // src file and lib
       end-pr;

       //--*ENTRY-------------------------------------------------
       dcl-pi *n;
        p_SrcMbr char(10);
        p_SrcFilQual char(20);
        p_Output char(8);
       end-pi;
       //---------------------------------------------------------

       f_RunCmd('CLRPFM JCRSUBRPF');
       extIfile = f_GetQual(p_SrcFilQual);
       open JCRSUBRPF;
       open RPGSRC;
       read RPGSRC SrcDS;
 1b    dow not %eof;

          // do not process compile time arrays
 2b       if f_IsCompileTimeArray(SrcDS.CompileArray);
 1v          leave;
 2e       endif;

          string = %trimr(SrcDS.Src80);
 2b       if not f_IsIgnoreLine(string);

             // spin through until into C specs proper.
             // if C or c or /free, inside the C specs.
 3b          if SrcDS.Asterisk = ' '
                and (SrcDS.SpecType = 'C'
                or SrcDS.SpecType = 'c'
                or SrcDS.SpecType = ' ');

                IsFree = (SrcDS.SpecType = ' ');

                //---------------------------------------------------------
                // For /free code, extract opcode into OpCodeExtract field.
                // Look for first ' ' and first ';'  , the one not
                // zero and lowest value is end of opcode
                //---------------------------------------------------------
                OpCodeExtract = SrcDS.OpCode;
 4b             if IsFree
                   and SrcDS.Src80 > *blanks;
                   WrkA = %triml(SrcDS.Src80);
                   aa = %scan(' ': WrkA: 1);
                   bb = %scan(';': WrkA: 1);
                   clear OpCodeExtract;

 5b                if aa > 0 and (aa < bb or bb = 0);
                      OpCodeExtract = %subst(WrkA: 1: aa - 1);
 5x                elseif bb > 0 and (bb < aa or aa = 0);
                      OpCodeExtract = %subst(WrkA: 1: bb - 1);
 5e                endif;
 4e             endif;

                OpCodeExtract = %xlate(lo: up: OpCodeExtract);

                // Extract Parent subroutine name
 4b             if OpCodeExtract = 'BEGSR';
                   IsInsideSubroutine = *on;

                   // /free subroutine will be
                   // following 'begsr' and before ';'
 5b                if IsFree;
                      UpperSrc = %xlate(lo: up: SrcDS.Src80);
                      aa = %scan('BEGSR ': UpperSrc: 1);
                      bb = %scan(';': SrcDS.Src80: aa + 6);
                      srParent =
                      %triml(
                      %subst(SrcDS.Src80: aa + 6: bb - (aa + 6)));
 5x                else;
                      srParent = SrcDS.Factor1;
 5e                endif;
                   srUpperCas = %xlate(lo: up: SrParent);
                   srChild = '**';
                   write JCRSUBRPFR;

                   // Extract Child  name
 4x             elseif OpCodeExtract = 'EXSR';

                   // /free subroutine will be
                   // following 'begsr' and before ';'
 5b                if not IsInsideSubroutine;
                      srParent = '***';
 5e                endif;

 5b                if IsFree;
                      UpperSrc = %xlate(lo: up: SrcDS.Src80);
                      aa = %scan('EXSR ': UpperSrc: 1);
                      bb = %scan(';': SrcDS.Src80: aa + 5);
                      srChild =
                      %triml(
                      %subst(SrcDS.Src80: aa + 5: bb - (aa + 5)));
 5x                else;
                      srChild = SrcDS.Factor2;
 5e                endif;
                   write JCRSUBRPFR;

 4x             elseif %subst(OpCodeExtract: 1: 3) = 'CAS'
                   and not IsFree;
 5b                if not IsInsideSubroutine;
                      srParent = '***';
 5e                endif;
                   srChild = SrcDS.ResultField;
                   write JCRSUBRPFR;
 4e             endif;
 3e          endif;
 2e       endif;

          read RPGSRC SrcDS;
 1e    enddo;

       close RPGSRC;
       close JCRSUBRPF;
       callp p_JCRSUBRR2(p_SrcMbr: p_SrcFilQual);
       f_DisplayLastSplf('JCRSUBRR2': p_Output);
       *inlr = *on;
       return;
