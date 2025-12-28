@
@    Mecrisp-Stellaris - A native code Forth implementation for ARM-Cortex M microcontrollers
@    Copyright (C) 2013  Matthias Koch
@
@    This program is free software: you can redistribute it and/or modify
@    it under the terms of the GNU General Public License as published by
@    the Free Software Foundation, either version 3 of the License, or
@    (at your option) any later version.
@
@    This program is distributed in the hope that it will be useful,
@    but WITHOUT ANY WARRANTY; without even the implied warranty of
@    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@    GNU General Public License for more details.
@
@    You should have received a copy of the GNU General Public License
@    along with this program.  If not, see <http://www.gnu.org/licenses/>.
@

@ Terminalroutinen
@ Terminal code and initialisations.
@ Porting: Rewrite this !
@ 12 MHz Internal Clock, 115200 Baud UART0 (TX=P0.4, RX=P0.0)

.equ SYSAHBCLKCTRL, 0x40048080
.equ PRESETCTRL,    0x40048088
.equ PINASSIGN0,    0x4000C000
.equ UARTCLKDIV,    0x40048094
.equ FLASHCFG,      0x40040010  @ Flash configuration (Wait states)
.equ SYSPLLCTRL,    0x40048008  @ PLL Control
.equ SYSPLLSTAT,    0x4004800C  @ PLL Status
.equ SYSPLLCLKSEL,  0x40048040  @ PLL Source Select
.equ SYSPLLCLKUEN,  0x40048044  @ PLL Update Enable
.equ MAINCLKSEL,    0x40048070  @ Main Clock Select
.equ MAINCLKUEN,    0x40048074  @ Main Clock Update Enable
.equ SYSAHBCLKDIV,  0x40048078  @ System Clock Divider
.equ PDRUNCFG,      0x40048238  @ Power configuration register

.equ FRG0DIV,       0x400480F0
.equ FRG0MULT,      0x400480F4

.equ DIR0    , 0xA0002000
.equ MASK0   , 0xA0002080
.equ PIN0    , 0xA0002100
.equ MPIN0   , 0xA0002180
.equ SET0    , 0xA0002200
.equ CLR0    , 0xA0002280
.equ NOT0    , 0xA0002300
.equ DIRSET0 , 0xA0002380
.equ DIRCLR0 , 0xA0002400
.equ DIRNOT0 , 0xA0002480

.equ UART_Base, 0x40064000

.equ CFG       , UART_Base + 0x000
.equ CTL       , UART_Base + 0x004
.equ STAT      , UART_Base + 0x008
.equ INTENSET  , UART_Base + 0x00C
.equ INTENCLR  , UART_Base + 0x010
.equ RXDAT     , UART_Base + 0x014
.equ RXDATSTAT , UART_Base + 0x018
.equ TXDAT     , UART_Base + 0x01C
.equ BRG       , UART_Base + 0x020
.equ INTSTAT   , UART_Base + 0x024
.equ OSR       , UART_Base + 0x028
.equ ADDR      , UART_Base + 0x02C

@ -----------------------------------------------------------------------------
@ 子程序: 初始化系統時脈至 30 MHz
@ -----------------------------------------------------------------------------
system_init_30mhz:
   push {lr}

   @ 1. 設定 Flash Wait State (30MHz 需要 1 wait state)
   @ --------------------------------------------------------
   ldr r0, =FLASHCFG
   ldr r1, [r0]
   movs r2, #3
   bics r1, r2
   movs r2, #1       @ FLASHTIM = 1 (2 system clocks)
   orrs r1, r2
   str r1, [r0]

   @ 2. [順序修正] 先設定並更新 PLL 的輸入時脈來源
   @ --------------------------------------------------------
   @ 選擇 IRC 做為 PLL 輸入
   ldr r0, =SYSPLLCLKSEL
   movs r1, #0       @ Source = IRC (0)
   str r1, [r0]
   
   @ 必須 Toggle UEN 讓選擇生效！
   ldr r0, =SYSPLLCLKUEN
   movs r1, #0
   str r1, [r0]      @ 寫 0
   movs r1, #1
   str r1, [r0]      @ 寫 1 (Update)

   @ 3. 設定 PLL 參數 (產生 60 MHz)
   @ --------------------------------------------------------
   @ Input = 12 MHz, M = 5, P = 2
   @ Val = (PSEL=1)<<5 | (MSEL=4) = 0x20 | 0x04 = 0x24
   ldr r0, =SYSPLLCTRL
   movs r1, #0x24
   str r1, [r0]

   @ 4. 開啟 PLL 電源 (Power Up)
   @ --------------------------------------------------------
   @ 現在時脈穩定了，參數也設好了，終於可以開電了
   ldr r0, =PDRUNCFG
   ldr r1, [r0]
   movs r2, #0x80    @ Bit 7 (SYSPLL_PD)
   bics r1, r2       @ 清除 Bit 7 (0 = Power Up)
   str r1, [r0]

   @ 5. 等待 PLL 鎖定
   @ --------------------------------------------------------
   ldr r0, =SYSPLLSTAT
