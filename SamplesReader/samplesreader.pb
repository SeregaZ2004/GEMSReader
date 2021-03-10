
; system make enumeration for id's by it self. just 0, 1, 2, 3... 
Enumeration 
  #File ; same as #File = 0
EndEnumeration

; structure for sample array
Structure smpstr
  freqflag.a
  offset.l
  skip.u
  size.u
  loop.u
  endfile.u
  sampledata.l ; memory image
EndStructure
Global Dim Samples.smpstr(0) ; create global array for samples with structure

; system is didnt know exactly how many samples it have
If ReadFile(#File, "..\banks\Samples.bin") ; open file for read
  
  ; this code will not work with a case, where first slot of bank is empty.
  ; for that case need to remake code for some kind of repeat and read per 12 bytes until first offset will found
  
  If Lof(#File) > 0
    ; if file is not empty. it can be empty, where sound of game not use samples at all
  
    freqflag.a = ReadAsciiCharacter(#File) ; read first byte. 
                                           ; it should be 45$ for Dune. 
                                           ; but can be empty for other game
  
    offset1.a  = ReadAsciiCharacter(#File) ; no need to trace read point - it auto shift by this ReadAsciiCharacter
    offset2.a  = ReadAsciiCharacter(#File)
    offset3.a  = ReadAsciiCharacter(#File)
  
    ; PB no have read 3 bytes value, so we need to build that value by manualy
    offset.l  = offset3 << 16 + offset2 << 8 + offset1
  
    samplescount.a = offset / 12 ; 12 bytes header for one sample. 
                                 ; bank have at first part all headers near each other
                                 ; then samples data them selves. same near each other
  
  
    If samplescount
      ; bank can be empty. 0 byte. for a game, that no have samples that is why "If"
    
      ReDim Samples(samplescount) ; resize array from 0 to what we need
    
      ; write data of first sample
      Samples(1)\freqflag = freqflag
      Samples(1)\offset   = offset
  
      Samples(1)\skip     = ReadUnicodeCharacter(#File)
      Samples(1)\size     = ReadUnicodeCharacter(#File) : Debug Hex(Samples(1)\size)
      Samples(1)\loop     = ReadUnicodeCharacter(#File)
      Samples(1)\endfile  = ReadUnicodeCharacter(#File)
    
      If samplescount > 1
        ; if bank have bigger than 1 sample
      
        For i = 2 To samplescount
          ; frequency flag
          Samples(i)\freqflag  = ReadAsciiCharacter(#File)
          ; offset
          offset1 = ReadAsciiCharacter(#File)
          offset2 = ReadAsciiCharacter(#File)
          offset3 = ReadAsciiCharacter(#File)
          offset = smeshenie3 << 16 + smeshenie2 << 8 + smeshenie1
    
          Samples(i)\offset = offset
        
          ; another params. per 2 bytes for each
          Samples(i)\skip      = ReadUnicodeCharacter(#File)
          Samples(i)\size      = ReadUnicodeCharacter(#File) : Debug Hex(Samples(i)\size)
          Samples(i)\loop      = ReadUnicodeCharacter(#File)
          Samples(i)\endfile   = ReadUnicodeCharacter(#File)
        Next 
      
      EndIf
    
      ; read samples data itself
      For i = 1 To samplescount
    
        If Samples(i)\size
          ; if size is exists...
        
          Samples(i)\sampledata = AllocateMemory(Samples(i)\size) ; trying allocate memory
    
          If Samples(i)\sampledata
            ; if allocate is fine - read data into it
            ReadData(#File, Samples(i)\sampledata, Samples(i)\size)
            ; that is no head data. so it cant play yet. playing is later...
          EndIf
        EndIf
      Next
    
    EndIf
  
  EndIf
  
  CloseFile(#File)
  
  
Else
  Debug "no file ..\banks\Samples.bin"
EndIf

