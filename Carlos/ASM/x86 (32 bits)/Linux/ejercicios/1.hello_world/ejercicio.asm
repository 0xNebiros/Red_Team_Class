; Compilar con: rm -rf ejercicio.o ejercicio && nasm -felf32 -o ejercicio.o ejercicio.asm && ld -m elf_i386 ejercicio.o -o ejercicio
; Ejecutar con: ./ejercicio
; Debuggar con: gdb ./ejercicio
; Este programa es un simple Hello World!

section .data                ; Sección donde se almacenan los datos inicializados.
  msg: db "Hello World!", 10 ; Se crea una variable que contiene "Hello world!" con un salto de linea (10 en hexadecimal).
  msg_len: equ $-msg         ; Se calcula la longitud del string almacenado en msg.

section .text                ; Sección donde empieza el programa.
  global _start              ; Se indica al programa la dirección de memoria donde debe empezar a ejecutarse (siempre sera en _start).

_start:                      ; Dirección de memoria en la que inicia el programa.
mov eax, 4                   ; Se mueve a eax la instrucción para el kernel (4 = sys_write).
mov ebx, 1                   ; Se mueve a ebx el indicador del fichero de salida (1 = standard output).
mov ecx, msg                 ; Se mueve a ecx la dirección de memoria msg, que contiene el mensaje a mostrar.
mov edx, msg_len             ; Se mueve a edx la dirección de memoria msg_len, que contiene la cantidad de bytes a mostrar.
int 0x80	                   ; Llamada al kernel.

mov eax, 1                   ; Se mueve a eax la instrucción para el kernel (1 = sys_exit).
mov ebx, 0                   ; Se mueve a ebx el código de la salida, 0 es que no hay error.
int 0x80	                   ; Llamada al kernel.
