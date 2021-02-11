section .data
	ask_com: db "Introduce el comando a ejecutar: ", 0
	ask_com_len: equ $-ask_com
	ask_par: db "Introduce un parametro (vacio para salir): ", 0
	ask_par_len: equ $-ask_par

section .bss
	start_stack: resb 8									; Variable para almacenar la posición de la pila en la que se ha almacenado el nombre del comando, esto lo utilizaré mas adelante para darle la vuelta a la pila.
	command: resb 255										; Variable para almacenar el texto que introduzca el usuario.
	command_start: resb 8								; Variable para determinar en que punto de command se guardará la información, de esta forma no se pisan los datos.

section .text
	global _start

_start:
	; Inicializar datos.
	mov [command_start], dword command	; Inicializa la variable command_start a 0, de forma que se empiezen a guardar los datos en la posición a la que apunta command.

	; Preparar pila.
	push 0															; Se mete 0 a la pila, de esta forma se podrá saber cuando acaban los parametros del comando.
	mov [start_stack], esp							; Se guarda la dirección de memoria de eax en start_stack, esto luego lo utilizaré para recorrer la pila de forma inversa.

	; Sys_Write, pide el comando que se va a ejecutar.
	mov eax, 4
	mov ebx, 1
	mov ecx, ask_com
	mov edx, ask_com_len
	int 0x80

ask_command:
	; Sys_Read, deja al usuario escribir el comando o los parametros.
	mov eax, 3
	mov ebx, 0
	mov ecx, [command_start]
	mov edx, 10
	int 0x80

	; Ruptura del bucle.
	cmp [ecx], byte 0xA									; Comprueba que el caracter introducido no sea un salto de linea (la condición de salida),
	je prepare_stack										; si el usuario ha pulsado enter sin escribir nada deja de preguntar parametros y sale del bucle.

	; Quitar salto de linea y meter comando en la pila.
	mov byte [ecx+eax-1], 0x0						; Elimina el salto de linea que se ha leido en la introducción del usuario, para ello coge la dirección de memoria en la que se ha almacenado el string (ecx) y le suma el tamaño del dicho string (eax), se resta uno y se obtiene el último byte que se ha guardado.
	push ecx														; Mete la dirección de memoria en la que se aloja el comando introducido a la pila.


	add eax, ecx												; Suma la longitud del texto introducido (eax) la dirección de memoria en la que se ha empezado a escribir.
	mov [command_start], eax						; Y guarda el resultado en command_start para poder escribir mas tarde en ese punto.

	; Sys_Write, pide un parametro para el comando.
	mov eax, 4
	mov ebx, 1
	mov ecx, ask_par
	mov edx, ask_par_len
	int 0x80

	jmp ask_command

prepare_stack:
	; Prepara en eax y ebx los espacios de memoria del principio y fin de la pila para recorrerla.
	mov eax, [start_stack]							; Guarda en eax el punto de la pila en el que esta almacenado el 0 introducido al principio del programa.
	sub eax, 4													; Se le restan 4 para empezar en el primer comando introducido, cada dirección de memoria son 4 bytes.
	mov ebx, esp												; Se guarda en ebx el principio de la pila.

exchange_values:

	; Intercambia el contenido de las direcciónes de memoria de eax y ebx, esto implica darle la vuelta a la pila.
	mov ecx, [eax]											; Mueve a ecx el contenido de la dirección de memoria a la que apunta eax.
	mov edx, [ebx]											; Mueve a edx el contenido de la dirección de memoria a la que apunta ebx.
	mov [eax], edx											; Mueve al contenido de eax el contenido de la dirección de memoria de edx
	mov [ebx], ecx											; Mueve al contenido de ebx el contenido de la dirección de memoria de ecx.

	; Los contadores cambian y se busca la siguiente dirección de memoria.
	sub eax, 4													; Resta 4 bytes al contador superior de la pila para acceder a la siguiente dirección de memoria (contando desde abajo).
	add ebx, 4													; Suma 4 bytes al contador inferior de la pila para acceder a la siguiente dirección de memoria (contando desde arriba).
	cmp eax, ebx												; Compara eax con ebx,
	jg  exchange_values									; Si eax es mayor vuelve al bucle, porque significa que aun quedan registros que hay que invertir.

	; Ejecutar comando (Sys_Execve)
	mov eax, 0x0B
	mov ebx, command
	mov ecx, esp
	mov edx, 0
	int 0x80

	; Exit
	; Sys_Exit, cierra el programa sin problemas.
	mov eax, 1
	mov ebx, 0
	int 0x80
