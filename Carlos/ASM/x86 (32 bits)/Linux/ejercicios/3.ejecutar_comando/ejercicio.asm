; Compilar con: rm -rf ejercicio.o ejercicio && nasm -felf32 -o ejercicio.o ejercicio.asm && ld -m elf_i386 ejercicio.o -o ejercicio
; Ejecutar con: ./ejercicio
; Debuggar con: gdb ./ejercicio
; Programa que pide un comando y una lista "infinita" de argumentos, despues debe ejecutar el comando con todos sus argumentos.

%include "standard.asm"

section .data
  command db "Introduce el comando que quieres ejecutar: ", 0
  command_len equ $-command
  argument db "Introduce el siguiente argumento (vacío para salir): ", 0
  argument_len equ $-argument
  empty db "Error: No se han introducido argumentos.", 0
  empty_len equ $-argument

section .bss
  input resb 24

section .text
  global _start

save_input_stack:
  mov eax, 24               ; 24 será la última posición del buffer que he creado, hay que empezar a leer desde aquí hacia atras de 4 en 4 bytes.
  check_start:
    sub eax, 4
    cmp byte [ecx+eax], 0   ; Comprueba que haya datos en la dirección de memoria a la que apunta ecx+eax
    jz check_start          ; Si no encuentra bytes vuelve al bucle para comprobar 4 bytes atras.

  pop ebx                     ; Recupera la dirección de la pila a la que tiene que volver.

  push_input:
    push dword [input+eax]
    sub eax, 4
    cmp eax, 0
    jge push_input

  push ebx                    ; Vuelve a guardar la dirección de memoria en la que debe continuar la ejecución y salta a esta.
  ret

_start:
  mov ebp, esp                ; Creo mi propia pila para usarla en este programa.

  ; Iniciar el programa pidiendo un comando.
  mov ecx, command
  mov edx, command_len
  call sys_write

  ; Bucle de recoger los datos introducidos por el usuario.
read_input:
  ; Leer teclado.
  mov ecx, input
  mov edx, 24
  call sys_read

  ; Si no se han introducido datos rompe el bucle.
  cmp byte [input], 0x0A
  je prepare_stack

  call save_input_stack

  ; Pedir un argumento.
  mov ecx, argument
  mov edx, argument_len
  call sys_write

  jmp read_input

  ; Prepara la lista de argumentos para ejecutar.
prepare_stack:
  cmp esp, ebp
  je empty_arguments

  mov eax, esp
  push 0

  push_argument:
    push eax
    end_argument:
      inc eax
      cmp byte [eax], 0x0A
      jne end_argument
      mov byte [eax], 0    ; Elimina el salto de linea.
    start_argument:
      inc eax
      cmp byte [eax], 0
      jz start_argument
    cmp eax, ebp
    jne push_argument

  ; Ejecutar el comando introducido.
execute:
  mov ebx, [esp]    ; Mueve a ebx la dirección en la que esta el nombre del comando.
  mov ecx, esp      ; Mueve a ecx la dirección donde empieza la lista de direcciones con los argumentos (incluido el nombre del programa).
  call sys_execve

  ; Finalizar el programa.
  jmp sys_exit

  ; Finalizar el programa con un mensaje de que no se han introducido argumentos.
empty_arguments:
  mov ecx, empty
  mov edx, empty_len
  call sys_write
  jmp sys_exit
