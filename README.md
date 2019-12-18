# Implementation of Twitter Engine without UI


Gopichand Kommineni         UFID 0305-5523
Hemanth Kumar Malyala       UFID 6348-5914

# Twitter Engine

 Twitter is a messaging service where users post and interact with messages known as "tweets".  
 Registered users can post, and retweet tweets, but unregistered users can only read them. 
 Users can group posts together by topic or type by use of hashtags – words or phrases prefixed with a 
 “#” sign. Similarly, the “@” sign followed by a username is used for mentioning or replying to other users.
 To repost a message from another Twitter user and share it with one's own followers, a user can click the 
 retweet button within the Tweet. 
 
 We have implemented the below functionalities in this project:
 Proj4.register(n) - registers a new user/creates a new account
 Proj4.subscribe(n1,n2) - A user can subscribe to any other user of his choice
 Proj4.delete_account(n) - deleteing the account of a user
 Proj4.retweet(n) - User 'n' can retweet the tweets he just recieved 
 Proj4.hash_query("#Iamusern") - This fetches all the tweets posted with the hashtag "#Iamusern".
 Proj4.mention_query("@n") - This fetches all the tweets posted mentioning the user "n".


#How to run this project
mix run proj4 num_user num_msg
Where num_user is the number of actors you have to create and num_msg is
the number of tweets a user has to make. The input is provided as command line argument.

#How to run test cases
mix test
The above command will execute all the test cases written in the file twitter_test.exs.
A total of 15 test cases are written checking the functionalities of each one listed above.

#Statistics:

The maximum number of actors created are 7000, i.e 7000 users are registered
Maximum number of tweets is 300.
All the test cases in test.ex file are successfully executed in 5.7 seconds

# Test cases:
1. register user
2. register existing again
3. Subscribe user
4. delete user
5. delete non-exisiting user
6. Subscribe a deleted failure user
7. delete non-exisiting user
8. retweet
9. retweeting from deleted account
10. hash_query
11. hash_query incorrect format
12. hash_query of non-existent user
13. mention_query
14. mention_query incorrect format
15. mention_query non-existing user

 
Number of Clients  Number of Tweets      1       3          8        10        13
    100                   10           143.7  80347.087   1698.9    1890.3   26017.0
    500                   5            900.01 146711.644  4025.833  1953.2   38443.1
	1000                  10           909.8  146502.35   4400.723  2107.3   51209.0
    300                   100          1500   15098.6     5690.8    3178.9   53908.9	
	(in microseconds)



