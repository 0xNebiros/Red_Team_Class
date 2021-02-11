; Compilar con: rm -rf ejercicio.o ejercicio && nasm -felf32 -o ejercicio.o ejercicio.asm && ld -m elf_i386 ejercicio.o -o ejercicio
; Ejecutar con: ./ejercicio
; Debuggar con: gdb ./ejercicio
; Programa que calcula la longitud de un texto.

section .data
  msg db "Esto es un string", 0    ; Texto de prueba para calcular su longitud, este acaba con un 0, de forma que se indica al ensamblador donde acaba el string.

section .text
  global _start

_start:
  mov eax, msg        ; Mueve la dirección de msg a eax.

  next_char:
    cmp byte[eax], 0  ; Compara el byte al que apunta eax con 0, 0 es el delimitador de final de string. Es decir, los strings acaban con un byte 0.
    je finished       ; Salta a la dirección de memoria a "finished" si la comparación anterior ha dado como resultado que ambos numeros son iguales, es decir, si salta la flag 0.
    inc eax           ; Incrementa eax en 1.
    jmp next_char     ; Salta a la dirección de memoria next_char para repetir el bucle.

  finished:
    sub eax, msg      ; Resta la dirección de eax a la dirección de msg.
                      ; En este punto eax tiene almacenada la dirección de memoria del ultimo byte de msg, ya que empezó donde empieza msg y ha ido incrementando hasta encontrar un 0.
                      ; Cuando se resta la dirección de memoria de eax menos la dirección de memoria de msg se obtiene el segmento que esta última ocupa, es decir, la longitud del texto.

  mov edx, eax        ; Se mueve a edx la longitud del string que esta almacenada en eax.
  mov eax, 4          ; Se mueve a eax la instrucción 4, para escribir por pantalla.
  mov ebx, 1          ; Se elige la salida estandar.
  mov ecx, msg        ; Se mueve a ecx la dirección en la que empieza el texto que se va a mostrar.
  int 0x80

  mov eax, 1
  mov ebx, 0
  int 0x80
