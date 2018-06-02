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
strCommand 		db "Pause",13,10,0
format 			db "%s",0
pathdep 		db "Entrer le chemin du repertoire à lister avec des \ : ",0
Tab 	db "   ",0
previousFolder 	db "..",0
currentFolder 	db ".",0
indicfichier 		db "<fichier> %s",10,0
indicdossier 		db "<dossier> %s",10,0
ajoutslash 		db "/",0
ajoutfin 		db "/*",0


.DATA?
; variables non-initialisées
result 	WIN32_FIND_DATA <>
path 		db 				?


.CODE



listDirectory:

    ; préparation de la pile   
	; ebp = bas de pile                      
	; esp = haut de pile                                     
	; on passe le bas de pile en haut de la pile via le push 
	; puis on déplace le haut de pile en bas de pile  
	push ebp
	mov ebp,esp
	sub esp, 260
	mov edx,esp

	mov ebx, [ebp+8] 					

	push ebx
	push edx
	call crt_strcpy 
	add esp,8 

	; EDX <- Path local
	mov edx,ebp
	sub edx,260 						

	push offset ajoutfin
	push edx
	call crt_strcat ; Path local + "/*"
	add esp,8 

	; EDX <- Path local = Path argument/*
	mov edx,ebp
	sub edx,260 						

	push offset result
	push edx
	call FindFirstFile ; EAX <- return du FindFirstFile

	mov ebx,ebp
	sub ebx,4 							
	mov [ebx], eax 						

	doWhile:
		; comparaison pour savoir si c'est un dossier
		cmp result.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
		jne file 

		directory:
		    ; On passe les "." et les ".."
				push offset currentFolder 
				push offset result.cFileName
				call crt_strcmp
				; restauration de la pile
				add esp,8
				cmp eax,0
				je nextFile 
				push offset previousFolder 	
				push offset result.cFileName
				call crt_strcmp
				add esp,8 					 
				cmp eax,0
				je nextFile 
			; fin des "." et ".."

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
			sub ecx,4 
			push offset result 
			push [ecx]
			call FindNextFile
			cmp eax,1 
			je doWhile 

	mov ecx,ebp
	sub ecx,4 
	push [ecx]
	call FindClose

	mov esp,ebp
	pop ebp
	ret


tabulation:

    ; préparation de la pile                                 
       
	push ebp
	mov ebp,esp 
	sub esp, 4                     
	; EBX <- tabulation passé en argument
	mov ebx,[ebp+8]                
	cmp ebx,0
	je return                      
	mov [ebp-4],ebx                ; on place notre compteur dans notre variable locale
	loop_inc:
		; utilisation de EAX pour gérer le compteur
		push offset Tab
		call crt_printf
		add esp,4                  

		mov eax,[ebp-4]
		dec eax
		mov [ebp-4],eax ; on decremente le compteur puis on le replace dans la variable locale

		cmp eax,0
		jne loop_inc               
	return:
		mov esp,ebp
		pop ebp
		ret


start:
	push offset pathdep
	call crt_printf
	push offset path
	push offset format
	call crt_scanf 

	push 0
	push offset path
	call listDirectory

	invoke crt_system, offset strCommand
	mov eax, 0
	invoke	ExitProcess,eax
end start