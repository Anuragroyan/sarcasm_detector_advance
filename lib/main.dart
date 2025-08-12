import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(SarcasmDetectorApp());
}

class SarcasmDetectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarcasm Detector',
      home: SarcasmHomePage(),
    );
  }
}

class SarcasmHomePage extends StatefulWidget {
  @override
  _SarcasmHomePageState createState() => _SarcasmHomePageState();
}

class _SarcasmHomePageState extends State<SarcasmHomePage> {
  static const platform = MethodChannel('sarcasm.detector.channel');

  final TextEditingController _controller = TextEditingController();
  String _result = 'Enter text and tap Detect.';
  bool isButtonEnabled = false;


  @override
  void initState() {
    super.initState();

    // Add listener to text field controller
    _controller.addListener(() {
      setState(() {
        isButtonEnabled = _controller.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _detectSarcasm() async {
    try {
      final String prediction = await platform.invokeMethod(
        'predictSarcasm',
        {'text': _controller.text},
      );
      setState(() {
        _result = prediction;
      });

    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  Future<void> _clearSarcasm() async {
    try {
      setState(() {
        _result =  "Please Enter Something to Predict☝️️";
        _controller.clear();
      });

    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sarcasm Detector',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 30.0,
        ),
        textAlign: TextAlign.justify,
      )
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter text to analyze',
                labelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
         Expanded(child: ElevatedButton(
           onPressed: isButtonEnabled ? _detectSarcasm : null,
           child: Text('Detect Sarcasm',
             textAlign: TextAlign.center,
             style: TextStyle(
               color: Colors.teal,
               fontWeight: FontWeight.bold,
               fontSize: 13.0,
             ),
           ),
         ),
         ),
      SizedBox(width: 16),
      Expanded(child: ElevatedButton(
        onPressed: isButtonEnabled ? _clearSarcasm : null,
        child: Text('Clear',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
      ),
      ),
            ],
    ),
    ),
            SizedBox(height: 16),
            SizedBox(width: 15),
            Text(
              _result,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
