section .data 			  					     																			; Espacio de memoria para la declaración de datos inicializados.
	ask_com: db "Introduce el comando que quieres ejecutar: ", 0 	     			; Declaración de mensaje que se mostrara por pantalla, como grupos de un byte (db).
	ask_com_len: equ $-ask_com 					     																; Declaración de la longitud del mensaje que se va a mostrar en forma de constante (equ).
	ask_arg: db "Introduce el siguiente argumento (vacio para salir): ", 0  ; Declaración de mensaje que se mostrara por pantalla, como grupos de un byte (db).
	ask_arg_len: equ $-ask_arg 					    															 	; Declaración de la longitud del mensaje que se va a mostrar en forma de constante (equ).
	com_max_len: equ 500						     																		; Declaración de la longitud maxima que podrá tener el comando en forma de constante (equ).

section .bss
	command: resb com_max_len   ; Espacio de memoria reservado para almacenar el comando escrito por el usuario, se reserva un espacio de 20 bytes (resb 20).
	com_len: resb 2		   	     	; Espacio de memoria reservado para almacenar el tamaño maximo que podrá contener el comando escrito por el usuario.

section .text
	global _start

check_command: 					; Bucle utilizado para eliminar el salto de linea de los textos introducidos por teclado y calcular la longitud del string introducido, esto se hace recorriendo posiciones de memoria a partir de ecx hasta encontrar el salto de linea.
												; Este bucle es inutil, podría haberlo hecho en menos lineas de código si hubiese aprovechado el resultado que se guarda en eax con el sys_write.
	; Recorrer string
	inc eax								; Incrementa eax en uno por cada recorrido del bucle, es decir, por cada byte leido.
	inc ecx								; Incrementa la posición de memoria almacenada en ecx en 1.
	cmp [ecx], byte 0xA		; Compara el byte que hay en la dirección de memoria de ecx con 0xA, que es el salto de linea en hexadecimal.
	jne check_command			; Vuelve a empezar el bucle.

	; Corregir comando y actualizar longitud
	mov byte [ecx], 0			; Mueve al contenido de la posición de memoria almacenada en ecx el byte 0, de esta forma se esta eliminando el salto de linea del comando.
	add [com_len], eax		; Suma al contenido de la posición de memoria almacenada en com_len el contenido de eax, de esta forma se tiene el tamaño total del texto.

	; Pedir argumentos.
	mov eax, 4						; Mueve a eax 4, esta es la opción de sys_call que se desea ejecutar (4 = sys_write).
	mov ebx, 1						; Mueve a ebx 1, este es el "fichero" de salida en el que mostrar el mensaje (1 = standard output, en este caso la consola).
	mov ecx, ask_arg			; Mueve a ecx la dirección de memoria almacenada en ask_arg, esta dirección de memoria contiene el mensaje que se va a mostrar por pantalla (realmente son varias direcciónes porque el mensaje mide mas de 8 bytes.)
	mov edx, ask_arg_len	; Mueve a edx la dirección de memoria almacenada en ask_com_len, esta dirección de memoria contiene la cantidad de bytes que contiene el mensaje que se va a mostrar por pantalla, es decir, la longitud del mensaje.
	int 0x80
	jmp write

_start:
	; Pedir un comando por pantalla (sys_write).
	mov eax, 4						; Mueve a eax 4, esta es la opción de sys_call que se desea ejecutar (4 = sys_write).
	mov ebx, 1						; Mueve a ebx 1, este es el "fichero" de salida en el que mostrar el mensaje (1 = standard output, en este caso la consola).
	mov ecx, ask_com			; Mueve a ecx la dirección de memoria almacenada en ask_com, esta dirección de memoria contiene el mensaje que se va a mostrar por pantalla (realmente son varias direcciónes porque el mensaje mide mas de 8 bytes.)
	mov edx, ask_com_len	; Mueve a edx la dirección de memoria almacenada en ask_com_len, esta dirección de memoria contiene la cantidad de bytes que contiene el mensaje que se va a mostrar por pantalla, es decir, la longitud del mensaje.
	int 0x80  						; Llamada al kernel

