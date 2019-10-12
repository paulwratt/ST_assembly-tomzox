; ----------------------------------------------------------------------------
; Copyright 1987-1988,2019 by T.Zoerner (tomzo at users.sf.net)
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; ----------------------------------------------------------------------------
 module    BUTTON_1
 ;section   zwei
 ;pagelen   32767
 ;pagewid   133
 ;noexpand
 include "f_sys.s"
 include "f_def.s"
 ;
 XREF  frmodus,frmuster,frtext,frlinie,frraster,frzeiche
 XREF  chookoo,choofig,chooset,chooras,chootxt,choopat,chooseg
 XREF  menu_adr,rec_adr,drawflag,mrk,logbase,bildbuff
 XREF  maus_rec,copy_blk,save_scr,fram_del,form_do,form_del
 XREF  hide_m,show_m,work_blk,work_bl2,alertbox,pinsel,spdose,gummi
 XREF  punkt,kurve,radier,over_old,over_que,over_beg,mfdb_q
 ;
 XDEF  evt_butt,stack,appl_id,aescall,vdicall,grhandle,aespb,vdipb
 XDEF  contrl,intin,intout,ptsin,ptsout,addrin,addrout,mark_buf
 XDEF  win_xy,fram_drw,save_buf,win_abs,noch_qu,return,set_wrmo
 XDEF  koos_mak,clip_on,new_1koo,new_2koo,set_att2,ret_att2
 XDEF  ret_attr,set_attr,fram_ins,last_koo

**********************************************************************
*  A6  Address of INTIN
*  A5  Address of CONTRL
*  A4  Address of PTSIN
**********************************************************************
          ;
evt_butt  lea       win_xy,a0           WIN_XY: window coords.
          move.l    YX_OFF(a4),8(a0)
          clr.w     12(a0)
          bsr       win_abs
          move.l    maus_rec+16,d0
          bsr       alrast              round X/Y to closest point in alrast, if enabled
          move.l    d0,maus_rec+16
          move.w    d0,d1
          swap      d0
          bsr       noch_in             click into window?
          bne       donot               no -> abort
          cmp.w     #$43,choofig        ++ Selection tool active? ++
          bne.s     evt_but5
          move.w    mark_buf,d2         selection ongoing?
          beq.s     evt_but4
          lea       mark_buf+2,a0
          add.w     win_xy+8,d1
          add.w     win_xy+10,d0
          bsr       noch_in             click into selection area?
          beq       schub               -> move selection
          bsr       fram_drw
          bra.s     evt_but4
evt_but5  move.l    drawflag+12,d0      ++ regular tool ++
          cmp.l     BILD_ADR(a4),d0
          bne.s     evt_but4
          clr.w     mrk+EINF            disable "paste"
          move.l    menu_adr,a0
          bset.b    #3,1643(a0)
evt_but4  bsr       save_scr
          lea       drawflag,a0
          move.w    #$ff00,(a0)
          lea       last_koo,a0
          clr.w     8(a0)
          lea       ptsin,a4            A4: address of PTSIN
          move.l    maus_rec+16,d3      D3: mouse X/Y-pos.
*- - - - - - - - - - - - - - - - - - - - - - - - - - -GRAPHICS-HANDLER
          move.w    choofig,d0
          cmp.b     #$55,d0
          beq       pospe               save position
          cmp.b     #$43,d0
          bne.s     evt_but6
          moveq.l   #$27,d0             mark selection
evt_but6  sub.w     #$1f,d0
          lsl.w     #1,d0
          lea       tool_func_table,a0
          move.w    (a0,d0.w),d0
          jsr       (a0,d0.w)
          ;
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit_beg  lea       last_koo,a1         + convert coordinates to absolute +
          move.w    8(a1),d2
          beq.s     exit1
          move.l    rec_adr,a0
          move.w    YX_OFF(a0),d0
          move.w    YX_OFF+2(a0),d1
          cmp.w     #1,d2
          beq.s     exit2
          add.w     d0,2(a1)
          add.w     d1,(a1)
exit2     add.w     d0,6(a1)
          add.w     d1,4(a1)
exit1     move.b    drawflag,d0
          beq.s     exit6
          move.l    rec_adr,a0          abs window?
          move.w    SCHIEBER(a0),d0     -> no backup needed
          bmi       exit6
          bsr       save_buf            save buffer
          bsr       win_abs             + start new selection +
          move.l    win_xy,d0
          move.l    win_xy+4,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF(a0),d2
          add.l     YX_OFF+2(a0),d2
          move.l    BILD_ADR(a0),a1
          move.l    logbase,a0
          bsr       copy_blk
exit3     move.l    menu_adr,a0
          bclr.b    #3,491(a0)          enable "undo"
          move.w    mark_buf,d0
          beq.s     exit6
          bsr       fram_drw
exit6     bsr       show_m
exit7     move.b    maus_rec+1,d0       wait for mouse button to be released
          bne       exit7
          clr.w     maus_rec
exit_rts  rts
          ;
donot     lea       maus_rec,a0         mouse click unhandled
          move.w    #-1,2(a0)
          rts
          ;
*---------------------------------------------------------------------
tool_func_table:
          dc.w     punkt-tool_func_table
          dc.w     pinsel-tool_func_table
          dc.w     spdose-tool_func_table
          dc.w     fuellen-tool_func_table
          dc.w     text-tool_func_table
          dc.w     radier-tool_func_table
          dc.w     gummi-tool_func_table
          dc.w     linie-tool_func_table
          dc.w     quadrat-tool_func_table
          dc.w     quadrat-tool_func_table
          dc.w     linie-tool_func_table
          dc.w     kreis-tool_func_table
          dc.w     kreis-tool_func_table
          dc.w     kurve-tool_func_table
          ;
*---------------------------------------------------GRAPHICS-FUNCTIONS
pospe     lea       drawflag,a0         *** Save position ***
          clr.w     (a0)
          move.l    rec_adr,a0
          add.w     YX_OFF(a0),d3
          add.l     YX_OFF+2(a0),d3
          lea       last_koo,a0
          move.l    4(a0),(a0)+
          move.l    d3,(a0)
          bra       exit7
          ;
linie     dc.w      $a000               *** Shape: Line ***
          move.l    a0,a3
          move.l    d3,38(a3)           starting coord.
          clr.l     d4
          bra.s     linie2+2
