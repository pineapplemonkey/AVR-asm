; =================================================
; UART Serial Communication
; An example of how to perform communication over
; the serial bus with an AVR processor
; =================================================

; Include the aliases and constants
.INCLUDE "../resources/m328Pdef.inc"


.def reg1 = r16
.def reg2 = r17
.def delay_reg1 = r18
.def delay_reg2 = r19
.def delay_reg3 = r20
.def reg_bitmask = r21

; At origin 0x0000, hook in our calls.. Why?
.ORG 0x0000
    jmp main

main:
    call usart_init 
    
    ; Init debug LED i'm using (pin 11)
    ldi reg_bitmask, (1<<DDB3) | (1<<DDB5)
    out DDRB, reg_bitmask
    cbi PORTB, 3
    cbi PORTB, 5

program_loop:
    ldi reg2, 65 ; load send-data with A
    sbi PORTB, 3
    call delay_start ; wait 1 second
    call usart_transmit ; send data
    cbi PORTB, 3
    cbi PORTB, 5
    call delay_start ; wait 1 second
    jmp program_loop

    ; Prepares the AVR for UART communication
    ; by setting correct bits in the appropriate registers
usart_init:
    ; Asyncrhonous communication uses a fixed baud rate as
    ; the communication frequency. Calculated form following
    ; formula (async normal mode):
    ;   BAUD = f_osc / ( 16 * (UBBRn + 1) )
    ;   UBBRn = (f_osc / (16*BAUD) )) - 1
    ; To set the baud rate on this AVR use the UBBR0 register
    ; This is 16 bit, so set UBBR0H and UBBR0L.
    ;   f_osc = 16MHZ
    ;   BAUD = 9600
    ;   UBBR0 = (16000000 / (16*9600)) - 1
    ;   UBBR0 = 103.166
    ; R16 is used as the lower part of the 16 bit number (14=0x0e)
    ldi reg1, 103
    ldi reg2, 0
    sts UBRR0H, reg2 
    sts UBRR0L, reg1
    ; Enable the receiver and transmitter
    ldi reg1, (1<<RXEN0) | (1<<TXEN0)
    sts UCSR0B, reg1
    ; Set the frame format to use, 8 bit data, 2 stop bit
    ldi reg1, (1<<USBS0) | (3<<UCSZ00)
    sts UCSR0C, reg1

    ret

; send a usart packet (8-bit)
usart_transmit:
    ; wait for an empty transmit buffer
    lds reg1, UCSR0A
    sbrs reg1, UDRE0
    rjmp usart_transmit
    ; Put data into buffer, which will send it
    sbi PORTB, 5
    sts UDR0, reg2
    ret


; A 1 second delay, see delay project for details on how this works.
delay_start:    
        LDI delay_reg1, 64
delay_l1:
        LDI delay_reg2, 250
delay_l2:
        LDI delay_reg3, 250
delay_l3:
        DEC delay_reg3
        NOP
        BRNE delay_l3

        DEC delay_reg2
        BRNE delay_l2

        DEC delay_reg1
        BRNE delay_l1
        
        RET

