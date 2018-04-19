       //---------------------------------------------------------
       ctl-opt copyright('This program is free software, you can redistribute +
       it and/or modify it under the terms of the GNU General Public License +
       as published by the Free Software Foundation. See GNU General Public +
       License for detail.    Craig Rutledge      < www.jcrcmds.com > ');
       //---------------------------------------------------------
       // JCRSPLFV - Validity checking program
       //---------------------------------------------------------
       /define ControlStatements
       /define f_CheckObj
       // *ENTRY
       /define p_JCRSPLFR
       /COPY JCRCMDS,JCRCMDSCPY

 1b    if not(%subst(p_OutqQual: 1: 10) = '*ALL');
          f_CheckObj(p_OutqQual: '*OUTQ');
 1e    endif;

 1b    if not(p_Usrprf = '*ALL' or p_Usrprf = '*CURRENT');
          f_CheckObj(p_Usrprf + 'QSYS': '*USRPRF');
 1e    endif;

       *inlr = *on;
       return;
