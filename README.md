# MineGCG

MineGCG is a tool that computes statistics for annotated cross-tables.com games. Matthew O'Connor thought of the original idea in the summer of 2018 while we were on vacation in Cloyne. It has since accumulated many new statistics and features and continues to be updated regularly. The web version can be found at <a href='randomracer.com'>randomracer.com</a> or you can install it from the command line. If you find any bugs or want to suggest improvements, email them to joshuacastellano7@gmail.com and I'll add your name to the contributions list.

# Installation

For the command line version, you must have a UNIX-based operating system (this includes MacOS and Linux). To use, navigate to a desired empty directory and run the following commands:

git clone https://github.com/jvc56/MineGCG<br/>
cd MineGCG<br/>
chmod +x ./scripts/*.pl<br/>
./scripts/main.pl<br/>

A usage message telling you how to use the command should appear. 

# Usage

This section describes the usage of the web version. For questions about the command line version, message me directly for now.<br/>
To search for someone's statistics, go to <a href='randomracer.com'>randomracer.com</a> and enter their name into the 'Player Name' field. The name must exactly match their name as it appears on <a href='cross-tables'>cross-tables.com</a> except for capitalization and punctuation. There are other parameters you can use to narrow your search which are described below:<br/>
Player Name: Specifies the name of the player (ignoring capitalization and punctuaion).<br/>
Game Type:   An optional parameter used to search for only casual and club games or only tournament games. Games are considered tournament games if they are associated with a tournament and a round number. Games tagged as 'Tournament Game' in cross-tables with no specific tournament are not considered tournament games.<br/>
Tournament ID: An optional parameter used to search for only games of a specific tournament. To find a tournament's tournament ID, go to that tournament's page on <a href='cross-tables'>cross-tables.com</a> and look for the number in the address bar. For example, the address of the 29th National Championship Main Event is<br/>
https://www.cross-tables.com/tourney.php?t=10353&div=1<br/>
which has a tournament ID of 10353.<br/>
Lexicon: An optional parameters used to search for only games of a specific lexicon.<br/>

# Contributions

Turns with a blank statistic (Marlon Hill)<br/>
Discovery of GCG mining bug in the preload script (Ben Schoenbrun)<br/>
Bingo lists, bingo probabilities, and various statistics (Joshua Sokol)<br/>
Initial idea (Matthew O'Connor)<br/>
