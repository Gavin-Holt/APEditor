;******************
;*                *
;*    HE_Print    *
;*                *
;******************
;
;
;   Description
;   ===========
;   Simple WYSIWYG print function for the HiEdit control.
;
;
;
;   Parameters
;   ==========
;
;       Name            Description
;       ----            -----------
;       p_hEdit         Handle to the HiEdit control.
;
;       p_Owner         Handle to the owner window.  [Optional]
;
;
;       p_MarginLeft    Page margins based upon the locale system of
;       p_MarginTop     measurement -- English or Metric. [Optional]  If 
;       p_MarginRight   English, the margin is measured in thousandths of 
;       p_MarginRight   inches.  If metric, the margin is measured in hundredths
;       p_MarginBottom  of millimeters.
;                       
;                       English example: To get a 0.5 inch margin (12.7 mm), set
;                       the margin to 500.
;
;                       Metric example: To get a 25.40 mm margin (1 inch English
;                       equivalent), set the margin to 2540.
;
;
;
;   Return Codes
;   ============
;   {None}
;
;
;
;   Credit
;   ======
;   Some of the ideas/code for this function was extracted from the source code
;   for the HiEditor demo program ("Print" procedure) and from the Notepad2
;   source code ("Print.cpp").
;
;
;
;   Programming and Usage Notes
;   ===========================
;   xxxxx
;   
;   
;-------------------------------------------------------------------------------
HE_Print(p_hEdit
        ,p_Owner=""
        ,p_MarginLeft=""
        ,p_MarginTop=""
        ,p_MarginRight=""
        ,p_MarginBottom="")
    {
    ;[====================]
    ;[  Global variables  ]
    ;[====================]
    Global $LineNumbersBar
                ;-- This global variable is set to TRUE if the line numbers bar
                ;   is showing, otherwise it is FALSE
          ,hDevMode
          ,hDevNames


    ;[====================]
    ;[  Static variables  ]
    ;[====================]
    Static PD_ALLPAGES          :=0x0
          ,PD_SELECTION         :=0x1
          ,PD_PAGENUMS          :=0x2
          ,PD_NOSELECTION       :=0x4
          ,PD_NOPAGENUMS        :=0x8
          ,PD_RETURNDC          :=0x100
          ,PD_RETURNDEFAULT     :=0x400
          ,PD_ENABLEPRINTHOOK   :=0x1000    ;-- Not used (for now)
          ,PD_USEDEVMODECOPIES  :=0x40000   ;-- Same as PD_USEDEVMODECOPIESANDCOLLATE
          ,PD_DISABLEPRINTTOFILE:=0x80000
          ,PD_HIDEPRINTTOFILE   :=0x100000

          ,LOCALE_USER_DEFAULT  :=0x400
          ,LOCALE_IMEASURE      :=0xD
          ,LOCALE_RETURN_NUMBER :=0x20000000

          ,MM_TEXT              :=0x1
          ,HORZRES              :=0x8
          ,VERTRES              :=0xA
          ,LOGPIXELSX           :=0x58
          ,LOGPIXELSY           :=0x5A
          ,PHYSICALWIDTH        :=0x6E
          ,PHYSICALHEIGHT       :=0x6F
          ,PHYSICALOFFSETX      :=0x70
          ,PHYSICALOFFSETY      :=0x71

          ,WM_USER              :=0x400 ;-- 1024

          ,EM_EXGETSEL          :=1076  ;-- WM_USER+52
          ,EM_FORMATRANGE       :=1081  ;-- WM_uSER+57
          ,EM_SETTARGETDEVICE   :=1096  ;-- WM_USER+72
          ,WM_GETTEXTLENGTH     :=0xE


    ;[==============]
    ;[  Initialize  ]
    ;[==============]
    SplitPath A_ScriptName,,,,l_ScriptName


    ;-- Get locale system of measurement (0=Metric, 1=English)
    VarSetCapacity(lpLCData,4,0)
    DllCall("GetLocaleInfo"
        ,"UInt",LOCALE_USER_DEFAULT
        ,"UInt",LOCALE_IMEASURE|LOCALE_RETURN_NUMBER
        ,"UInt",&lpLCData
        ,"UInt",4)
    
    l_LOCALE_IMEASURE:=NumGet(lpLCData,0,"Unit")
    if l_LOCALE_IMEASURE=0      ;-- 0=HiMetric (hundredths of millimeters)
        l_LocaleUnits:=2540
     else                       ;-- 1=HiEnglish (thousandths of inches)
        l_LocaleUnits:=1000


    ;[==============]
    ;[  Parameters  ]
    ;[==============]
    if p_MarginLeft is not Integer
        p_MarginLeft:=l_LocaleUnits/2   ;-- (0.5 inch or 12.7 mm)

    if p_MarginTop is not Integer
        p_MarginTop:=l_LocaleUnits/2

    if p_MarginRight is not Integer
        p_MarginRight:=l_LocaleUnits/2

    if p_MarginBottom is not Integer
        p_MarginBottom:=l_LocaleUnits/2


    ;[================]
    ;[  Prep to call  ]
    ;[    PrintDlg    ]
    ;[================]
    ;-- Define/Populate the PRINTDLG structure
    VarSetCapacity(PRINTDLG_Structure,66,0)
    NumPut(66,PRINTDLG_Structure,0,"UInt")                  ;-- lStructSize
    
    if p_Owner is Integer
        Numput(p_Owner,PRINTDLG_Structure,4,"UInt")         ;-- hwndOwner

    if hDevMode is Integer
        NumPut(hDevMode,PRINTDLG_Structure,8,"UInt")        ;-- hDevMode

    if hDevNames is Integer
        NumPut(hDevNames,PRINTDLG_Structure,12,"UInt")      ;-- hDevMode


    ;-- Collect start/End select positions
    VarSetCapacity(CHARRANGE_Structure,8,0)
    SendMessage EM_EXGETSEL,0,&CHARRANGE_Structure,,ahk_id %p_hEdit%
    l_StartSelPos:=NumGet(CHARRANGE_Structure,0,"Int")      ;-- cpMin
    l_EndSelPos  :=NumGet(CHARRANGE_Structure,4,"Int")      ;-- cpMax
        ;-- Programming note: The HE_GetSel function is not used here so that
        ;   this function can be used independent of the HiEdit library.  This
        ;   will probably be changed in the future.


    ;-- Determine/Set Flags
    l_Flags:=PD_ALLPAGES|PD_RETURNDC|PD_USEDEVMODECOPIES
    if (l_StartSelPos=l_EndSelPos)
        l_Flags |= PD_NOSELECTION
     else
        l_Flags |= PD_SELECTION

    NumPut(l_Flags,PRINTDLG_Structure,20,"UInt")            ;-- Flags


    ;-- Page and copies
    NumPut(1 ,PRINTDLG_Structure,24,"UShort")               ;-- nFromPage
    NumPut(1 ,PRINTDLG_Structure,26,"UShort")               ;-- nToPage
    NumPut(1 ,PRINTDLG_Structure,28,"UShort")               ;-- nMinPage
    NumPut(-1,PRINTDLG_Structure,30,"UShort")               ;-- nMaxPage
    NumPut(1 ,PRINTDLG_Structure,32,"UShort")               ;-- nCopies
        ;-- Note: Use -1 to specify the maximum page number (65535).
        ;
        ;   Programming note:  The values that are loaded to these fields are
        ;   critical.  The Print dialog will not display (returns an error) if
        ;   unexpected values are loaded to one or more of these fields.


    ;[================]
    ;[  Print dialog  ]
    ;[================]
    ;-- Open the Print dialog.  Bounce if the user cancels.
    if not DllCall("comdlg32\PrintDlgA","UInt",&PRINTDLG_Structure)
        return

    hDevMode:=NumGet(PRINTDLG_Structure,8,"UInt")
        ;-- Handle to a global memory object that contains a DEVMODE structure

    hDevNames:=NumGet(PRINTDLG_Structure,12,"UInt")
        ;-- Handle to a movable global memory object that contains a DEVNAMES
        ;   structure.


    ;-- Free global structures created by PrintDlg
    ;
    ;   Programming note:  This function assumes that the user-selected printer
    ;   settings will be retained in-between print requests.  If this behaviour
    ;   is not desired, the global memory objects created by the PrintDlg
    ;   function can be released immediately by uncommenting the following code.
    ;   However, if this behavior is desired, the global memory objects should
    ;   be released before the script is terminated.  Copy the following code
    ;   (uncommented of course) to the appropriate "Exit" routine in your
    ;   script.
    ;
;;;;;    if hDevMode
;;;;;        {
;;;;;        DllCall("GlobalFree","UInt",hDevMode)
;;;;;        hDevMode:=0
;;;;;        }
;;;;;    
;;;;;    if hDevNames
;;;;;        {
;;;;;        DllCall("GlobalFree","UInt",hDevNames)
;;;;;        hDevNames:=0
;;;;;        }



    ;-- Get the printer device context.  Bounce if not defined.
    l_hDC:=NumGet(PRINTDLG_Structure,16,"UInt")             ;-- hDC
    if not l_hDC
        {
        outputdebug,
           (ltrim join`s
            Function: %A_ThisFunc% - Printer device context (hDC) not defined.
           )

        return
        }


    ;[====================]
    ;[  Prepare to print  ]
    ;[====================]
    ;-- Collect Flags
    l_Flags:=NumGet(PRINTDLG_Structure,20,"UInt")           ;-- Flags


    ;-- Determine From/To Page
    if l_Flags & PD_PAGENUMS
        {
        l_FromPage:=NumGet(PRINTDLG_Structure,24,"UShort")  ;-- nFromPage
        l_ToPage  :=NumGet(PRINTDLG_Structure,26,"UShort")  ;-- nToPage
        }
     else
        {
        l_FromPage:=1
        l_ToPage  :=65535
        }


    ;-- Collect printer statistics
    l_HORZRES:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",HORZRES)
    l_VERTRES:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",VERTRES)
        ;-- Width and height, in pixels, of the printable area of the page

    l_LOGPIXELSX:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",LOGPIXELSX)
    l_LOGPIXELSY:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",LOGPIXELSY)
        ;-- Number of pixels per logical inch along the page width and height

    l_PHYSICALWIDTH :=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",PHYSICALWIDTH)
    l_PHYSICALHEIGHT:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",PHYSICALHEIGHT)
        ;-- The width and height of the physical page, in device units. For
        ;   example, a printer set to print at 600 dpi on 8.5" x 11" paper
        ;   has a physical width value of 5100 device units. Note that the
        ;   physical page is almost always greater than the printable area of
        ;   the page, and never smaller.

    l_PHYSICALOFFSETX:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",PHYSICALOFFSETX)
    l_PHYSICALOFFSETY:=DllCall("GetDeviceCaps","UInt",l_hDC,"UInt",PHYSICALOFFSETY)
        ;-- The distance from the left/right edge (PHYSICALOFFSETX) and the
        ;   top/bottom edge (PHYSICALOFFSETY) of the physical page to the edge
        ;   of the printable area, in device units. For example, a printer set
        ;   to print at 600 dpi on 8.5-by-11-inch paper, that cannot print on
        ;   the leftmost 0.25-inch of paper, has a horizontal physical offset of
        ;   150 device units.


    ;-- Define/Populate the FORMATRANGE structure
    VarSetCapacity(FORMATRANGE_Structure,48,0)
    NumPut(l_hDC,FORMATRANGE_Structure,0,"UInt")            ;-- hdc
    NumPut(l_hDC,FORMATRANGE_Structure,4,"UInt")            ;-- hdcTarget


   ;-- Define FORMATRANGE.rcPage
    ;
    ;   rcPage is the entire area of a page on the rendering device, measured in
    ;   twips (1/20 point or 1/1440 of an inch)
    ;
    ;   Note: rc defines the maximum printable area which does not include the
    ;   printer's margins (the unprintable areas at the edges of the page).  The
    ;   unprintable areas are represented by PHYSICALOFFSETX and
    ;   PHYSICALOFFSETY.
    ;
    NumPut(0,FORMATRANGE_Structure,24,"UInt")               ;-- rcPage.Left
    NumPut(0,FORMATRANGE_Structure,28,"UInt")               ;-- rcPage.Top

    l_rcPage_Right:=Round((l_HORZRES/l_LOGPIXELSX)*1440)
    NumPut(l_rcPage_Right,FORMATRANGE_Structure,32,"UInt")  ;-- rcPage.Right

    l_rcPage_Bottom:=Round((l_VERTRES/l_LOGPIXELSY)*1440)
    NumPut(l_rcPage_Bottom,FORMATRANGE_Structure,36,"UInt") ;-- rcPage.Bottom


   ;-- Define FORMATRANGE.rc
    ;
    ;   rc is the area to render to (rcPage - margins), measured in twips (1/20
    ;   point or 1/1440 of an inch).
    ;
    ;   If the user-defined margins are smaller than the printer's margins (the
    ;   unprintable areas at the edges of each page), the user margins are set
    ;   to the printer's margins.
    ;
    ;   In addition, the user-defined margins must be adjusted to account for
    ;   the printer's margins.  For example: If the user requests a 3/4 inch
    ;   (19.05 mm) left margin but the printer's left margin is 1/4 inch
    ;   (6.35 mm), rc.Left is set to 720 twips (1/2 inch or 12.7 mm).
    ;
    ;-- Left
    if (l_PHYSICALOFFSETX/l_LOGPIXELSX>p_MarginLeft/l_LocaleUnits)
        p_MarginLeft:=Round((l_PHYSICALOFFSETX/l_LOGPIXELSX)*l_LocaleUnits)

    l_rc_Left:=Round(((p_MarginLeft/l_LocaleUnits)*1440)-((l_PHYSICALOFFSETX/l_LOGPIXELSX)*1440))
    NumPut(l_rc_Left,FORMATRANGE_Structure,8,"UInt")        ;-- rc.Left


    ;-- Top
    if (l_PHYSICALOFFSETY/l_LOGPIXELSY>p_MarginTop/l_LocaleUnits)
        p_MarginTop:=Round((l_PHYSICALOFFSETY/l_LOGPIXELSY)*l_LocaleUnits)

    l_rc_Top:=Round(((p_MarginTop/l_LocaleUnits)*1440)-((l_PHYSICALOFFSETY/l_LOGPIXELSY)*1440))
    NumPut(l_rc_Top,FORMATRANGE_Structure,12,"UInt")        ;-- rc.Top


    ;-- Right
    if (l_PHYSICALOFFSETX/l_LOGPIXELSX>p_MarginRight/l_LocaleUnits)
        p_MarginRight:=Round((l_PHYSICALOFFSETX/l_LOGPIXELSX)*l_LocaleUnits)

    l_rc_Right:=l_rcPage_Right-Round(((p_MarginRight/l_LocaleUnits)*1440)-((l_PHYSICALOFFSETX/l_LOGPIXELSX)*1440))
    NumPut(l_rc_Right,FORMATRANGE_Structure,16,"UInt")      ;-- rc.Right


    ;-- Bottom
    if (l_PHYSICALOFFSETY/l_LOGPIXELSY>p_MarginBottom/l_LocaleUnits)
        p_MarginBottom:=Round((l_PHYSICALOFFSETY/l_LOGPIXELSY)*l_LocaleUnits)

    l_rc_Bottom:=l_rcPage_Bottom-Round(((p_MarginBottom/l_LocaleUnits)*1440)-((l_PHYSICALOFFSETY/l_LOGPIXELSY)*1440))
    NumPut(l_rc_Bottom,FORMATRANGE_Structure,20,"UInt")     ;-- rc.Bottom


    ;-- Determine print range.
    ;
    ;   If "Selection" option is chosen, use selected text, otherwise use the
    ;   entire document.
    ;
    if l_Flags & PD_SELECTION
        {
        l_StartPrintPos:=l_StartSelPos
        l_EndPrintPos  :=l_EndSelPos
        }
     else
        {
        l_StartPrintPos:=0
        l_EndPrintPos  :=-1     ;-- (-1=Select All)
        }

    Numput(l_StartPrintPos,FORMATRANGE_Structure,40)        ;-- cr.cpMin
    NumPut(l_EndPrintPos  ,FORMATRANGE_Structure,44)        ;-- cr.cpMax


    ;-- Define/Populate the DOCINFO structure
    VarSetCapacity(DOCINFO_Structure,20,0)
    NumPut(20           ,DOCINFO_Structure,0)               ;-- cbSize
    NumPut(&l_ScriptName,DOCINFO_Structure,4)               ;-- lpszDocName
    NumPut(0            ,DOCINFO_Structure,8)               ;-- lpszOutput
        ;-- Programming note: All other DOCINFO_Structure fields intentionally
        ;   left as null.


    ;-- Determine l_MaxPrintIndex
    if l_Flags & PD_SELECTION
        l_MaxPrintIndex:=l_EndSelPos
     else
        {
        SendMessage WM_GETTEXTLENGTH,0,0,,ahk_id %p_hEdit%
        l_MaxPrintIndex:=ErrorLevel
            ;-- Programming note: HE_GetTextLength is not used here so that this 
            ;   function can be used independent of the HiEdit library.  This
            ;   will probably be changed in the future.
        }


    ;-- Set LineNumbersBar to max size
    ;
    ;   Programming note:  This step is necessary because the LineNumbersBar
    ;   does not render correctly past the first couple of pages if the
    ;   "autosize" option is used.  A bug perhaps, but this workaround is
    ;   acceptable and the fixed size may even be desirable.
    ;
    ;   If you don't use the line numbers bar or you don't want to make any
    ;   changes to the line numbers bar, you can comment out this code.
    ;
    if $LineNumbersBar
        HE_LineNumbersBar(p_hEdit,"automaxsize")


   ;-- Be sure that the printer device context is in text mode
    DllCall("SetMapMode","UInt",l_hDC,"UInt",MM_TEXT)


    ;[=============]
    ;[  Print it!  ]
    ;[=============]
    ;-- Start a print job.  Bounce if there is a problem.
    l_PrintJob:=DllCall("StartDoc","UInt",l_hDC,"UInt",&DOCINFO_Structure,"Int")
    if l_PrintJob<=0
        {
        outputdebug Function: %A_ThisFunc% - DLLCall of "StartDoc" failed.
        return
        }


    ;-- Print page loop
    l_Page:=0
    l_PrintIndex:=0
    While (l_PrintIndex<l_MaxPrintIndex)
        {
        l_Page++


        ;-- Are we done yet?
        if (l_Page>l_ToPage)
            break


        if l_Page between %l_FromPage% and %l_ToPage%
            {
            ;-- StartPage function.  Break if there is a problem.
            if DllCall("StartPage","UInt",l_hDC,"Int")<=0
                {
                outputdebug,
                   (ltrim join`s
                    Function: %A_ThisFunc% - DLLCall of "StartPage" failed.
                   )

                break
                }
            }


        ;-- Format or measure page
        if l_Page between %l_FromPage% and %l_ToPage%
            l_Render:=true
         else
            l_Render:=false

        SendMessage EM_FORMATRANGE,l_Render,&FORMATRANGE_Structure,,ahk_id %p_hEdit%
        outputdebug ErrorLevel from EM_FORMATRANGE=%ErrorLevel%
        l_PrintIndex:=ErrorLevel


        if l_Page between %l_FromPage% and %l_ToPage%
            {
            ;-- EndPage function.  Break if there is a problem.
            if DllCall("EndPage","UInt",l_hDC,"Int")<=0
                {
                outputdebug,
                   (ltrim join`s
                    Function: %A_ThisFunc% - DLLCall of "EndPage" failed.
                   )

                break
                }
            }


        ;-- Update FORMATRANGE_Structure for the next page
        Numput(l_PrintIndex ,FORMATRANGE_Structure,40)      ;-- cr.cpMin
        NumPut(l_EndPrintPos,FORMATRANGE_Structure,44)      ;-- cr.cpMax
        }


    ;-- End the print job
    DllCall("EndDoc","UInt",l_hDC)


    ;-- Delete the printer device context
    DllCall("DeleteDC","UInt",l_hDC)


    ;-- Reset control (free cached information)
    SendMessage EM_FORMATRANGE,0,0,,ahk_id %p_hEdit%


    ;-- Reset the LineNumbersBar
    ;
    ;   Programming note: If you don't use the line numbers bar or you don't
    ;   want to make any changes to the line numbers bar, you can comment out
    ;   this code.
    ;
    if $LineNumbersBar
        HE_LineNumbersBar(p_hEdit,"autosize")


    ;-- Return to sender
    return
    }
