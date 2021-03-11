
; system make enumeration for id's by it self. just 0, 1, 2, 3... 
Enumeration 
  #File ; same as #File = 0
EndEnumeration

; complex structure inside of structure for modilation\envelopes array
Structure modulationsstr2
  counter.a
  value.w
EndStructure
Structure modulationsstr
  startpitch.w
  Array Tik.modulationsstr2(0)
EndStructure

Global Dim Modulations.modulationsstr(0) ; create array with modulations

; system is didnt know exactly how many envelopes it have
If ReadFile(#File, "..\banks\Envelopes.bin") ; open file for read
  
  If Lof(#File) > 0
    ; if file is not empty. it can be empty, where sound of game not use envelope at all
  
    ; get offset first of envelope or modulation
    offsetenv.u = ReadUnicodeCharacter(#File) ; 2 bytes, unicode
    
    envcount = offsetenv / 2 : Debug "envelopes count " + Str(envcount)
    ; offsetenv / 2 = because 2 bytes per offset for each envelopes
    
    ReDim Modulations(envcount) ; redim main array for all envelopes
  
    FileSeek(#File, offsetenv)  ; jump pointer of reading file into first envelopes
    
    num.a = 0 ; temporaly counter
    Repeat 
      startpitch.w = ReadWord(#File) ; first 2 bytes it starting pitch
      Modulations(num)\startpitch = startpitch
 
      Repeat    
        counter.a = ReadAsciiCharacter(#File) : Debug "counter = " + Str(counter) + " ; arr num = " + Str(num)
        If counter
          ; if counter positive. else if 0 - means end of modulation
          
          value.w = ReadWord(#File)
          
          sz = ArraySize(Modulations(num)\Tik()) + 1 ; get current internal array size and +1
          ReDim Modulations(num)\Tik(sz) ; encrease internal array by redim array
          ; write data for new item of internal array
          Modulations(num)\Tik(sz)\counter = counter
          Modulations(num)\Tik(sz)\value   = value
          ; counter and value means how many times - counter - to make some operation + or - value
        EndIf
      Until counter = 0
      num + 1
    Until num = envcount
    
  
  
  EndIf
  
  CloseFile(#File)
    
Else
  Debug "no file ..\banks\Samples.bin"
EndIf
