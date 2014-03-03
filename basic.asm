org 7c00h                                        ; Tell NASM that the code's base will be at 7c00h.
                                                 ; Otherwise it will assume offset 0 when calculating
                                                 ; addresses.
 
jmp short start                                  ; jump over data
 
message:
    db "Desea encender el LED? y/n ", 0          ; un mensaje, es un array de bits, termina en 0, que marca el fin del string
message2:
    db "El LED esta encendido, presiona x para regresar", 0                
message3:
    db "el LED esta apagado, presiona x para regresar", 0                    
 
start:
    xor al, al                                   ; Limpiamos AL, para que con la interrupcion 10h el VM=40*25
    xor ax, ax                                   ; cuando ax=0, la interrupcion 10h setea el modo de video
    push ax                                      ; nuestro estado inicial, que es 0, lo metemos a la pila
    ;int 0x10                                    ; la interrupcion de video

    mov ds, ax                                   ; ds needs to be 0 for lodsb
    cld                                          ; clear direction flag for lodsb
 
main:
    mov si, message                              ; move the message's address into si for lodsb
    jmp string                                   ; jump to the string routine
 
; Displays a character
; int 0x10 ah=e
; al = character, bh = page number

char:
    mov bx, 0x1
    mov ah, 0xe
    int 0x10
 
; print a string
string:
    lodsb                                        ; carga el primer byte de ds:esi a al, luego el indice aumenta automaticamente en uno.
    cmp al, 0x0
    jnz char                                     ; si ahorita AL no es 0, es por q no hemos llegado al final del string.
    ;xor ax, ax
    pop ax                                       ; ponemos el ultimo valor de la pila en ah, para ver el estado
    cmp ax, 0x0                                  ; comparamos con 0, si es asi, iremos a introducir un input del teclado
    jne end                                      ; si es 1, terminamos el programa
    jmp getchar                                  ; a obtener inputs del teclado

getchar:
    mov ah,0x0                                   ; ah debe de ser 0 para que la interrupcion 16 sepa que debe de leer del teclado
    mov al, 0x0                                  ; lo hacemos 0, solo par evitar algun problema, aqui se guarda el valor ascii usado
    int 0x16                                     ; la interrupcion "read", el valor ascii se guarda en al.
    
    ;mov bx, 0x1                                  ; 
    ;mov ah, 0xe                                  ; esto le dice a la interrupcion 16h que se escribira un caracter
    ;int 0x10                                     ; interrupcion de video  
    call clearS                                  ; limpiamos la pantalla 
    cmp al, 0x79                                 ; comparamos
    mov ax, 1h                                   ; ponemos 1 en ah, que sera nuestri "estado" despues de presionar una tecla
    push ax                                      ; lo ponemos en la pila
    je ONLED                                     ; si al era igual a 'y', saltamos a ONLED
    jmp OFFLED                                   ; si no, saltamos a OFFLED

ONLED:                                            ;aqui haceos que salga el mensaje 2
    xor ax, ax                                   ; limpiamos ax
    mov ds, ax                                   ; ds needs to be 0 for lodsb
    cld 
    mov si, message2
    jmp string

OFFLED:
    xor ax, ax                                   ; limpiamos ax
    mov ds, ax                                   ; ds needs to be 0 for lodsb
    cld 
    mov si, message3                             ; si no, cargamos el mensaje 3
    jmp string                                   ; e iremos a ponerlo

clearS:
    ;mov ax,0x0B800                               ;0B800:0000 es donde esta el buffer de video en modo texto, DI solo debe de ser 0000, asi que lo limpiaremos
    ;mov es, ax                                   ;guardamos esta localizacion en ES, por q de ES:DI se leera la localizacion para "stosw"         
    ;xor di,di                                    ;limpiamos DI, DI=0000
    ;xor ax,ax
    ;mov cx,2000d                                 ; movemos 1000 a cx, por que esta es la cantidad de veces que "rep" repetira a "stosw" 
    ;cld                                     ; limpiamos la bandera de direccion, por que si es 0, la direccion inicial ira aumentando un word, en uno decrementaria
    ;rep stosw                            ; se repetira cx veces stosw, stosw guarda un word en la direccion especificada y aumenta automaticamente la direccion luego
    push ax                                      ; para que no perdamos el valor de la ultima tecla que apretamos
    mov ah, 6d                                   ; cuando AH=6h, int 0x10 aplicara la funcion de "scroll up" que puede usarse para limpiar el texto
    mov al, 0                                    ; al indica cuantas lineas subir, si lo ponemos en 0, limpia la pantalla
    mov bh, 7h                                   ; bh cambia el color de fondo, con este queda en negro aun (?)
    mov cx, 0                                    ; ch y cl controlan el primer par ordenado (ie, donde inicia la pantalla) en este caso, ambos seran 0
    mov dl, 79                                   ; la columna del segundo par, 79 por que el TTY normal es de 80x25 (iniciando en 0)
    mov dh, 24                                   ; la fila del segundo par
    int 0x10
    
    mov ah, 2h                                   ; AH=2 es para mover el cursor, lo volveremos a poner al inicio
    mov bh, 0                                    ; BH controla el numero de pagina
    mov dx, 0                                    ; dh y dl controlan las filas y columnas donde estara el cursor, en este caso, al inicio
    int 0x10
    pop ax                                       ; recuperamos el valor (ademas, si no llamamos pop, ret no sabria a donde regresar)
    ret                                          ; regresamos de donde nos hayan llamado
 
                                    ; infinite loop that does nothing
end:
    jmp short end
 
times 0200h - 2 - ($ - $$)  db 0    ; NASM directive: zerofill up to 510 bytes
 
dw 0AA55h                           ; Magic boot sector signature
