

# RandomRacer

This is RandomRacer, a site that collects and presents statistics
       and comments from annotated scrabble games on cross-tables.com.

# Usage


      Simply enter a name in the 'Player Name' field on the main page and hit submit.
      There are other parameters you can use to narrow your search:

      <br><br>
<h5>Game Type</h5>
      An optional parameter used to search for only casual and club games or only tournament games.
      Games are considered tournament games if they are associated with a tournament and a round number.
      Games tagged as 'Tournament Game' in cross-tables with no specific tournament are not considered tournament games.

      <br><br>
<h5>Tournament ID</h5>
      An optional parameter used to search for only games of a specific tournament.
      To find a tournament's ID, go to that tournament's page on cross-tables.com
      and look for the number in the address bar.

      For example, the address of the 29th National Championship Main Event is

      https://www.cross-tables.com/tourney.php?t=10353&div=1

      which has a tournament ID of 10353.

      <br><br>
<h5>Lexicon</h5>
      An optional parameter used to search for only games of a specific lexicon.

      <br><br>
<h5>Game ID</h5>
      An optional parameter used to search for only one game. To find a game's ID,
      go to that game's page on cross-tables.com and look for the number in the address bar.
      For example, the following game:

      https://www.cross-tables.com/annotated.php?u=31231#0#

      has a game ID of 31231.

      <br><br>
<h5>Opponent Name</h5>
      An optional parameter used to search for only games against a specific opponent.

      <br><br>
<h5>Start Date</h5>
      An optional parameter used to search for only games beyond a certain date.

      <br><br>
<h5>End Date</h5>
      An optional parameter used to search for only games before a certain date.

# Statistics, Lists, and Notable Games

<br><br>
<h5>Errors</h5>


      Errors are (most likely) the result of malformed GCG files.
      Common errors are described below:

      <br><br>
<h5>No moves found</h5>
      This error appears when an empty GCG file is detected.
      <br><br>
<h5>Disconnected play detected</h5>
      This error appears when a play is made that does not connect to other tiles on the board.
      <br><br>
<h5>Both players have the same name</h5>
      This error appears when both players have the exact same name. In this case the program cannot distinguish who is making which plays.
      <br><br>
<h5>No valid lexicon found</h5>
      This error appears when the game is not tagged with a lexicon or the game uses an unrecognized lexicon, such as THTWL85.
      <br><br>
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
      <br><br>
<h5>Warnings</h5>


      Warnings are for letting players know that they
      might want to correct certain GCG files. The complete
      list of warnings is below:
      
      <br><br>
<h5>Duplicate game detected</h5>
      This appears when two games with the same tournament
      and round number are detected. The duplicate game is
      not included in statistics or leaderboards. It probably
      means that both you and your opponent uploaded the same
      game. In this case the racks that you recorded might
      have been overwritten when you opponent uploaded their game.

      <br><br>
<h5>Note before moves detected</h5>
      Notes that appear before moves are not associated with
      either player, so mistakes tagged in these notes will
      not be recorded.
      <br><br>
<h5>Games</h5>


      The number of valid games RandomRacer retrieved
      from cross-tables.com.
      <br><br>
<h5>Invalid Games</h5>


      The number of games that threw an error
      when being processed by RandomRacer.
      <br><br>
<h5>Total Turns</h5>


      The total number of turns of the player and the opponent.
      <br><br>
<h5>Bingos</h5>


      The number of bingos played by the player that were not challenged off.
      <br><br>
<h5>Triple Triples</h5>

Triple triples played by the player that were not challenged off. They do not have to be bingos.<br><br>
<h5>Bingo Nines or Above</h5>


      Bingos played by the player that were nine
      letters or longer and were not challenged off.
      <br><br>
<h5>Challenged Phonies</h5>


      Plays made by the player that
      formed at least one phony and were challenged off by an opponent.
      <br><br>
<h5>Unchallenged Phonies</h5>


      Plays made by the player that formed
      at least one phony and were not challenged by an opponent.
      <br><br>
<h5>Plays That Were Challenged</h5>


      Plays made by the player that were challenged by an opponent.
      <br><br>
<h5>Wins</h5>


      The number of wins of the player.
      <br><br>
<h5>Score</h5>


      The game score of the player.
      <br><br>
<h5>Score per Turn</h5>


      The average score per turn of the player based on all of their games.
      <br><br>
<h5>Turns</h5>


      The number of turns made by the player.
      <br><br>
<h5>Firsts</h5>


      The number of times the player went first.
      <br><br>
<h5>Vertical Openings per First</h5>


      The number of times the player went first and opened vertically.
      Vertical openings that were challenged off do not count.
      <br><br>
<h5>Full Rack per Turn</h5>


      The percentage of fully annotated racks out of all of the players racks for every game.
      <br><br>
<h5>Exchanges</h5>


      The number of exchanges made by the player.
      <br><br>
<h5>High Game</h5>


      The player's highest game.
      <br><br>
<h5>Low Game</h5>


      The player's lowest game.
      <br><br>
<h5>Highest Scoring Turn</h5>


      The player\s highest scoring turn.
      <br><br>
<h5>Bingos Played</h5>


      The number of bingos played by the player that were not challenged off, shown
      as a total and broken down by length.
      <br><br>
<h5>Bingo Probabilities</h5>


      The average probabilities of the bingos played by the player.
      These are the probabilities as listed in the Zyzzyva word study program, so higher
      values are less probable.
      <br><br>
<h5>Tiles Played</h5>


      The number of tiles played by the player.
      <br><br>
<h5>Power Tiles Played</h5>


      The power number of tiles played by the player. This includes J, Q, X, Z, S, and the blank.
      <br><br>
