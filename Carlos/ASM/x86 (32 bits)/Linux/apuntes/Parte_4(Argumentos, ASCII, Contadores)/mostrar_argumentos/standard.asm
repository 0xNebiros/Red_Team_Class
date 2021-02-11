; Sale del programa.
sys_exit:
  mov eax, 1
  mov ebx, 0
  int 0x80

; Escribe por pantalla.
sys_write:
  mov eax, 4
  mov ebx, 1
  int 0x80
  ret

; Calcula la longitud del string en edx y lo pone en ecx.
count_length:
  mov edx, ecx        ; Guarda la dirección de memoria en la que empieza el texto en edx.

  ; Comprueba caracter por caracter hasta encontrar un 0 (final de string)
  next_char:
    inc edx
    cmp byte [edx], 0
    jnz next_char

  sub edx, ecx      ; Resta a la dirección en la que se encuentra la dirección donde ha empezado, de esta forma se obtiene la longitud total.

  ret
