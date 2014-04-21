        .386
        .model flat,stdcall
        option casemap:none   ; case sensitive
    
; ####################################################
    
        include E:\masm32\include\windows.inc
        include E:\masm32\include\user32.inc
        include E:\masm32\include\kernel32.inc
        include E:\masm32\include\comctl32.inc

        includelib E:\masm32\lib\user32.lib
        includelib E:\masm32\lib\kernel32.lib
        includelib E:\masm32\lib\comctl32.lib
		
		
    
; ####################################################

        
        ID_SLIDER_OXIGEN equ 201
		ID_SLIDER_NOISE equ 202
		ID_SLIDER_DUST equ 203

		ID_EDIT_OXIGEN equ 501
		ID_EDIT_NOISE equ 502
		ID_EDIT_DUST equ 503

; --------------------------------------------------------
    
        ControlsMadness PROTO :DWORD,:DWORD,:DWORD,:DWORD
        SetControlsPosition PROTO :DWORD,:DWORD
		GetMouseValue PROTO :DWORD,:DWORD
    
; --------------------------------------------------------
    
.data
        hInstance dd ?
		hOxigen dd ?
		hNoise dd ?
		hDust dd ?
        NewPosition dd 0
        dlgname db "CONTROLS",0
		szNameFile db "E:\\emu8086.io",0
		szHexBuf  db 17 dup(?)

.data?
        icex INITCOMMONCONTROLSEX <> ;structure for Controls
    
; ###############################################################
    
.code
    
start:
    
; ###############################################################
    
        invoke GetModuleHandle,NULL
        mov hInstance,eax
        mov icex.dwSize,sizeof INITCOMMONCONTROLSEX
        mov icex.dwICC,0FFFFh
        invoke InitCommonControlsEx,ADDR icex
    
; ---------------------------------------------
;   Call the dialog box stored in resource file
; ---------------------------------------------
        invoke DialogBoxParam,hInstance,ADDR dlgname,0,ADDR ControlsMadness,0
        invoke ExitProcess,eax
    
; ###############################################################
    
ControlsMadness proc hWin:DWORD,uMsg:DWORD,aParam:DWORD,bParam:DWORD
    
    LOCAL Ps:PAINTSTRUCT
        .if uMsg == WM_INITDIALOG
                    invoke SendDlgItemMessage,hWin,ID_SLIDER_OXIGEN,TBM_SETRANGEMIN,FALSE,0
                    invoke SendDlgItemMessage,hWin,ID_SLIDER_OXIGEN,TBM_SETRANGEMAX,FALSE,255
                    invoke SendDlgItemMessage,hWin,ID_SLIDER_DUST,TBM_SETRANGEMIN,FALSE,0
                    invoke SendDlgItemMessage,hWin,ID_SLIDER_DUST,TBM_SETRANGEMAX,FALSE,255
					invoke SendDlgItemMessage,hWin,ID_SLIDER_NOISE,TBM_SETRANGEMIN,FALSE,0
                    invoke SendDlgItemMessage,hWin,ID_SLIDER_NOISE,TBM_SETRANGEMAX,FALSE,255
					invoke SendDlgItemMessage,hWin,ID_EDIT_OXIGEN,EM_SETREADONLY,TRUE,0
					invoke SendDlgItemMessage,hWin,ID_EDIT_NOISE,EM_SETREADONLY,TRUE,0
					invoke SendDlgItemMessage,hWin,ID_EDIT_DUST,EM_SETREADONLY,TRUE,0
					invoke SetDlgItemInt,hWin,ID_EDIT_OXIGEN,0,TRUE
					invoke SetDlgItemInt,hWin,ID_EDIT_DUST,0,TRUE
					invoke SetDlgItemInt,hWin,ID_EDIT_NOISE,0,TRUE
					invoke GetDlgItem,hWin,ID_SLIDER_OXIGEN
					mov hOxigen, eax
					invoke GetDlgItem,hWin,ID_SLIDER_NOISE
					mov hNoise, eax
					invoke GetDlgItem,hWin,ID_SLIDER_DUST
					mov hDust, eax
                    invoke SetFocus,hWin
    
        .elseif uMsg == WM_COMMAND
				mov eax, aParam
				mov ebx, bParam
        .elseif uMsg == WM_PAINT
    
        .elseif uMsg == WM_CLOSE
                        invoke EndDialog,hWin,NULL   
        .elseif uMsg == WM_VSCROLL
                        mov eax,aParam
                        and eax,0FFFFh  
                        .if eax == TB_THUMBPOSITION
                            mov eax,aParam
                            shr eax,16
                            mov NewPosition,eax
                            invoke SetControlsPosition,hWin,bParam
                        .elseif eax == TB_THUMBTRACK
                            mov eax,aParam
                            shr eax,16
                            mov NewPosition,eax
                            invoke SetControlsPosition,hWin,bParam
						.elseif eax == TB_PAGEDOWN
							invoke GetMouseValue,hWin,bParam
                            invoke SetControlsPosition,hWin,bParam
						.elseif eax == TB_PAGEUP
							invoke GetMouseValue,hWin,bParam
                            invoke SetControlsPosition,hWin,bParam
						.elseif eax == SB_LINEUP
                            .if NewPosition != 0
                                dec NewPosition
                            .endif
                            invoke SetControlsPosition,hWin,bParam
                        .elseif eax == SB_LINEDOWN
                            .if NewPosition != 255
                                inc NewPosition
                            .endif 
                            invoke SetControlsPosition,hWin,bParam

                        .endif
    
        .endif
    
        xor eax,eax
        ret
    
