we need a banks. i get it from Dune game and it have samples and envelopes. some game can have no samples or no envelopes, or no both. but for our tests need to full house.

and yes. Dune have 2 sets of banks. first one is intro melody. second one all battle melodies and sfx and etc. we choice second one, where is many songs and sfx.



for test what it is - start GEMSPlay.bat file, to load banks into player and press enter. will play a song (for Windows)


i change banks for new one - from romhacks. original was a little wrong :) not a full instruments bank was taking from rom game.



for unpack GEMS banks - you need to start game_gems_split.bat. then go to unpackedbanks folder to see every slot of GEMS sequence's bank. every one will have his copy of instruments and envelopes and samples.

files:
.cfg - file, with all enumeration all data, that have this song. text file.
.code - song's command. text file.
.sfx - sample's header. text file.
.snd - sample's data. bin file.
.ins - some kind of instrument header. text file.
.raw - instruments file. 39 bytes is FM, 7 bytes is PSG and Noice. bin file.
.mod - envelope data. bin file.