<h5>Power Tiles Stuck With</h5>


      The number of power tiles left on the player's rack after the opponent went out.
      <br><br>
<h5>Turns With a Blank</h5>


      The number turns that the play had a blank on their rack.
      This statistic is only meaningful for players with a significant
      portion of the full racks recorded.
      <br><br>
<h5>Triple Triples Played</h5>


      The number of triple triples played by the player.
      The triple triples do not have to be bingos.
      <br><br>
<h5>Bingoless Games</h5>


      The number of games where the player does not bingo.
      <br><br>
<h5>Bonus Square Coverage</h5>


      The number of bonus squares that the player covered.
      <br><br>
<h5>Phony Plays</h5>


      The number of phony plays made by the player, both challenged and unchalleged.
      <br><br>
<h5>Challenges</h5>


      The number of challenges made by both the player and the opponent, broken down
      by challenges that the player made against opponent's plays and challenges
      that the opponent made against the player's plays.
      <br><br>
<h5>Challenge Percentage</h5>


      The percentage of challenges that the player made against an opponent's play which were successful.
      <br><br>
<h5>Defending Challenge Percentage</h5>


      The percentage of challenges made by opponents against the player's plays that were unsuccessful.
      <br><br>
<h5>Percentage Phonies Unchallenged</h5>


      The percentage of plays that formed a phony and were not challenged off by an opponent.
      <br><br>
<h5>Comments</h5>


      The number of comments made in the GCG file.
      This stat counts comments that appear on both the player and the opponent's turn.
      <br><br>
<h5>Comments Word Length</h5>


      The number words in all the comments of the GCG file of the game.
      This stat counts comments that appear on the player's turn and the opponent's turn.
      <br><br>
<h5>Many Double Letters Covered</h5>


      The number words in all the comments of the GCG file of the game.
      This stat counts comments that appear on the player's turn and the opponent's turn.
      <br><br>
<h5>Many Double Words Covered</h5>


      Games in which at least 15 double word bonus squares were covered.
      <br><br>
<h5>All Triple Letters Covered</h5>


      Games in which every triple letter bonus square was covered.
      <br><br>
<h5>All Triple Words Covered</h5>


      Games in which every triple word bonus square was covered.
      <br><br>
<h5>High Scoring</h5>


      Games in which at least one player scores at least 700 points.
      <br><br>
<h5>Combined High Scoring</h5>


      Games in which the combined score is at least 1100 points.
      <br><br>
<h5>Combined Low Scoring</h5>


      Games in which the combined score is no greater than 200 points.
      Many games on cross-tables.com end before a combined score of 200 points
      but are considered incomplete and are not counted. Many valid six pass games
      are not included because they are malformed.
      <br><br>
<h5>Ties</h5>


      Games that end in ties.
      <br><br>
<h5>One Player Plays Every Power Tile</h5>


      Games in which one player plays the Z, X, Q, J, every blank, and every S.
      <br><br>
<h5>One Player Plays Every E</h5>


      Games in which one player plays every E.
      <br><br>
<h5>Many Challenges</h5>


      Games in which there are at least 5 challenges by either player.
      <br><br>
<h5>Mistakeless Turns</h5>


      The number of turns the player made that are not tagged with a mistake.
      Dynamic mistakes do not count for this statistic.
      <br><br>
<h5>Mistakes per Turn</h5>


      The number of mistakes that the player makes per turn.
      <br><br>
<h5>Mistakes</h5>


yeet
      <br><br>
<h5>Mistakes List</h5>


      The listing of all of the player's mistakes.
      <br><br>
<h5>Dynamic Mistakes</h5>


      More on this later.
      <br><br>
<h5>Dynamic Mistakes List</h5>


      The listing of the player's dynamic mistakes.

# Leaderboards

Leaderboards are updated every midnight (EST).
       Only players with 50 or more games are included in the leaderboards.

# Omitted Games


      You might notice that there are some annotated games that are
      not included in your statistics or in the leaderboards. Games
      are omitted if they meet any of the following criteria:
      <br>
      <ul>
       <li>The game does not appear on your annotated games page on cross-tables.com</li>
       <li>The game gives an error</li>
       <li>The game does not have any associated lexicon</li>
      </ul>

      Games with no lexicons are omitted because the lexicons are necessary for
      computing several statistics and the resulting inaccuracies could be
      misleading and introduce error (or more error anyway) into the leaderboards.

# Development Team

RandomRacer is maintained by Joshua Castellano, but many people have suggested new features. Contributors
      are listed in the Contributions section.

# Contributions


        The following lists the intellectual contributions made to RandomRacer
        in reverse chronological (roughly) order.
        <br>
	<ul>
        <li>Win Correlations (James Curley)</li>
        <li>Dynamic Mistakes (Kenji Matsumoto)</li>
        <li>Vertical Play statistics (Matthew O'Connor)</li>
        <li>Mistakeless Turns statistic (César Del Solar)</li>
        <li>Saddest/Sadder/Sad mistake magnitudes aliases (Jackson Smylie)</li>
        <li>Highest Scoring Play statistic (Will Anderson)</li>
        <li>Discovery of a bug in the Full Rack per Turn statistic (Will Anderson)</li>
        <li>Notable games (Matthew O'Connor)</li>
        <li>Firsts statistic (Ben Schoenbrun)</li>
        <li>Turns with a blank statistic (Marlon Hill)</li>
        <li>Discovery of GCG mining bug in the preload script (Ben Schoenbrun)</li>
        <li>Bingo lists, bingo probabilities, and various statistics (Joshua Sokol)</li>
        <li>Initial idea (Matthew O'Connor)</li>
	</ul>