

# RandomRacer

This is RandomRacer, a site that collects and presents statistics
       and comments from annotated scrabble games on cross-tables.com.

# Usage

Simply enter a name in the 'Player Name' field on the main page and hit submit.
There are other parameters you can use to narrow your search:



<h5>Game Type</h5>
An optional parameter used to search for only casual and club games or only tournament games.
Games are considered tournament games if they are associated with a tournament and a round number.
Games tagged as 'Tournament Game' in cross-tables with no specific tournament are not considered tournament games.



<h5>Tournament ID</h5>
An optional parameter used to search for only games of a specific tournament.
To find a tournament's ID, go to that tournament's page on cross-tables.com
and look for the number in the address bar.

For example, the address of the 29th National Championship Main Event is

https://www.cross-tables.com/tourney.php?t=10353&div=1

which has a tournament ID of 10353.



<h5>Lexicon</h5>
An optional parameter used to search for only games of a specific lexicon.



<h5>Game ID</h5>
An optional parameter used to search for only one game. To find a game's ID,
go to that game's page on cross-tables.com and look for the number in the address bar.
For example, the following game:

https://www.cross-tables.com/annotated.php?u=31231#0#

has a game ID of 31231.



<h5>Opponent Name</h5>
An optional parameter used to search for only games against a specific opponent.



<h5>Start Date</h5>
An optional parameter used to search for only games beyond a certain date.



<h5>End Date</h5>
An optional parameter used to search for only games before a certain date.

# Statistics, Lists, and Notable Games



<h3>Errors</h3>

Errors are (most likely) the result of malformed GCG files.
Common errors are described below:



<h5>No moves found</h5>
This error appears when an empty GCG file is detected.


<h5>Disconnected play detected</h5>
This error appears when a play is made that does not connect to other tiles on the board.


<h5>Both players have the same name</h5>
This error appears when both players have the exact same name. In this case the program cannot distinguish who is making which plays.


<h5>No valid lexicon found</h5>
This error appears when the game is not tagged with a lexicon or the game uses an unrecognized lexicon, such as THTWL85.


<h5>Game is incomplete</h5>
This error appears when the GCG file is incomplete.
The errors above are relatively common and well-tested.
If you encounter any of these errors, it probably means
that the GCG file of the game is somehow malformed or tagged incorrectly.
To correct these errors, update the game on cross-tables.com and
the corrected version should appear in your stats the next day.

Any other errors that appear are rare and likely due to a bug.
If you see an error or warning that was not described above,
please email them to joshuacastellano7@gmail.com.

<h3>Warnings</h3>

Warnings are for letting players know that they
might want to correct certain GCG files. The complete
list of warnings is below:
      


<h5>Duplicate game detected</h5>
This appears when two games with the same tournament
and round number are detected. The duplicate game is
not included in statistics or leaderboards. It probably
means that both you and your opponent uploaded the same
game. In this case the racks that you recorded might
have been overwritten when you opponent uploaded their game.



<h5>Note before moves detected</h5>
Notes that appear before moves are not associated with
either player, so mistakes tagged in these notes will
not be recorded.

<h3>Games</h3>

The number of valid games RandomRacer retrieved from cross-tables.com.

<h3>Invalid Games</h3>

The number of games that threw an error when being processed by RandomRacer.

<h3>Total Turns</h3>

The total number of turns of the player and the opponent.

<h3>Bingos</h3>

The number of bingos played by the player that were not challenged off.

<h3>Triple Triples</h3>

Triple triples played by the player that were not challenged off. They do not have to be bingos.

<h3>Bingo Nines or Above</h3>

Bingos played by the player that were nine letters or longer and were not challenged off.

<h3>Challenged Phonies</h3>

Plays made by the player that formed at least one phony and were challenged off by an opponent.

<h3>Unchallenged Phonies</h3>

Plays made by the player that formed at least one phony and were not challenged by an opponent.

<h3>Plays That Were Challenged</h3>

Plays made by the player that were challenged by an opponent.

<h3>Wins</h3>

The number of wins of the player.

<h3>Score</h3>

The game score of the player.

<h3>Score per Turn</h3>

The average score per turn of the player based on all of their games.

<h3>Turns</h3>

The number of turns made by the player.

<h3>Firsts</h3>

The number of times the player went first.

<h3>Vertical Openings per First</h3>

The number of times the player went first and opened vertically. Vertical openings that were challenged off do not count.

<h3>Full Rack per Turn</h3>

The percentage of fully annotated racks out of all of the players racks for every game.

<h3>Exchanges</h3>

The number of exchanges made by the player.

<h3>High Game</h3>

The player's highest game.

<h3>Low Game</h3>

The player's lowest game.

<h3>Highest Scoring Turn</h3>

The player\s highest scoring turn.

<h3>Bingos Played</h3>

The number of bingos played by the player that were not challenged off, shown as a total and broken down by length.

<h3>Bingo Probabilities</h3>

