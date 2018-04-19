       //---------------------------------------------------------
       ctl-opt copyright('This program is free software, you can redistribute +
       it and/or modify it under the terms of the GNU General Public License +
       as published by the Free Software Foundation. See GNU General Public +
       License for detail.    Craig Rutledge      < www.jcrcmds.com > ');
       //---------------------------------------------------------
       // JCRSUBRR2 - Subroutines List - print report
       //---------------------------------------------------------
       /define ControlStatements
       /define f_RunCmd
       /define f_OvrPrtf
       /define f_DltOvr
       /define f_Qusrmbrd
       /define f_BuildString
       /define f_GetDayName
       /COPY JCRCMDS,JCRCMDSCPY

       dcl-f JCRSUBRLF keyed extfile('JCRSUBRPF') extdesc('JCRSUBRPF')
       rename(jcrsubrpfr:bykeyr) prefix(x) usropn;
       dcl-f JCRSUBRPF usropn;
       dcl-f JCRSUBRP printer oflind(IsOverFlow) usropn;

       dcl-s Alpha100 char(100);
       dcl-s Alpha132 char(132);
       dcl-s scDow char(9);
       dcl-s LevelCnt uns(3);
       dcl-s scObjHead char(100);

       //--*ENTRY-------------------------------------------------
       dcl-pi *n;
        p_SrcMbr char(10);
        p_SrcFilQual char(20);
       end-pi;
       //---------------------------------------------------------

       open JCRSUBRPF;
       open JCRSUBRLF;
       f_OvrPrtf('JCRSUBRP': '*JOB': p_SrcMbr);
       open JCRSUBRP;
       scDow = f_GetDayName();
       QusrmbrdDS = f_Qusrmbrd(p_SrcFilQual: p_SrcMbr: 'MBRD0100');

       scObjHead =
       f_BuildString('Mbr: &   &   &   &':
       QusrmbrdDS.Mbr: QusrmbrdDS.File: QusrmbrdDS.Lib: QusrmbrdDS.Text);

       clear Alpha100;
       write PrtHead;
       IsOverFlow = *off;

       //---------------------------------------------------------
       // read back through work file,
       // generate begsr print line when SR name changes.
       // Function runs down SR execution stack.
       //---------------------------------------------------------
       read JCRSUBRPFR;
 1b    dow not %eof;

 2b       if not(srParent = Alpha100);
             Alpha100 = srParent;
             write PrtBegSR;
 3b          if IsOverFlow;
                write PrtHead;
                IsOverFlow = *off;
 3e          endif;
 2e       endif;

          LevelCnt = 1;
 2b       if not(srChild = '**');
             Run_Down_SR_Stack(srChild: LevelCnt);
 2e       endif;
          read JCRSUBRPFR;
 1e    enddo;

       close JCRSUBRPF;
       close JCRSUBRLF;
       f_RunCmd('CLRPFM JCRSUBRPF');
       close JCRSUBRP;
       f_DltOvr('JCRSUBRP');
       *inlr = *on;
       return;

       //---------------------------------------------------------
       // Print indented executed-from subroutine stack.
       // This recursive function follows parent-child subroutine chain down to end-of-chain.
       //---------------------------------------------------------
       dcl-proc Run_Down_SR_Stack;
        dcl-pi *n;
         p_ChildSR char(100);
         p_LevelCnt uns(3);
        end-pi;

        dcl-s Key100 char(100);
        dcl-s NextLevelCnt uns(3);
        dcl-c lo const('abcdefghijklmnopqrstuvwxyz');
        dcl-c up const('ABCDEFGHIJKLMNOPQRSTUVWXYZ');

        Key100 = %xlate(lo: up: p_ChildSR);

       // indent over 5 spaces for each level
        clear Alpha132;
        %subst(Alpha132: p_LevelCnt*5) =
        %char(p_LevelCnt) + ' ' + p_ChildSR;
        write PrtChild;
 1b     if IsOverFlow;
           write PrtHead;
           IsOverFlow = *off;
 1e     endif;

        NextLevelCnt = p_LevelCnt + 1;
       // now execute function recursively for each record
        setll key100 BYKEYR;
        reade key100 BYKEYR;
 1b     dow not %eof;
 2b        if not(xsrChild = '**');
              callp Run_Down_SR_Stack(xsrChild: NextLevelCnt);
 2e        endif;
           reade key100 BYKEYR;
 1e     enddo;
        return;

       end-proc;
