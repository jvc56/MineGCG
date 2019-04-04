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

This statistic may not be completely accurate for games using double challenge (TWL or NSW games) as passes and lost challenges in a double challenge game are indistinguishable in the GCG file. If the following criteria are met, the play is considered a lost challenge:

 - The play is a pass
 - The previous play formed at least one word
 - The game is played with a TWL or NSW lexicon
 - The game has less than 20 turns

If you think you can improve these heuristics, please message me.
<h5>Full Rack per Turn</h5>

This statistic refers to the percentage of racks that contain all seven (or a certain lower number during the endgame) tiles.
<h5>Turns with a Blank</h5>

This statistic is only meaningful for players with a significant percentage of their full racks recorded.

# Mistakes

The mistakes statistic if a self-reported statistic that is divided into 5 categories (knowledge, finding, vision, tactics, strategy). To mark a move as a mistake in your annotated game, include the tag of the mistake in the comment of the move. You can also tag the magnitude (large, medium, or small) of the mistake which will organize your mistakes by magnitude in the mistakes table. For example, if you missed a bingo because you haven't studied it yet, that would probably be a large mistake due to word knowledge (called 'knowledge' in this case) which you can tag by adding the following in your comment of the move:

\#knowledge \#large

The tags are case insensitive and can appear anywhere in any order in the comment. If you only include the magntitude tag, it will not be counted as a mistake at all. If you only include the mistake tag, the mistake will appear under the 'Unspecified' category in the mistakes table.

# Leaderboards

The <a href='http://randomracer.com'>randomracer.com</a> website maintains <a href='http://randomracer.com/leaderboard.html'>leaderboards</a> for all of the statistics that are shown in a search. Only players with 50 or more annotated games are included in the leaderboards. With the exception of the number of games, all statistics are listed as per game unless otherwise stated in the title.

# Errors and Warnings

If there were errors or warnings during a search, they will appear just under the color key. There are a variety of errors and warnings, but only a few are common:<br/><br/>

<h5>Game against ... is a duplicate</h5>
This appears when two games with the same tournament and round number are detected. It is considered a warning and the duplicate game is not included in statistics or leaderboards. It probably means that both you and your opponent uploaded the same game. In this case the racks that you recorded might have been overwritten when you opponent uploaded their game.

<h5>ERROR: no moves found</h5>
This error appears when an empty GCG file is detected.

<h5>ERROR: disconnected play detected</h5>
This error appears when a play is made that does not connect to other tiles on the board.

<h5>ERROR: both players have the same name</h5>
This error appears when both players have the exact same name. In this case the program cannot distinguish who is making which plays.

<h5>ERROR: no valid lexicon found</h5>
This error appears when the game is not tagged with a lexicon or the game uses an unrecognized lexicon, such as THTWL85.

<br/><br/>The errors above are relatively common and well-tested. If you encounter any of these errors, it probably means that the GCG file of the game is somehow malformed or tagged incorrectly. To correct these errors, update the game on <a href='https://cross-tables.com'>cross-tables.com</a> and then message me so I can delete the outdated game that is cached in the database.<br/><br/>

Currently, the only warning is for notes that start before moves. If you see this warning no action is needed. More warnings might be added in the future.<br/><br/>

Any other errors or warnings that appear are rare and likely due to a bug. If you see an error or warning that was not described above, please message me.

# Omitted Games

You might notice that there are some annotated games that are not included in your statistics or in the leaderboards. Games are omitted if they meet any of the following criteria:

 - The game does not appear on your annotated games page on <a href='https://cross-tables.com'>cross-tables.com</a>
 - The game gives an error
 - The game does not have any associated lexicon
 - The game is from a blacklisted tournament

Games with no lexicons are omitted because the lexicons are necessary for computing several statistics and the resulting inaccuracies could be misleading and introduce error (or more error anyway) into the leaderboards. Currently there is only one blacklisted tournament (Can-Am Match CSW, 2015). Tournaments are blacklisted if an annoyingly significant portion of their annotated games are empty or otherwise malformed.

# Contributions

Notable games (Matthew O'Connor)<br/>
Firsts statistic (Ben Schoenbrun)<br/>
Turns with a blank statistic (Marlon Hill)<br/>
Discovery of GCG mining bug in the preload script (Ben Schoenbrun)<br/>
Bingo lists, bingo probabilities, and various statistics (Joshua Sokol)<br/>
Initial idea (Matthew O'Connor)<br/>