The average probabilities of the bingos played by the player. These are the probabilities as listed in the Zyzzyva word study program, so higher values are less probable.

<h3>Tiles Played</h3>

The number of tiles played by the player.

<h3>Power Tiles Played</h3>

The power number of tiles played by the player. This includes J, Q, X, Z, S, and the blank.

<h3>Power Tiles Stuck With</h3>

The number of power tiles left on the player's rack after the opponent went out.

<h3>Turns With a Blank</h3>

The number turns that the play had a blank on their rack. This statistic is only meaningful for players with a significant portion of the full racks recorded.

<h3>Triple Triples Played</h3>

The number of triple triples played by the player. The triple triples do not have to be bingos.

<h3>Bingoless Games</h3>

The number of games where the player does not bingo.

<h3>Bonus Square Coverage</h3>

The number of bonus squares that the player covered.

<h3>Phony Plays</h3>

The number of phony plays made by the player, both challenged and unchalleged.

<h3>Challenges</h3>

The number of challenges made by both the player and the opponent, broken down by challenges that the player made against opponent's plays and challenges that the opponent made against the player's plays.

<h3>Challenge Percentage</h3>

The percentage of challenges that the player made against an opponent's play which were successful.

<h3>Defending Challenge Percentage</h3>

The percentage of challenges made by opponents against the player's plays that were unsuccessful.

<h3>Percentage Phonies Unchallenged</h3>

The percentage of plays that formed a phony and were not challenged off by an opponent.

<h3>Comments</h3>

The number of comments made in the GCG file. This stat counts comments that appear on both the player and the opponent's turn.

<h3>Comments Word Length</h3>

The number words in all the comments of the GCG file of the game. This stat counts comments that appear on the player's turn and the opponent's turn.

<h3>Many Double Letters Covered</h3>

Games in which at least 20 double letter bonus squares were covered.

<h3>Many Double Words Covered</h3>

Games in which at least 15 double word bonus squares were covered.

<h3>All Triple Letters Covered</h3>

Games in which every triple letter bonus square was covered.

<h3>All Triple Words Covered</h3>

Games in which every triple word bonus square was covered.

<h3>High Scoring</h3>

Games in which at least one player scores at least 700 points.

<h3>Combined High Scoring</h3>

Games in which the combined score is at least 1100 points.

<h3>Combined Low Scoring</h3>

Games in which the combined score is no greater than 200 points. Many games on cross-tables.com end before a combined score of 200 points but are considered incomplete and are not counted. Many valid six pass games are not included because they are malformed.

<h3>Ties</h3>

Games that end in ties.

<h3>One Player Plays Every Power Tile</h3>

Games in which one player plays the Z, X, Q, J, every blank, and every S.

<h3>One Player Plays Every E</h3>

Games in which one player plays every E.

<h3>Many Challenges</h3>

Games in which there are at least 5 challenges made.

<h3>Mistakeless Turns</h3>

The number of turns the player made that are not tagged with a mistake. Dynamic mistakes do not count for this statistic.

<h3>Mistakes per Turn</h3>

The number of mistakes that the player makes per turn.

<h3>Mistakes</h3>

yeet

<h3>Mistakes List</h3>

The listing of all of the player's mistakes.

<h3>Dynamic Mistakes</h3>

More on this later.

<h3>Dynamic Mistakes List</h3>

The listing of the player's dynamic mistakes.

# Leaderboards

Leaderboards are updated every midnight (EST). Only players with 50 or more games are included in the leaderboards.

# Omitted Games

You might notice that there are some annotated games that are
not included in your statistics or in the leaderboards. Games
are omitted if they meet any of the following criteria:


 - The game does not appear on your annotated games page on cross-tables.com
 - The game gives an error
 - The game does not have any associated lexicon


Games with no lexicons are omitted because the lexicons are necessary for
computing several statistics and the resulting inaccuracies could be
misleading and introduce error (or more error anyway) into the leaderboards.

# Development Team

RandomRacer is maintained by Joshua Castellano, but many people have suggested new features. Contributors
      are listed in the Contributions section.

# Contributions

The following lists the intellectual contributions made to RandomRacer in reverse chronological (roughly) order.


 - Win Correlations (James Curley)
 - Dynamic Mistakes (Kenji Matsumoto)
 - Vertical Play statistics (Matthew O'Connor)
 - Mistakeless Turns statistic (César Del Solar)
 - Saddest/Sadder/Sad mistake magnitudes aliases (Jackson Smylie)
 - Highest Scoring Play statistic (Will Anderson)
 - Discovery of a bug in the Full Rack per Turn statistic (Will Anderson)
 - Notable games (Matthew O'Connor)
 - Firsts statistic (Ben Schoenbrun)
 - Turns with a blank statistic (Marlon Hill)
 - Discovery of GCG mining bug in the preload script (Ben Schoenbrun)
 - Bingo lists, bingo probabilities, and various statistics (Joshua Sokol)
 - Initial idea (Matthew O'Connor)
