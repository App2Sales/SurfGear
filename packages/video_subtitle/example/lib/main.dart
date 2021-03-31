// Copyright (c) 2019-present,  SurfStudio LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

import 'package:video_player_header/video_player_header.dart';
import 'package:video_subtitle/video_subtitle.dart';

const videoUrl =
    'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8';

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final _videoController = VideoPlayerController.asset('assets/video.mp4');

  @override
  void initState() {
    super.initState();

    _videoController.initialize().then((_) {
      setState(() {});
    });
  }

  bool showSub1 = true;
  String sub =
      'https://firebasestorage.googleapis.com/v0/b/o-mensageiro.appspot.com/o/sub%2Fsubtitle.srt?alt=media&token=cbf7fdee-c43e-4ac1-90b5-1481abfa1bac';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFab(),
        persistentFooterButtons: [
          InkWell(
            child: Text('Mudar Legenda ${showSub1 ? 'SUB 1' : 'SUB 2'}'),
            onTap: () {
              final sub1 = showSub1
                  ? 'https://firebasestorage.googleapis.com/v0/b/o-mensageiro.appspot.com/o/sub%2Fsubtitle.srt?alt=media&token=cbf7fdee-c43e-4ac1-90b5-1481abfa1bac'
                  : 'https://firebasestorage.googleapis.com/v0/b/o-mensageiro.appspot.com/o/sub%2Fsubtitle2.srt?alt=media&token=0b4d24cb-d286-4b25-bad3-46a206a73b50';
              setState(() {
                showSub1 = !showSub1;
                sub = sub1;
              });

              final snackBar = SnackBar(content: Text('Yay! A SnackBar!'));

              // Find the ScaffoldMessenger in the widget tree
              // and use it to show a SnackBar.
              Scaffold.of(context).showSnackBar(snackBar);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();

    super.dispose();
  }

  Widget _buildFab() {
    return FloatingActionButton(
      child: Icon(
        _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
      ),
      onPressed: () {
        if (_videoController.value.isPlaying) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
        setState(() {});
      },
    );
  }

  Widget _buildBody() {
    return Center(
      child: SizedBox(
        height: 200,
        child: Stack(
          children: <Widget>[
            AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoSubtitle.network(
                sub,
                videoController: _videoController,
                builder: (context, subtitle) => Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.amber,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(0.0, 0.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Video subtitles'),
    );
  }
}
