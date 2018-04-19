       //---------------------------------------------------------
       ctl-opt copyright('This program is free software, you can redistribute +
       it and/or modify it under the terms of the GNU General Public License +
       as published by the Free Software Foundation. See GNU General Public +
       License for detail.    Craig Rutledge      < www.jcrcmds.com > ');
       //---------------------------------------------------------------
       // JCRUSERSR -  Search User Profiles/ Outq / Jobd / Initial program
       //---------------------------------------------------------------
       ctl-opt dftactgrp(*no) actgrp(*stgmdl) datfmt(*iso) timfmt(*iso)
       option(*nounref: *nodebugio) expropts(*resdecpos) bnddir('JCRCMDSDIR')
       stgmdl(*teraspace) alloc(*stgmdl);

       dcl-f JCRUSERSD workstn sfile(sbfdta1:rrn1) infds(infds) indds(ind);
       dcl-f JCRUSERSP printer oflind(IsOverFlow) usropn;

       /define Sds
       /define Infds
       /define Constants
       /define FunctionKeys
       /define f_Quscrtus
       /define ApiErrDS
       /define f_GetDayName
       /define f_GetApiISO
       /define f_BuildString
       /define f_RunCmd
       /define f_RmvSflMsg
       /define f_SndSflMsg
       /define ListAuthorizedUsers
       /define f_GetEmail
       /COPY JCRCMDS,JCRCMDSCPY

       dcl-s rrn1 uns(5);
       dcl-s xx uns(5);
       dcl-s yy uns(5);
       dcl-s isfirsttime ind;
       dcl-s IsOk1 ind;
       dcl-s IsOk2 ind;
       dcl-s IsOk3 ind;
       dcl-s IsOk4 ind;
       dcl-s IsOk5 ind;
       dcl-s lenscan uns(3);
       dcl-s upcase char(50);

       //--*DATA STRUCTURES---------------------------------------
       // name screen indicators
       dcl-ds ind qualified;
        changes ind pos(12) inz(*off);
        sfldsp ind pos(31) inz(*off);
        sfldspctl ind pos(32) inz(*off);
       end-ds;

       // overlay portion of user space to store usri info.
      //  I can sort, search, and redisplay without loading file or reloading data
       dcl-ds Autu0100DS based(autu0100ptr) qualified;
        UsrPrf char(10);
        lastused char(10);
        Status char(10);
        Text char(39);
        Initialpgm char(10);
        InitialpgmL char(10);
        Jobd char(10);
        JobdL char(10);
        Outq char(10);
        OutqL char(10);
       end-ds;

       f_RmvSflMsg(ProgId);
       scDow = f_GetDayName();
       ApiHeadPtr = f_Quscrtus(UserSpaceName);
       exsr srclearsfl;
       isfirsttime = *on;

       //---------------------------------------------------------
       //---------------------------------------------------------
 1b    dou 1=2;
          ind.sfldsp = (rrn1 > 0);
          ind.sfldspctl = *on;

          write msgctl;
          write SFOOTER1;
          exfmt SBFCTL1;
          f_RmvSflMsg(ProgId);

 2b       if infdsfkey = f03
             or infdsfkey = f12;
             *inlr = *on;
             return;

 2x       elseif infdsfkey = f05;
             scuser = *blanks;
             sctext = *blanks;
             scinit = *blanks;
             scjobd = *blanks;
             scoutq = *blanks;
             exsr srclearsfl;

 2x       elseif infdsfkey = f06;
             exsr srPrint;
             f_SndSflMsg(ProgId: 'Print Completed');

 2x       elseif infdsfkey = f08;
             f_RunCmd('WRKSPLF');

 2x       elseif ind.changes;
 3b          if IsFirsttime;
                exsr srhardrefresh;
                isfirsttime = *off;
 3x          else;
                exsr srsearchuserspace;
 3e          endif;

             //----------------------------------------
 2x       elseif (rrn1 > 0);

             readc sbfdta1;
 3b          dow not %eof();

 4b             if sfopt = '2';
                   f_RunCmd(f_buildstring(
                   '?CHGUSRPRF USRPRF(&)':
                   sfusrprf));

 4x             elseif sfopt = '5';
                   f_RunCmd(f_buildstring(
                   'DSPUSRPRF USRPRF(&)':
                   sfusrprf));

 4x             elseif sfopt = '6';
                   wcusrprf = sfusrprf;
                   wctext = sftext;
                   wcAddress = f_GetEmail(sfusrprf);

 5b                if wcAddress = *blanks;
                      wcAddress = 'User Not Setup In WRKDIRE';
 5x                elseif wcAddress = '@';
                      wcAddress = 'Email Address Not Setup In WRKDIRE';
 5e                endif;
                   exfmt EMAILWIN;

 4x             elseif sfopt = '9';
                   f_RunCmd(f_buildstring(
                   'WRKUSRPRF USRPRF(&)':
                   sfusrprf));
 4e             endif;

                clear sfopt;
                update sbfdta1;

                readc sbfdta1;
 3e          enddo;

 2e       endif;
 1e    enddo;

       *inlr = *on;

       //---------------------------------------------------------
       //---------------------------------------------------------
       begsr srPrint;
       open JCRUSERSP;
       write PrtHead;
       IsOverFlow = *off;
       yy = rrn1;

 1b    for xx = 1 to yy;
          chain xx sbfdta1;
          write PrtDetail;
 2b       if IsOverFlow;
             write PrtHead;
             IsOverFlow = *off;
 2e       endif;
 1e    endfor;

       close JCRUSERSP;
       endsr;

       //---------------------------------------------------------
       // spin through user space applying filters
       //---------------------------------------------------------
       begsr srsearchuserspace;
       exsr srclearsfl;
       Autu0100ptr = ApiHeadPtr + ApiHead.OffSetToList;
 1b    for ForCount = 1 to ApiHead.ListEntryCount;

          exsr srApplyFilters;

          Autu0100Ptr += ApiHead.ListEntrySize;
 1e    endfor;
       endsr;

       //---------------------------------------------------------
       // load user profile names into user space.
       //---------------------------------------------------------
       begsr srhardrefresh;
       exsr srclearsfl;
 1b    if not isfirsttime;
          scuser = *blanks;
          sctext = *blanks;
          scinit = *blanks;
          scjobd = *blanks;
          scoutq = *blanks;
 1e    endif;

       callp QSYLAUTU(
             UserSpaceName:
             'AUTU0100':
             ApiErrDS);

       //---------------------------------------------------------
       // get user id then load info from qsyrusri into user space
       //  do initial sbfile load as quickly as possible.
       //---------------------------------------------------------
       Autu0100ptr = ApiHeadPtr + ApiHead.OffSetToList;
 1b    for ForCount = 1 to ApiHead.ListEntryCount;

          // retrieve values from the user profile.
          callp QSYRUSRI(
                Usri0300DS:
                %len(Usri0300DS):
                'USRI0300':
                Autu0100DS.UsrPrf:
                ApiErrDS);

          Autu0100DS.LastUsed = f_GetApiISO(Usri0300DS.PrvSignDatTim);
          Autu0100DS.Status = usri0300DS.status;
          Autu0100DS.Text = usri0300DS.text;
          Autu0100DS.Initialpgm = usri0300DS.InitialPgm;
          Autu0100DS.InitialpgmL = usri0300DS.InitialPgmL;
          Autu0100DS.Jobd = usri0300DS.Jobd;
          Autu0100DS.JobdL = usri0300DS.JobdL;
          Autu0100DS.Outq = usri0300DS.Outq;
          Autu0100DS.OutqL = usri0300DS.OutqL;

          exsr srApplyFilters;

          Autu0100Ptr += ApiHead.ListEntrySize;
 1e    endfor;
       endsr;

       //-----------------------
       //-----------------------
       begsr srclearsfl;
       ind.sfldsp = *off;
       ind.sfldspctl = *off;
       write SBFCTL1;
       ind.sfldspctl = *on;
       rrn1 = 0;
       sfopt = *blanks;
       endsr;

       //-----------------------
       // if first character is blank, then filter is a wild card
       // if first character <> blank, then trailing is wild card
       // scuser is position to.
       // sctext, scinit, scjobd, scoutq is only show these.
       //-----------------------
       begsr srApplyFilters;

       IsOk1 = *off;
 1b    if scuser > *blanks;
 2b       if %subst(scuser:1:1)>*blanks;
             lenscan = %len(%trimr(scuser));
 3b          if %subst(Autu0100DS.usrprf:1:lenscan) >= scuser;
                IsOk1 = *on;
 3e          endif;
 2x       else;
 3b          if %scan(%trim(scuser): Autu0100DS.usrprf: 1) > 0;
                IsOk1 = *on;
 3e          endif;
 2e       endif;
 1x    else;
          IsOk1 = *on;
 1e    endif;

       //-----------------------------
       IsOk2 = *off;
 1b    if sctext > *blanks;
          upcase = %xlate(lo:up:Autu0100DS.text);

 2b       if %subst(sctext:1:1)>*blanks;
             lenscan = %len(%trimr(sctext));
 3b          if %subst(upcase:1:lenscan) = sctext;
                IsOk2 = *on;
 3e          endif;
 2x       else;
 3b          if %scan(%trim(sctext): upcase: 1) > 0;
                IsOk2 = *on;
 3e          endif;
 2e       endif;
 1x    else;
          IsOk2 = *on;
 1e    endif;

       //-----------------------------
       IsOk3 = *off;
 1b    if scinit > *blanks;

 2b       if %subst(scinit:1:1)>*blanks;
             lenscan = %len(%trimr(scinit));
 3b          if %subst(Autu0100DS.Initialpgm:1:lenscan) = scinit;
                IsOk3 = *on;
 3e          endif;
 2x       else;
 3b          if %scan(%trim(scinit): Autu0100DS.Initialpgm: 1) > 0;
                IsOk3 = *on;
 3e          endif;
 2e       endif;

 1x    else;
          IsOk3 = *on;
 1e    endif;

       //-----------------------------
       IsOk4 = *off;
 1b    if scjobd > *blanks;

 2b       if %subst(scjobd:1:1)>*blanks;
             lenscan = %len(%trimr(scjobd));
 3b          if %subst(Autu0100DS.Jobd:1:lenscan) = scjobd;
                IsOk4 = *on;
 3e          endif;
 2x       else;
 3b          if %scan(%trim(scjobd): Autu0100DS.Jobd: 1) > 0;
                IsOk4 = *on;
 3e          endif;
 2e       endif;

 1x    else;
          IsOk4 = *on;
 1e    endif;

       //-------------------------------------
       IsOk5 = *off;
 1b    if scoutq > *blanks;

 2b       if %subst(scoutq:1:1)>*blanks;
             lenscan = %len(%trimr(scoutq));
 3b          if %subst(Autu0100DS.Outq:1:lenscan) = scoutq;
                IsOk5 = *on;
 3e          endif;
 2x       else;
 3b          if %scan(%trim(scoutq): Autu0100DS.Outq: 1) > 0;
                IsOk5 = *on;
 3e          endif;
 2e       endif;

 1x    else;
          IsOk5 = *on;
 1e    endif;

 1b    if IsOk1 and IsOk2 and IsOk3 and IsOk4 and IsOk5;
          rrn1 += 1;
          sfusrprf = Autu0100DS.UsrPrf;
          sftext = Autu0100DS.text;
          sfLastUsed = Autu0100DS.lastused;
          sfstatus = Autu0100DS.status;
          sfinitpgm = Autu0100DS.Initialpgm;
          sfinitlib = Autu0100DS.InitialpgmL;
          sfjobd    = Autu0100DS.Jobd;
          sfjobdlib = Autu0100DS.JobdL;
          sfoutq =    Autu0100DS.Outq;
          sfoutqlib = Autu0100DS.OutqL;
          write sbfdta1;
 1e    endif;
       endsr;
