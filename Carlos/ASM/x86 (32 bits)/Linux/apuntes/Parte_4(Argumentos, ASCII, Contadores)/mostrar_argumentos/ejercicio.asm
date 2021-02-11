%include "standard.asm"

section .data
  total1 db "Has introducido ", 0
  total1_len equ $-total1
  total2 db " argumentos.", 0x0A, 0
  total2_len equ $-total2
  argument db "Argumento ", 0
  argument_len equ $-argument

section .text
  global _start

; Convierte un numero a ascii y lo mete en la pila para poderlo mostrar.
number_to_ascii:
  pop eax
  add ecx, 48     ; Suma 48 al número en ecx para convertirlo en su caracter númerico en ascii.
  push ecx        ; Guarda el caracter ascii en la pila.
  mov ecx, esp    ; Mueve la dirección del tope de la pila a ecx para poder mostrar ese texto por pantalla.
  mov edx, 1      ; La longitud del texto será 1.
  push eax
  ret

_start:
  ; Mostrar mensaje "Has introducido."
  mov ecx, total1
  mov edx, total1_len
  call sys_write

  ; Mostrar número de argumentos.
  pop ecx         ; Guarda el número de argumentos en ecx.
  dec ecx         ; Resta uno al número de argumentos, ya que el primer argumento es el nombre del programa.
  mov esi, ecx    ; Mueve el número de argumentos de ecx a esi para usar esi como contador.
  call number_to_ascii
  call sys_write
  add esp, 4      ; Limpia el valor introducido en la pila.

  ; Mostrar mensaje "argumentos."
  mov ecx, total2
  mov edx, total2_len
  call sys_write

  add esp, 4    ; Limpia el primer registro de la pila, que es el nombre del programa.
  mov edi, 0    ; Inicializa edi a 0 para poder usarlo como contador.

  ; Recorrer argumentos.
next_argument:
  ; Cierra el programa cuando no queden mas argumentos, es decir cuando edi sea mayor que esi.
  inc edi
  cmp edi, esi
  jg sys_exit

  ; Mostrar mensaje "Argumento "
  mov ecx, argument
  mov edx, argument_len
  call sys_write

  ; Mostrar el número de argumento.
  mov ecx, edi
  call number_to_ascii
  call sys_write

  ; Mostrar el texto ": ".
  push ": "
  mov ecx, esp
  mov edx, 2
  call sys_write

  ; Mostrar el siguiente argumento de la pila.
  add esp, 8          ; Limpia los dos registros que se han mostrado anteriormente en la pila.
  pop ecx             ; Guarda el argumento en ecx.
  call count_length   ; Cuenta la longitud de dicho argumento.
  call sys_write      ; Escribe el argumento por pantalla.

  ; Poner un salto de linea.
  push 0x0A
  mov ecx, esp
  mov edx, 1
  call sys_write
  add esp, 4          ; Limpia el registro de la pila.

  jmp next_argument
