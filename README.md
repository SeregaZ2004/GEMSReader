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