wait_lock:
   ldr r1, [r0]
   movs r2, #1
   tst r1, r2
   beq wait_lock     @ 等待 Bit 0 變成 1

   @ 6. 設定系統除頻器 (Div by 2 -> 30MHz)
   @ --------------------------------------------------------
   ldr r0, =SYSAHBCLKDIV
   movs r1, #2
   str r1, [r0]

   @ 7. 切換主時脈到 PLL
   @ --------------------------------------------------------
   ldr r0, =MAINCLKSEL
   movs r1, #3       @ Select PLL Output
   str r1, [r0]

   ldr r0, =MAINCLKUEN
   movs r1, #0
   str r1, [r0]      @ Toggle Update
   movs r1, #1
   str r1, [r0]

   pop {pc}

@ -----------------------------------------------------------------------------
uart_init: @ ( -- )
@ -----------------------------------------------------------------------------

  push {lr}
  @ === [關鍵] 先把速度拉到 30 MHz ===
   bl system_init_30mhz

  @ 1. 開啟 Clock (Switch Matrix, GPIO, UART0, IOCON)
  ldr r0, =SYSAHBCLKCTRL
  ldr r1, [r0]
  movs r2, #1
  lsls r2, r2, #6  @ Bit 6: GPIO
  orrs r1, r2
  movs r2, #1
  lsls r2, r2, #7  @ Bit 7: SWM
  orrs r1, r2
  movs r2, #1
  lsls r2, r2, #14 @ Bit 14: UART0
  orrs r1, r2
  @ Bit 18: IOCON (optional, usually on)
  str r1, [r0]

  @ 2. Reset UART0 and FRG0
  ldr r0, =PRESETCTRL
  ldr r1, [r0]

  movs r2, #1
  lsls r2, r2, #3  @ Bit 3: UART0 Reset
  bics r1, r2
  movs r2, #1
  lsls r2, r2, #14 @ Bit 14: FRG0 Reset
  bics r1, r2
  str r1, [r0]
  
  @ Release Reset
  ldr r1, [r0]
  movs r2, #1
  lsls r2, r2, #3
  orrs r1, r2
  movs r2, #1
  lsls r2, r2, #14
  orrs r1, r2
  str r1, [r0]

  @ 3. 設定 Switch Matrix (SWM) - Map UART0 to Pins
  @ U0_TXD -> P0.4 (Bits 7:0 = 0x04)
  @ U0_RXD -> P0.0 (Bits 15:8 = 0x00)
  @ U0_RTS/CTS Disabled (0xFF)
  @ Value = 0xFFFF0004
  ldr r0, =PINASSIGN0
  ldr r1, =0xFFFF0004
  str r1, [r0]

  @ 4. 設定 UART Clock Source -> FRG0 Clock
  ldr r0, =UARTCLKDIV
  @ [修正] 改為 2 (因為 MainClock 是 60MHz)
  @ 60MHz / 2 = 30MHz 輸入給 UART，符合我們原本的 FRG/BRG 計算
  movs r1, #2
  str r1, [r0]

  @ 5. 設定 FRG0 (Input: 12MHz IRC -> Output to UART)
  @ Target: 115200. With BRG=5, we need divide by ~1.085
  @ Mult = 22, Div = 255
  @ Select IRC (12MHz) for FRG input
  @@ ldr r0, =FRG0DIV
  @@ movs r1, #255
  @@ str r1, [r0]
  @@ 
  @@ ldr r0, =FRG0MULT
  @@ movs r1, #22
  @@ str r1, [r0]
  @ 6. 設定 USART0 Baud Rate Generator
  @@ ldr r0, =BRG
  @@ movs r1, #5      @ BRG value (Divide by 5+1=6)
  @@ str r1, [r0]

  @ 5. 設定波特率 115200 (For 30MHz Clock)
  @ Target: 115200
  @ Input: 30,000,000 Hz
  @ BRG = 15 (Divide by 16)
  @ FRG Mult = 4
  @ FRG0DIV = 255
  ldr r0, =FRG0DIV
  movs r1, #255
  str r1, [r0]
  
  @ FRG0MULT = 4 (修正後的參數)
  ldr r0, =FRG0MULT
  movs r1, #4
  str r1, [r0]
  
  @ BRG = 15 (修正後的參數)
  ldr r0, =BRG
  movs r1, #15
  str r1, [r0]
  
  @ ----------------------------------------------------------
  @ [NEW] 關鍵步驟：確保關閉 UART 中斷
  @ ----------------------------------------------------------
  ldr r0, =INTENCLR
  movs r1, #0
  mvns r1, r1
  str r1, [r0]  @ 寫入 0 到 Interrupt Enable Set 暫存器

  @ 7. Enable UART0 (8N1)
  ldr r0, =CFG
  movs r1, #1      @ Enable
  lsls r1, r1, #2  @ Data Length 8 bit
  movs r2, #1      @ No Parity, 1 Stop bit defaults
  orrs r1, r2
  str r1, [r0]

  @ 8. Ready to Tx/Rx
  ldr r0, =CTL
  movs r1, #0
  str r1, [r0] @ Clear control

  @ --------------------------------------------------------------------------
   @ 9. LED 初始化 (RGB on P0.15, P0.16, P0.17)
   @ --------------------------------------------------------------------------
   
   @ 設定 P0.15, P0.16, P0.17 為 Output
   @ Bit 15 | Bit 16 | Bit 17 = 0x8000 | 0x10000 | 0x20000 = 0x38000
   ldr r0, =DIR0
   ldr r1, [r0]
   ldr r2, =0x38000     @ 選擇 Pin 15, 16, 17
   orrs r1, r2          @ 設定為 1 (Output)
   str r1, [r0]

   @ 初始化狀態：綠燈亮 (Low)，紅藍滅 (High)
   @ 假設 LED 是 Active Low (共陽極)

   @ 步驟 A: 先把紅(15) 和 藍(17) 關掉 (設為 High)
   ldr r0, =SET0
   ldr r1, =0x28000     @ Bit 15 (0x8000) + Bit 17 (0x20000)
   str r1, [r0]

   @ 步驟 B: 把 綠(16) 打開 (設為 Low)
   ldr r0, =CLR0
   movs r1, #1
   lsls r1, r1, #16     @ Bit 16
   str r1, [r0]

  pop {pc}

