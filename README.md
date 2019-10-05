

# RandomRacer

<a href="randomracer.com">RandomRacer.com</a> is a site that collects and presents statistics and comments from annotated scrabble games on <a href="cross-tables.com">cross-tables.com</a>. All content is updated daily starting at midnight (EST). Updates usually finish in 3.5 hours. Initial development began August 2018 and in February 2019 the first version was released.

In October 2019, the site underwent major updates which include:


 - Mobile-friendly bootstrap reskin.
 - Front page quote, mistake, and notable games carousels.
 - Player pictures on player results pages.
 - Sortable, filterable, and downloadable datatables for all results.
 - Win Correlation graphs for every statistic on the leaderboard.
 - Confidence intervals for all Tiles Played statistics.
 - Dynamic mistake tagging.


You can learn more about some of these features in later sections. Please report any bugs to joshuacastellano7@gmail.com

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
and look for the number in the address bar. For example, the address of the 29th National Championship Main Event is

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

Errors are (most likely) the result of malformed GCG files. To learn more, check the 'Errors and Warnings' section in the <a href="/about.html">about page</a>.

<h3>Warnings</h3>

Warnings are notifications to players that they might want to update some of their GCG files. To learn more, check the 'Errors and Warnings' section in the <a href="/about.html">about page</a>.

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

Plays made by the player that were challenged by an opponent.  This list may not be completely accurate. Check the 'Challenge Heuristics' section of the <a href="/about.html">about page</a> for more information.

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

The player's highest scoring turn.

<h3>Bingos Played</h3>

The number of bingos played by the player that were not challenged off, shown as a total and broken down by length.

<h3>Bingo Probabilities</h3>

The average probabilities of the bingos played by the player. These are the probabilities as listed in the Zyzzyva word study program, so higher values are less probable. Keep in mind that comparing across lexicons not completely accurate due to the varying amounts of words in each lexicon.

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

The number of challenges made by both the player and the opponent, broken down by challenges that the player made against opponent's plays and challenges that the opponent made against the player's plays.  This stat may not be completely accurate. Check the 'Challenge Heuristics' section of the <a href="/about.html">about page</a> for more information.

<h3>Challenge Percentage</h3>

The percentage of challenges that the player made against an opponent's play which were successful.

<h3>Defending Challenge Percentage</h3>

The percentage of challenges made by opponents against the player's plays that were unsuccessful. This stat may not be completely accurate. Check the 'Challenge Heuristics' section of the <a href="/about.html">about page</a> for more information.

<h3>Percentage Phonies Unchallenged</h3>

The percentage of plays that formed a phony and were not challenged off by an opponent.

<h3>Comments</h3>

The number of comments made in the GCG file. This stat counts comments that appear on both the player and the opponent's turn.

<h3>Comments Word Length</h3>

The number of words in all the comments of the GCG file of the game. This stat counts comments that appear on the player's turn and the opponent's turn.

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

Games in which there are at least 5 challenges made. This list may not be completely accurate. Check the 'Challenge Heuristics' section of the <a href="/about.html">about page</a> for more information.

<h3>Mistakeless Turns</h3>

The number of turns the player made that are not tagged with a standard mistake. For more information about mistakes, check the 'Mistakes' section of the <a href="/about.html">about page</a>.

<h3>Mistakes per Turn</h3>

The number of mistakes that the player makes per turn. For more information about mistakes, check the 'Mistakes' section of the <a href="/about.html">about page</a>.

<h3>Mistakes</h3>

The number of mistakes the player made. For more information about mistakes, check the 'Mistakes' section of the <a href="/about.html">about page</a>.

<h3>Mistakes List</h3>

The listing of all of the player's mistakes. For more information about mistakes, check the 'Mistakes' section of the <a href="/about.html">about page</a>.

<h3>Dynamic Mistakes</h3>

The dynamic mistakes made by the player. For more information about mistakes, check the 'Mistakes' section of the <a href="/about.html">about page</a>.

