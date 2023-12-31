import 'package:buttons/main.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:buttons/screens/pageofinstructions.dart';

class GuessTheImageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

late AudioPlayer player;

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int repeatCount = 4; // Set the number of repetitions

  int currentPage = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    loadBackgroundMusic();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> loadBackgroundMusic() async {

  try {
    final audioSource = AudioSource.asset(
      'assets/Sounds/background.mp3',
      tag: MediaItem(
        id: 'background_music',
        title: 'Background Music',
      ),
    );



      // Load the audio source
      await player.setAudioSource(audioSource);

      // Set loop mode and volume
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(1.0);

      // Start playing
      await player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void showCongratulationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You completed the second level of the game.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HelpSplashScreen(
                        text:
                            "Welcome to Level 3! \nIn this stage, you'll be exploring the fundamentals of DNA base pairing.\n Given a single DNA strand,\n your task is to correctly assign the matching base pairs to form the complementary strand.\n Successfully completing this level will propel you to Level 4. Good luck!",
                        imagePath: "assets/3danimations/correct_ans.json",
                        levelName: 3),
                  ),
                ); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void nextPage() {
    setState(() {
      currentPage++;
      if (currentPage == repeatCount) {
        // If we reached the desired number of repetitions, show the dialog
        showCongratulationsDialog();
      } else {
        // Otherwise, go to the next page
        pageController.nextPage(
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> assetPaths = [
      'assets/images/autoclave.jpg',
      'assets/images/eppendorf centrifuge.jpg',
      'assets/images/gel electrophoresis.jpg',
      'assets/images/geldoc.jpg',
      'assets/images/nanodrop.jpg',
      'assets/images/pipette.jpg'
    ];

    final List<String> wordsToGuesses = [
      'AUTOCLAVE',
      'EPPENDORF CENTRIFUGE',
      'GEL ELECTROPHORESIS',
      'GELDOC',
      'NANODROP',
      'PIPETTE',
    ];

    return MaterialApp(
      home: Scaffold(
        body: PageView.builder(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          itemCount: repeatCount * assetPaths.length,
          itemBuilder: (context, index) {
            final assetIndex = index % assetPaths.length;
            final assetPath = assetPaths[assetIndex];
            final wordsToGuess = wordsToGuesses[assetIndex];

            return GuessTheImagePage(
              wordsToGuess: wordsToGuess,
              assetPath: assetPath,
              isLastPage: index == (repeatCount * assetPaths.length),
              onNext: nextPage, // update to the next level
            );
          },
        ),
      ),
    );
  }
}

class GuessTheImagePage extends StatefulWidget {
  final String assetPath;
  final bool isLastPage;
  final String wordsToGuess;
  final VoidCallback onNext;

  GuessTheImagePage({
    required this.assetPath,
    required this.isLastPage,
    required this.wordsToGuess,
    required this.onNext,
  });
  @override
  _GuessTheImagePageState createState() => _GuessTheImagePageState();
}

class _GuessTheImagePageState extends State<GuessTheImagePage> {
  late final String length;
  List<String> selectedLetters = [];
  List<String> availableLetters = [];
  List<String> filledBoxes = [];

  int timerSeconds = 60; // Set your desired countdown time here
  late Timer timer;
  bool isTimeUp = false;

  @override
  void initState() {
    length = widget.wordsToGuess.length.toString();
    filledBoxes = List.filled(int.parse(length), '');
    // Move the initialization here
    super.initState();
    availableLetters = generateRandomLetters(widget.wordsToGuess);
    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timerSeconds > 0) {
          timerSeconds--;
        } else {
          timer.cancel();
          isTimeUp = true;
        }
      });
    });
  }

  List<String> generateRandomLetters(String targetWord) {
    List<String> allLetters = targetWord.split('');
    List<String> randomLetters = [];

    while (allLetters.isNotEmpty) {
      int randomIndex = Random().nextInt(allLetters.length);
      randomLetters.add(allLetters[randomIndex]);
      allLetters.removeAt(randomIndex);
    }

    // Add extra random letters to fill the available letters box
    int lettersToAdd = max(6 - targetWord.length, 0);
    for (int i = 0; i < lettersToAdd; i++) {
      randomLetters
          .add(String.fromCharCode(Random().nextInt(26) + 'A'.codeUnitAt(0)));
    }

    return randomLetters;
  }

  Widget buildLetterButton(String letter) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (filledBoxes.contains('')) {
            int emptyBoxIndex = filledBoxes.indexOf('');
            if (emptyBoxIndex < widget.wordsToGuess.length &&
                letter == widget.wordsToGuess[emptyBoxIndex]) {
              filledBoxes[emptyBoxIndex] = letter;
              selectedLetters.add(letter);
              availableLetters.remove(letter);
            }
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 243, 224, 11),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSelectedBoxes() {
    List<Widget> selectedBoxWidgets = filledBoxes.map((letter) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 243, 100, 33),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 5,
      children: selectedBoxWidgets,
    );
  }

  Widget buildAvailableLetters() {
    List<Widget> availableLetterWidgets = availableLetters.map((letter) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: buildLetterButton(letter),
      );
    }).toList();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 5,
      children: availableLetterWidgets,
    );
  }

  bool isAnswerCorrect() {
    return filledBoxes.join('') == widget.wordsToGuess;
  }

  // int index=0;
  // final String image = assetPaths[index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LexiPic'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              textAlign: TextAlign.center,
              'Timer: ${timerSeconds.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
        // leading: BackButton(onPressed: () {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => CrosswordApp(),
        //     ),
        //   );
        // }
        // )
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 48, 213, 200),
              Color.fromARGB(255, 48, 213, 200)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ListView(
            // mainAxisAlignment: MainAxisAlignment.center,
            scrollDirection: Axis.vertical,
            children: [
              // Image Here
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.all(16.0),
                    width: 200.0,
                    height: 200.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage(
                            widget.assetPath), // Replace with your image asset
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              // Empty boxes for guessing
              buildSelectedBoxes(),
              SizedBox(height: 16.0),
              // Available letters
              buildAvailableLetters(),
              SizedBox(height: 16.0),
              if (isAnswerCorrect())
                Text(
                  'Correct Answer!', //$widget.wordsToGuess,
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 131, 4),
                  ),
                ),
              SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Implement logic to move to the next puzzle or action
                    if (isAnswerCorrect()) {
                      widget.onNext();
                    }
                  },
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
              if (isTimeUp)
                AlertDialog(
                  title: Text('TIME UP....'),
                  content: Text('GO TO THE HOME PAGE AND START AGAIN....'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FirstRoute(),
                          ),
                        ); // Close the dialog
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
