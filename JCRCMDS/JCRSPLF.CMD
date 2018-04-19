/*--------------------------------------------------------------------------*/
/* JCRSPLF - List spool files with Options - CMD                            */
/*   Craig Rutledge  < www.jcrcmds.com >                                    */
/*--------------------------------------------------------------------------*/
             CMD        PROMPT('List Spool Files with Options')
             PARM       KWD(SPLFNAME) TYPE(*GENERIC) LEN(10) +
                          RSTD(*NO) DFT(*ALL) SPCVAL((*ALL)) +
                          PROMPT('Spooled File')

             PARM       KWD(USERDATA) TYPE(*CHAR) LEN(10) RSTD(*NO) +
                          DFT(*ALL) SPCVAL((*ALL)) PROMPT('User data')

             PARM       KWD(OUTQ) TYPE(OUTQ) PROMPT('Outq')
 OUTQ:       QUAL       TYPE(*NAME) LEN(10) DFT(*ALL) SPCVAL((*ALL))
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) SPCVAL((*LIBL)) PROMPT('Library')

             PARM       KWD(USER) TYPE(*NAME) LEN(10) RSTD(*NO) +
                          DFT(*CURRENT) SPCVAL((*CURRENT) (*ALL)) PROMPT('User')

             PARM       KWD(FORMTYPE) TYPE(*NAME) LEN(10) RSTD(*NO) +
                          DFT(*ALL) SPCVAL((*STD) (*ALL)) PROMPT('Form type')