write:  ; Dar la opción de escribir (sys_read).
	mov eax, command			; Mueve a eax la dirección de memoria asociada a command, es decir, guarda la posición donde empieza el comando.
	add eax, [com_len]		; Suma a eax el contenido de la dirección de memoria asociada a com_len, esto es para saber en que punto se puede empezar a escribir.
	mov ecx, eax					; Mueve a ecx la dirección de memoria asociada a eax, esta dirección de memoria es el espacio vacío reservado para escribir el comando, es decir, es el buffer del comando al que se le ha quitado la parte ya escrita.
	mov eax, com_max_len	; *1 Se guarda en eax el tamaño maximo del buffer que se ha creado para introducir comandos.
	sub eax, [com_len]		; Resta a eax el contenido de la dirección de memoria asociada a la etiqueta com_len. De esta forma se puede saber cuanto se podrá escribir.
	mov edx, eax					; Mueve a edx el contenido de eax, este es el tamaño maximo del espacio de memoria que aceptará el programa.
	mov eax, 3						; Mueve a eax 3, esta es la opción de sys_call que se desea ejecutar (3 = sys_read).
	mov ebx, 2						; Mueve a ebx 2, este es el metodo de entrada utilizado para introducir los datos (2 = standard input, en este caso el teclado).
	int 0x80							; Llamada al kernel

	cmp [ecx], byte 0xA		; Compara el byte que hay en la dirección de memoria de ecx con 0xA, que es el salto de linea en hexadecimal.
	je prepare_stack			; Si se ha introducido un salto de linea se acaba el programa.

	; Eliminar el salto de linea del texto introducido y contar longitud.
	mov eax, 1						; Mueve a eax 0, esto lo hago para poder utilizar eax como contador.
	jmp check_command			; Salta a la etiqueta check_command, donde se comprobará la longitud del texto y se modificara el \n

prepare_stack:
	mov byte [ecx], 0			; Mueve al contenido de la dirección de memoria almacenada en ecx el byte 0, de esta forma se elimina el ultimo salto de linea que se ha utilizado para salir.
	mov eax, command			; Mueve a eax la dirección de memoria a la que hace referencia la etiqueta command, de esta forma podré saber donde empiezan los comandos.
	push 0								; Mueve uno al principio de la pila, de esta forma se indicará donde acaba la lista de comandos.
	dec ecx								; Decrementa la dirección de memoria almacenada en ecx en uno, esta primera decrementación es necesaria porque sino empezará en la ultima posición que es un 0 despues de un 0 y eso da error.

keep_decrementing:
	dec ecx			; Decrementa la dirección de memoria almacenada en ecx en uno, de esta forma ire recorriendo todas las direcciones entre el principio de los comandos y el final.

	cmp eax, ecx					; Compara la dirección de memoria almacenada en eax con la dirección de memoria almacenada en ecx.
	je  end_stack					; Si son iguales salta a end_stack, esto significa que estoy en el ultimo (primero segun se mire) parametro por lo que ya puede salir.
	cmp byte [ecx], 0			; Compara el byte que hay en eax con 0, 0 es la separación entre comandos, por lo que si es 0 significa que esta en un cambio de comando.
	jne keep_decrementing	; Si no es igual vuelve al bucle, esto significa que esta leyendo un comando.

	; Guardar comando. Esto no me gusta nada como ha quedado, eso de incrementar ecx, meter a la pila y decrementar queda muy feo, tengo que pensar una forma mas optima.
	inc ecx								; Incrementa ecx.
	push ecx							; Mueve la dirección de memoria alojada en ecx a la pila.
	dec ecx								; Decrementa ecx de nuevo (no queremos un bucle infinito).
	jmp keep_decrementing	; Vuelve de nuevo al bucle.

end_stack:
	push command					; Se mete la dirección de memoria asociada a comando a en la pila, este es el comando que se va a ejecutar

	; Ejecutar comando (sys_execve).
	mov eax, 0x0b					; Mueve a eax el numero en hexadecimal B, que es la opción de sys_call que se desea ejecutar (B = sys_execve, la opción utilizada para ejecutar comandos).
	mov ebx, command			; Mueve a ebx la dirección de memoria asociada a la etiqueta command, esta es la dirección de memoria donde esta el fichero que se va a ejecutar, en este caso es dentro del propio programa.
	mov ecx, esp					; Mueve a ecx la dirección esp, esta dirección es donde empieza la pila, seran los argumentos que va a necesitar el programa para ejecutarse correctamente.
	mov edx, 0						; Mueve a edx 0.
	int 0x80							; Llamada al kernel

	; Finalizar el programa.
	mov eax, 1						; Mueve a eax 1, esta es la opción de sys_call que se desea ejecutar (1 = sys_exit).
	mov ebx, 0						; Mueve a ebx 0, este es el código de error que se guardará en la salida, 0 es que no ha habido errores.
	int 0x80							; Llamada al kernel
