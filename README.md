# GEMSReader
this is some kind of clone of r57shell's combaine, with explanations and examples, where and what data lays inside GEMS banks.

as you probably know GEMS usual have 4 banks, that is some kind of arhive, or folders with specific data:
1. Samples
2. Modulations
3. Patches\Instruments
4. Sequences

so game use this banks some kind of like this:
game want to play song num 7.
system start read sequences bank and find that 7 song (06 num. starts from 00).
first is pointer to melodie\sfx (2 bytes)
then it goes to that location and read 1 byte - tracks count for this song. (can be up to 16 tracks)
for example it was 1 track. next 2 or 3 bytes (depends driver version or modifications) is pointer to track data.
system jump to that track data and start play. it is some pack of commands - delay, duration, instrument settings, note, modulation settings, volume, prioritet and etc.
so when system find unstruction "set instrument num 3" - it start read Patches\Instruments bank. find that num 3 (02, because starts from 00), load it, 
according type of instrument (it can be FM, Sample, PSG and Noice).

copy from electropage.ru
type 0 - FM
|??????tt| - type
|????ovvv| - LFO on, LFO value      (register 22 LFO bits)
|mm??????| - Channel 3 mode         (register 27 channel 3 bits)
|??fffaaa| - Feedback, Algorithm    (raw register B0)
|lraa?fff| - Left/Right, AMS, FMS   (raw register B4)
4 operators: (4 times) in order 1,3,2,4
|?dddmmmm| - Detune, Multiply       (raw register 30)
|?ttttttt| - TLevel                 (raw register 40)
|rr?aaaaa| - Rate Scale, Attack     (raw register 50)
|a??ddddd| - AM, Decay              (raw register 60)
|???sssss| - Sustain                (raw register 70)
|ssssrrrr| - Sustain Level, Release (raw register 80)

|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 4 (A6, A2)
|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 3 (AC, A8)
|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 1 (AD, A9)
|??ffffffffffffff| - 14-bit frequency channel 3 mode operator 2 (AE, AA)

|????kkkk| - Operator On ("Key") - bit for each operator in 4,3,2,1 order
|????????|


type 1 DAC (Samples)
|??????tt| - type
|??????ss| - DAC Sample Rate (usual 4 - means get value of frequency from header of sample)


type 2 PSG/NOISE (0 - loud, $F - silence)
Offset	Notation	Range
0	Type	2 or 3
1	Noise Data	[0,7] (not exactly 0 up to 7, but read only 3 bits. i am get before some value - higher than 7)
2	Attack Rate	[0,$FF]
3	Sustain Level	[0,$F]
4	Attack Level	[0,$F]
5	Decay Rate	[0,$FF]
6	Release Rate	[0,$FF]


samples playing is sets by setting some instrument's number, that is set as sample playing. for example 10 num. so system starts play not a note, but sample from Samples bank.
for example it was 3 sample (00 sample it is 30$ value. so 3 sample num from bank - it is 32$ in a hex)
so read samples banks and get this header data:
45 5C 04 00 00 00 2E 0E  00 00 00 00 
where is:

45 - first byte flag of frequency and 8 or 4 bit setting, enabling loop and something third one effect. dont remember.
where 4x is flag for frequency 5$ to A$
10.4/8.7/7.3/6.5/5.8/5.2 - frequency FLAGS
 5  /6  /7  /8  /9  /A
 
three bytes:
5C 04 00
pointer to sample data in a samples bank (some games can have it as 2 bytes).

per 2 bytes:
00 00  2E 0E  00 00  00 00
skip, first, loop, end - parametres. they can be empty and size of sample is - "first" 2E 0E - 3630 bytes for this case.
this loop and skip and end params can be used for echo effects - not exactly echo, but repeat some part of sample for save memory space in a room.
size of sample, flag and every another header params - can be empty. when first slot in a sample bank is empty.


when song is playing and it have some modulation command - it start read modulation bank and do some instruction, that modulation have.
2 bytes = pointer to modulation\envelope data
when data starts: 
first 2 bytes - starting pitch, .w type
then repeatable 3 bytes. where is 
1 byte is counter (how many times instruction will apply) 
2 bytes - value of .w type, that will + or - to main value.
it work some kind of that: note value have 01 00 value. it have modulation with 0 starting pitch, 5 counter and 00 05 value. then modulation is ends.
so start play with 01 00 value. then count 1 delay timer, 01 00 + 00 05 = note changes to 01 05, then wait 1 delay, 01 05 + 00 05 = 01 10 (0A actualy, but ok). and repeat that + 00 05 by 5 times, until counter becomes to 0.


code with examples with comments will be later for read all this banks.


resume:
so - it is a little dificult to work with compiled banks as is - i mean all 4 banks, when you need edit only 1 melodie or sfx. i think it need to be unpacked, as r57shell's combaine do. it unpack this banks into GEMS slots. every folder 000 up to 255 probably - it is one slot of melody or sfx. it have melodie file itself and copy of instruments and samples and modulations. they are as independent files, not as bank. any of them can be edit and then it can be compiled back into banks (it kicks any instruments, that is already inside a bank - so no any duplicate happen), and then that banks inserted into game.

with Deflemask 2 GEMS all of this procedures is done. but my problem is - counting effects of Deflemask. 01 xx, 02 xx, 03 xx, E1 xx, E2 xx... my trying of convert that is fail. my brain is explow, when i try to image how to correct count that frequency changing and transfer it into GEMS modulations. next - Deflemask into GEMS is much easy, than GEMS 2 Deflemask. problem is - Deflemask have same limit for tracks. for example 10 channels - 2 patterns per 64 rows = 128 rows at all. GEMS can have variable of lengs of tracks for melodie. even worse - every track for GEMS can have his own loop markers. it is save memory, but is will be dificult for transfer. another problem is 16 tracks for GEMS - but Defle have only 10. same with FM and PSG and Samples case - Defle have 6th channel for Samples, 7-8-9 for PSG and 10 for noice. GEMS can have any case with any of 16 tracks. another problem is Samples format - Defle have high quality. GEMS can have 10.4khz as max (depends game. old GEMS drivers cant play 10.4 only 6 or 7k). now i didnt convert samples at all, but it can be done with bass.dll. i use it for reencode samples for another case.