<h3>Dynamic Mistakes List</h3>

The listing of the player's dynamic mistakes. For more information about mistakes, check the 'Mistakes' section of the <a href="/about.html">about page</a>.

# Errors and Warnings

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

To correct any errors or warnings, simply update the game with the corrected GCG file on cross-tables.com. Your new game will be retrieved by RandomRacer in the daily midnight updates.

# Challenge Heuristics

The Challenge statistics may not be completely accurate for games using a double challenge rule (TWL or NSW games) as passes and lost challenges in a double challenge game are indistinguishable in the GCG file. If the following criteria are met, the play is considered a lost challenge:


 - The play is a pass
 - The previous play formed at least one word
 - The game is played with a TWL or NSW lexicon
 - The game has less than 20 turns


If you think you can improve these heuristics, please contact joshuacastellano7@gmail.com.

# Mistakes

There are two kinds of mistakes: standard mistakes (simply called 'mistakes' on the stats pages and leaderboards) and dynamic mistakes.



<h5>Standard Mistakes</h5>
The Standard mistakes statistic is a self-reported statistic that is divided into 7 categories (knowledge, finding, vision, tactics, strategy, time, and endgame). To mark a move as a standard mistake in your annotated game, include the tag of the standard mistake in the comment of the move. You can also tag the magnitude (large, medium, or small) of the standard mistake which will organize your standard mistakes by magnitude in the standard mistakes table. For example, if you missed a bingo because you haven't studied it yet, that would probably be a large mistake due to word knowledge (called 'knowledge' in this case) which you can tag by adding the following in your comment of the move:

#knowledgelarge

The large, medium, and small magnitudes can also be denoted by 'saddest', 'sadder', and 'sad' respecitvely. For example, to tag a standard mistake as a large time mistake, you can write:

#timeSADDEST

If you do not want to specify the magnitude of the standard mistake you can omit the magnitude part of the tag:

#knowledge

If you tag the standard mistake like this the mistake will appear under the 'Unspecified' category in the mistakes table. Standard mistakes are case insensitive so the following standard mistake tags would be equivalent:

#findingSMALL
#FiNdINGsmAlL



<h5>Dynamic Mistakes</h5>
The dynamic mistakes statistic is a self-reported statistic for which the player can create their own categories. To mark a move as a dynamic mistake use two hashtags instead of just one, for example:

##thisisaveryverbosedynamicmistakecategory

Dynamic mistakes can be any alphanumeric string that the player places after '##'. Dynamic mistakes cannot contain anything other than numbers or letters.

There are some key differences between dynamic mistakes and standard mistakes. Dynamic mistakes do not have magnitudes, so if you tagged a move with these dynamic mistakes:

##findingparallelsmall
##findingparallellarge

They would count as completely distinct categories and would not be grouped together in any way.

Unlike mistakes, dynamic mistakes are case sensitive, so if you tagged a move with these dynamic mistakes:

##Yikes
##yikes

They would count as separate dynamic mistake categories.

Dynamic mistake tags that are identical to standard mistake tags are completely valid, but are only counted as dynamic mistakes, not standard mistakes. For example, the following tags are dynamic mistakes:

##finding
##strategylarge
##timeSaddest

While confusing, you are completely free to make these dynamic tags, which will not appear in the standard mistakes section.



<h5>Notes on Both Standard and Dynamic Mistakes</h5>
The tags for all mistakes can appear anywhere in any order in the comment. Keep in mind that all mistakes are associated with moves, and moves are associated with players, so be sure to tag your mistakes on your moves only. For example, if you don't challenge a phony play, you can write the commentary on your opponent's move, but include the tags on your succeeding move to make sure they appear as your mistakes and not your opponents'.
You can also mark a move with more than one mistake:

#findingmedium blah blah blah #tacticslarge ##dynamicsomething ##moredynamic

Mistakes and dynamic mistakes are completely distinct categories. Standard mistakes are never counted as dynamic mistakes and dynamic mistakes are never counted as standard mistakes. If you see this happen on RandomRacer, please contact joshuacastellano7#gmail.com.

