.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\gdiplus.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\msvcrt.lib

StrLen      PROTO :DWORD

.DATA
strCommand db 10,"Pause",13,10,0
path      db "c:\",0	; sprintf(filename, "C:/../../%s", buffer)
search_path	db	"\*",0

; temp	db "c:\Users\antoi\Documents",10
print db	10," ", 10, 0
dossier db 10,"C'est un fucking dossier", 0
.DATA?

path2     db 256 dup(?)
result      WIN32_FIND_DATA <?>
hdl         dd ?

.CODE

suppresion_etoile:
	mov eax, offset result.cFileName
	mov ecx, offset path
	compteur:
		mov BL, BYTE PTR[ecx]
		CMP BL, 00 ;on vérifie que l'on n'est pas à la fin de la chaine
		je path_modif ;si on est à la fin
		CMP BL, 0000002Ah
		jne erreur; si pas égal on incrémente
		SUB BL, 0000002Ah
		MOV BYTE PTR[ecx], BL
		erreur:
			ADD ecx, 1 ;passe à la lettre suivante
			jmp compteur
			
			
path_modif:
	push MAX_PATH	; 260 bytes
	call crt_malloc
	; mov eax, offset result.cFileName
	; mov ebx, offset path
	; push eax
	; push ebx
	; call crt_strcat
	mov edx, eax ; pointer to a 260 bytes buffer
	push offset result.cFileName
	push offset path
	push eax
	call crt_sprintf
	jmp debut

					
start:

  concatenation: 
	push MAX_PATH	; 260 bytes
	call crt_malloc
	mov edx, eax ; pointer to a 260 bytes buffer
	push offset search_path
	push offset path
	push eax
	call crt_sprintf
	push edx
	call crt_printf

 debut:
	push edx
	call crt_printf
	mov eax, edx
	push eax
	call crt_printf
    invoke FindFirstFile, ADDR path, ADDR result
    .IF eax!=INVALID_HANDLE_VALUE

        mov hdl, eax
		invoke crt_printf, ADDR result.cFileName
 le_loop:
        invoke FindNextFile, hdl, ADDR result
        cmp eax, 0
        je fini
		push offset print
		call crt_printf
		invoke crt_printf, ADDR result.cFileName
	
	
	; test si un dossier
	mov eax,[result.dwFileAttributes]
    and eax,FILE_ATTRIBUTE_DIRECTORY
    test eax,eax
    je le_loop
	
	
	; Compare le nom de fichier avec "."
    mov eax,DWORD PTR [result.cFileName]
    cmp eax,00002E2Eh
    je le_loop

	
	call crt_printf
	jmp suppresion_etoile

	

	
	
jmp le_loop
    .ELSE
   
    .ENDIF
   fini:
   invoke crt_system, offset strCommand
	mov eax, 0
	invoke	ExitProcess,eax
    invoke FindClose, hdl
    invoke ExitProcess, 0

end start