
; system make enumeration for id's by it self. just 0, 1, 2, 3... 
Enumeration 
  #File ; same as #File = 0
EndEnumeration

; structure for instruments array
Structure insstr
  addres.u
  type.a
  mem.l ; memory image. but can be just value for samples = 4
EndStructure
Global Dim InstrumentsArray.insstr(0) ; global array

; system is didnt know exactly how many instruments it have
If ReadFile(#File, "..\banks\Instruments.bin") ; open file for read
  
  firstinstadd = ReadWord(#File) ; offset of first instrument
  
  instcount = firstinstadd / 2 ; because 2 bytes per each offset of instrument
  Debug "instruments count = " + Str(instcount)
  
  ; increase array
  ReDim InstrumentsArray(instcount) ; no check for empty file, because instrument bank cant be empty
                                    ; game can have empty envelopes and samples banks, 
                                    ; but instruments And sequencses always have some data
  
  ; save first one
  InstrumentsArray(1)\addres = firstinstadd
  
  ; save all another, if bank have more, than 1 instr
  If instcount > 1
    For inst = 2 To instcount
      addres = ReadWord(#File)
      InstrumentsArray(inst)\addres = addres
    Next 
  EndIf
  
  ; now pointer on first instrument. so start read from first to last one
  For inst = 1 To instcount
    type = ReadAsciiCharacter(#File)
    InstrumentsArray(inst)\type = type
    
    Select type
      Case 0 ; FM
        Debug Str(inst-1) + " FM " + Hex(inst-1)
        InstrumentsArray(inst)\mem = AllocateMemory(38) ; allocate 38 byte per instrument. FM have 38 bytes size
        If InstrumentsArray(inst)\mem
          ; if memory is allocated fine - read it
          ReadData(#File, InstrumentsArray(inst)\mem, 38)
          ; hm. if memory allocation will be broken - next data will be read incorrect :)))
        EndIf
      Case 1 ; DAC
        Debug Str(inst-1) + " DAC " + Hex(inst-1)
        InstrumentsArray(inst)\mem = ReadAsciiCharacter(#File) ; no memory creation. just store this value as is
        Debug InstrumentsArray(inst)\mem
      Case 2 ; PSG
        Debug Str(inst-1) + " PSG " + Hex(inst-1)
        InstrumentsArray(inst)\mem = AllocateMemory(6)   ; PSG instrument have 6 bytes
        If InstrumentsArray(inst)\mem
          ReadData(#File, InstrumentsArray(inst)\mem, 6)
        EndIf
      Case 3 ; Noise
        Debug Str(inst-1) + " Noise " + Hex(inst-1)      ; same as PSG - 6 bytes
        InstrumentsArray(inst)\mem = AllocateMemory(6)
        If InstrumentsArray(inst)\mem
          ReadData(#File, InstrumentsArray(inst)\mem, 6)
        EndIf
    EndSelect
    
  Next
  
  
Else
  Debug "no file ..\banks\Instruments.bin"
EndIf


;0 – FM
;1 – DAC
;2 – PSG
;3 – Noise

;{ 0. FM
;|??????tt| - type
;|????ovvv| - LFO on, LFO value      (register 22 LFO bits)
;|mm??????| - Channel 3 mode         (register 27 channel 3 bits)
;|??fffaaa| - Feedback, Algorithm    (raw register B0)
;|lraa?fff| - Left/Right, AMS, FMS   (raw register B4)
;4 operators: (4 times) in order 1,3,2,4
;|?dddmmmm| - Detune, Multiply       (raw register 30)
;|?ttttttt| - TLevel                 (raw register 40)
;|rr?aaaaa| - Rate Scale, Attack     (raw register 50)
;|a??ddddd| - AM, Decay              (raw register 60)
;|???sssss| - Sustain                (raw register 70)
;|ssssrrrr| - Sustain Level, Release (raw register 80)
;|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 4 (A6, A2)
;|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 3 (AC, A8)
;|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 1 (AD, A9)
;|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 2 (AE, AA)
;|????kkkk| - Operator On ("Key") - bit For each operator in 4,3,2,1 order
;|????????|
;}

;1. DAC
;|??????tt| - type
;|??????ss| - DAC Sample Rate (usual value is 4 - means take frequency from header of sample)

;2. PSG/NOISE (0 - loud, $F - silence)
;Offset	Notation	Range
;0	Type	2 Or 3
;1	Noise Data	[0,7]
;2	Attack Rate	[0,$FF]
;3	Sustain Level	[0,$F]
;4	Attack Level	[0,$F]
;5	Decay Rate	[0,$FF]
;6	Release Rate	[0,$FF]
