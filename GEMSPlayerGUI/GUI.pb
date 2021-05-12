
Enumeration
  #Window   ; = 0
  #Library  ; = 1
  #ListView ; = 2
  #SNDCFGFile
  #SNDSFXFile
  #SNDInstrumImage
  #SNDSampleImage
  #SNDModulationFile
  #SNDCodeFile
EndEnumeration

Structure gemsinstrumentsstr
  id$
  type.a
  dac.a
  memoryimage.l
EndStructure
Global Dim GEMSInstrumentsArray.gemsinstrumentsstr(0)

Structure gemssamplesstr
  id$
  flags.a
  skip.u
  first.u
  loop.u
  enddac.u
  memoryimage.l
  size.l
EndStructure
Global Dim GEMSSamplesArray.gemssamplesstr(0)

Structure gemsmodulsstr  
  id$
  memoryimage.l
  size.l
EndStructure
Global Dim GEMSodulationsArray.gemsmodulsstr(0)

Structure gemscodestr2
  command.u
  value.u
  specialcase.u
EndStructure
Structure gemscodestr
  ChannelMemSize.l
  Array Channel.gemscodestr2(0)
EndStructure
Global Dim CODEMainArray.gemscodestr(0)

Global *GEMSBankPatches, *GEMSBankSamples, *GEMSBankEnvelopes, *GEMSBankSequences

;{ bits operation. PB no functions for this. so we use macro
Macro SetBit(Var, Bit)
  Var | (Bit)
EndMacro 
Macro ClearBit(Var, Bit)
  Var & (~(Bit))
EndMacro 
Macro TestBit(Var, Bit)
  Bool(Var & (Bit))
EndMacro
Macro NumToBit(Num)
  (1<<(Num))
EndMacro
Macro GetBits(Var, StartPos, EndPos)
  ((Var>>(StartPos))&(NumToBit((EndPos)-(StartPos)+1)-1))
EndMacro
;}

; for 3 bytes write into memory
Procedure WriteBE24MEM(address.l, Value.l)
  first.a = Value >> 16
  secnd.a = Value >> 8
  third.a = Value  
  PokeA(address, third)
  PokeA(address + 1, secnd)
  PokeA(address + 2, first)
EndProcedure

Procedure.s ClearTextString(tmp$, type.a)
  
  tmp$ = StringField(tmp$, 1, ";")       ; del comments
  If tmp$
    tmp$ = ReplaceString(tmp$, Chr(9), "") ; tabs
    tmp$ = ReplaceString(tmp$, Chr(1), "") ; SOH
    tmp$ = ReplaceString(tmp$, Chr(2), "") ; 
    Select type
      Case 1
        tmp$ = StringField(tmp$, 2, "dc.l ")
        tmp$ = StringField(tmp$, 1, "|")       
      Case 2
        tmp$ = ReplaceString(tmp$, "dc.w", "")
      Case 3
        tmp$ = ReplaceString(tmp$, " ", "")    ; cut spaces
        tmp$ = ReplaceString(tmp$, "-", "equ(")
      Case 4
        tmp$ = StringField(tmp$, 2, "include")
      Case 5
        tmp$ = StringField(tmp$, 2, "incbin")
      Case 6
        tmp$ = StringField(tmp$, 2, "dc.b")
      Case 7 ; для surfaces.asm
        tmp$ = ReplaceString(tmp$, "dc.b", "")
        tmp$ = ReplaceString(tmp$, "dc.w", "")
        tmp$ = ReplaceString(tmp$, " ", "")
    EndSelect

    tmp$ = Trim(tmp$)
  EndIf
  
  ProcedureReturn tmp$
  
EndProcedure

