# MineGCG

MineGCG is a tool that computes statistics for annotated cross-tables.com games. Matthew O'Connor thought of the original idea in the summer of 2018 while we were on vacation in Cloyne. It has since accumulated many new statistics and features and continues to be updated regularly. The web version can be found at <a href='http://randomracer.com'>randomracer.com</a> or you can install it from the command line. If you find any bugs or want to suggest improvements, email them to joshuacastellano7@gmail.com and I'll add your name to the contributions list!

# Installation

For the command line version, you must have a UNIX-based operating system (this includes MacOS and Linux). To use, navigate to a desired empty directory and run the following commands:

git clone https://github.com/jvc56/MineGCG<br/>
cd MineGCG<br/>
chmod +x ./scripts/*.pl<br/>
./scripts/main.pl<br/>

A usage message telling you how to use the command should appear. 

# Usage

This section describes the usage of the web version. For questions about the command line version, message me directly for now. To search for someone's statistics, go to <a href='http://randomracer.com'>randomracer.com</a> and enter their name into the 'Player Name' field. The name must exactly match their name as it appears on <a href='https://cross-tables.com'>cross-tables.com</a> except for capitalization and punctuation. There are other parameters you can use to narrow your search which are described below:<br/><br/>
<h5>Player Name</h5> Specifies the name of the player (ignoring capitalization and punctuaion).<br/><br/>
<h5>Game Type</h5>   An optional parameter used to search for only casual and club games or only tournament games. Games are considered tournament games if they are associated with a tournament and a round number. Games tagged as 'Tournament Game' in cross-tables with no specific tournament are not considered tournament games.<br/><br/>
<h5>Tournament ID</h5> An optional parameter used to search for only games of a specific tournament. To find a tournament's ID, go to that tournament's page on <a href='https://cross-tables.com'>cross-tables.com</a> and look for the number in the address bar. For example, the address of the 29th National Championship Main Event is<br/><br/>
https://www.cross-tables.com/tourney.php?t=10353&div=1<br/><br/>
which has a tournament ID of 10353.<br/><br/>
<h5>Lexicon</h5> An optional parameter used to search for only games of a specific lexicon.<br/><br/>
<h5>Game ID</h5> An optional parameter used to search for only one game. To find a game's ID, go to that game's page on <a href='https://cross-tables.com'>cross-tables.com</a> and look for the number in the address bar. For example, the address of one of my games against Marlon is<br/><br/>
https://www.cross-tables.com/annotated.php?u=31231#0#<br/><br/>
which has a game ID of 31231.<br/><br/>
<h5>Opponent Name</h5> An optional parameter used to search for only games against a specific opponent. The name must exactly match their name as it appears on <a href='https://cross-tables.com'>cross-tables.com</a> (ignoring capitalization and punctuaion).<br/><br/>
<h5>Start Date</h5> An optional parameter used to search for only games beyond a certain date.<br/><br/>
<h5>End Date</h5> An optional parameter used to search for only games before a certain date.<br/><br/>

# Statistics and Lists

After running a search, a new page will appear with your bingos and other statistics. For all of the lists, each word listed links to the annotated cross-tables game in which it appears. For bingos and triple triples, the number next to the word is the probability order as it appears on Zyzzyva.<br/><br/>
Below the lists are the statistics for all of the games in the search. The AVERAGE column refers to the average per game unless otherwise stated in the statistic title to the left. Several statistics might be inaccurate for various reasons or warrant further explanation:<br/><br/>

<h5>Challenges You Won/You Lost</h5>
This statistic may not be completely accurate for games using double challenge (TWL or NSW games) as passes and lost challenges in a double challenge game are indistinguishable in the GCG file. If the following criteria are met, the play is considered a lost challenge:<br/>

 - The previous play formed at least one word
 - The game is played with a TWL or NSW lexicon
 - The game has less than 20 turns

If you think you can improve these heuristics, please message me.
<h5>Full Rack per Turn</h5>
This statistic refers to the percentage of racks that contain all seven (or a certain lower number during the endgame) tiles.
<h5>Turns with a Blank</h5>
This statistic is only meaningful for players with a significant percentage of their full racks recorded.

# Leaderboards

The <a href='http://randomracer.com'>randomracer.com</a> website maintains <a href='http://randomracer.com/leaderboards.html'>leaderboards</a> for all of the statistics that are shown in a search. Only players with 50 or more annotated games are included in the leaderboards.

# Errors, Warnings, and Omitted Games

If there were errors or warnings during a search, they will appear just under the color key. There are a variety of errors and warnings, but only a few are common:<br/><br/>

<h5>Game against ... is a duplicate</h5>
This appears when two games with the same tournament and round number are detected. It is not considered a warning or error, though it probably means that both you and your opponent uploaded the same game. In this case the racks that you recorded might have been overwritten when you opponent uploaded their game.

<h5>ERORR: no moves found</h5>
This error appears when an empty GCG file is detected.

<h5>ERORR: disconnected play detected</h5>
This error appears when a play is made that does not connect to other tiles on the board.

<br/><br/>The errors above are relatively common and well-tested. If you encounter any of these errors, it probably means that the GCG file of the game is somehow malformed. To correct these errors, update the game on <a href='https://cross-tables.com'>cross-tables.com</a> and then message me so I can delete the outdated game that is cache in the database. It is also possible that there is a bug that is causing the error. If you think this is the case, message me and I will add you to the contributions list!<br/><br/>

Currently, the only warnings is for notes that start before moves. If you see this warning no action is needed. More warnings might be added in the future.<br/><br/>

You might notice that there are some annotated games that are not included in your statistics or in the leaderboards. Games are omitted if they meet any of the following criteria:

 - The game gives an error
 - The game does not have any associated lexicon
 - The game is from a blacklisted tournament

Games with no lexicons are omitted because the lexicons are necessary for computing several statistics and the resulting inaccuracies could be misleading and introduce error (or more error anyway) into the leaderboards. Currently there is only one blacklisted tournament (Can-Am Match CSW, 2015). Tournaments are blacklisted if an annoyingly significant portion of their annotated games are empty or otherwise malformed.

# Contributions

Turns with a blank statistic (Marlon Hill)<br/>
Discovery of GCG mining bug in the preload script (Ben Schoenbrun)<br/>
Bingo lists, bingo probabilities, and various statistics (Joshua Sokol)<br/>
Initial idea (Matthew O'Connor)<br/>
