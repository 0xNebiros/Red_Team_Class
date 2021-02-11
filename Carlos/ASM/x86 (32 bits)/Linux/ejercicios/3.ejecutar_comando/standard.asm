; Fichero con funciones repetitivas.

; Salir del programa
sys_exit:
  mov eax, 1
  mov ebx, 0
  int 0x80

; Leer texto introducido por teclado.
sys_read:
  mov eax, 0
  clean_buffer:         ; Mueve 0 de 4 en 4 bytes hasta haber limpiado todo el buffer.
    mov dword [ecx+eax], 0
    add eax, 4
    cmp byte [ecx+eax], 0
    jnz clean_buffer

  mov eax, 3
  mov ebx, 0
  int 0x80
  ret

; Ejecutar comando.
sys_execve:
  mov eax, 0x0B
  mov edx, 0
  int 0x80
  ret

; Escribir texto por pantalla.
sys_write:
  mov eax, 4
  mov ebx, 1
  int 0x80
  ret
