import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob用

class GameScreen extends StatefulWidget {
  final List<File> images;
  final dynamic backImage; // FileまたはString（アセットのパス）を保持

  const GameScreen({super.key, required this.images, this.backImage});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<bool> _isFlipped;
  List<int> _selectedCards = [];
  int _score = 0;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 効果音再生用

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  void _loadInterstitialAd() {
    // 既存の広告があれば破棄
    _interstitialAd?.dispose();
    _interstitialAd = null;

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-8946560300471397/1989907543', // テスト用広告ユニットID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              // 広告が閉じられた後にリソースを解放
              ad.dispose();
              _loadInterstitialAd(); // 次の広告をロード
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd(); // 次の広告をロード
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('インタースティシャル広告の読み込み失敗: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // 次回の表示のためにリセット
      _isAdLoaded = false; // ロードフラグをリセット
    } else {
      print('広告がロードされていません');
    }
  }


  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    _isFlipped = List<bool>.filled(widget.images.length, false);
  }

  Future<void> _playSound(String filePath) async {
    await _audioPlayer.setSource(AssetSource(filePath));
    await _audioPlayer.resume(); // 再生
  }

  void _flipCard(int index) {
    if (_selectedCards.length < 2 && !_isFlipped[index]) {
      setState(() {
        _isFlipped[index] = true;
        _selectedCards.add(index);
      });

      _playSound('sounds/card_flip.mp3'); // カードをめくる音

      if (_selectedCards.length == 2) {
        _checkForMatch();
      }
    }
  }

  void _checkForMatch() {
    final firstIndex = _selectedCards[0];
    final secondIndex = _selectedCards[1];

    if (widget.images[firstIndex].path == widget.images[secondIndex].path) {
      // ペアが一致
      setState(() {
        _score += 1;
        _selectedCards.clear();
      });

      _playSound('sounds/pair_match.mp3'); // ペア一致の音

      if (_isFlipped.every((flipped) => flipped)) {
        _showGameOverDialog();
      }
    } else {
      _playSound('sounds/wrong_pair.mp3'); // ペア不一致の音（ぶぶー）

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isFlipped[firstIndex] = false;
          _isFlipped[secondIndex] = false;
          _selectedCards.clear();
        });
      });
    }
  }

  void _showGameOverDialog() {
    _playSound('sounds/game_clear.mp3'); // ゲームクリアの音

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームクリア！'),
        content: const Text('おめでとうございます！すべてのペアを見つけました。'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInterstitialAd(); // 動画広告を表示
              Navigator.pop(context);
            },
            child: const Text('もう一度プレイ'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('ゲームを終了して戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('はい'),
          ),
        ],
      ),
    )) ??
        false;
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _audioPlayer.dispose(); // リソース解放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white, // 背景を白に設定
        appBar: AppBar(
          title: Text('スコア: $_score ペア'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: widget.images.length,
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: _selectedCards.length < 2 && !_isFlipped[index]
                  ? () => _flipCard(index)
                  : null,
              child: Card(
                child: _isFlipped[index]
                    ? Image.file(
                  widget.images[index],
                  fit: BoxFit.cover,
                )
                    : widget.backImage != null
                    ? (widget.backImage is String
                    ? Image.asset(
                  widget.backImage,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  widget.backImage,
                  fit: BoxFit.cover,
                ))
                    : Container(
                  color: Colors.blue,
                  child: const Center(
                    child: Text(
                      '裏面',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}