ControlsMadness endp
    
; ###############################################################
    
SetControlsPosition proc hWin:DWORD,sliderElement:DWORD


    LOCAL hFile :DWORD                          ; file handle


		invoke GetLastError
		invoke CreateFile,ADDR szNameFile,GENERIC_WRITE,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
		mov hFile, eax 
		invoke GetLastError      
		mov ebx, sliderElement
		mov ecx, hOxigen
		cmp ebx,ecx
		je OXIGEN
		mov ecx, hDust
		cmp ebx,ecx
		je DUST
		mov ecx, hNoise
		cmp ebx,ecx
		je NOISE
		jmp ENDE
		OXIGEN:
			invoke SetDlgItemInt,hWin,ID_EDIT_OXIGEN,NewPosition,TRUE
			invoke SetFilePointer,hFile,2,NULL,FILE_BEGIN
			jmp ENDE
		DUST:
			invoke SetDlgItemInt,hWin,ID_EDIT_DUST,NewPosition,TRUE
			invoke SetFilePointer,hFile,4,NULL,FILE_BEGIN
			jmp ENDE
		NOISE:
			invoke SetDlgItemInt,hWin,ID_EDIT_NOISE,NewPosition,TRUE
			invoke SetFilePointer,hFile,3,NULL,FILE_BEGIN
		ENDE:
		mov eax, NewPosition
		invoke WriteFile,hFile,ADDR NewPosition,1,NULL,NULL
		invoke GetLastError
		invoke CloseHandle,hFile
        ret

SetControlsPosition endp

GetMouseValue proc hWin:DWORD,sliderElement:DWORD
		mov ebx, sliderElement
		mov ecx, hOxigen
		cmp ebx,ecx
		je OXIGEN
		mov ecx, hDust
		cmp ebx,ecx
		je DUST
		mov ecx, hNoise
		cmp ebx,ecx
		je NOISE
		jmp ENDE
		OXIGEN:
			invoke SendDlgItemMessage,hWin,ID_SLIDER_OXIGEN,TBM_GETPOS,0,0
			jmp ENDE
		DUST:
			invoke SendDlgItemMessage,hWin,ID_SLIDER_DUST,TBM_GETPOS,0,0
			jmp ENDE
		NOISE:
			invoke SendDlgItemMessage,hWin,ID_SLIDER_NOISE,TBM_GETPOS,0,0
		ENDE:
		mov NewPosition, eax
        ret
GetMouseValue endp
    
; ###############################################################
    
end start