linie2    move.l    d3,d4               D2: last end point
          bsr       noch_qu
          bsr       hide_m
          move.w    #$aaaa,34(a3)       line pattern: gray
          move.w    #2,36(a3)           drawing mode XOR
          tst.w     d4
          beq.s     linie3
          move.l    d4,42(a3)           remove previous line
          dc.w      $a003
linie3    move.b    maus_rec+1,d0
          beq.s     linie1
          move.l    d3,42(a3)           draw new line
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bsr       show_m
          bra       linie2
linie1    tst.w     d4                  mouse moved?
          beq.s     linie4
          move.w    choofig,d0
          cmp.w     #$29,d0             polygon?
          beq.s     vieleck
linie4    bsr       set_att2            --- finalize line ---
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          move.l    d0,(a6)
          vdi       108 0 2             ;...end_styles
          move.l    38(a3),d0
          move.l    d3,d1
          bsr       new_2koo
          move.l    d0,(a4)
          move.l    d3,4(a4)
          vdi       6 2 0               ;polyline
          bra       ret_att2
          ;
vieleck   clr.w     maus_rec            *** Shape: Polygon ***
          move.l    bildbuff,a2
          move.l    38(a3),(a2)+
          move.l    d4,(a2)
          move.l    a2,d7
          move.l    d4,d6
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bsr       show_m
vieleck7  moveq.l   #-1,d3              wait for first mouse movement
          bsr       vieleck3            RETURN key?
          move.l    maus_rec+12,d0
          lea       win_xy,a0
          bsr       corr_adr
          cmp.l     d6,d3
          beq       vieleck7
          bsr       hide_m
          move.l    d7,d0               first/starting line drawn?
          sub.l     bildbuff,d0
          cmp.l     #4,d0
          bls.s     vieleck2
          move.l    d6,42(a3)           delete previous "root" line
          move.l    bildbuff,a0
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
vieleck2  move.l    d3,d4               +++ Loop +++
          bsr       viele_dr            draw new line
          bsr       show_m
vieleck4  bsr.s     vieleck3            RETURN key?
          moveq.l   #-1,d3
          move.w    maus_rec,d0         mouse botton?
          bne.s     vieleck5
          move.l    maus_rec+12,d0      mouse moved?
          lea       win_xy,a0
          bsr       corr_adr
          cmp.l     d3,d4
          beq       vieleck4
          bsr       hide_m              delete old lines
          bsr       viele_dr
          bra       vieleck2
          ;
vieleck5  bsr       hide_m              +++ mouse click +++
          addq.l    #4,d7
          move.l    d7,a2
          move.l    d4,(a2)
          move.l    d4,d6
vieleck6  move.b    maus_rec+1,d0
          bne       vieleck6
          clr.w     maus_rec
          bsr       show_m
          move.l    d7,d0               more than 128 corners?
          sub.l     bildbuff,d0
          lsr.w     #2,d0
          sub.b     #2,d0
          bpl       vieleck7
          lea       stralmax,a0         yes -> display error dialog
          moveq.l   #1,d0
          bsr       alertbox
          bra.s     vielec10
          ;
