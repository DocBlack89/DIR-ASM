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


.DATA
; variables initialisées
pathdep 		db "Entrer le chemin du répertoire à lister avec des \ : ",0
Tab 	db "   ",0
indicfichier 		db "<fichier> %s",10,0
indicdossier 		db "<dossier> %s",10,0
mytestpath 		db ".",0
currentFolder 	db ".",0
previousFolder 	db "..",0
ajoutslash 		db "/",0
ajoutfin 		db "/*.*",0
strCommand 		db "Pause",13,10,0
format 			db "%s",0


.DATA?
; variables non-initialisées (bss)
result 	WIN32_FIND_DATA <>
pathUser 		db 				?


.CODE
tabulation PROC

    ; préparation de la pile                                 
	; ebp = bas de pile                      
	; esp = haut de pile                                     
	; on passe le bas de pile en haut de la pile via le push 
	; puis on déplace le haut de pile en bas de pile         
	push ebp
	mov ebp,esp ; le haut de pile et le bas de pile pointent au même endroit

	; réservation d'espace pour variable locale pour contenir la variable tabulation
	sub esp, 4                     
	; EBX <- tabulation passé en argument
	mov ebx,[ebp+8]                
	; si compteur == 0 -> return
	cmp ebx,0
	je return                      
	mov [ebp-4],ebx                ; on place notre compteur dans notre variable locale
	loop_inc:
		; utilisation de EAX pour gérer le compteur
		push offset Tab
		call crt_printf
		; restauration de la pile (1 argument de 4 octets)
		add esp,4                  

		mov eax,[ebp-4]
		dec eax
		mov [ebp-4],eax ; on decremente le compteur puis on le replace dans la variable locale

		; si compteur != 0 on boucle
		cmp eax,0
		jne loop_inc               
	return:
		mov esp,ebp
		pop ebp
		ret
tabulation ENDP


listDirectory PROC

    ; préparation de la pile                                 
	; ebp = bas de pile                                      
	; esp = haut de pile                                     
	; on passe le bas de pile en haut de la pile via le push 
	; puis on déplace le haut de pile en bas de pile 
	push ebp
	mov ebp,esp

    ;     4 octets pour le HANDLE [ebp+4]
    ; + 256 octets pour le PATH   [ebp+8]
	sub esp, 260
	mov edx,esp

	; EBX <- Path argument
	mov ebx, [ebp+8] 					

	push ebx
	push edx
	call crt_strcpy ; on place dans notre variable locale l'argument Path
	; restauration de la pile : 2 arguments de 4 octets
	add esp,8 

	; EDX <- Path local
	mov edx,ebp
	sub edx,260 						

	push offset ajoutfin
	push edx
	call crt_strcat ; EDX <- Path local + "/*.*"
	add esp,8 

	; EDX <- Path local = Path argument/*.*
	mov edx,ebp
	sub edx,260 						

	push offset result
	push edx
	call FindFirstFile ; EAX <- return du FindFirstFile

	; EBX <- récupération du handle
	mov ebx,ebp
	sub ebx,4 							
	; stockage du handle dans ebp-4
	mov [ebx], eax 						

	doWhile:
		; verification si File ou Directory
		cmp result.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
		jne file 

		directory:
		    ; -- DEBUT gestion des "." et ".." --
				push offset currentFolder 
				push offset result.cFileName
				call crt_strcmp
				; restauration de la pile : 2 arguments de 4 octets
				add esp,8
				cmp eax,0
				je nextFile 
				push offset previousFolder 	
				push offset result.cFileName
				call crt_strcmp
				add esp,8 					 
				cmp eax,0
				je nextFile 
			; -- FIN gestion des "." et ".." --

			; ECX <- Path local
			mov ecx,[ebp+8]
			mov edx,ebp
			sub edx,260

			push ecx
			push edx
			call crt_strcpy
			add esp,8

			mov edx,ebp
			sub edx,260
			push offset ajoutslash
			push edx
			call crt_strcat
			add esp,8 

			mov eax,ebp
			sub eax,260
			push offset result.cFileName
			push eax
			call crt_strcat
			add esp,8  

			; gestion de la tabulation
			; ECX <- compteur passé en argument
			mov ecx, [ebp+12]
			push ecx
			call tabulation
			add esp,4

			push offset result.cFileName
			push offset indicdossier
			call crt_printf
			add esp,8

			; EAX <- Path local, nouveau directory à lister
			mov eax,ebp
			sub eax,260
			mov edx,[ebp+12] 
			inc edx

			push edx
			push eax
			; appel recursif avec le nouveau Path (dossier dans le dossier donc) et la tabulation incrémentée
			call listDirectory

			jmp nextFile

		file:
			; ECX <- tabulation passée en argument
			mov ecx, [ebp+12] 				
			push ecx
			call tabulation 
			add esp,4

			push offset result.cFileName
			push offset indicfichier
			call crt_printf
			add esp,8 

		nextFile:
			mov ecx,ebp
			sub ecx,4 ; stockage du handle
			push offset result 
			push [ecx] ; FindNextFile demande une string en argument, on push donc la valeur du handle
			call FindNextFile
			; retour de FindNextFile : si 0 => pu de fichier, si 1 => continuer
			cmp eax,1 
			je doWhile 

	; ECX <- handle
	mov ecx,ebp
	sub ecx,4 
	push [ecx] ; FindClose demande une string en argument, on push donc la valeur du handle
	call FindClose

	mov esp,ebp
	pop ebp
	ret
listDirectory ENDP


start:
	push offset pathdep
	call crt_printf
	push offset pathUser
	push offset format
	call crt_scanf 

	push 0
	push offset pathUser
	call listDirectory

	invoke crt_system, offset strCommand
	mov eax, 0
	invoke	ExitProcess,eax
end start