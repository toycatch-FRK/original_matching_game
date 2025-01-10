import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'game_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // AdMob用

class ImageSelectionScreen extends StatefulWidget {
  const ImageSelectionScreen({super.key});

  @override
  _ImageSelectionScreenState createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  final List<File?> _selectedImages = List<File?>.filled(10, null); // 選択済み画像リスト
  dynamic _backImage; // FileまたはString（アセットのパス）を保持

  BannerAd? _bannerAd; // バナー広告用の変数
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd(); // バナー広告の読み込み
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8946560300471397/3781663067',
      // adUnitId: 'ca-app-pub-3940256099942544/6300978111',//test
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('バナー広告の読み込み失敗: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImages[index] = File(pickedFile.path); // 指定インデックスの画像を更新
      });
    }
  }

  Future<void> _pickBackImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;

        return Container(
          padding: const EdgeInsets.all(16.0),
          height: isTablet ? 300.0 : 200.0, // タブレットで大きく表示
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Image.asset('assets/star.png', width: 60, height: 60),
                title: const Text(
                  '星マークを選択',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () {
                  setState(() {
                    _backImage = 'assets/star.png'; // 星マークを選択
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/heart.png', width: 60, height: 60),
                title: const Text(
                  'ハートマークを選択',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () {
                  setState(() {
                    _backImage = 'assets/heart.png'; // ハートマークを選択
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, size: 40),
                title: const Text(
                  'ギャラリーから選択',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    setState(() {
                      _backImage = File(pickedFile.path); // ギャラリー画像を選択
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startGame() {
    final allImages = _selectedImages.whereType<File>().toList()
      ..addAll(_selectedImages.whereType<File>().toList())
      ..shuffle();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(images: allImages, backImage: _backImage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              '表面用画像を選択してください（10枚）',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 5 : 4,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1, // 正方形に調整
            ),
            itemCount: 10,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _pickImage(index),
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _selectedImages[index] != null
                      ? Image.file(
                    _selectedImages[index]!,
                    fit: BoxFit.cover,
                  )
                      : const Center(
                    child: Text(
                      '画像を選択',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          Column(
            children: [
              const Text(
                '裏面用画像を選択してください（1枚）',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: _pickBackImage,
                child: Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.green,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SizedBox(
                    height: isTablet ? 180.0 : 120.0, // タブレットで拡大
                    width: isTablet ? 180.0 : 120.0,
                    child: _backImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _backImage is String
                          ? Image.asset(
                        _backImage,
                        fit: BoxFit.cover,
                      )
                          : Image.file(
                        _backImage,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Center(
                      child: Text(
                        '裏面画像を選択',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _selectedImages.every((image) => image != null) &&
                _backImage != null
                ? _startGame
                : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48.0 : 32.0,
                vertical: isTablet ? 24.0 : 16.0,
              ),
              textStyle: TextStyle(
                fontSize: isTablet ? 24.0 : 20.0, // タブレットで拡大
              ),
            ),
            child: const Text('ゲームスタート'),
          ),
          const SizedBox(height: 24.0),

          if (_isAdLoaded)
            Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width,
              height: 50.0, // 広告の高さと同じ
              color: Colors.grey, // グレーの背景色
              child: Text(
                '広告スペース',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
        ],
      ),
    );
  }
}