vieleck3  move.w    #$b,-(sp)           ;bconstat
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bpl       tool_rts
          move.w    #1,-(sp)            ;conin
          trap      #1
          addq.l    #2,sp
          cmp.w     #13,d0              Return ?
          beq.s     vielec12
          move.l    d7,d0               +++ Backspace key pressed +++
          sub.l     bildbuff,d0
          cmp.l     #4,d0
          bls       tool_rts
          addq.l    #4,sp
          bsr       hide_m
          bsr       viele_dr
          subq.l    #4,d7
          move.l    d7,a0
          move.l    (a0),38(a3)
          move.l    4(a0),42(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bra       vieleck2
vielec12  lea       stralvie,a0         +++ Return key pressed +++
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #2,d0
          beq       exit7               wait for mouse button to be released
          addq.l    #4,sp
vielec10  bsr       hide_m
          move.l    bildbuff,a0         delete polygon
          move.w    #2,36(a3)
          addq.l    #4,d7
          move.l    d7,a1
          tst.l     d3
          bmi.s     vieleck9
          move.l    d4,(a1)+
          addq.l    #4,d7
vieleck9  move.l    (a0),(a1)
          move.l    d7,d5               only two corners?
          sub.l     bildbuff,d5
          subq.l    #8,d5
          bne.s     vieleck8
          clr.l     d7
          move.l    -4(a1),d3
vieleck8  move.l    (a0)+,38(a3)
          move.l    (a0),42(a3)
          move.l    a0,d6
          move.w    #$aaaa,34(a3)
          dc.w      $a003
          move.l    d6,a0
          cmp.l     a0,d7
          bhi       vieleck8
          tst.w     d5
          beq       linie4
          bsr       set_attr            set attributes
          moveq.l   #9,d0
          move.w    chooset,d1          filling enabled?
          bne.s     vieleck1
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          btst      #16,d0
          bne.s     vielec11            round corners
          bset      #17,d0
vielec11  move.l    d0,(a6)
          vdi       108 0 2             ;line end mode
          moveq.l   #6,d0
vieleck1  move.w    d0,(a5)             Polyline/Fill area
          lea       vdipb+8,a2
          move.l    bildbuff,(a2)
          move.l    d7,d0
          sub.l     bildbuff,d0
          lsr.w     #2,d0
          addq.w    #1,d0
          move.w    d0,2(a5)
          clr.w     6(a5)
          bsr       vdicall
          move.l    a4,(a2)
          bra       ret_attr
          ;
viele_dr  move.l    d7,a0               +++ Draw lines on screen +++
          move.l    d4,42(a3)
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          move.l    bildbuff,a0
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          dc.w      $a003
          rts
          ;
fuellen   bsr       new_1koo            *** Shape: Fill ***
          vdi       23 0 1 !frmuster+6  ;fill_style
          vdi       24 0 1 !frmuster+20 ;fill_index
          vdi       25 0 1 !frmuster+34 ;fill_color
          bsr       hide_m
          bsr       clip_on
          move.l    d3,(a4)
          move.w    frmuster+34,(a6)
          vdi       103 1 1             ;contour_fill
          vdi       23 0 1 1
          bra       return
          ;
quadrat   dc.w      $a000               *** Tools: Square, Rectangle ***
          move.l    a0,a3
          move.w    #-1,32(a3)          dummy
          move.l    d3,38(a3)
          move.w    d3,d7               D7: Y-root
          move.l    d3,d6               D6: X-root
          swap      d6
          clr.w     d4
quadrat1  bsr       noch_qu
          bsr       hide_m
          move.w    #$aaaa,34(a3)       line pattern
          tst.w     d4
          beq.s     quadrat5
          bsr       quadr_dr
quadrat5  move.b    maus_rec+1,d0
          beq.s     quadrat2
          move.w    d3,d5               D5: Y-new
          move.l    d3,d4               D4: X-new
          swap      d4
          cmp.b     #$28,choofig+1      square?
          bne.s     quadra10
          move.w    d4,d0
          move.w    d5,d1
          sub.w     d6,d0
          bpl.s     quadra11
          not.w     d0
          addq.w    #1,d0
quadra11  sub.w     d7,d1
          bpl.s     quadra12
          not.w     d1
          addq.w    #1,d1
quadra12  cmp.w     d0,d1               height >= width?
          bhs.s     quadra13
          cmp.w     d4,d6
          bhs.s     quadra14
          move.w    d6,d4
          add.w     d1,d4               no -> width := height
          bra.s     quadra10
quadra14  move.w    d6,d4
          sub.w     d1,d4
          bra.s     quadra10
quadra13  cmp.w     d5,d7
          bhs.s     quadra15
          move.w    d7,d5
          add.w     d0,d5               yes -> height := width
          bra.s     quadra10
quadra15  move.w    d7,d5
          sub.w     d0,d5
quadra10  bsr       quadr_dr
          bsr       show_m
          bra       quadrat1
quadrat2  cmp.w     #$43,choofig        --- finalize square ---
          beq       markier
          tst.w     d4                  mouse never moved -> abort
          beq       tool_rts
          bsr       set_attr            set attributes
          move.w    chooset+2,d0
          bne       quadrat7            -> rounded corners
          move.w    chooset,10(a5)
          bne.s     quadrat6            -> fill
          vdi       108 0 2 0 2
          vdi       6 5 0 !d6 !d7 !d4 !d7 !d4 !d5 !d6 !d5 !d6 !d7
          vdi       108 0 2 0 0
          bra.s     quadrat9
quadrat6  move.w    #1,10(a5)           ;bar
          bra.s     quadrat8
quadrat7  move.w    #8,10(a5)           ;rounded_rec
          move.w    chooset,d0
          beq.s     quadrat8
          move.w    #9,10(a5)           ;filled_rounded_rec
quadrat8  ;
          vdi       11 2 0 !d6 !d7 !d4 !d5
quadrat9  lea       last_koo,a0         store coords.
          move.w    d6,(a0)
          move.w    d7,2(a0)
          move.w    d4,4(a0)
          move.w    d5,6(a0)
          move.w    #-1,8(a0)
          bra       ret_attr
          ;
quadr_dr  move.w    #2,36(a3)           ++ Draw rubberband-rectangle ++
          move.w    #1,24(a3)
          move.w    d6,38(a3)
          move.w    d7,40(a3)
          move.w    d4,42(a3)
          move.w    d7,44(a3)
          dc.w      $a003               x1y1-x2y1
          move.w    d6,42(a3)
          move.w    d5,44(a3)
          dc.w      $a003               x1y1-x1y2
          move.w    d4,42(a3)
          move.w    d5,40(a3)
          dc.w      $a003               x1y2-x2y2
          move.w    d4,38(a3)
          move.w    d7,40(a3)
          dc.w      $a003               x2y1-x2y2
          rts
          ;
markier   move.b    mrk+OV,d0           *** Mark selection ***
          beq.s     markier6
          move.w    mark_buf,d0
          beq.s     markier6
          move.b    mrk+CHG,d0
          beq.s     markier6
          bsr       show_m
          bsr       over_que            ask to confirm "commit selection?"
          move.w    d0,d2
          bsr       hide_m
          cmp.w     #1,d2
          beq.s     markier6
          addq.l    #4,sp
          bra       exit3
markier6  lea       drawflag,a0         disable "undo"
          clr.w     (a0)
          tst.w     d4
          bne.s     markier4
          lea       mark_buf,a2         --- only delete borders ---
          clr.b     (a2)
          bsr       fram_del
          addq.l    #4,sp
          bra       exit6
markier4  cmp.w     d4,d6               --- new borders ---
          blo.s     markier1
          exg       d4,d6
markier1  cmp.w     d5,d7
          blo.s     markier2
          exg       d5,d7
markier2  add.w     win_xy+8,d5         convert coords. to abs.
          add.w     win_xy+8,d7
          add.w     win_xy+10,d4
          add.w     win_xy+10,d6
          lea       mark_buf,a0
          move.w    #-1,(a0)
          move.w    d6,2(a0)            store X1Y1 & X2Y2
          move.w    d7,4(a0)
          move.w    d4,6(a0)
          move.w    d5,8(a0)
          lea       last_koo,a1         save coords.
          move.l    2(a0),(a1)
          move.l    6(a0),4(a1)
          bsr       fram_drw
          move.l    menu_adr,a2
          bset.b    #3,1643(a2)
          move.b    mrk+OV,d0           overlay mode?
          beq.s     markier5
          bsr       over_beg
          bclr.b    #3,1667(a2)         enable "discard" command
          move.b    mrk+COPY,d0
          bne.s     markier5
          bclr.b    #3,1643(a2)
markier5  lea       1739(a2),a0
          moveq.l   #7,d0               enable menu commands
markier3  bclr.b    #3,(a0)
          add.w     #24,a0
          dbra      d0,markier3
          lea       mrk,a0
          clr.b     EINF(a0)            no paste
          clr.b     OVKU(a0)
          clr.w     MODI(a0)            no combination mode
          clr.b     CHG(a0)             unmodified
          clr.b     PART(a0)            no cut-off
          rts
          ;
kreis     bsr       clip_on             *** Shape: Circle/Arc & Ellipsis ***
          vdi       32 0 1 3            XOR
          vdi       15 0 1 7            self-defined line type
          vdi       16 1 0 1 0          line width 1
          vdi       17 0 1 1            line color black
          vdi       113 0 1 $aaaa       line style gray
          vdi       23 0 1 0            no filling
          move.w    d3,d5               D5: Y-coord. of center
          move.l    d3,d4               D4: X-coord.
          swap      d4
          moveq.l   #-1,d6
          clr.w     d7
kreis1    bsr       noch_qu             ---- Loop ----
          bsr       hide_m
          tst.w     d6
          bmi.s     kreis2
          bsr       kreis_k
kreis2    move.b    maus_rec+1,d0
          beq.s     kreis3
          move.w    d3,d7               D7: Y-offset
          sub.w     d5,d7
          bpl.s     kreis4
          not.w     d7
          addq.w    #1,d7
kreis4    move.l    d3,d6               D6: X-offset
          swap      d6
          sub.w     d4,d6
          bpl.s     kreis9
          not.w     d6
          addq.w    #1,d6
kreis9    cmp.b     #$2a,choofig+1      Circle?
          bne.s     kreis10
          cmp.w     d6,d7               yes -> choose larger of radius values
          bls.s     kreis10
          move.w    d7,d6
kreis10   bsr       kreis_k
          bsr       show_m
          bra       kreis1
kreis3    tst.w     d6                  ---- finalize circle ----
          bmi       tool_rts
          bsr       set_attr
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          move.l    d0,(a6)
          vdi       108 0 2             ;end_styles
          move.w    chooseg,d1
          move.w    chooseg+2,d2
          move.w    choofig,d3
          moveq.l   #2,d0
          add.w     chooset,d0          arc or pie?
          cmp.b     #3,d0
          bne.s     kreis6
          tst.w     d1
          bne.s     kreis6
          cmp.w     #3600,d2
          beq.s     kreis8              -> circle
kreis6    cmp.w     #$2b,d3
          beq       kreis12             -> arc of ellipsis
          move.w    d0,10(a5)
          vdi       11 4 2 !d4 !d5 0 0 0 0 !d6 0 !d1 !d2  ;arc/pie
          bra.s     kreis7
kreis8    cmp.w     #$2b,d3
          beq.s     kreis11             -> ellipsis
          move.w    #4,10(a5)
          vdi       11 3 0 !d4 !d5 0 0 !d6 0  ;filled_circle
          bra.s     kreis7
kreis11   moveq.l   #1,d0
kreis12   add.w     #4,d0
          move.w    d0,10(a5)
          vdi       11 2 2 !d4 !d5 !d6 !d7 !d1 !d2  ;ellipse/arc/pie
kreis7    lea       last_koo,a0
          move.w    d4,(a0)             store coords.
          move.w    d5,2(a0)
          add.w     d6,d4
          add.w     d7,d5
          move.w    d4,4(a0)
          move.w    d5,6(a0)
          move.w    #-1,8(a0)
          bra       ret_attr
          ;
kreis_k   move.l    chooseg,(a6)
          cmp.b     #$2b,choofig+1
          beq.s     kreis_e
          move.w    #2,10(a5)
          vdi       11 4 2 !d4 !d5 0 0 0 0 !d6 0  ;arc
          rts
kreis_e   move.w    #6,10(a5)
          vdi       11 4 2 !d4 !d5 !d6 !d7  ;elliptical_arc
          rts
          ;
text      bsr       new_1koo            *** Shape: Text ***
          move.l    rec_adr,a0
          bsr       save_buf
          lea       data_buf,a2
          move.l    d3,(a2)
          bsr       text_att            configure attributes
          lea       stack,a3
text3     move.b    maus_rec+1,d0       wait for button release
          bne       text3
          clr.w     maus_rec
text1     bsr       show_m              +++ Loop +++
text11    move.b    maus_rec,d0
          bne       text4
          move.w    #$b,-(sp)           ;constat
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bpl       text11
          bsr       hide_m
          move.w    #7,-(sp)            ;conin without echo
          trap      #1
          addq.l    #2,sp
          cmp.l     #$620000,d0         Help key pressed?
          bne.s     text13
          moveq.l   #-1,d0
text13    cmp.l     #$610000,d0         UNDO key pressed?
          bne.s     text14
          moveq.l   #-2,d0
text14    tst.b     d0                  not an ASCII-key?
          beq       text1
          cmp.b     #13,d0              Return?
          bne       text2
          move.w    6(a2),d1            -> down by one line
          lea       win_xy,a0
          move.w    4(a2),d0
          bne.s     text12
          add.w     d1,2(a2)            0 degree angle
          move.w    6(a0),d0
          cmp.w     2(a2),d0
          blo       text4
          bra.s     text17
text12    cmp.w     #1,d0               90 degree angle
          bne.s     text18
          add.w     d1,(a2)
          move.w    4(a0),d0
          cmp.w     (a2),d0
          blo       text4
          bra.s     text17
text18    cmp.w     #2,d0               180 degree angle
          bne.s     text19
          sub.w     d1,2(a2)
          move.w    2(a0),d0
          cmp.w     2(a2),d0
          bhi       text4
          bra.s     text17
text19    sub.w     d1,(a2)             270 degree angle
          move.w    (a0),d0
          cmp.w     2(a2),d0
          bhi       text4
text17    move.l    win_xy,d0           temporary copy of image
          move.l    win_xy+4,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF(a0),d2
          add.l     YX_OFF+2(a0),d2
          move.l    BILD_ADR(a0),a1
          move.l    logbase,a0
          bsr       copy_blk
          lea       stack,a3
          lea       data_buf,a2
          bra       text1
          ;
text2     move.w    d0,d2
          lea       stack,a0
          lea       vdipb+4,a1
          move.l    a0,(a1)
          cmp.l     a0,a3               at least one char in the text buffer?
          beq       text7
          movem.l   d2/a2-a3,-(sp)      +++ restore image +++
          move.l    a3,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          vdi       116 0 !d0           ;inquire_text_extend
          move.l    data_buf,d0
          move.l    d0,d1
          move.w    data_buf+4,d3       vertical text?
          btst      #0,d3
          bne.s     text20
          sub.l     ptsout+12,d0        0+180 degrees
          add.l     ptsout+4,d1
          bra.s     text21
text20    cmp.b     #1,d3               90 degrees
          bne.s     text22
          sub.l     ptsout+4,d0
          bra.s     text21
text22    move.l    ptsout+12,d2        270 degrees
          swap      d2
          add.l     d2,d1
text21    sub.l     #$30003,d0
          add.l     #$30003,d1
          bsr       lim_win             clip to window
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF(a0),d0
          add.w     YX_OFF(a0),d1
          add.l     YX_OFF+2(a0),d0
          add.l     YX_OFF+2(a0),d1
          move.l    BILD_ADR(a0),a0
          move.l    logbase,a1
          bsr       copy_blk
          movem.l   (sp)+,d2/a2-a3
          cmp.b     #8,d2               Backspace key?
          bne.s     text8
          subq.w    #2,a3               -> delete last character
          lea       stack,a0            char buffer empty?
          cmp.l     a0,a3
          bne       text15+2            no -> draw string again
          bra       text9
          ;
text7     cmp.b     #8,d2               not backspace
          beq       text9
text8     move.w    d2,d3               Help or Undo keys?
          bpl       text15
          lea       vdipb+4,a0          +++ Formulare +++
          move.l    a6,(a0)
          bsr       show_m
          bsr       text_rat
          movem.l   a2-a4/d2,-(sp)
          move.l    rec_adr,a4
          moveq.l   #9,d2
          lea       frtext,a2
          cmp.w     #-1,d3
          beq.s     text16
          moveq.l   #17,d2
          lea       frzeiche,a2
text16    bsr       form_do
          bsr       form_del
          bsr       hide_m
          move.l    win_xy,d0           redisplay image
          move.l    win_xy+4,d1
          move.l    d0,d2
          add.w     YX_OFF(a4),d0
          add.w     YX_OFF(a4),d1
          add.l     YX_OFF+2(a4),d0
          add.l     YX_OFF+2(a4),d1
          move.l    BILD_ADR(a4),a0
          move.l    logbase,a1
          bsr       copy_blk
          movem.l   (sp)+,a2-a4/d2
          bsr       text_att
text6     move.b    maus_rec+1,d0
          bne       text6
          clr.w     maus_rec
          lea       vdipb+4,a0
          lea       stack,a1
          move.l    a1,(a0)
          cmp.w     #-1,d2              UNDO-key?
          beq.s     text15+2
          move.w    frzeiche+6,d2
          ;
text15    move.w    d2,(a3)+            +++ draw new string +++
          clr.w     (a3)
          lea       stack,a0
          move.l    a3,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          move.l    (a2),(a4)
          vdi       8 1 !d0             ;text
text9     lea       vdipb+4,a0
          move.l    a6,(a0)
          bra       text1
          ;
text4     move.l    bildbuff,a0         +++ End +++
          move.l    rec_adr,a1
          move.l    BILD_ADR(a1),a1
          move.w    #1999,d0
text5     move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,text5
          bsr       hide_m
text_rat  ;
          vdi       39 0 2 0 0          +++ Restore attributes +++
          vdi       13 0 1 0
          vdi       106 0 1 0
          vdi       22 0 1 1
          vdi       12 1 0 0 13
          bra       return
text_att  move.w    frtext+20,d0        +++ Configure attributes +++
          move.w    d0,d1
          mulu.w    #10,d0
          ext.l     d1
          add.w     #45,d1              calc. quadrant
          divu      #90,d1
          move.w    d1,4(a2)
          vdi       13 0 1 !d0          ;angle
          vdi       22 0 1 !frtext+34   ;color
          vdi       106 0 1 !chootxt    ;effects
          vdi       12 1 0 0 !frtext+6  ;size
          move.w    ptsout+6,d0
          btst.b    #4,chootxt+1        border?
          beq.s     text_at1
          addq.w    #2,d0
text_at1  move.w    d0,6(a2)            line height
          vdi       39 0 2 0 3          ;orientation
          bsr       set_wrmo
          bra       clip_on
          ;
schub     move.b    mrk+MODI,d7         *** Move selection ***
          bsr       over_old
          lea       mrk,a2
          move.b    d7,MODI(a2)
          move.l    COPY(a2),d2
          bsr       save_scr
          move.l    d2,COPY(a2)
          tst.b     DEL(a2)             delete old selection?
          beq.s     schub1
          clr.b     DEL(a2)
          clr.w     d3
          move.l    bildbuff,a0
          move.l    drawflag+4,d0
          move.l    drawflag+8,d1
          bsr       work_bl2
schub1    lea       stack,a3            + set parameters +
          move.l    mark_buf+2,d0
          move.l    mark_buf+6,d1
          lea       drawflag+4,a1
          move.l    d0,(a1)+            store prev. border coords.
          move.l    d1,(a1)
          move.l    d0,d2
          move.l    d1,d3
          move.b    mrk+PART,d4         restore cut-off?
          bpl.s     schub7
          move.b    mrk+OV,d4
          beq.s     schub7
          move.l    mrk+OLD,d2
          move.l    mrk+OLD+4,d3
          sub.w     mrk+OLD+10,d0
          swap      d0
          sub.w     mrk+OLD+8,d0
          swap      d0
schub7    move.l    d2,24(a3)           24: source coord.
          move.l    d3,28(a3)
          sub.l     d2,d3
          move.l    d3,8(a3)            8: selection width
          move.l    rec_adr,a0
          sub.w     YX_OFF(a0),d0
          sub.l     YX_OFF+2(a0),d0
          sub.w     YX_OFF(a0),d1
          sub.l     YX_OFF+2(a0),d1
          move.l    maus_rec+16,(a3)    0: prev. mouse coords.
          move.l    d0,4(a3)            4: cur selection frame coords.
          bsr       lim_win
          lea       mark_buf+2,a1       cur frame (rel)
          move.l    d0,(a1)+
          move.l    d1,(a1)
          clr.b     12(a3)              12: borders deleted?
          move.b    mrk+OV,d0
          beq.s     schub9
          move.b    mrk+PART,d0         + OV-mode +
          bmi.s     schub5
          bsr       save_buf
schub5    move.l    mrk+BUFF,16(a3)     16: background source address
          move.l    bildbuff,20(a3)     20: selection image source
          bra.s     schub4
schub9    move.l    bildbuff,16(a3)     + NORM-Mode +
          move.l    BILD_ADR(a4),20(a3)
          move.b    mrk+OVKU,d0         Kurz-Overlay-Mode?
          bne.s     schub4              -> keep old background
          bsr       save_buf
          move.b    mrk+COPY,d0         copy mode?
          bne.s     schub4
          clr.w     d3
          move.l    bildbuff,a0
          move.l    drawflag+4,d0
          move.l    drawflag+8,d1
          bsr       work_bl2
schub4    move.b    mrk+VMOD,d0         + new combination mode? +
          cmp.b     mrk+MODI,d0
          beq.s     schub2
          move.l    stack,d3            -> draw immediately
          bsr       hide_m
          bra.s     schub8
schub2    lea       stack,a3            +++ Loop +++
          move.l    (a3),d3
          bsr       noch_qu
          bsr       hide_m
          move.b    maus_rec+1,d0       done?
          beq.s     schub3
schub8    move.l    d3,-(sp)            ++ Restore ++
          spl.b     12(a3)
          move.l    mark_buf+2,d0
          move.l    mark_buf+6,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF(a0),d0
          add.w     YX_OFF(a0),d1
          add.l     YX_OFF+2(a0),d0
          add.l     YX_OFF+2(a0),d1
          move.l    stack+16,a0
          move.l    logbase,a1
          bsr       copy_blk
          move.l    (sp)+,d3
          move.l    d3,d4               ++ Redraw ++
          lea       stack,a3
          sub.w     2(a3),d3
          add.w     d3,6(a3)
          swap      d3
          sub.w     (a3),d3             prev. pos. + mouse offset =
          add.w     d3,4(a3)            4: new selection coords. (upper-left corner)
          move.l    d4,(a3)             0: new mouse coords.
          move.l    logbase,a1
          bsr       fram_ins            commit selection
          bsr       show_m
          bra       schub2
schub3    move.l    rec_adr,a2          +++ End +++
          move.b    mrk+OV,d0
          bne.s     schub20
          lea       mark_buf+2,a0       + NORM mode +
          move.w    YX_OFF(a2),d0
          move.w    YX_OFF+2(a2),d1
          add.w     d1,(a0)+
          add.w     d0,(a0)+
          add.w     d1,(a0)+
          add.w     d0,(a0)
          clr.b     mrk+PART
          bra       schub21
schub20   move.w    #1999,d3            + OV mode +
          move.l    mrk+BUFF,a0
          move.l    BILD_ADR(a2),a1
schub26   move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d3,schub26
          lea       win_xy,a0
          clr.l     (a0)+
          move.l    #$27f018f,(a0)+
          lea       stack+4,a1
          move.w    (a0)+,d0
          move.w    (a0),d1
          add.w     d1,(a1)+
          add.w     d0,(a1)
          move.l    BILD_ADR(a2),a1
          bsr       fram_ins
          move.l    mark_buf+6,d0       selection cut off at window borders?
          sub.l     mark_buf+2,d0
          move.l    stack+28,d1
          sub.l     stack+24,d1
          lea       mrk,a0
          move.l    menu_adr,a1
          cmp.l     d0,d1
          beq.s     schub22
          sne.b     PART(a0)
          bclr.b    #3,1691(a1)         enable "commit" command
          move.l    stack+24,OLD(a0)
          move.l    stack+28,OLD+4(a0)
          move.l    mark_buf+2,OLD+8(a0)
          move.w    stack+4,d0
          sub.w     d0,OLD+8(a0)
          move.w    stack+6,d0
          sub.w     d0,OLD+10(a0)
          bra.s     schub21
schub22   bset.b    #3,1691(a1)
          move.l    stack+24,OLD(a0)
          bclr.b    #7,PART(a0)
          bne.s     schub21
          clr.b     PART(a0)
schub21   lea       mrk,a0              + set flags +
          clr.w     EINF(a0)            pasting done
          move.b    stack+12,d0
          beq       exit6
          lea       drawflag,a1         enable undo
          move.w    #-1,(a1)
          tst.b     OV(a0)
          beq       exit_beg
          move.b    VMOD(a0),MODI(a0)   store V-Mode
          beq       exit3
          move.l    menu_adr,a0
          bclr.b    #3,1691(a0)         enable "commit" command
          bra       exit3
*----------------------------------------------------GEM-SUBFUNCTIONS
          ;
set_attr  clr.w     d0                  ** set attributes **
          move.w    chooset,d1
          beq.s     set_att1+4           filling requested?
          vdi       24 0 1 !frmuster+20  ;fill pattern
          vdi       25 0 1 !frmuster+34  ;fill color
set_att1  move.w    frmuster+6,d0
          vdi       23 0 1 !d0           ;fill style
          vdi       104 0 1 !chooset+4   ;border on/off
set_att2  ;
          vdi       15 0 1 !frlinie+34   ;line style
          vdi       16 1 0 !frlinie+20 0 ;line width
          vdi       17 0 1 !frlinie+6    ;line color
          vdi       113 0 1 !choopat     ;line pattern
          bsr.s     clip_on
          ;
set_wrmo  clr.w     d0                  ** set current mode **
          move.b    frmodus+5,d0
          addq.b    #1,d0
          vdi       32 0 1 !d0          ;set_writing_modus
          rts
          ;
clip_on   move.l    win_xy,(a4)         ** set clipping rect. **
          move.l    win_xy+4,4(a4)
          move.w    #1,(a6)
          vdi       129 2 1
          rts
ret_attr  ;                             ** set GEM-attributes **
          vdi       108 0 2 0 0
ret_att2  ;
          vdi       15 0 1 1
          vdi       16 1 0 1 0
          vdi       17 0 1 1
          vdi       23 0 1 1
return    ;
          vdi       129 0 1 0           ;delete clipping rect.
          vdi       32 0 1 3            ;set_writing_mode XOR
          rts
*--------------------------------------------------------SUBFUNCTIONS
noch_qu   lea       win_xy,a0           ** Query mouse **
noch_qu5  move.b    maus_rec+1,d0
          beq.s     noch_rts
          move.l    maus_rec+12,d0
corr_adr  bsr       alrast
          swap      d0                  position within window?
          cmp.w     (a0),d0
          bhs.s     noch_qu1
          move.w    (a0),d0             no -> correct
          bra.s     noch_qu2
noch_qu1  cmp.w     4(a0),d0
          bls.s     noch_qu2
          move.w    4(a0),d0
noch_qu2  swap      d0
          cmp.w     2(a0),d0
          bhs.s     noch_qu3
          move.w    2(a0),d0
          bra.s     noch_qu4
noch_qu3  cmp.w     6(a0),d0
          bls.s     noch_qu4
          move.w    6(a0),d0
noch_qu4  cmp.l     d0,d3
          beq       noch_qu5
          move.l    d0,d3
          tst.w     chookoo
          beq.s     noch_rts
          movem.l   a1/d1-d2,-(sp)
          bsr       koos_out            display mouse coord., if enabled
          movem.l   (sp)+,a1/d1-d2
noch_rts  rts
          ;
noch_in   cmp.w     (a0),d0             ** Pos. within selection area? **
          blo.s     noch_in1
          cmp.w     4(a0),d0
          bhi.s     noch_in1
          cmp.w     2(a0),d1
          blo.s     noch_in1
          cmp.w     6(a0),d1
          bhi.s     noch_in1
          clr.w     d2
          rts
noch_in1  moveq.l   #1,d2
          rts
          ;
win_abs   move.l    rec_adr,a0          ** Limit window size **
          move.l    FENSTER(a0),d0
          move.l    FENSTER+4(a0),d1
          lea       win_xy,a0
          move.l    d0,(a0)
          add.l     d1,d0
          sub.l     #$10001,d0
          move.l    d0,4(a0)
          cmp.w     #400,6(a0)
          blo.s     win_abs1
          move.w    #399,6(a0)
win_abs1  cmp.w     #640,4(a0)
          blo.s     win_abs2
          move.w    #639,4(a0)
win_abs2  rts
          ;
lim_win   lea       win_xy,a0           ** Limit to window **
          cmp.w     2(a0),d0
          bge.s     lim_win1
          move.w    2(a0),d0
lim_win1  cmp.w     6(a0),d1
          bls.s     lim_win2
          move.w    6(a0),d1
lim_win2  swap      d0
          swap      d1
          cmp.w     (a0),d0
          bge.s     lim_win3
          move.w    (a0),d0
lim_win3  cmp.w     4(a0),d1
          bls.s     lim_win4
          move.w    4(a0),d1
lim_win4  swap      d0
          swap      d1
          rts
          ;
new_1koo  lea       last_koo,a0         ** Store mouse coord. **
          move.l    4(a0),(a0)
          move.l    d3,4(a0)
          addq.w    #1,8(a0)
          bpl.s     new_3koo
          move.w    #-1,8(a0)
          rts
new_2koo  lea       last_koo,a0
          move.l    d0,(a0)
          move.l    d1,4(a0)
          move.w    #-1,8(a0)
new_3koo  rts
          ;
save_buf  move.l    rec_adr,a1          ** Copy image to undo buffer **
          move.l    BILD_ADR(a1),a1
          move.l    bildbuff,a2
          move.l    #1999,d0
save_bu1  move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          dbra      d0,save_bu1
          rts
          ;
fram_ins  lea       stack+4,a3          ** Draw selection border frame **
          move.l    (a3),d0
          move.l    d0,d1
          add.w     6(a3),d1
          swap      d1
          add.w     4(a3),d1
          swap      d1
          bsr       lim_win
          move.l    d0,d2
          lea       mark_buf+2,a0       store new border coord.
          move.l    d0,(a0)+
          move.l    d1,(a0)
          sub.w     2(a3),d0            calc selection source addr.
          sub.w     2(a3),d1
          swap      d0
          swap      d1
          sub.w     (a3),d0
          sub.w     (a3),d1
          swap      d0
          swap      d1
          add.l     20(a3),d0
          add.l     20(a3),d1
          move.b    mrk+VMOD,d3         just move?
          bne.s     fram_in1
          move.l    stack+20,a0         1:1-copy
          bra       copy_blk
fram_in1  clr.w     d3                  use combination mode
          move.b    mrk+VMOD,d3
          lea       mfdb_q,a0
          move.l    stack+20,(a0)
          move.l    a1,20(a0)
          move.w    d3,(a6)             mode
          move.l    d1,d3
          sub.l     d0,d3
          move.l    d3,4(a0)
          move.l    d3,24(a0)
          move.l    a0,14(a5)
          add.w     #20,a0
          move.l    a0,18(a5)
          lea       ptsin,a0
          move.l    d0,(a0)+
          move.l    d1,(a0)+
          move.l    d2,(a0)+
          add.l     d3,d2
          move.l    d2,(a0)
          vdi       109 4 1             ;copy_raster
          rts
          ;
fram_drw  lea       mark_buf,a0         ** frame the selection **
          tst.w     (a0)
          beq       tool_rts
          move.l    rec_adr,a1
          move.w    2(a0),d4            x1y1-x2y2: border coords.
          move.w    4(a0),d5
          move.w    6(a0),d6
          move.w    8(a0),d7
          sub.w     YX_OFF(a1),d5
          sub.w     YX_OFF(a1),d7
          bmi       tool_rts
          sub.w     YX_OFF+2(a1),d4
          sub.w     YX_OFF+2(a1),d6
          bmi       tool_rts
          move.l    FENSTER(a1),d0      window borders
          move.l    FENSTER+4(a1),d1
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d0             screen borders
          bhs       tool_rts
          cmp.w     #400,d1
          blo.s     fram_d14
          move.w    #399,d1
fram_d14  swap      d0
          cmp.w     #640,d0
          bhs       tool_rts
          swap      d0
          swap      d1
          cmp.w     #640,d1
          blo.s     fram_d16
          move.w    #639,d1
fram_d16  swap      d1
          moveq.l   #15,d3              D3: border control flags
          cmp.w     d0,d5               limit border
          bge.s     fram_dr2            (D5 may be <0)
          move.w    d0,d5
          bclr      #1,d3               1: top
fram_dr2  cmp.w     d1,d7
          bls.s     fram_dr3
          move.w    d1,d7
          bclr      #3,d3               3: bottom
fram_dr3  swap      d0
          swap      d1
          cmp.w     d0,d4
          bge.s     fram_dr4
          move.w    d0,d4
          bclr      #0,d3               0: left
fram_dr4  cmp.w     d1,d6
          bls.s     fram_dr5
          move.w    d1,d6
          bclr      #2,d3               2: right
fram_dr5  cmp.w     d5,d7               selection outside of window?
          blo.s     fram_d10
          cmp.w     d4,d6
          bhs.s     fram_d12
fram_d10  clr.w     d3
fram_d12  tst.w     d3                  Borders visible?
          beq       tool_rts            no -> abort
          bsr       hide_m
          dc.w      $a000               Line-A init
          move.l    a0,a3
          move.w    #-1,32(a3)
          move.w    #1,24(a3)
          move.w    #2,36(a3)
          move.w    d4,38(a3)           draw visible parts of border
          move.w    d5,40(a3)
          move.w    d6,42(a3)
          move.w    d5,44(a3)
          btst      #1,d3
          beq.s     fram_dr6
          move.w    #$cccc,34(a3)
          dc.w      $a003               X1Y1-X2Y1
fram_dr6  move.w    d7,40(a3)
          move.w    d7,44(a3)
          btst      #3,d3
          beq.s     fram_dr7
          move.w    #$cccc,34(a3)
          dc.w      $a003               X1Y2-X2Y2
fram_dr7  move.w    d5,40(a3)
          move.w    d4,42(a3)
          cmp.w     d5,d7               height = 1?
          bne.s     fram_d17
          move.w    #$cccc,d7
          bra.s     fram_d18
fram_d17  move.w    #$cccc,d7
fram_d18  sub.w     mark_buf+4,d5
          and.w     #3,d5
          beq.s     fram_dr1
          rol.w     d5,d7
fram_dr1  btst      #0,d3
          beq.s     fram_dr8
          move.w    d7,34(a3)
          dc.w      $a003               X1Y1-X1Y2
fram_dr8  move.w    d6,38(a3)
          move.w    d6,42(a3)
          btst      #2,d3
          beq.s     fram_dr9
          move.w    d7,34(a3)
          dc.w      $a003               X2Y1-X2Y2
fram_dr9  bra       show_m
          ;
koos_mak  move.w    chookoo,d0          ** Display mouse position **
          beq       tool_rts
          move.l    rec_adr,a1          window open?
          move.w    (a1),d0
          bmi       koos_ou2
          lea       koo_buff,a0         within a window?
          move.l    FENSTER(a1),d1
          move.l    d1,d2
          add.l     FENSTER+4(a1),d2
          sub.l     #$10001,d2
          move.l    d1,(a0)
          move.l    d2,4(a0)
          move.w    maus_rec+12,d0
          move.w    maus_rec+14,d1
          bsr       noch_in
          bne.s     koos_ou2
          move.l    YX_OFF(a1),win_xy+8
          swap      d0
          move.w    d1,d0
          bsr.s     alrast              align with raster, if enabled
          lea       chookoo+2,a0
          cmp.l     (a0),d0             coords changed?
          beq       tool_rts
          move.l    d0,(a0)
koos_out  move.l    rec_adr,a1          ++ print coords into string ++
          move.w    d0,d1
          add.w     YX_OFF(a1),d1
          lea       koostr+11,a0
          bsr.s     koos_ou1
          move.l    d0,d1
          swap      d1
          add.w     YX_OFF+2(a1),d1
          subq.l    #1,a0
          bsr.s     koos_ou1
          pea       koostr
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
koos_ou1  ext.l     d1                  ++ convert binary number to decimal string ++
          moveq.l   #2,d2
koos_ou3  cmp.l     #10,d1
          blo.s     koos_ou5
          divu      #10,d1
          swap      d1
koos_ou5  add.b     #'0',d1
          move.b    d1,-(a0)
          clr.w     d1
          swap      d1
          dbra      d2,koos_ou3
          rts
koos_ou2  lea       chookoo+2,a0        ++ address is not within window ++
          move.l    (a0),d0
          bmi       tool_rts
          move.l    #-1,(a0)
          pea       koostr2
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
          ;
alrast    tst.w     chooras             ** align XY-coords. with raster **
          beq       tool_rts
          movem.l   d2-d4,-(sp)
          swap      d0
          move.w    d0,d3               X-coord.
          move.w    frraster+6,d2
          move.w    d2,d4
          lsr.w     #1,d4
          add.w     win_xy+10,d3
          bmi.s     alrast1
          sub.w     frraster+34,d3
          ext.l     d3
          divu      d2,d3
          swap      d3
          sub.w     d3,d0
          cmp.w     d4,d3
          bls.s     alrast1
          add.w     d2,d0
alrast1   swap      d0                  Y-coord.
          move.w    d0,d3
          move.w    frraster+20,d2
          move.w    d2,d4
          lsr.w     #1,d4
          add.w     win_xy+8,d3
          bmi.s     alrast2
          sub.w     frraster+48,d3
          ext.l     d3
          divu      d2,d3
          swap      d3
          sub.w     d3,d0
          cmp.w     d4,d3
          bls.s     alrast2
          add.w     d2,d0
alrast2   movem.l   (sp)+,d2-d4
tool_rts  rts
          ;
aescall   move.l    #aespb,d1
          move.l    #$c8,d0
          trap      #2
          rts
          ;
vdicall   move.w    grhandle,12(a5)
          move.l    #vdipb,d1
          moveq.l   #$73,d0
          trap      #2
          rts
          ;
*-----------------------------------------------------------------DATA
win_xy    ds.w   7
mark_buf  ds.w   5
data_buf  ds.w   4
koostr    dc.b   27,'Y h###/###',0
koostr1   dc.b   27,'Y h       ',0
koostr2   dc.b   27,'Y h---/---',0
koo_buff  ds.w   4
last_koo  dcb.l  2,0
;mfdb_q    dc.w   0000,0000,00,00,40,0,1,0,0,0
;          dc.w   0000,0000,00,00,40,0,1,0,0,0
stralvie  dc.b   '[3][Polygon completed?][Ok|Continue]',0
stralmax  dc.b   '[3][Maximum is 128 corners!][Abort]',0
*---------------------------------------------------------------------
grhandle  ds.w   1
appl_id   ds.w   1
aespb     dc.l   contrl,global,intin,intout,addrin,addrout
vdipb     dc.l   contrl,intin,ptsin,intout,ptsout
contrl    ds.w   11
global    ds.w   20
intin     ds.w   20
ptsin     ds.w   10
intout    ds.w   50
ptsout    ds.w   20
addrin    ds.l   3
addrout   ds.l   3
stack     ds.w   1000 /* FIXME multi-purpose buffer of undefined size */
          END