; search
Procedure ListingFiles(dir$, ext$="", gadget.l=-1, id.a=0, tmppath$="") 

  lenext = Len(ext$)
  
  If ExamineDirectory(id, dir$, "*.*")  
    While NextDirectoryEntry(id)
      name$ = DirectoryEntryName(id)
      If DirectoryEntryType(id) = #PB_DirectoryEntry_File
        
        filename$ = DirectoryEntryName(id)
        
        If ext$
          
          If Right(filename$, lenext) = ext$
            
            If tmppath$
              ;Debug tmppath$ + "\" + filename$
              If gadget > -1
                AddGadgetItem(gadget, -1, tmppath$ + "\" + filename$)
              EndIf
            ;Else
            ;  ;Debug filename$
            ;  If gadget > -1
            ;    AddGadgetItem(gadget, -1, filename$)
            ;  EndIf              
            EndIf
            
          EndIf
          
        Else
        
          If tmppath$
            ;Debug tmppath$ + "\" + filename$
            If gadget > -1
              AddGadgetItem(gadget, -1, tmppath$ + "\" + filename$)
            EndIf
          Else
            ;Debug filename$
            If gadget > -1
              AddGadgetItem(gadget, -1, filename$)
            EndIf 
          EndIf
          
        EndIf
        
      Else ; means folder
        
        ; avoid "." and ".."
        name$ = DirectoryEntryName(id)
        If name$ <> "." And name$ <> ".."
          
          ; recurs
          If tmppath$
            tmppathsend$ = tmppath$ + "\" + name$
          Else
            tmppathsend$ = name$
          EndIf
          
          If ext$ = ""
            ;Debug tmppathsend$
          EndIf
          
          ListingFiles(dir$ + "\" + name$, ext$, gadget, id+1, tmppathsend$)
          
        EndIf         
        
      EndIf      
    Wend
    FinishDirectory(id)
  EndIf

EndProcedure

; read unpacked GEMS slot and unpack back into memory for play.
Procedure.b CODEReader(filename$)
  
  ret.b
    
  ;{ reset
  sz = ArraySize(GEMSInstrumentsArray())
  If sz
    For i = 1 To sz
      If GEMSInstrumentsArray(i)\memoryimage
        FreeMemory(GEMSInstrumentsArray(i)\memoryimage)
      EndIf
    Next
  EndIf
  ReDim GEMSInstrumentsArray(0)
  
  sz = ArraySize(GEMSSamplesArray())
  If sz
    For i = 1 To sz
      If GEMSSamplesArray(i)\memoryimage
        FreeMemory(GEMSSamplesArray(i)\memoryimage)
      EndIf
    Next
  EndIf
  ReDim GEMSSamplesArray(0)
  
  sz = ArraySize(GEMSodulationsArray())
  If sz
    For i = 1 To sz
      If GEMSodulationsArray(i)\memoryimage
        FreeMemory(GEMSodulationsArray(i)\memoryimage)
      EndIf
    Next
  EndIf
  ReDim GEMSodulationsArray(0)
  
  sz = ArraySize(CODEMainArray())
  If sz
    For i = 1 To sz
      ReDim CODEMainArray(i)\Channel(0)
    Next
  EndIf
  ReDim CODEMainArray(0)
  
  If *GEMSBankPatches
    FreeMemory(*GEMSBankPatches)
    *GEMSBankPatches = 0
  EndIf
  If *GEMSBankSamples
    FreeMemory(*GEMSBankSamples)
    *GEMSBankSamples = 0
  EndIf
  If *GEMSBankEnvelopes
    FreeMemory(*GEMSBankEnvelopes)
    *GEMSBankEnvelopes = 0
  EndIf
  If *GEMSBankSequences
    FreeMemory(*GEMSBankSequences)
    *GEMSBankSequences = 0
  EndIf
  ;}
  
  tmpfilepath$ = GetPathPart(filename$)
  
  If ReadFile(#SNDCFGFile, filename$)
    While Eof(#SNDCFGFile) = 0
      tmp$ = ReadString(#SNDCFGFile, #PB_Ascii)
      tmp$ = ClearTextString(tmp$, 0)
      If tmp$
        command$ = StringField(tmp$, 1, " ") ;: Debug command$
        tmp$     = ReplaceString(tmp$, ",", " ")
        id$      = StringField(tmp$, 2, " ") ;: Debug id$
        Select command$
            
            
          Case "code" ;{
            ; path to code file
            codefilepath$ = StringField(tmp$, 2, "'")
            If codefilepath$
              codefilepath$ = tmpfilepath$ + codefilepath$
            Else
              MessageRequester("error", "config file reading error. didnt see code file path.")
              ret = -1
              Break
            EndIf
            ;}
            
            
          Case "instrument" ;{
            instrfilepath$ = StringField(tmp$, 2, "'")
            If instrfilepath$
              ; path to instrument's config file
              instrfilepath$ = tmpfilepath$ + instrfilepath$
              
              ; read path file to instrument's file
              If ReadFile(#SNDSFXFile, instrfilepath$)
                tmp$ = ReadString(#SNDSFXFile, #PB_Ascii)
                tmp$ = ClearTextString(tmp$, 0)
                sz = ArraySize(GEMSInstrumentsArray())
                Select StringField(tmp$, 1, " ")
                    
                  Case "DAC" ;{
                    ; this is sample's instrument
                    sz + 1
                    ReDim GEMSInstrumentsArray(sz)
                    GEMSInstrumentsArray(sz)\type = 1
                    tmp = Val(StringField(tmp$, 2, " "))
                    If tmp = 0
                      tmp = 4
                    EndIf                      
                    GEMSInstrumentsArray(sz)\dac  = tmp
                    GEMSInstrumentsArray(sz)\id$  = id$
                    ;}
                    
                  Case "importraw" ;{
                    ; FM or PSG instrument
                    instrumentfilepath$ = StringField(tmp$, 2, "'") ;: Debug instrumentfilepath$
                    If instrumentfilepath$
                      instrumentfilepath$ = tmpfilepath$ + instrumentfilepath$
                      If ReadFile(#SNDInstrumImage, instrumentfilepath$)
                        length = Lof(#SNDInstrumImage)  
                        Select length
                          Case 7                            
                            sz + 1
                            ReDim GEMSInstrumentsArray(sz)
                            GEMSInstrumentsArray(sz)\id$ = id$ 
                            GEMSInstrumentsArray(sz)\type = 2
                            GEMSInstrumentsArray(sz)\memoryimage = AllocateMemory(7)
                            If GEMSInstrumentsArray(sz)\memoryimage
                              ReadData(#SNDInstrumImage, GEMSInstrumentsArray(sz)\memoryimage, 7)
                            Else
                              ret = -1
                              MessageRequester("error", "memory allocation error")
                              Break
                            EndIf
                          Case 39
                            sz + 1
                            ReDim GEMSInstrumentsArray(sz)
                            GEMSInstrumentsArray(sz)\id$ = id$ 
                            GEMSInstrumentsArray(sz)\type = 0
                            GEMSInstrumentsArray(sz)\memoryimage = AllocateMemory(39)
                            If GEMSInstrumentsArray(sz)\memoryimage
                              ReadData(#SNDInstrumImage, GEMSInstrumentsArray(sz)\memoryimage, 39)
                            Else
                              ret = -1
                              MessageRequester("error", "memory allocation error") 
                              Break
                            EndIf
                        EndSelect
                        CloseFile(#SNDInstrumImage)
                      EndIf
                    EndIf
                    ;}
                    
                EndSelect
                CloseFile(#SNDSFXFile)
              EndIf
            EndIf
            ;}
            
            
          Case "sample" ;{
            samplefilepath$ = StringField(tmp$, 2, "'") ;: Debug samplefilepath$
            If samplefilepath$
              ; path to file config of sample
              samplefilepath$ = tmpfilepath$ + samplefilepath$ 
              
              If ReadFile(#SNDSFXFile, samplefilepath$)
                sz = ArraySize(GEMSSamplesArray())
                sz + 1
                ReDim GEMSSamplesArray(sz)
                GEMSSamplesArray(sz)\id$ = id$
                
                While Eof(#SNDSFXFile) = 0
                  tmp$ = ReadString(#SNDSFXFile, #PB_Ascii)
                  tmp$ = ClearTextString(tmp$, 0)
                  
                  command$ = StringField(tmp$, 1, " ")
                  Select command$
                    Case "RAW"
                      ; path to sample's data file
                      ;RAW 'sample_13.snd'
                      sampledatafile$ = StringField(tmp$, 2, "'")
                      If sampledatafile$
                        sampledatafile$ = tmpfilepath$ + sampledatafile$
                        sampleslength = 0
                        If ReadFile(#SNDSampleImage, sampledatafile$)
                          sampleslength = Lof(#SNDSampleImage) ;: Debug sampleslength
                          GEMSSamplesArray(sz)\size = sampleslength
                          If sampleslength
                            GEMSSamplesArray(sz)\memoryimage = AllocateMemory(sampleslength)
                            If GEMSSamplesArray(sz)\memoryimage
                              ReadData(#SNDSampleImage, GEMSSamplesArray(sz)\memoryimage, sampleslength)
                            Else
                              ret = -1
                              MessageRequester("error", "memory allocation error")
                              CloseFile(#SNDSampleImage)
                              CloseFile(#SNDSFXFile)
                              Break 2
                            EndIf
                          EndIf
                          CloseFile(#SNDSampleImage)
                        EndIf                        
                      EndIf
                    Case "FLAGS"
                      tmp = Val(StringField(tmp$, 2, "=")) ;: Debug Hex(tmp)
                      GEMSSamplesArray(sz)\flags  = tmp
                    Case "FIRST"
                      ; recheck file size with this param
                      tmp = Val(StringField(tmp$, 2, "="))
                      If sampleslength = 0
                        tmp = 0
                      ElseIf sampleslength < tmp
                        tmp = sampleslength
                      EndIf
                      GEMSSamplesArray(sz)\first  = tmp
                    Case "SKIP"
                      tmp = Val(StringField(tmp$, 2, "="))
                      GEMSSamplesArray(sz)\skip   = tmp
                    Case "LOOP"
                      tmp = Val(StringField(tmp$, 2, "="))
                      GEMSSamplesArray(sz)\loop   = tmp
                    Case "END"
                      endlengthtest$ = StringField(tmp$, 2, "=")
                      If Len(endlengthtest$) > 5
                        endlengthtest$ = Left(endlengthtest$, 5)
                      EndIf
                      tmp = Val(endlengthtest$); : Debug tmp
                      GEMSSamplesArray(sz)\enddac = tmp
                  EndSelect
                Wend
                  
                CloseFile(#SNDSFXFile)
                  
              EndIf
            EndIf
            ;}
            
            
          Case "modulation" ;{
            modulfilepath$ = StringField(tmp$, 2, "'")
            If modulfilepath$
              modulfilepath$ = tmpfilepath$ + modulfilepath$ ;: Debug modulfilepath$
              
              If ReadFile(#SNDModulationFile, modulfilepath$)
                length = Lof(#SNDModulationFile)
                If length
                  sz = ArraySize(GEMSodulationsArray())
                  sz + 1
                  ReDim GEMSodulationsArray(sz)
                  GEMSodulationsArray(sz)\memoryimage = AllocateMemory(length)
                  GEMSodulationsArray(sz)\size = length
                  GEMSodulationsArray(sz)\id$ = id$
                  If GEMSodulationsArray(sz)\memoryimage
                    ReadData(#SNDModulationFile, GEMSodulationsArray(sz)\memoryimage, length)
                    ;Debug "envelopes count " + Str(sz)
                  Else
                    ret = -1
                    MessageRequester("error", "memory allocation error")
                    Break
                  EndIf
                EndIf
                CloseFile(#SNDModulationFile)
              EndIf
              GEMSodulationsArray()
              
            EndIf
            ;}
            
            
        EndSelect
      EndIf
    Wend
    CloseFile(#SNDCFGFile)
    
    If ret = 0
      ; no error and i have all arrays with data
      
      ; read code txt file
      If ReadFile(#SNDCodeFile, codefilepath$)
        While Eof(#SNDCodeFile) = 0
          tmp$ = ReadString(#SNDCodeFile, #PB_Ascii)
          tmp$ = ClearTextString(tmp$, 0)
          If tmp$
            
            command$ = StringField(tmp$, 1, " ")
            param$   = StringField(tmp$, 2, " ")
            
            ;- Read code
            Select command$
              Case "dc.b"
                ; all tracks count
                gemstracks = Val(param$)
                If gemstracks = 0
                  ; empty file
                  ret = 0
                  Break
                Else
                  ReDim CODEMainArray(gemstracks)
                  ;SetGadgetAttribute(#CodeLoadProg, #PB_ProgressBar_Maximum, gemstracks)
                EndIf
                
              Case "note"
                ;$0-$5F: note
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                If FindString(param$, "sample")
                  note = 0 ;: Debug "have a note " + param$
                  For i = 1 To ArraySize(GEMSSamplesArray())
                    If param$ = GEMSSamplesArray(i)\id$
                      note = i - 1
                      Break
                    EndIf
                  Next
                  CODEMainArray(tracknum)\Channel(tracksize)\command = $30 + note
                Else
                  CODEMainArray(tracknum)\Channel(tracksize)\command = Val(param$)
                EndIf
                
              Case "duration"
                ;$80-BF: duration
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                param = Val(param$)
                Select param
                  Case 0 To 63
                    tracksize + 1
                    ReDim CODEMainArray(tracknum)\Channel(tracksize)
                    CODEMainArray(tracknum)\Channel(tracksize)\command = $80 + param
                  Default
                    If param > 4095
                      param = 4095
                    EndIf
                    first = GetBits(param, 0, 5)
                    secnd = GetBits(param, 6, 11)
                    
                    tracksize + 1
                    ReDim CODEMainArray(tracknum)\Channel(tracksize)
                    CODEMainArray(tracknum)\Channel(tracksize)\command = $80 + secnd
                    
                    CODEMainArray(tracknum)\ChannelMemSize + 1
                    tracksize + 1
                    ReDim CODEMainArray(tracknum)\Channel(tracksize)
                    CODEMainArray(tracknum)\Channel(tracksize)\command = $80 + first
                EndSelect
                
              Case "delay"
                ;$C0-FF: delay
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                param = Val(param$)
                Select param
                  Case 0 To 63
                    tracksize + 1
                    ReDim CODEMainArray(tracknum)\Channel(tracksize)
                    CODEMainArray(tracknum)\Channel(tracksize)\command = $C0 + param
                  Default
                    If param > 4095
                      param = 4095
                    EndIf
                    first = GetBits(param, 0, 5)
                    secnd = GetBits(param, 6, 11)
                    
                    tracksize + 1
                    ReDim CODEMainArray(tracknum)\Channel(tracksize)
                    CODEMainArray(tracknum)\Channel(tracksize)\command = $C0 + secnd
                    
                    CODEMainArray(tracknum)\ChannelMemSize + 1
                    tracksize + 1
                    ReDim CODEMainArray(tracknum)\Channel(tracksize)
                    CODEMainArray(tracknum)\Channel(tracksize)\command = $C0 + first
                EndSelect
                
              Case "eos"
                ;$60 end track 
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $60
                ;SetGadgetState(#CodeLoadProg, tracknum)
                
              Case "patch"
                ;$61 set instrument
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $61
                patch = 0
                For i = 1 To ArraySize(GEMSInstrumentsArray())
                  If param$ = GEMSInstrumentsArray(i)\id$
                    patch = i - 1
                    Break
                  EndIf
                Next
                CODEMainArray(tracknum)\Channel(tracksize)\value = patch
                
              Case "modulation"
                ;$62 set envelope 
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $62
                modulation = 0
                sz = ArraySize(GEMSodulationsArray())
                If sz
                  ;Debug "param$ = " + param$
                  For i = 1 To ArraySize(GEMSodulationsArray())
                    ;Debug GEMSodulationsArray(i)\id$
                    If param$ = GEMSodulationsArray(i)\id$
                      modulation = i - 1
                      ;Debug "param$ = " + param$ + "; mod = " + Str(modulation)
                      Break
                    EndIf
                  Next
                EndIf
                CODEMainArray(tracknum)\Channel(tracksize)\value = modulation
                
              Case "nop"
                ;$63 NOP.
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $63
                
              Case "loop"
                ;$64 loop + 1 byte count how many times need loop 
                ; set $7F for infinity
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1                
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $64
                CODEMainArray(tracknum)\Channel(tracksize)\value = Val(param$)              
                
              Case "loopend"
                ;$65 end of loop
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $65
                
              Case "retrigger"
                ;$66 relaunch modulation i think. every new note will have same envelope, as it was set before
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $66
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                
              Case "sustain"
                ;$67 sustain mode. 1 byte - turn on or off
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $67
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                
              Case "tempo"
                ;$68 bpm. from 40 up to max as 295 (?)
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $68
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$) - 40
                
              Case "mute"
                ;$69 Mute. 1 byte %???TСCCC.
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $69
                param = Val(param$) << 4 + tracknum
                CODEMainArray(tracknum)\Channel(tracksize)\value   = param
                
              Case "priority"
                ;$6A 0 – lower, $7F – higher.
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $6A
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                
              Case "pitch"
                ;$6C set pitch. 2 bytes .w type
                CODEMainArray(tracknum)\ChannelMemSize + 3
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $6C
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                
              Case "sfx"
                ;$6D "Set song to use SFX timebase." - 150 bpm
                CODEMainArray(tracknum)\ChannelMemSize + 1
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $6D
                
              Case "samplerate"
                ;$6E set dac samplerate.
                CODEMainArray(tracknum)\ChannelMemSize + 2
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $6E
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                
              Case "mastervolume"
                ;$72 all's volume comand. (samples and PSG not obey that)
                CODEMainArray(tracknum)\ChannelMemSize + 3
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $72
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                CODEMainArray(tracknum)\Channel(tracksize)\specialcase = 4
                
              Case "volume"
                ;$72 volume per 1 track. (samples and PSG not obey that)
                CODEMainArray(tracknum)\ChannelMemSize + 3
                
                tracksize + 1
                ReDim CODEMainArray(tracknum)\Channel(tracksize)
                CODEMainArray(tracknum)\Channel(tracksize)\command = $72
                CODEMainArray(tracknum)\Channel(tracksize)\value   = Val(param$)
                CODEMainArray(tracknum)\Channel(tracksize)\specialcase = 5
                
                
              Default
                If FindString(tmp$, ":")
                  If StringField(tmp$, 1, "_") = "channel"
                    ; treack header
                    tracknum + 1
                  
                    gemstracks - 1
                    If gemstracks < 0
                      ret = -1
                      MessageRequester("error", "code file context error. too many tracks.")
                      Break
                    Else
                      tracksize = ArraySize(CODEMainArray(tracknum)\Channel())                    
                    EndIf
                  EndIf
                EndIf
            EndSelect
            
          EndIf
        Wend        
        CloseFile(#SNDCodeFile)
        
        If ret = 0 
          If gemstracks = 0
            ; everything fine
            
            ;{ create envelope bank
               ;- mod bank
               ; full size
               modsize = 0
               sz = ArraySize(GEMSodulationsArray())
               If sz
                 For i = 1 To sz
                   modsize + GEMSodulationsArray(i)\size + 2
                 Next
                 *GEMSBankEnvelopes = AllocateMemory(modsize)
                 If *GEMSBankEnvelopes
                   ; start write modulations
                   
                   ; first is = count of mods * 2
                   offset = sz * 2
                   For i = 1 To sz
                     PokeU(*GEMSBankEnvelopes + ((i - 1) * 2), offset)
                     
                     CopyMemory(GEMSodulationsArray(i)\memoryimage, *GEMSBankEnvelopes + offset, GEMSodulationsArray(i)\size)
                     
                     offset + GEMSodulationsArray(i)\size
                   Next
                 Else
                   ret = -1
                   MessageRequester("error", "memory allocation error")
                 EndIf
                 
               EndIf
               
               
            ;}
            
            ;{ creating samples bank 
               ;- samp bank
               ; full size 
               sampsize = 0
               sz = ArraySize(GEMSSamplesArray())
               If sz And ret = 0
                 For i = 1 To sz
                   sampsize + GEMSSamplesArray(i)\size + 12 ; sample size it self + 12 b per header
                 Next
                 *GEMSBankSamples = AllocateMemory(sampsize)
                 If *GEMSBankSamples
                   ; start write
                   
                   ; first offset - just whole count * 12 - miss all headers
                   offset = sz * 12
                   
                   For i = 1 To sz
                     startmemadd = *GEMSBankSamples + ((i - 1) * 12)
                     ; flag
                     PokeA(startmemadd, GEMSSamplesArray(i)\flags)
                     ; offset
                     WriteBE24MEM(startmemadd + 1, offset)
                     ; SKIP
                     PokeU(startmemadd + 4, GEMSSamplesArray(i)\skip)
                     ;FIRST =$0B50
                     PokeU(startmemadd + 6, GEMSSamplesArray(i)\first)
                     ;LOOP  =$0000
                     PokeU(startmemadd + 8, GEMSSamplesArray(i)\loop)
                     ;End 
                     PokeU(startmemadd + 10, GEMSSamplesArray(i)\enddac)

                     If GEMSSamplesArray(i)\first
                       CopyMemory(GEMSSamplesArray(i)\memoryimage, *GEMSBankSamples + offset, GEMSSamplesArray(i)\size)
                     EndIf
                     
                     offset + GEMSSamplesArray(i)\size
                   Next
                   
                 Else
                   ret = -1
                   MessageRequester("error", "memory allocation error")
                 EndIf
                 
                 ;If CreateFile(0, "D:\samptest.bin")
                 ;  WriteData(0, *GEMSBankSamples, sampsize)
                 ;  CloseFile(0)
                 ;EndIf
                 
                 
               EndIf
               
            ;}   
               
            ;{ creating instruments bank
               
               ; full size 
               instsize = 0
               sz = ArraySize(GEMSInstrumentsArray())
               If sz And ret = 0
                 For i = 1 To sz
                   Select GEMSInstrumentsArray(i)\type
                     Case 0
                       instsize + 39 + 2
                     Case 1
                       instsize + 4
                     Case 2
                       instsize + 9                      
                   EndSelect
                 Next
                 *GEMSBankPatches = AllocateMemory(instsize)
                 If *GEMSBankPatches
                   ; start write instruments
                   
                   ; first offset is = instruments count * 2
                   offset = sz * 2 ;: Debug "instr count " + Str(sz)
                   For i = 1 To sz
                     PokeU(*GEMSBankPatches + ((i - 1) * 2), offset)
                     
                     Select GEMSInstrumentsArray(i)\type
                       Case 0 ; FM
                         size = 39
                         CopyMemory(GEMSInstrumentsArray(i)\memoryimage, *GEMSBankPatches + offset, size)
                         
                       Case 1 ; DAC
                         size = 2
                         PokeA(*GEMSBankPatches + offset, 1)
                         PokeA(*GEMSBankPatches + offset + 1, GEMSInstrumentsArray(i)\dac)
                         
                       Case 2 ; PSG
                         size = 7
                         CopyMemory(GEMSInstrumentsArray(i)\memoryimage, *GEMSBankPatches + offset, size)
                         
                     EndSelect

                     offset + size
                   Next
                 Else
                   ret = -1
                   MessageRequester("error", "memory allocation error")
                 EndIf
                 
                 ;If CreateFile(0, "D:\insttest.bin")
                 ;  WriteData(0, *GEMSBankPatches, instsize)
                 ;  CloseFile(0)
                 ;EndIf
                 
               EndIf

            ;}
               
            ;{ creating sequences bank 
               
               If ret = 0
                 songsize = 0
                 sz = ArraySize(CODEMainArray())
                 If sz
                   songsize = 3 + (sz * 3)
                   For i = 1 To sz
                     songsize + CODEMainArray(i)\ChannelMemSize
                   Next
                   ;Debug "songsize = " + Str(songsize)
                   *GEMSBankSequences = AllocateMemory(songsize) 
                   If *GEMSBankSequences
                     ; + 2
                     PokeU(*GEMSBankSequences, 2)
                     PokeA(*GEMSBankSequences + 2, sz)
                     offset = 3 + (sz * 3) ; offset to first channel
                     For i = 1 To sz
                       WriteBE24MEM(*GEMSBankSequences + 3 + ((i - 1) * 3), offset)
                       
                       startchannelmem = *GEMSBankSequences + offset
                       
                       For n = 1 To ArraySize(CODEMainArray(i)\Channel())
                         Select CODEMainArray(i)\Channel(n)\command
                           Case 0 To $5F ;$0-$5F: note
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                           Case $80 To $BF ;$80-BF: duration
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                           Case $C0 To $FF ; $C0-FF
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                           Case $60 ; $60 eos
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                           Case $61, $62, $64, $66, $67, $68, $69, $6A, $6E 
                             ; patch 2 b, modul, loop, retrigger, sust, temp
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\value)
                             startchannelmem + 1
                           Case $63, $65, $6D ; nop, endloop, sfx
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                           Case $6C ; pitch - 3 b
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                             PokeU(startchannelmem, CODEMainArray(i)\Channel(n)\value)
                             startchannelmem + 2
                           Case $72 ; macro
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\command)
                             startchannelmem + 1
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\specialcase)
                             startchannelmem + 1
                             PokeA(startchannelmem, CODEMainArray(i)\Channel(n)\value)
                             startchannelmem + 1
                             
                         EndSelect
                       Next
                       
                       offset + CODEMainArray(i)\ChannelMemSize
                       
                     Next
                     
                     ret = 1
                     
                     ;If CreateFile(0, "D:\seqtest.bin")
                     ;  WriteData(0, *GEMSBankSequences, songsize)
                     ;  CloseFile(0)
                     ;EndIf
                     
                   Else
                     ret = -1
                     MessageRequester("error", "memory allocation error")
                   EndIf
                   
                 Else
                   ret = -1
                 EndIf
               EndIf
               
            ;}   
               
          Else
            ret = -1
            MessageRequester("error", "code file context error. header have bigger tracks, as it is in a file.")
          EndIf
        EndIf
        
      Else
        ret =-1
        MessageRequester("error", "main code file reading error")
      EndIf
      
      
    EndIf    
    
  EndIf
  
  ;If damp = 1
  ;  If songsize
  ;  If CreateFile(0, "D:\1seqtest.bin")
  ;    WriteData(0, *GEMSBankSequences, songsize)
  ;    CloseFile(0)
  ;  EndIf
  ;  EndIf
  ;  If instsize
  ;  If CreateFile(0, "D:\2insttest.bin")
  ;    WriteData(0, *GEMSBankPatches, instsize)
  ;    CloseFile(0)
  ;  EndIf
  ;  EndIf
  ;  If sampsize
  ; If CreateFile(0, "D:\3samptest.bin")
  ;    WriteData(0, *GEMSBankSamples, sampsize)
  ;    CloseFile(0)
  ;  EndIf
  ;  EndIf
  ;  If modsize
  ;  If CreateFile(0, "D:\4modtest.bin")
  ;    WriteData(0, *GEMSBankEnvelopes, modsize)
  ;    CloseFile(0)
  ;  EndIf
  ;  EndIf
  ;EndIf
  
  ProcedureReturn ret
  
EndProcedure



; load dll and functions from it
If OpenLibrary(#Library, "GEMSPlayLibrary.dll")  
  
  ;                            *memory - pointers to memory image of banks
  PrototypeC.i gemsplay_initprt(patches.l, envelopes.l, sequences.l, samples.l)
  PrototypeC gemsplay_cleanupprt()
  PrototypeC gemsplay_stopprt()
  PrototypeC gemsplay_pauseprt()
  PrototypeC gemsplay_playprt()
  PrototypeC gemsplay_set_gems28modeprt(enable.i)
  
  Global GEMSInit.gemsplay_initprt = GetFunction(#Library, "gemsplay_init")
  Global GEMSCleanup.gemsplay_cleanupprt = GetFunction(#Library, "gemsplay_cleanup")  
  Global GEMSStop.gemsplay_stopprt = GetFunction(#Library, "gemsplay_stop")
  Global GEMSPause.gemsplay_pauseprt = GetFunction(#Library, "gemsplay_pause")
  Global GEMSPlay.gemsplay_playprt = GetFunction(#Library, "gemsplay_play")
  Global GEMSgemsplay_set_gems28mode.gemsplay_set_gems28modeprt = GetFunction(#Library, "gemsplay_set_gems28mode")
  

  ; main window of programm
  If OpenWindow(#Window, 100, 100, 120, 200, "GUI")
    
    ListViewGadget(#ListView, 10, 10, 100, 180)
    
    ; when ends of window paint...
    ; call search and fill list
    ListingFiles("..\banks\unpackedbanks\", ".cfg", #ListView)
  
    Repeat ; events monitoring
      Select WaitWindowEvent()

        Case #PB_Event_Gadget

          Select EventGadget()
           
            Case #ListView
              If EventType() = #PB_EventType_LeftDoubleClick
                ; if was double click on a list
                
                ; check selected one
                SelectedItem$ = GetGadgetText(#ListView) ; text's value, mean path to selected folder
                
                If oldSelectedItem$ = SelectedItem$
                  ; already load
                  
                  If *GEMSBankPatches And *GEMSBankSequences
                    ; check existing memory images of 2 banks. 
                    ; 2 banks is always - patches and sequences. 
                    ; 1 samples And 1 envelope can be empty.
                    
                    ; play from lib
                    GEMSPlay()
                  EndIf
                  
                Else
                  
                  GEMSStop() ; just in case
                  Delay(5)
                  GEMSCleanup()
                  Delay(5)
                  
                  ; load new
                  If CODEReader("..\banks\unpackedbanks\" + SelectedItem$) = 1
                    ; if everythig loading is fine
                    
                    ;Debug "fine"
                    
                    oldSelectedItem$ = SelectedItem$
                    ; initialisation of all banks
                    If GEMSInit(*GEMSBankPatches, *GEMSBankEnvelopes, *GEMSBankSequences, *GEMSBankSamples)
                      GEMSgemsplay_set_gems28mode(1) ; dont remember sure. probably 3 bytes variant.
                                                     ; but some GEMS game use 2 bytes. no matter for play
                      ; play
                      GEMSPlay()
                    EndIf
                  Else
                    ; something is wrong.
                    
                    ;Debug "not fine"
                    
                    ; clean data
                    oldSelectedItem$ = ""
                    If *GEMSBankPatches
                      FreeMemory(*GEMSBankPatches)
                      *GEMSBankPatches = 0
                    EndIf
                    If *GEMSBankEnvelopes 
                      FreeMemory(*GEMSBankEnvelopes)
                      *GEMSBankEnvelopes = 0
                    EndIf
                    If *GEMSBankSequences 
                      FreeMemory(*GEMSBankSequences)
                      *GEMSBankSequences = 0
                    EndIf
                    If *GEMSBankSamples
                      FreeMemory(*GEMSBankSamples)
                      *GEMSBankSamples = 0
                    EndIf 
                    
                    ; and no play
                    
                    
                    ; that Clean data part - FreeMemory - is not very well and have very rare crash.
                    ; later i am make static big memory area and write everytime in that place and play from it
                    ; every time same addresses.
                    
                  EndIf
                  
                EndIf
                

              EndIf

          EndSelect

        Case #PB_Event_CloseWindow
          qiut = 1
          GEMSStop() ; just in case
          Delay(5)
          GEMSCleanup()
          Delay(5)
   
      EndSelect
    Until qiut = 1

  EndIf
  
  CloseLibrary(#Library)
  
EndIf
End