.include "../common/terminalhooks.s"

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit"
serial_emit: @ ( c -- ) Emit one character
@ -----------------------------------------------------------------------------
   push {lr}

1: bl serial_qemit
   cmp tos, #0
   drop
   beq 1b

   uxtb tos, tos
   ldr r0, =TXDAT  @ Abschicken
   str tos, [r0]
   drop

   pop {pc}

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key"
serial_key: @ ( -- c ) Receive one character
@ -----------------------------------------------------------------------------
   push {lr}

1: bl serial_qkey
   cmp tos, #0
   drop
   beq 1b

   pushdatos          @ Platz auf dem Datenstack schaffen
   ldr tos, =RXDAT    @ Adresse für den Ankunftsregister
   ldr tos, [tos]     @ Einkommendes Zeichen abholen
   uxtb tos, tos      @ 8 Bits davon nehmen

   pop {pc}

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-emit?"
serial_qemit:  @ ( -- ? ) Ready to send a character ?
@ -----------------------------------------------------------------------------
   push {lr}
   bl pause

   pushdaconst 0

   ldr r0, =STAT
   movs r2, #4     @ Transmitter Ready

   ldr r1, [r0]
   ands r1, r2
   beq 1f
     mvns tos, tos
1: pop {pc}

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "serial-key?"
serial_qkey:  @ ( -- ? ) Is there a key press ?
@ -----------------------------------------------------------------------------
   push {lr}
   bl pause

   pushdaconst 0

   ldr r0, =STAT
   movs r2, #1      @ Receiver Ready

   ldr r1, [r0]
   ands r1, r2
   beq 1f
     mvns tos, tos
1: pop {pc}

  .ltorg @ Hier werden viele spezielle Hardwarestellenkonstanten gebraucht, schreibe sie gleich !
