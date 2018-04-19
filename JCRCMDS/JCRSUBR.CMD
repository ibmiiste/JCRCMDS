/*--------------------------------------------------------------------------*/
/* JCRSUBR - Subroutines List - CMD                                         */
/*   Craig Rutledge  < www.jcrcmds.com >                                    */
/*--------------------------------------------------------------------------*/
             CMD        PROMPT('Subroutines List')
             PARM       KWD(PGM) TYPE(*NAME) LEN(10) MIN(1) +
                          PGM(*YES) PROMPT('RPG program')

             PARM       KWD(SRCFILE) TYPE(SRCFILE) PROMPT('Source file')
 SRCFILE:    QUAL       TYPE(*NAME) LEN(10) DFT(QRPGLESRC) SPCVAL((QRPGLESRC))
             QUAL       TYPE(*NAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL)) PROMPT('Library')

             PARM       KWD(OUTPUT) TYPE(*CHAR) LEN(8) RSTD(*YES) +
                          DFT(*) VALUES(* *PRINT) PROMPT('Output')