# Win Correlation Graphs

For each statistic on the leaderboard there is an associated scatter plot of the win correlation for that statistic.
The statistic is plotted on the X axis and the win percentage is plotted on the Y axis. Each dot represents a player. You can hover over the dot to see which player it is. The 'r' in the legend is the coefficient of correlation. An r value of 1 means that the statistic and win percentage are directly correlated. An r value of -1 means that the statistic and win percentage are inversely correlated. An r value of 0 means that there is no correlation. The slope is the rate of change of win percentage proportional to the statistic. So if the graph has a slope of m, an increase of x in the statistic is proportional to an increase of m*x in win percentage.

# Confidence Intervals

All confidence intervals are calculated with a 99% confidence level. If a player's observed probability of drawing a given tile exceeds the upper bound of the confidence interval, their row is highlighted red. If a player's observed probability of drawing a given tile is below the lower bound of the confidence interval, their row is highlighted green. Observed probabilities are calculated by dividing the average number of tiles played per game by the tile frequency. The equations used to calculate the confidence intervals for a tile \(t\) are as follows:

<div style="text-align: center">
First establish a confidence level, given by \( c \). This is always 99%.
\[c = 0.99\]
Using the confidence level, calculate a normally distributed \(z\)-score where \(a\) is the error, \(K\) is the percentile, and CDF() is the cumulative distribution function of the normal distribution:
\[a = 1 - c\]
\[K = 1 - {a \over 2} \]
\[z = \mathrm{CDF}(K) \]
Let \(P\) be the percentage of all tiles played by the player. For example, if the player averages playing 49 tiles a game, \(P\) would take a value of \(0.49\), since there are 100 tiles in the bag. Let \(n\) be the maximum possible number of tile \(t\) which the player could have played in all of their games. For example, if the player played 100 games and there are \(f\) tiles  of type \(t\) in the bag, \(n\) would take a value of \(100 * f \). Now we can calculate the upper and lower bounds of the confidence interval, where \(l\) is the lower bound and \(u\) is the upper bound:
\[I = z * \sqrt{P * ( 1 - P ) \over n} \]
\[l = P - I \]
\[u = P + I \]
As mentioned above, the observed probability, which we will denote as \(p\), is simply the average number of times that the player plays tile \(t\) per game, divided by how many tiles \(t\) are in the bag. If the observed probability \(p\) is less than \(l\), it is considered below the confidence interval and the row will be highlighted green. If the observed probability \(p\) is greater than \(u\), it is considered above the confidence interval and the row will be highlighted green. If the distribution of tiles played is completely random, as our observations of the random variable \(p\) increases, we should expect to see \(p\) fall within the confidence interval for 99% of those observations. Keep in mind that the leaderboards only give a single observation for \(p\).
</div>

Please note that probabilities that fall outside the confidence interval are in no way suspect. The sample of games analyzed by RandomRacer is subject to a heavy selection bias. Sometimes people tend to only post their good or their bad games. This can cause more probabilities than expected to fall outside the confidence interval. Also, with 26 tiles and about 200 players on the leaderboard and a 99% confidence interval, we can reasonably expect that about 26 * 200 * .01 = 52 probabilities will fall outside the given confidence interval. This is exactly in line with the approximately 50 probabilities that have done so in reality.

# Leaderboards

Leaderboards are updated every midnight (EST). Only players with 50 or more games are included in the leaderboards. More information about the statistics on the leaderboards can be found under 'Statistics, Lists, and Notable Games'.

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

Contact joshuacastellano7@gmail.com if you think a game was omitted by mistake.

# Development Team

RandomRacer is maintained by Joshua Castellano, but many people have suggested new features. Contributors
      are listed in the Contributions section.

# Contributions

The following lists the intellectual contributions made to RandomRacer in reverse chronological (roughly) order.


 - Tiles Played Confidence Intervals (James Curley)
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
